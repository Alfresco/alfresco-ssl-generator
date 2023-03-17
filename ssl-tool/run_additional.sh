#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source $SCRIPT_DIR/utils.sh

# This script is a follow up to run_ca.sh script.
# It is responsible for sets of keystores and truststores for services to be used in mTLS approach.

# PARAMETERS

# Using "current" format by default (only available from ACS 7.0+)
ALFRESCO_FORMAT=current
# Folder name to place results of script in
SUBFOLDER_NAME=
# Service name, to be used as folder name where results are generated to
SERVICE_NAME=service
# Alias of private key
ALIAS=
# Role to be fulfilled by the keystore key (both/client/server)
ROLE="both"
# Distinguished name of the CA
SERVICE_CERT_DNAME="/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Service"
# Service server name, to be used as Alternative Name in the certificates
SERVICE_SERVER_NAME=localhost

# Root CA Password
ROOT_CA_PASS=
# RSA key length (1024, 2048, 4096)
KEY_SIZE=2048
# Keystore format (PKCS12, JKS, JCEKS)
KEYSTORE_TYPE=JCEKS
# Default password for every keystore and private key
KEYSTORE_PASS=$PASSWORD_PLACEHOLDER

NO_TRUSTSTORE=false
# Truststore format (JKS, JCEKS)
TRUSTSTORE_TYPE=JCEKS
# Default password for every truststore
TRUSTSTORE_PASS=$PASSWORD_PLACEHOLDER

function readKeystorePassword {
  PASSWORD=$KEYSTORE_PASS
  askForPasswordIfNeeded "[service name] $SERVICE_NAME, [role] $ROLE, keystore"
  KEYSTORE_PASS=$PASSWORD
}

function readTruststorePassword {
  PASSWORD=$TRUSTSTORE_PASS
  askForPasswordIfNeeded "[service name] $SERVICE_NAME, [role] $ROLE, truststore"
  TRUSTSTORE_PASS=$PASSWORD
}

# Set basic settings depending on role
function settingsBasedOnRole {
  if [ "$ROLE" == "client" ]; then
    EXTENSION=client_cert
    FILE_SUFFIX=_client
    echo "Warning: For client role, servername parameter will be unused even if provided."
    SERVICE_SERVER_NAME=
  elif [ "$ROLE" == "server" ]; then
    EXTENSION=server_cert
    FILE_SUFFIX=_server
  elif [ "$ROLE" == "both" ]; then
    EXTENSION=clientServer_cert
    FILE_SUFFIX=
  elif [ -z "$ROLE" ]; then
    echo "No role provided, using default role: 'both'"
    ROLE="both"
    EXTENSION=clientServer_cert
    FILE_SUFFIX=
  else
    echo "Warning: Unsupported role provided, using 'both' as value"
    ROLE="both"
    EXTENSION=clientServer_cert
    FILE_SUFFIX=
  fi
}

# Generates service keystore, trustore and certificate required for Alfresco SSL configuration
function generate {
  echo "---Run Additional Script Execution for $SERVICE_NAME---"

  if [ -z "$ROOT_CA_PASS" ]; then
    echo "Root CA password [parameter: rootcapass] is mandatory"
    exit 1
  fi

  if [ -z "$ALIAS" ]; then
    ALIAS=$SERVICE_NAME
  fi

  if [ -z "$SUBFOLDER_NAME" ]; then
    SUBFOLDER_NAME=$SERVICE_NAME
  fi

  readKeystorePassword
  if [ "$NO_TRUSTSTORE" = "false" ]; then
    readTruststorePassword
  fi
  settingsBasedOnRole

  SERVICE_KEYSTORES_DIR=$KEYSTORES_DIR/$SUBFOLDER_NAME
  if [ ! -d "$SERVICE_KEYSTORES_DIR" ]; then
    mkdir -p $SERVICE_KEYSTORES_DIR
  fi

  if [ "$ROLE" != "client" ]; then
    subjectAlternativeNames $SERVICE_SERVER_NAME
  fi

  FILE_NAME=$SERVICE_NAME$FILE_SUFFIX

  #Generate key and CSR
  openssl req -newkey rsa:$KEY_SIZE -nodes -out $CERTIFICATES_DIR/$FILE_NAME.csr -keyout $CERTIFICATES_DIR/$FILE_NAME.key -subj "$SERVICE_CERT_DNAME"
  #Sign CSR with CA
  openssl ca -config $SCRIPT_DIR/openssl.cnf -extensions $EXTENSION -passin pass:$ROOT_CA_PASS -batch -notext \
  -in $CERTIFICATES_DIR/$FILE_NAME.csr -out $CERTIFICATES_DIR/$FILE_NAME.cer
  #Export keystore with key and certificate
  openssl pkcs12 -export -out $CERTIFICATES_DIR/$FILE_NAME.p12 -inkey $CERTIFICATES_DIR/$FILE_NAME.key \
  -in $CERTIFICATES_DIR/$FILE_NAME.cer -password pass:$KEYSTORE_PASS -certfile $CA_DIR/certs/ca.cert.pem
  #Convert keystore to desired format, set alias
  keytool -importkeystore \
  -srckeystore $CERTIFICATES_DIR/$FILE_NAME.p12 -destkeystore ${SERVICE_KEYSTORES_DIR}/$FILE_NAME.keystore \
  -srcstoretype PKCS12 -deststoretype $KEYSTORE_TYPE \
  -srcstorepass $KEYSTORE_PASS -deststorepass $KEYSTORE_PASS \
  -srcalias 1 -destalias $ALIAS \
  -srckeypass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS \
  -noprompt
  #Import CA certificate into Service keystore, for complete certificate chain
  keytool -importcert -noprompt -alias ssl.alfresco.ca -file $CA_DIR/certs/ca.cert.pem \
  -keystore ${SERVICE_KEYSTORES_DIR}/$FILE_NAME.keystore -storetype $KEYSTORE_TYPE -storepass $KEYSTORE_PASS

  # Create Keystore password file
  echo "keystore.password=$KEYSTORE_PASS" >> ${SERVICE_KEYSTORES_DIR}/$FILE_NAME-keystore-passwords.properties
  echo "aliases=$ALIAS" >> ${SERVICE_KEYSTORES_DIR}/$FILE_NAME-keystore-passwords.properties
  echo "$ALIAS.password=$KEYSTORE_PASS" >> ${SERVICE_KEYSTORES_DIR}/$FILE_NAME-keystore-passwords.properties

  if [ "$NO_TRUSTSTORE" = "false" ]; then
    # Include CA certificates in Service Truststore
    keytool -import -trustcacerts -noprompt -alias alfresco.ca -file $CA_DIR/certs/ca.cert.pem \
    -keystore ${SERVICE_KEYSTORES_DIR}/$FILE_NAME.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

    # Create TrustStore password file
    echo "keystore.password=$TRUSTSTORE_PASS" >> ${SERVICE_KEYSTORES_DIR}/$FILE_NAME-truststore-passwords.properties
    echo "aliases=alfresco.ca" >> ${SERVICE_KEYSTORES_DIR}/$FILE_NAME-truststore-passwords.properties
  fi

  #
  # Removing files for current Alfresco Format
  #
  if [ "$ALFRESCO_FORMAT" = "current" ]; then
    rm ${SERVICE_KEYSTORES_DIR}/$FILE_NAME-keystore-passwords.properties
    if [ "$NO_TRUSTSTORE" = "false" ]; then
      rm ${SERVICE_KEYSTORES_DIR}/$FILE_NAME-truststore-passwords.properties
    fi
  fi
}

# EXECUTION
# Parse params from command line
while test $# -gt 0
do
    case "$1" in
        # Subfolder name, useful multiple keystores per service, if unset will take on -servicename value
        -subfoldername)
            SUBFOLDER_NAME=$2
            shift
        ;;
        # Service name
        -servicename)
            SERVICE_NAME=$2
            shift
        ;;
        # Alias
        -alias)
            ALIAS=$2
            shift
        ;;
        # Role: server, client, both (default)
        -role)
            ROLE=$2
            shift
        ;;
        # Root CA password
        -rootcapass)
            ROOT_CA_PASS=$2
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
        # Password for keystores and private keys
        -keystorepass)
            KEYSTORE_PASS=$2
            shift
        ;;
        # Password for keystores and private keys
        -notruststore)
            NO_TRUSTSTORE=true
        ;;
        # JKS, JCEKS
        -truststoretype)
            TRUSTSTORE_TYPE=$2
            shift
        ;;
        # Password for truststores
        -truststorepass)
            TRUSTSTORE_PASS=$2
            shift
        ;;
        # DName for Service certificate
        -certdname)
            SERVICE_CERT_DNAME="$2"
            shift
        ;;
        # DNS name for Service
        -servername)
            SERVICE_SERVER_NAME="$2"
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
            echo "  -subfoldername"
            echo "  -servicename"
            echo "  -alias"
            echo "  -role"
            echo "  -rootcapass"
            echo "  -keysize"
            echo "  -keystoretype"
            echo "  -keystorepass"
            echo "  -notruststore"
            echo "  -truststoretype"
            echo "  -truststorepass"
            echo "  -certdname"
            echo "  -servername"
            echo "  -alfrescoformat"
            exit 1
        ;;
    esac
    shift
done

generate