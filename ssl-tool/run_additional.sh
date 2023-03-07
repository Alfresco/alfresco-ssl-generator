#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

# This script is a follow up to run.sh script (it generates the CA that will be required here).
# It is responsible for sets of keystores and truststores for additional services to be used in mTLS approach.

PASSWORD_PLACEHOLDER="<password>"

# PARAMETERS

# Using "current" format by default (only available from ACS 7.0+)
ALFRESCO_FORMAT=current

# Service name, to be used as folder name where results are generated to
SERVICE_NAME=service
# Alias of private key
ALIAS=$SERVICE_NAME
# Role to be fulfilled by the keystore key (both/client/server)
ROLE="both"
# Distinguished name of the CA
SERVICE_CERT_DNAME="/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Service"
# Service server name, to be used as Alternative Name in the certificates
SERVICE_SERVER_NAME=localhost

KEYSTORES_DIR=keystores
CERTIFICATES_DIR=certificates

# Root CA Password
ROOT_CA_PASS=
# RSA key length (1024, 2048, 4096)
KEY_SIZE=2048
# Keystore format (PKCS12, JKS, JCEKS)
KEYSTORE_TYPE=JCEKS
# Default password for every keystore and private key
KEYSTORE_PASS=$PASSWORD_PLACEHOLDER

# Truststore format (JKS, JCEKS)
TRUSTSTORE_TYPE=JCEKS
# Default password for every truststore
TRUSTSTORE_PASS=$PASSWORD_PLACEHOLDER

# Password reading functions
function verifyPasswordConditions {
  CHECK_FAILED=false

  PASSWORD_LENGTH=${#PASSWORD}
  if [ $PASSWORD_LENGTH -lt 6 ] || [ $PASSWORD_LENGTH -gt 1023 ]
  then
    printf "\nPassword must have at least 6 characters and no more than 1023\n"
    CHECK_FAILED=true
  fi
}

function readPassword {
  read -s -r -p "Please enter password for $1 (leading and trailing spaces will be removed): " PASSWORD

  verifyPasswordConditions
  if $CHECK_FAILED; then
    PASSWORD=$PASSWORD_PLACEHOLDER
    return
  fi

  read -s -r -p $'\nPlease repeat pass phrase : ' PASSWORD_CHECK

  if [ "$PASSWORD" != "$PASSWORD_CHECK" ]
  then
    echo
    echo "Password verification failed"
    PASSWORD=$PASSWORD_PLACEHOLDER
    return
  fi
}

function askForPasswordIfNeeded {
  if [ "$PASSWORD" != "$PASSWORD_PLACEHOLDER" ]; then
    verifyPasswordConditions
    if $CHECK_FAILED; then
      exit 1
    fi
  fi

  while [ "$PASSWORD" == "$PASSWORD_PLACEHOLDER" ]
  do
    readPassword "$1"
  done

  echo
}

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
  else
    echo "Warning: Unsupported role provided, using 'both' as value"
    ROLE="both"
    EXTENSION=clientServer_cert
    FILE_SUFFIX=
  fi
}

# Generates service keystore, trustore and certificate required for Alfresco SSL configuration
function generate {
  printf "\n---Run Additional Script Execution---\n"

  if [ -z "$ROOT_CA_PASS" ]; then
    echo "Root CA password [parameter: rootcapass] is mandatory"
    exit 1
  fi

  readKeystorePassword
  readTruststorePassword
  settingsBasedOnRole

  SERVICE_KEYSTORES_DIR=$KEYSTORES_DIR/$SERVICE_NAME
  if [ ! -d "$SERVICE_KEYSTORES_DIR" ]; then
    mkdir -p $SERVICE_KEYSTORES_DIR
  fi

  #Subject Alternative Name provided through config file substitution
  if [ -n "$SERVICE_SERVER_NAME" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/DNS.1.*/DNS.1 = $SERVICE_SERVER_NAME/" openssl.cnf;
    else
      sed -i "s/DNS.1.*/DNS.1 = $SERVICE_SERVER_NAME/" openssl.cnf;
    fi
  fi

  #Generate key and CSR
  openssl req -newkey rsa:$KEY_SIZE -nodes -out $CERTIFICATES_DIR/$SERVICE_NAME$FILE_SUFFIX.csr -keyout $CERTIFICATES_DIR/$SERVICE_NAME$FILE_SUFFIX.key -subj "$SERVICE_CERT_DNAME"
  #Sign CSR with CA
  openssl ca -config openssl.cnf -extensions $EXTENSION -passin pass:$ROOT_CA_PASS -batch -notext \
  -in $CERTIFICATES_DIR/$SERVICE_NAME$FILE_SUFFIX.csr -out $CERTIFICATES_DIR/$SERVICE_NAME$FILE_SUFFIX.cer
  #Export keystore with key and certificate
  openssl pkcs12 -export -out $CERTIFICATES_DIR/$SERVICE_NAME$FILE_SUFFIX.p12 -inkey $CERTIFICATES_DIR/$SERVICE_NAME$FILE_SUFFIX.key \
  -in $CERTIFICATES_DIR/$SERVICE_NAME$FILE_SUFFIX.cer -password pass:$KEYSTORE_PASS -certfile ca/certs/ca.cert.pem
  #Convert keystore to desired format, set alias
  keytool -importkeystore \
  -srckeystore $CERTIFICATES_DIR/$SERVICE_NAME$FILE_SUFFIX.p12 -destkeystore ${SERVICE_KEYSTORES_DIR}/$SERVICE_NAME$FILE_SUFFIX.keystore \
  -srcstoretype PKCS12 -deststoretype $KEYSTORE_TYPE \
  -srcstorepass $KEYSTORE_PASS -deststorepass $KEYSTORE_PASS \
  -srcalias 1 -destalias $ALIAS \
  -srckeypass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS \
  -noprompt
  #Import CA certificate into Service keystore, for complete certificate chain
  keytool -importcert -noprompt -alias ssl.alfresco.ca -file ca/certs/ca.cert.pem \
  -keystore ${SERVICE_KEYSTORES_DIR}/$SERVICE_NAME$FILE_SUFFIX.keystore -storetype $KEYSTORE_TYPE -storepass $KEYSTORE_PASS

  # Create Keystore password file
  echo "aliases=$ALIAS" >> ${SERVICE_KEYSTORES_DIR}/keystore-passwords.properties
  echo "$ALIAS.password=$KEYSTORE_PASS" >> ${SERVICE_KEYSTORES_DIR}/keystore-passwords.properties

  # Include CA certificates in Service Truststore
  keytool -import -trustcacerts -noprompt -alias alfresco.ca -file ca/certs/ca.cert.pem \
  -keystore ${SERVICE_KEYSTORES_DIR}/$SERVICE_NAME$FILE_SUFFIX.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  # Create TrustStore password file
  echo "aliases=alfresco.ca" >> ${SERVICE_KEYSTORES_DIR}/truststore-passwords.properties
  echo "alfresco.ca.password=$TRUSTSTORE_PASS" >> ${SERVICE_KEYSTORES_DIR}/truststore-passwords.properties

  #
  # Removing files for current Alfresco Format
  #
  if [ "$ALFRESCO_FORMAT" = "current" ]; then
    rm ${SERVICE_KEYSTORES_DIR}/truststore-passwords.properties
    rm ${SERVICE_KEYSTORES_DIR}/keystore-passwords.properties
  fi
}

# EXECUTION
# Parse params from command line
while test $# -gt 0
do
    case "$1" in
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
            echo "  -servicename"
            echo "  -alias"
            echo "  -role"
            echo "  -rootcapass"
            echo "  -keysize"
            echo "  -keystoretype"
            echo "  -keystorepass"
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