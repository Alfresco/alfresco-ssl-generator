#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

# This script generates certificates for Repository and SOLR TLS/SSL Mutual Auth Communication:
#
# * CA Entity to issue all required certificates (alias alfresco.ca)
# * Server Certificate for Alfresco (alias ssl.repo)
# * Server Certificate for SOLR (alias ssl.repo.client)
#
# "openssl.cnf" file is provided for CA Configuration.
#
# Once this script has been executed successfully, following resources are generated in ${KEYSTORES_DIR} folder for "classic" Alfresco format:
#
# .
# ├── alfresco
# │   ├── keystore
# │   ├── keystore-passwords.properties
# │   ├── ssl-keystore-passwords.properties
# │   ├── ssl-truststore-passwords.properties
# │   ├── ssl.keystore
# │   └── ssl.truststore
# ├── client
# │   └── browser.p12
# ├── solr
# │   ├── ssl-keystore-passwords.properties
# │   ├── ssl-truststore-passwords.properties
# │   ├── ssl.repo.client.keystore
# │   └── ssl.repo.client.truststore
# └── zeppelin
#     ├── ssl.repo.client.keystore
#     └── ssl.repo.client.truststore
#
# When using "current" Alfresco format (available from ACS 7.0), following resources are generated in ${KEYSTORES_DIR}
# .
# ├── alfresco
# │   ├── keystore
# │   ├── ssl.keystore
# │   └── ssl.truststore
# ├── client
# │   └── browser.p12
# ├── solr
# │   ├── ssl-repo-client.keystore
# │   └── ssl-repo-client.truststore
# └── zeppelin
#     ├── ssl-repo-client.keystore
#     └── ssl-repo-client.truststore
#
# "alfresco" files must be copied to "alfresco/keystore" folder
# "solr" files must be copied to "solr6/keystore"
# "zeppelin" files must be copied to "zeppelin/keystore"
# "client" files can be used from a browser to access the server using HTTPS in port 8443

# PARAMETERS

# Version of Alfresco: enterprise, community
ALFRESCO_VERSION=enterprise

# Using "current" format by default (only available from ACS 7.0+)
ALFRESCO_FORMAT=current

# Distinguished name of the CA
CA_DNAME="/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA"
# Distinguished name of the Server Certificate for Alfresco
REPO_CERT_DNAME="/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository"
# Distinguished name of the Server Certificate for SOLR
SOLR_CERT_DNAME="/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository Client"
# Distinguished name of the Browser Certificate for SOLR
BROWSER_CLIENT_CERT_DNAME="/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Browser Client"

# Alfresco and SOLR server names, to be used as Alternative Name in the certificates
CA_SERVER_NAME=localhost
ALFRESCO_SERVER_NAME=localhost
SOLR_SERVER_NAME=localhost

# CA parameters
SSL_BASE=ca
SSL_CA_KEY=$SSL_BASE/private/ca.key.pem
SSL_CA_CERT=$SSL_BASE/certs/ca.cert.pem
SSL_CA_PASS=ca
SSL_CA_DAYS=7300

# RSA key length (1024, 2048, 4096)
KEY_SIZE=2048

# Caducity for generated server certificates (Alfresco, Solr)
SSL_DAYS=3650

# Keystore format (PKCS12, JKS, JCEKS)
KEYSTORE_TYPE=JCEKS
# Truststore format (JKS, JCEKS)
TRUSTSTORE_TYPE=JCEKS

# Default password for every keystore and private key
KEYSTORE_PASS=keystore
# Default password for every truststore
TRUSTSTORE_PASS=truststore

# Encryption secret key passwords
ENC_STORE_PASS=password
ENC_METADATA_PASS=password
ENC_STORE_TYPE=PKCS12
ENC_KEY_ALG="-keyalg AES -keysize 256"

# Folder where keystores, truststores and cerfiticates are generated
KEYSTORES_DIR=keystores
ALFRESCO_KEYSTORES_DIR=keystores/alfresco
SOLR_KEYSTORES_DIR=keystores/solr
ZEPPELIN_KEYSTORES_DIR=keystores/zeppelin
CLIENT_KEYSTORES_DIR=keystores/client
CERTIFICATES_DIR=certificates

create_ca_dirs() {
    mkdir -p $KEYSTORES_DIR
    mkdir -p $ALFRESCO_KEYSTORES_DIR
    mkdir -p $SOLR_KEYSTORES_DIR
    mkdir -p $ZEPPELIN_KEYSTORES_DIR
    mkdir -p $CLIENT_KEYSTORES_DIR
    mkdir -p $CERTIFICATES_DIR
    mkdir -p ca
    mkdir $SSL_BASE/{certs,crl,newcerts,private}
    chmod 700 ca/private

}

cleanup_ca() {
    rm -rf $SSL_BASE/*
    rm -rf $KEYSTORES_DIR/*
    rm -rf $ALFRESCO_KEYSTORES_DIR/*
    rm -rf $SOLR_KEYSTORES_DIR/*
    rm -rf $ZEPPELIN_KEYSTORES_DIR/*
    rm -rf $CLIENT_KEYSTORES_DIR/*
    rm -rf $CERTIFICATES_DIR/*
    create_ca_dirs
}

create_ca_key(){

    if [[ ! -e $SSL_BASE/index.txt ]];then
        touch $SSL_BASE/index.txt
    fi
    echo "creating new ca key: $SSL_CA_KEY" 
    openssl genrsa -aes256 -passout pass:$SSL_CA_PASS -out $SSL_CA_KEY $KEY_SIZE
    chmod 400 $SSL_CA_KEY

}

create_ca_cert(){

    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/DNS.1.*/DNS.1 = $CA_SERVER_NAME/" openssl.cnf;
    else
      sed -i "s/DNS.1.*/DNS.1 = $CA_SERVER_NAME/" openssl.cnf;
    fi

    if [[ -e $SSL_CA_KEY ]];then

        echo "creating new CA csr: $SSL_BASE/ca.cert.pem"
        openssl req -config openssl.cnf -new \
            -key $SSL_CA_KEY \
            -out $SSL_BASE/ca.csr \
            -subj "$CA_DNAME" \
            -extensions v3_ca \
            -sha256 \
            -passin pass:$SSL_CA_PASS         

        echo "creating new CA cert: $SSL_CA_CERT" 
        openssl ca -create_serial \
            -config openssl.cnf \
            -batch \
            -out $SSL_CA_CERT \
            -days $SSL_CA_DAYS \
            -keyfile $SSL_CA_KEY -passin pass:$SSL_CA_PASS \
            -selfsign -extensions v3_ca \
            -infiles $SSL_BASE/ca.csr 
    else
        echo "no CA key found - exiting ..."
        exit 1
    fi
}

create_server_cert() {

  local SERVER_NAME="$1"
  local CERT_DNAME="$2"
  local CERT_NAME="$3" 
  local CERT_PASSWORD="$4"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/DNS.1.*/DNS.1 = $SERVER_NAME/" openssl.cnf;
  else
    sed -i "s/DNS.1.*/DNS.1 = $SERVER_NAME/" openssl.cnf;
  fi
  
  echo "creating new Alfresco cert: $CERTIFICATES_DIR/$CERT_NAME.key"
  openssl req -newkey rsa:$KEY_SIZE -nodes -out $CERTIFICATES_DIR/$CERT_NAME.csr -keyout $CERTIFICATES_DIR/$CERT_NAME.key -subj "$CERT_DNAME"

  openssl ca -config openssl.cnf -extensions clientServer_cert -passin pass:$SSL_CA_PASS -batch -notext \
  -days $SSL_DAYS -in $CERTIFICATES_DIR/$CERT_NAME.csr -out $CERTIFICATES_DIR/$CERT_NAME.cer

  openssl pkcs12 -export -out $CERTIFICATES_DIR/$CERT_NAME.p12 -inkey $CERTIFICATES_DIR/$CERT_NAME.key \
  -in $CERTIFICATES_DIR/$CERT_NAME.cer -password pass:$CERT_PASSWORD -certfile $SSL_CA_CERT

  openssl verify -CAfile $SSL_CA_CERT "$CERTIFICATES_DIR/$CERT_NAME.cer"
  RESULT=$?
  if [[ $RESULT != 0 ]];then
      echo "failed to validate certificate path for $CERTIFICATES_DIR/$CERT_NAME.cer!"
      exit 1
  fi

}

create_solr_browser_cert() {

  echo "creating new Solr cert: $CERTIFICATES_DIR/browser.p12"

  openssl req -newkey rsa:$KEY_SIZE -nodes -out $CERTIFICATES_DIR/browser.csr -keyout $CERTIFICATES_DIR/browser.key \
  -subj "$BROWSER_CLIENT_CERT_DNAME"

  openssl ca -config openssl.cnf -extensions client_cert -passin pass:$SSL_CA_PASS -batch -notext \
  -days $SSL_DAYS -in $CERTIFICATES_DIR/browser.csr -out $CERTIFICATES_DIR/browser.cer

  openssl pkcs12 -export -out $CERTIFICATES_DIR/browser.p12 -inkey $CERTIFICATES_DIR/browser.key \
  -in $CERTIFICATES_DIR/browser.cer -password pass:$KEYSTORE_PASS -certfile $SSL_CA_CERT

  openssl verify -CAfile $SSL_CA_CERT "$CERTIFICATES_DIR/browser.cer"
  RESULT=$?
  if [[ $RESULT != 0 ]];then
      echo "failed to validate certificate path for $CERTIFICATES_DIR/browser.cer!"
      exit 1
  fi

    cp $CERTIFICATES_DIR/browser.p12 $CLIENT_KEYSTORES_DIR/browser.p12

}

create_solr_truststore() {

  keytool -import -trustcacerts -noprompt -alias alfresco.ca -file ca/certs/ca.cert.pem \
  -keystore ${SOLR_KEYSTORES_DIR}/ssl.repo.client.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  keytool -importcert -noprompt -alias ssl.repo -file $CERTIFICATES_DIR/repository.cer \
  -keystore ${SOLR_KEYSTORES_DIR}/ssl.repo.client.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  keytool -importcert -noprompt -alias ssl.repo.client -file $CERTIFICATES_DIR/solr.cer \
  -keystore ${SOLR_KEYSTORES_DIR}/ssl.repo.client.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  echo "aliases=alfresco.ca,ssl.repo,ssl.repo.client" >> ${SOLR_KEYSTORES_DIR}/ssl-truststore-passwords.properties
  echo "keystore.password=$TRUSTSTORE_PASS" >> ${SOLR_KEYSTORES_DIR}/ssl-truststore-passwords.properties
  echo "alfresco.ca.password=$TRUSTSTORE_PASS" >> ${SOLR_KEYSTORES_DIR}/ssl-truststore-passwords.properties
  echo "ssl.repo.password=$TRUSTSTORE_PASS" >> ${SOLR_KEYSTORES_DIR}/ssl-truststore-passwords.properties
  echo "ssl.repo.client.password=$TRUSTSTORE_PASS" >> ${SOLR_KEYSTORES_DIR}/ssl-truststore-passwords.properties

}

create_solr_keystore() {

  keytool -importkeystore \
  -srckeystore $CERTIFICATES_DIR/solr.p12 -destkeystore ${SOLR_KEYSTORES_DIR}/ssl.repo.client.keystore \
  -srcstoretype PKCS12 -deststoretype $KEYSTORE_TYPE \
  -srcstorepass $KEYSTORE_PASS -deststorepass $KEYSTORE_PASS \
  -srcalias 1 -destalias ssl.repo.client \
  -srckeypass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS \
  -noprompt

  keytool -importcert -noprompt -alias ssl.alfresco.ca -file ca/certs/ca.cert.pem \
  -keystore ${SOLR_KEYSTORES_DIR}/ssl.repo.client.keystore -storetype $KEYSTORE_TYPE -storepass $KEYSTORE_PASS

  echo "aliases=ssl.alfresco.ca,ssl.repo.client" >> ${SOLR_KEYSTORES_DIR}/ssl-keystore-passwords.properties
  echo "keystore.password=$KEYSTORE_PASS" >> ${SOLR_KEYSTORES_DIR}/ssl-keystore-passwords.properties
  echo "ssl.repo.client.password=$KEYSTORE_PASS" >> ${SOLR_KEYSTORES_DIR}/ssl-keystore-passwords.properties
  echo "ssl.alfresco.ca.password=$KEYSTORE_PASS" >> ${SOLR_KEYSTORES_DIR}/ssl-keystore-passwords.properties

}

create_alfresco_truststore() {

  keytool -import -trustcacerts -noprompt -alias alfresco.ca -file ca/certs/ca.cert.pem \
  -keystore ${ALFRESCO_KEYSTORES_DIR}/ssl.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  keytool -importcert -noprompt -alias ssl.repo.client -file $CERTIFICATES_DIR/solr.cer \
  -keystore ${ALFRESCO_KEYSTORES_DIR}/ssl.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  echo "aliases=alfresco.ca,ssl.repo.client" >> ${ALFRESCO_KEYSTORES_DIR}/ssl-truststore-passwords.properties
  echo "keystore.password=$TRUSTSTORE_PASS" >> ${ALFRESCO_KEYSTORES_DIR}/ssl-truststore-passwords.properties
  echo "alfresco.ca.password=$TRUSTSTORE_PASS" >> ${ALFRESCO_KEYSTORES_DIR}/ssl-truststore-passwords.properties
  echo "ssl.repo.client=$TRUSTSTORE_PASS" >> ${ALFRESCO_KEYSTORES_DIR}/ssl-truststore-passwords.properties

}

create_alfresco_keystore() {

  keytool -importkeystore \
  -srckeystore $CERTIFICATES_DIR/repository.p12 -destkeystore ${ALFRESCO_KEYSTORES_DIR}/ssl.keystore \
  -srcstoretype PKCS12 -deststoretype $KEYSTORE_TYPE \
  -srcstorepass $KEYSTORE_PASS -deststorepass $KEYSTORE_PASS \
  -srcalias 1 -destalias ssl.repo \
  -srckeypass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS \
  -noprompt

  keytool -importcert -noprompt -alias ssl.alfresco.ca -file ca/certs/ca.cert.pem \
  -keystore ${ALFRESCO_KEYSTORES_DIR}/ssl.keystore -storetype $KEYSTORE_TYPE -storepass $KEYSTORE_PASS

  echo "aliases=ssl.alfresco.ca,ssl.repo" >> ${ALFRESCO_KEYSTORES_DIR}/ssl-keystore-passwords.properties
  echo "keystore.password=$KEYSTORE_PASS" >> ${ALFRESCO_KEYSTORES_DIR}/ssl-keystore-passwords.properties
  echo "ssl.repo.password=$KEYSTORE_PASS" >> ${ALFRESCO_KEYSTORES_DIR}/ssl-keystore-passwords.properties
  echo "ssl.alfresco.ca.password=$KEYSTORE_PASS" >> ${ALFRESCO_KEYSTORES_DIR}/ssl-keystore-passwords.properties

}

create_zeppelin_stores() {

  if [ "$ALFRESCO_VERSION" = "enterprise" ]; then

    cp ${SOLR_KEYSTORES_DIR}/ssl.repo.client.keystore ${ZEPPELIN_KEYSTORES_DIR}/ssl.repo.client.keystore
    cp ${SOLR_KEYSTORES_DIR}/ssl.repo.client.truststore ${ZEPPELIN_KEYSTORES_DIR}/ssl.repo.client.truststore

  fi

}

create_encryption_keystore() {

  keytool -genseckey -alias metadata -keypass $ENC_METADATA_PASS -storepass $ENC_STORE_PASS -keystore ${ALFRESCO_KEYSTORES_DIR}/keystore \
  -storetype $ENC_STORE_TYPE $ENC_KEY_ALG

  echo "aliases=metadata" >> ${ALFRESCO_KEYSTORES_DIR}/keystore-passwords.properties
  echo "keystore.password=$ENC_STORE_PASS" >> ${ALFRESCO_KEYSTORES_DIR}/keystore-passwords.properties
  echo "metadata.keyData=" >> ${ALFRESCO_KEYSTORES_DIR}/keystore-passwords.properties
  echo "metadata.algorithm=DESede" >> ${ALFRESCO_KEYSTORES_DIR}/keystore-passwords.properties
  echo "metadata.password=$ENC_METADATA_PASS" >> ${ALFRESCO_KEYSTORES_DIR}/keystore-passwords.properties

}

apply_alfresco_format() {

  if [ "$ALFRESCO_FORMAT" = "current" ]; then
    rm ${SOLR_KEYSTORES_DIR}/ssl-truststore-passwords.properties
    rm ${SOLR_KEYSTORES_DIR}/ssl-keystore-passwords.properties
    rm ${ALFRESCO_KEYSTORES_DIR}/ssl-truststore-passwords.properties
    rm ${ALFRESCO_KEYSTORES_DIR}/ssl-keystore-passwords.properties
    rm ${ALFRESCO_KEYSTORES_DIR}/keystore-passwords.properties
    mv ${SOLR_KEYSTORES_DIR}/ssl.repo.client.truststore ${SOLR_KEYSTORES_DIR}/ssl-repo-client.truststore
    mv ${SOLR_KEYSTORES_DIR}/ssl.repo.client.keystore ${SOLR_KEYSTORES_DIR}/ssl-repo-client.keystore
    mv ${ZEPPELIN_KEYSTORES_DIR}/ssl.repo.client.keystore ${ZEPPELIN_KEYSTORES_DIR}/ssl-repo-client.keystore
    mv ${ZEPPELIN_KEYSTORES_DIR}/ssl.repo.client.truststore ${ZEPPELIN_KEYSTORES_DIR}/ssl-repo-client.truststore
  fi

}

# SCRIPT
# Generates every keystore, trustore and certificate required for Alfresco SSL configuration
function generate {

  cleanup_ca

  create_ca_key

  create_ca_cert

  create_server_cert $ALFRESCO_SERVER_NAME "$REPO_CERT_DNAME" "repository" $KEYSTORE_PASS

  create_server_cert $SOLR_SERVER_NAME "$SOLR_CERT_DNAME" "solr" $KEYSTORE_PASS

  create_solr_browser_cert

  create_solr_truststore

  create_solr_keystore

  create_alfresco_truststore

  create_alfresco_keystore
  
  create_zeppelin_stores

  create_encryption_keystore

  apply_alfresco_format

}

# EXECUTION
# Parse params from command line
while test $# -gt 0
do
    case "$1" in
        # community, enterprise
        -alfrescoversion)
            ALFRESCO_VERSION=$2
            shift
        ;;
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
        # Password for keystores and private keys
        -keystorepass)
            KEYSTORE_PASS=$2
            shift
        ;;
        # Password for truststores
        -truststorepass)
            TRUSTSTORE_PASS=$2
            shift
        ;;
        # Password for encryption keystore
        -encstorepass)
            ENC_STORE_PASS=$2
            shift
        ;;
        # Password for encryption metadata
        -encmetadatapass)
            ENC_METADATA_PASS=$2
            shift
        ;;
        # DName for CA issuing the certificates
        -cacertdname)
            CA_DNAME="$2"
            shift
        ;;
        # DName for Repository certificate
        -repocertdname)
            REPO_CERT_DNAME="$2"
            shift
        ;;
        # DName for SOLR certificate
        -solrcertdname)
            SOLR_CERT_DNAME="$2"
            shift
        ;;
        # DName for Browser certificate
        -browsercertdname)
            BROWSER_CLIENT_CERT_DNAME="$2"
            shift
        ;;
        # DNS name for CA Server
        -caservername)
            CA_SERVER_NAME="$2"
            shift
        ;;
        # DNS name for Alfresco Server
        -alfrescoservername)
            ALFRESCO_SERVER_NAME="$2"
            shift
        ;;
        # DNS name for SOLR Server
        -solrservername)
            SOLR_SERVER_NAME="$2"
            shift
        ;;
        # Alfresco Format: "classic" / "current" is supported only from 7.0
        -alfrescoformat)
            ALFRESCO_FORMAT="$2"
            shift
        ;;
        # SSL Days: caducity of the certificates in number of days 
        -ssldays)
            SSL_DAYS="$2"
            shift
        ;;
        *)
            echo "An invalid parameter was received: $1"
            echo "Allowed parameters:"
            echo "  -alfrescoversion"
            echo "  -keysize"
            echo "  -keystoretype"
            echo "  -keystorepass"
            echo "  -truststoretype"
            echo "  -truststorepass"
            echo "  -encstorepass"
            echo "  -encmetadatapass"
            echo "  -cacertdname"
            echo "  -repocertdname"
            echo "  -solrcertdname"
            echo "  -browsercertdname"
            echo "  -caservername"
            echo "  -alfrescoservername"
            echo "  -solrservername"
            echo "  -alfrescoformat"
            echo "  -ssldays"
            exit 1
        ;;
    esac
    shift
done

# Generating keystores, truststores and certificates
generate
