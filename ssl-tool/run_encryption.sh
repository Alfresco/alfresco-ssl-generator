#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

# This script is generating metadata encryption keystore

# Load common functions and variables
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source $SCRIPT_DIR/utils.sh

# ----------
# PARAMETERS
# ----------

SERVICE_NAME=encryption
SUBFOLDER_NAME=

# Using "current" format by default (only available from ACS 7.0+)
ALFRESCO_FORMAT=current

# Encryption secret key passwords
KEYSTORE_PASS=$PASSWORD_PLACEHOLDER
KEY_PASS=$PASSWORD_PLACEHOLDER

function readKeystorePassword {
  PASSWORD=$KEYSTORE_PASS
  askForPasswordIfNeeded "Encryption Keystore"
  KEYSTORE_PASS=$PASSWORD
}

function readKeyPassword {
  PASSWORD=$KEY_PASS
  askForPasswordIfNeeded "Encryption Key"
  KEY_PASS=$PASSWORD
}

# Generates Metadata keystore
function generate {
  if [ -z "$SUBFOLDER_NAME" ]; then
    SUBFOLDER_NAME=$SERVICE_NAME
  fi

  # Encryption keystore format: PKCS12 (default for "current"), JCEKS (default for "classic")
  if [ "$ALFRESCO_FORMAT" == "current" ]; then
    ENC_STORE_TYPE=PKCS12
  else
    ENC_STORE_TYPE=JCEKS
  fi

  # Key algorithm: AES (default for "current"), DESede (default for "classic")
  if [ "$ALFRESCO_FORMAT" == "current" ]; then
    ENC_KEY_ALG="-keyalg AES -keysize 256"
  else
    ENC_KEY_ALG="-keyalg DESede"
  fi

  DESTINATION_DIR=$KEYSTORES_DIR/$SUBFOLDER_NAME
  if [ ! -d $DESTINATION_DIR ]; then
    mkdir $DESTINATION_DIR
  fi

  readKeystorePassword
  readKeyPassword

  # Generate Encryption Secret Key
  keytool -genseckey -alias metadata -keypass $KEY_PASS -storepass $KEYSTORE_PASS -keystore ${DESTINATION_DIR}/$SERVICE_NAME.keystore \
  -storetype $ENC_STORE_TYPE $ENC_KEY_ALG

  if [ "$ALFRESCO_FORMAT" != "current" ]; then
    # Create Alfresco Encryption password file
    echo "aliases=metadata" >> ${DESTINATION_DIR}/$SERVICE_NAME-keystore-passwords.properties
    echo "keystore.password=$KEYSTORE_PASS" >> ${DESTINATION_DIR}/$SERVICE_NAME-keystore-passwords.properties
    echo "metadata.keyData=" >> ${DESTINATION_DIR}/$SERVICE_NAME-keystore-passwords.properties
    echo "metadata.algorithm=DESede" >> ${DESTINATION_DIR}/$SERVICE_NAME-keystore-passwords.properties
    echo "metadata.password=$KEY_PASS" >> ${DESTINATION_DIR}/$SERVICE_NAME-keystore-passwords.properties
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
        # Password for encryption keystore
        -encstorepass)
            KEYSTORE_PASS=$2
            shift
        ;;
        # Password for encryption metadata
        -encmetadatapass)
            KEY_PASS=$2
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
            echo "  -encstorepass"
            echo "  -encmetadatapass"
            echo "  -alfrescoformat"
            exit 1
        ;;
    esac
    shift
done

# Generating CA
generate