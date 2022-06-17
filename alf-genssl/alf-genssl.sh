#!/bin/bash
# (c) by ecm4u GmbH
# Author Heiko Robert <heiko.robert@ecm4u.de>
# this script is part of the ecm4u virtual appliance for Alfresco

# https://docs.alfresco.com/content-services/latest/admin/security/#alfresco-keystore-configuration

########## BEGIN setup environment ##########

### load variables and defaults defined in ALF_GENSSL_CONFIG
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
echo "SCRIPTPATH: $SCRIPTPATH"
: ${ALF_GENSSL_CONFIG:=$SCRIPTPATH/alf-gensslrc}

if [ -f "$ALF_GENSSL_CONFIG" ]; then
    . ${ALF_GENSSL_CONFIG}
fi

# check password variables or generate if not set
# CA key password
if [[ -z "$SSL_CA_PASS" ]];then
    # SSL_CA_PASS="$(pwgen 20 1)" # generate one password with 20 chars length
    # echo "SSL_CA_PASS=$SSL_CA_PASS" >> "$ALF_GENSSL_CUSTOM_CONFIG"
    echo "SSL_CA_PASS not set - aborting"
    exit 1
fi

# # content encryption key password
if [[ -z "$META_PASSWORD" ]];then
    echo "META_PASSWORD not set - aborting"
    exit 1
fi

# # repo key password
if [[ -z "$REPO_PASSWORD" ]];then
    echo "REPO_PASSWORD not set - aborting"
    exit 1
fi

# # solr (repo client) key password
if [[ -z "$SOLR_PASSWORD" ]];then
    echo "SOLR_PASSWORD not set - aborting"
    exit 1
fi


########## END setup environment ##########

create_ca_dirs(){
    mkdir -p $SSL_BASE/$SSL_CA_NAME/{certs,signedcerts,private}
    mkdir -p $SSL_BASE/{certs,backup-keystore,keystore}
    chmod 700 $SSL_BASE/$SSL_CA_NAME/private
}

cleanup_ca(){
    create_ca_dirs
    rm -f $SSL_CA_KEY
    rm -f $SSL_BASE/$SSL_CA_NAME/{index.txt,certs/*,private/*,serial,signedcerts/*}
    rm -f $SSL_CA_CERT $SSL_BASE/careq.pem
}

create_ca_key(){
    if [[ CREATE_FORCE==1 ]]; then
        cleanup_ca
    fi
    if [[ ! -e $SSL_BASE/$SSL_CA_NAME/index.txt ]];then
        touch $SSL_BASE/$SSL_CA_NAME/index.txt
    fi
    if [[ ! -e "$SSL_CA_KEY" ]]; then
        echo "creating new ca key: $SSL_CA_KEY" 
        openssl genrsa -aes256 -passout pass:$SSL_CA_PASS -out $SSL_CA_KEY $KEY_SIZE
        chmod 400 $SSL_CA_KEY
    fi
}

create_ca_cert(){
    if [[ -e $SSL_CA_KEY ]];then
        # create cert signing request
        openssl req -new \
            -key $SSL_CA_KEY \
            -out $SSL_BASE/ca.csr \
            -subj "$CA_SUBJ" \
            -extensions v3_ca \
            -passin pass:$SSL_CA_PASS 

        # to check csr details:
        # openssl req -text -noout -verify -in $SSL_BASE/ca.csr

        # now create new CA cert
        # -create_serial is especially important. 
        # Many HOW-TOs will have you echo "01" into the serial file thus starting the serial number at 1, 
        # and using 8-bit serial numbers instead of 128-bit serial numbers. This will generate a random 
        # 128-bit serial number to start with. The randomness helps to ensure that if you make a mistake 
        # and start over, you won't overwrite existing serial numbers out there.
        echo "creating new ca cert: $SSL_CA_CERT" 
        openssl ca -create_serial \
            -batch \
            -out $SSL_CA_CERT \
            -days $SSL_CA_DAYS \
            -keyfile $SSL_CA_KEY -passin pass:$SSL_CA_PASS \
            -selfsign -extensions v3_ca \
            -infiles $SSL_BASE/ca.csr 
        cp $SSL_CA_CERT $SSL_BASE/certs/
    else
        echo "no ca key found - exiting ..."
        exit 1
    fi
}


create_metadata_keystore(){
    
    create_ca_dirs
    
    #####  keystore for content encryption  #####  
    # we need to support an emtpy name for alfresco's pattern without a name 
    if [ -z "$SSL_META_NAME" ] && [ "${SSL_META_NAME+xxx}" = "xxx" ]; then  # SSL_META_NAME is set but empty
        SSL_META_NAME=metadata
        SSL_META_ALIAS=$SSL_META_NAME
        SSL_META_KEYSTORE=$SSL_KEYSTORE/$SSL_META_NAME.keystore
        SSL_META_KEYSTORE_PROP=keystore-passwords.properties
    else 
        : ${SSL_META_NAME:=metadata} # in case variable is not set at all
        : ${SSL_META_ALIAS:=$SSL_META_NAME}
        : ${SSL_META_KEYSTORE:=$SSL_KEYSTORE/$SSL_META_NAME.keystore}
        SSL_META_KEYSTORE_PROP=${SSL_META_NAME}-keystore-passwords.properties
    fi

    if [[ -f $SSL_META_KEYSTORE ]];then
        SSL_META_KEYSTORE_OLD=$SSL_META_NAME.keystore
        SSL_META_KEYSTORE_OLD_PROP=$SSL_META_NAME-keystore-passwords.properties
    elif [[ -f ${SSL_KEYSTORE}/keystore ]];then
        SSL_META_KEYSTORE_OLD=${SSL_KEYSTORE}/keystore
        SSL_META_KEYSTORE_OLD_PROP=keystore-passwords.properties
    fi

    if [[ $SSL_META_KEYSTORE_OLD ]];then
        echo "    creating keystore backup ..."
        tar cfz $SSL_BASE/backup-keystore/$(date '+%Y-%m-%d_%H%M%S')-metadata.tgz \
            -C $SSL_KEYSTORE/ $SSL_META_KEYSTORE_OLD $SSL_META_KEYSTORE_OLD_PROP
        echo "    moving $SSL_META_KEYSTORE to $SSL_BASE/backup-keystore/"
        mv $SSL_KEYSTORE/{$SSL_META_KEYSTORE_OLD,$SSL_META_KEYSTORE_OLD_PROP} $SSL_BASE/backup-keystore/
        BACKUP_METADATA_KEYSTORE=1
    else
        echo "no previous medadata keystore found ..."
    fi

    echo "    creating new metadata keystore $SSL_META_KEYSTORE $KEYSTORE_TYPE $META_KEYSTORE_KEY_ALG $META_KEYSTORE_KEY_SIZE"

    keytool -genseckey -alias $SSL_META_ALIAS -keypass $META_PASSWORD \
        -storepass $META_PASSWORD -keystore "$SSL_META_KEYSTORE" \
        -storetype $KEYSTORE_TYPE -keyalg $META_KEYSTORE_KEY_ALG -keysize $META_KEYSTORE_KEY_SIZE
    RESULT=$?

    if [[ $RESULT -eq 0 ]]; then
        # Create Alfresco Encryption password file
        echo "    generating ${SSL_META_NAME}keystore-passwords.properties ..." 

        echo "aliases=$SSL_META_ALIAS" > ${SSL_KEYSTORE}/$SSL_META_KEYSTORE_PROP
        echo "# The password protecting the keystore entries" >> ${SSL_KEYSTORE}/$SSL_META_KEYSTORE_PROP
        echo "keystore.password=$META_PASSWORD" >> ${SSL_KEYSTORE}/$SSL_META_KEYSTORE_PROP
        echo "# The password protecting the alias: $SSL_META_ALIAS" >> ${SSL_KEYSTORE}/$SSL_META_KEYSTORE_PROP
        echo "metadata.keyData=" >> ${SSL_KEYSTORE}/$SSL_META_KEYSTORE_PROP
        echo "metadata.algorithm=$META_KEYSTORE_KEY_ALG" >> ${SSL_KEYSTORE}/$SSL_META_KEYSTORE_PROP
        echo "metadata.password=$META_PASSWORD" >> ${SSL_KEYSTORE}/$SSL_META_KEYSTORE_PROP

        update_config

        if [[ $BACKUP_METADATA_KEYSTORE ]]; then
            echo ""
            echo ""
            echo " ######### IMPORTANT #############"
            echo " You MUST start alfresco now to migrate encrypted nodes"
            echo " if you call this script again without alfresco start"
            echo " your content may be lost!!!	"
            echo " ######### IMPORTANT #############"
            echo ""
            echo "please run now:"
            echo "sudo systemctl start alfresco"
        fi
    else
        # on ERROR recover backup-keystore
        if [[ $BACKUP_METADATA_KEYSTORE ]]; then
            mv $SSL_BASE/backup-keystore/{$(basename $SSL_META_KEYSTORE),$SSL_META_KEYSTORE_PROP} $SSL_KEYSTORE/
        fi

        echo "ERROR failed to generate metadata keystore!"
    fi
}

create_csr(){
    local SSL_NAME="$1" 
    local SSL_ALIAS="$2"
    local SSL_PASSWORD="$3"
    local SSL_DNAME="$4"

    echo "    creating keystore for: "$SSL_DNAME""
    # we just recreate the full keystore every time
    rm -f "${SSL_KEYSTORE}/$SSL_NAME.keystore"
    keytool -genkeypair -alias $SSL_ALIAS -keyalg $KEYSTORE_KEY_ALG \
    -keysize $KEY_SIZE -keystore "${SSL_KEYSTORE}/$SSL_NAME.keystore" \
    -storetype $KEYSTORE_TYPE -storepass "$SSL_PASSWORD" \
    -dname "$SSL_DNAME" \
    -validity $SSL_DAYS -keypass "$SSL_PASSWORD"
    # create certificat signing request
    rm -f "$SSL_BASE/$SSL_NAME.csr"
    keytool -keystore "${SSL_KEYSTORE}/$SSL_NAME.keystore" -alias "$SSL_ALIAS" -certreq -file "$SSL_BASE/$SSL_NAME.csr" \
        -storetype $KEYSTORE_TYPE -storepass "$SSL_PASSWORD"
}

create_cert(){
    local SSL_NAME="$1" 
    local SSL_ALIAS="$2"
    local SSL_PASSWORD="$3"
    if [[ -z $4 ]]; then
        SERVER_NAME=localhost
    else
        SERVER_NAME=$4
    fi
   
    echo "create_cert: SERVER_NAME: $SERVER_NAME"
    # replace alternative name in openssl config
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/DNS.1.*/DNS.1 = $SERVER_NAME/" $OPENSSL_CONF;
    else
        sed -i "s/DNS.1.*/DNS.1 = $SERVER_NAME/" $OPENSSL_CONF;
    fi

    # create and sign certificate
    rm -f "$SSL_BASE/certs/$SSL_NAME.crt"
    # openssl x509 -extensions server_cert -passin pass:$SSL_CA_PASS -CA $SSL_CA_CERT -CAkey $SSL_CA_KEY \
    #     -req -in $SSL_BASE/$SSL_NAME.csr -out "$SSL_BASE/certs/$SSL_NAME.crt" -days $SSL_DAYS
    openssl ca -extensions server_cert -passin pass:$SSL_CA_PASS -batch\
        -days $SSL_DAYS -in $SSL_BASE/$SSL_NAME.csr -out "$SSL_BASE/certs/$SSL_NAME.crt" # -config $OPENSSL_CONF 
    # openssl x509 -in "$SSL_BASE/certs/$SSL_NAME.crt" -text
    
    openssl verify -CAfile $SSL_CA_CERT "$SSL_BASE/certs/$SSL_NAME.crt"
    RESULT=$?
    if [[ $RESULT != 0 ]];then
        echo "failed to validate certificate path for $SSL_BASE/certs/$SSL_NAME.crt!"
        exit 1
    fi
}

import_cert(){
    local SSL_NAME="$1" 
    local SSL_ALIAS="$2"
    local SSL_PASSWORD="$3"

    # import CA
    keytool -import -noprompt -alias "$SSL_CA_ALIAS" -file "$SSL_CA_CERT" -keystore "${SSL_KEYSTORE}/$SSL_NAME.keystore" \
        -storetype $KEYSTORE_TYPE -storepass "$SSL_PASSWORD"
    # import certificate
    keytool -import -noprompt -alias $SSL_ALIAS -file "$SSL_BASE/certs/$SSL_NAME.crt" -keystore "${SSL_KEYSTORE}/$SSL_NAME.keystore" \
        -storetype $KEYSTORE_TYPE -storepass "$SSL_PASSWORD"

    # Create keystore password file
    echo "aliases=$SSL_CA_ALIAS, $SSL_ALIAS" > ${SSL_KEYSTORE}/$SSL_NAME-keystore-passwords.properties
    echo "# The password protecting the keystore entries" >> ${SSL_KEYSTORE}/$SSL_NAME-keystore-passwords.properties
    echo "keystore.password=$SSL_PASSWORD" >> ${SSL_KEYSTORE}/$SSL_NAME-keystore-passwords.properties
    echo "# The password protecting the alias: $SSL_ALIAS" >> ${SSL_KEYSTORE}/$SSL_NAME-keystore-passwords.properties
    echo "$SSL_ALIAS.keyData=" >> ${SSL_KEYSTORE}/$SSL_NAME-keystore-passwords.properties
    echo "$SSL_ALIAS.algorithm=$KEYSTORE_KEY_ALG" >> ${SSL_KEYSTORE}/$SSL_NAME-keystore-passwords.properties
    echo "$SSL_ALIAS.password=$SSL_PASSWORD" >> ${SSL_KEYSTORE}/$SSL_NAME-keystore-passwords.properties
    echo "$SSL_CA_ALIAS.password=$SSL_PASSWORD" >> ${SSL_KEYSTORE}/$SSL_NAME-keystore-passwords.properties

    # create truststore and import CA cert in one step
    rm -f "${SSL_KEYSTORE}/$SSL_NAME.truststore"
    keytool -import -trustcacerts -noprompt -alias "$SSL_CA_ALIAS" -file "$SSL_CA_CERT" -keystore "${SSL_KEYSTORE}/$SSL_NAME.truststore" \
        -storetype $TRUSTSTORE_TYPE  -storepass "$SSL_PASSWORD"
    # Create truststore password files
    echo "aliases=$SSL_CA_ALIAS" > ${SSL_KEYSTORE}/$SSL_NAME-truststore-passwords.properties
    echo "# The password protecting the keystore entries" >> ${SSL_KEYSTORE}/$SSL_NAME-truststore-passwords.properties
    echo "keystore.password=$SSL_PASSWORD" >> ${SSL_KEYSTORE}/$SSL_NAME-truststore-passwords.properties
    echo "# The password protecting the alias: $SSL_ALIAS" >> ${SSL_KEYSTORE}/$SSL_NAME-truststore-passwords.properties
    echo "$SSL_CA_ALIAS.keyData=" >> ${SSL_KEYSTORE}/$SSL_NAME-truststore-passwords.properties
    echo "$SSL_CA_ALIAS.algorithm=$KEYSTORE_KEY_ALG" >> ${SSL_KEYSTORE}/$SSL_NAME-truststore-passwords.properties
    echo "$SSL_CA_ALIAS.password=$SSL_PASSWORD" >> ${SSL_KEYSTORE}/$SSL_NAME-truststore-passwords.properties
}

export_client_certs(){
    local SSL_NAME="$1" 
    local SSL_ALIAS="$2"
    local SSL_PASSWORD="$3"

    
    # create browser store
    rm -f "$SSL_BASE/certs/browser-${SSL_NAME}.p12"
    keytool -importkeystore -srckeystore "${SSL_KEYSTORE}/$SSL_NAME.keystore" -srcstorepass "$SSL_PASSWORD" \
        -srcstoretype $KEYSTORE_TYPE -srcalias $SSL_ALIAS -srckeypass "$SSL_PASSWORD" -destkeystore "$SSL_BASE/certs/browser-${SSL_NAME}.p12" \
        -deststoretype pkcs12 -deststorepass "$BROWSER_IMP_PW" -destalias $SSL_ALIAS -destkeypass "$BROWSER_IMP_PW"
    # export pem cert for scripting
    openssl pkcs12 -in "$SSL_BASE/certs/browser-${SSL_NAME}.p12" -out $SSL_BASE/certs/client-${SSL_NAME}.pem -clcerts \
        -passin pass:"$BROWSER_IMP_PW" -passout pass:"$BROWSER_IMP_PW"
}

create_cert_full(){
    local SSL_NAME="$1" 
    local SSL_ALIAS="$2"
    local SSL_PASSWORD="$3"
    local SSL_DNAME="$4"
    if [[ -z $5 ]]; then
        SERVER_NAME=localhost
    else
        SERVER_NAME=$5
    fi

    echo "create_cert_full: SERVER_NAME: $SERVER_NAME"

    create_csr $SSL_NAME $SSL_ALIAS "$SSL_PASSWORD" "$SSL_DNAME"
    create_cert $SSL_NAME $SSL_ALIAS "$SSL_PASSWORD" "$SERVER_NAME"
    import_cert $SSL_NAME $SSL_ALIAS "$SSL_PASSWORD"
    export_client_certs  $SSL_NAME $SSL_ALIAS "$SSL_PASSWORD"
}

update_config(){

    if which confset > /dev/null;then 
        if [[ -e $ALF_HOME/conf/alfresco-global.properties ]];then
            if [[ $BACKUP_METADATA_KEYSTORE == 1 ]]; then
                echo "    metadata key has been recreated - configuring backup key ..."
                confset \
                    encryption.keystore.backup.location="\${dir.keystore}/../backup-keystore/$SSL_META_KEYSTORE_OLD" \
                    encryption.keystore.backup.type=$(sed -n -e 's/^encryption.keystore.backup.type=\(a-zA-Z\)*/\1/p' $ALF_HOME/conf/alfresco-global.properties) \
                    encryption.keystore.backup.keyMetaData.location="$(sed -n -e 's/^encryption.keystore.backup.keyMetaData.location=\(.*\)$/\1/p' $ALF_HOME/conf/alfresco-global.properties)" \
                    $ALF_HOME/conf/alfresco-global.properties
                
                if [[ $? != 0 ]];then
                    echo "ERROR: configuring encryption.keystore.backup failed"
                    echo "you must fix this not to loose your content!"
                    exit 1
                fi
            fi

            confset dir.keystore=${SSL_KEYSTORE} $ALF_HOME/conf/alfresco-global.properties
            confset \
                encryption.ssl.keystore.location="\${dir.keystore}/$SSL_REPO_NAME.keystore" \
                encryption.ssl.keystore.type="$KEYSTORE_TYPE" \
                encryption.ssl.keystore.keyMetaData.location="\${dir.keystore}/$SSL_REPO_NAME-keystore-passwords.properties" \
                encryption.ssl.truststore.location="\${dir.keystore}/$SSL_REPO_NAME.truststore" \
                encryption.ssl.truststore.type=$TRUSTSTORE_TYPE \
                encryption.ssl.truststore.keyMetaData.location="\${dir.keystore}/$SSL_REPO_NAME-truststore-passwords.properties" \
                encryption.keystore.location="\${dir.keystore}/$SSL_META_NAME.keystore" \
                encryption.keystore.type="$KEYSTORE_TYPE" \
                encryption.keystore.keyMetaData.location="\${dir.keystore}/$SSL_META_NAME-keystore-passwords.properties" \
                $ALF_HOME/conf/alfresco-global.properties
        else
            echo "WARNING: $ALF_HOME/conf/alfresco-global.properties not found!"
        fi

        if [[ -e /etc/default/solr.in.sh ]]; then
            confset \
                SOLR_SSL_KEY_STORE="$SSL_SOLR_KEYSTORE" \
                SOLR_SSL_KEY_STORE_TYPE=$KEYSTORE_TYPE \
                SOLR_SSL_KEY_STORE_PASSWORD="$SOLR_PASSWORD" \
                SOLR_SSL_TRUST_STORE="$SSL_SOLR_TRUSTSTORE" \
                SOLR_SSL_TRUST_STORE_PASSWORD="$SOLR_PASSWORD" \
                /etc/default/solr.in.sh
        fi

        if [[ ! -z $SOLR_CORE_TEMPLATE ]] && [[ -e $SOLR_CORE_TEMPLATE ]];then
            confset \
                alfresco.encryption.ssl.keystore.type="$KEYSTORE_TYPE" \
                alfresco.encryption.ssl.keystore.location="${SSL_KEYSTORE}/$SSL_SOLR_NAME.keystore" \
                alfresco.encryption.ssl.keystore.passwordFileLocation="${SSL_KEYSTORE}/$SSL_SOLR_NAME-keystore-passwords.properties" \
                alfresco.encryption.ssl.truststore.type=$TRUSTSTORE_TYPE \
                alfresco.encryption.ssl.truststore.location="${SSL_KEYSTORE}/$SSL_SOLR_NAME.truststore" \
                alfresco.encryption.ssl.truststore.passwordFileLocation="${SSL_KEYSTORE}/$SSL_SOLR_NAME-truststore-passwords.properties" \
                $SOLR_CORE_TEMPLATE/conf/solrcore.properties \
                $SOLR_HOME/alfresco/rerank/conf/solrcore.properties \
                $SOLR_HOME/alfresco/conf/solrcore.properties \
                $SOLR_HOME/alfresco/rerank/conf/solrcore.properties \
                $SOLR_HOME/archive/conf/solrcore.properties
        fi
      

        if [[ -e $ALF_HOME/tomcat/conf/server.xml ]] && which xmlstarlet > /dev/null && [[ ! -z $ALF_TOMCAT_SSL_PORT ]];then
            xmlstarlet ed --inplace --update '/Server/Service/Connector[@port='$ALF_TOMCAT_SSL_PORT']/@keystoreFile' --value "${SSL_KEYSTORE}/$SSL_REPO_NAME.keystore"  /opt/alfresco/tomcat/conf/server.xml
            xmlstarlet ed --inplace --update '/Server/Service/Connector[@port='$ALF_TOMCAT_SSL_PORT']/@keystorePass' --value "$REPO_PASSWORD"  /opt/alfresco/tomcat/conf/server.xml
            xmlstarlet ed --inplace --update '/Server/Service/Connector[@port='$ALF_TOMCAT_SSL_PORT']/@keystoreType' --value "$KEYSTORE_TYPE"  /opt/alfresco/tomcat/conf/server.xml
            xmlstarlet ed --inplace --update '/Server/Service/Connector[@port='$ALF_TOMCAT_SSL_PORT']/@truststoreFile' --value "${SSL_KEYSTORE}/$SSL_REPO_NAME.truststore"  /opt/alfresco/tomcat/conf/server.xml
            xmlstarlet ed --inplace --update '/Server/Service/Connector[@port='$ALF_TOMCAT_SSL_PORT']/@truststorePass' --value "$REPO_PASSWORD"  /opt/alfresco/tomcat/conf/server.xml
            xmlstarlet ed --inplace --update '/Server/Service/Connector[@port='$ALF_TOMCAT_SSL_PORT']/@truststoreType' --value "$TRUSTSTORE_TYPE"  /opt/alfresco/tomcat/conf/server.xml
        else
            echo "WARNING: please ajust tomcat's server.xml"
        fi
    else
        echo "sorry - command not supported here. Are you running from a ecm4u Alfresco Virtual Appliance?"
        exit 1
    fi

}


# # Parse params from command line
while test $# -gt 1
do
    case "$1" in
        # # community, enterprise
        # -alfrescoversion)
        #     ALFRESCO_VERSION=$2
        #     shift
        # ;;
        # 1024, 2048, 4096, ...
        -keysize)
            KEY_SIZE=$2
            shift
        ;;
        # PKCS12, JKS, JCEKS
        -keystoretype)
            KEYSTORE_TYPE=$2
            shift
        ;;
        # JKS, JCEKS
        -truststoretype)
            TRUSTSTORE_TYPE=$2
            shift
        ;;

        # Alfresco Format: "classic" / "current" is supported only from 7.0
        -alfrescoformat)
            ALFRESCO_FORMAT="$2"
            shift
        ;;
        *)
            echo "An invalid parameter was received: $1"
            echo "Allowed parameters:"
            echo "  -keysize 2048 [1024 | 2048 | 4096]"
            echo "  -keystoretype [PKCS12 | JKS | JCEKS]"
            echo "  -truststoretype JCEKS [JKS | JCEKS]"
            echo "  -alfrescoformat current [classic | current]"
            exit 1
        ;;
    esac
    shift
done


case "$1" in
    ca)
        cleanup_ca
        create_ca_key
        create_ca_cert
        ;;
    keystores)
        create_cert_full "$SSL_REPO_NAME" "$SSL_REPO_ALIAS" "$REPO_PASSWORD" "$REPO_CERT_DNAME" $(hostname -f)
        create_cert_full "$SSL_SOLR_NAME" "$SSL_SOLR_ALIAS" "$SOLR_PASSWORD" "$SOLR_CERT_DNAME" $(hostname -f)
        update_config
        ;;
    createcsr)
        echo create_csr "$SSL_REPO_NAME" "$SSL_REPO_ALIAS" "$REPO_PASSWORD" "$REPO_CERT_DNAME"
        echo create_csr "$SSL_SOLR_NAME" "$SSL_SOLR_ALIAS" "$SOLR_PASSWORD" "$SOLR_CERT_DNAME"

        ;;
    createcert)
        create_cert $SSL_REPO_NAME $SSL_REPO_ALIAS "$REPO_PASSWORD" $(hostname -f)
        create_cert $SSL_SOLR_NAME $SSL_SOLR_ALIAS "$SOLR_PASSWORD" $(hostname -f)
        ;;
    importcert)
        import_cert $SSL_REPO_NAME $SSL_REPO_ALIAS "$REPO_PASSWORD"
        import_cert $SSL_SOLR_NAME $SSL_SOLR_ALIAS "$SOLR_PASSWORD"
        ;;
    exportclientcerts)
        export_client_certs $SSL_REPO_NAME $SSL_REPO_ALIAS "$REPO_PASSWORD"
        export_client_certs $SSL_SOLR_NAME $SSL_SOLR_ALIAS "$SOLR_PASSWORD"
        ;;
    updateconfig)
        update_config
        ;;
    cadirs)
        create_ca_dirs
        ;;
    cleanup-ca)
        cleanup_ca
        ;;
    create-ca-key)
        create_ca_key
        ;;
    create-ca-cert)
        create_ca_cert
        ;;
    metadatakeystore)
        create_metadata_keystore
        ;;    
    *)
        echo "Usage: $0 {keystores|createcsr|createcert|importcert|exportclientcerts|updateconfig|cadirs|cleanup-ca|create-ca-key|create-ca-cert|metadatakeystore }"
        exit 1
        ;;

esac
