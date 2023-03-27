#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

# This script is generating a Root CA

# Load common functions and variables
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source $SCRIPT_DIR/utils.sh

# ----------
# PARAMETERS
# ----------

# Distinguished name of the CA
CA_DNAME="/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA"
# Alfresco and SOLR server names, to be used as Alternative Name in the certificates
CA_SERVER_NAME=localhost

# RSA key length (1024, 2048, 4096)
KEY_SIZE=2048
# Password placeholder
KEYSTORE_PASS=$PASSWORD_PLACEHOLDER

#If not set, assume it's a testing environment, Root CA of a testing environment shouldn't last more than a day
VALIDITY_DURATION=1

# SCRIPT
function cleanupFolders {
  # Remove previous working directories and certificates
  if [ -d $CA_DIR ]; then
    rm -rf $CA_DIR/*
  else
    mkdir $CA_DIR
  fi

  # Create folders for truststores, keystores and certificates
  if [ ! -d "$KEYSTORES_DIR" ]; then
    mkdir -p $KEYSTORES_DIR
  fi

  if [ ! -d "$CERTIFICATES_DIR" ]; then
    mkdir -p $CERTIFICATES_DIR
  else
    rm -rf $CERTIFICATES_DIR/*
  fi
}

function readKeystorePassword {
  PASSWORD=$KEYSTORE_PASS
  askForPasswordIfNeeded "Root CA"
  KEYSTORE_PASS=$PASSWORD
}

# Generates CA
function generate {

  if [ $VALIDITY_DURATION -lt 1 ]; then
    echo "Minimum validity of Root CA is 1 day"
    exit 1
  fi

  # If target folder for Keystores is not empty, skip generation
  if [ "$(ls -A $KEYSTORES_DIR)" ]; then
    echo "Keystores folder is not empty, skipping generation process..."
    exit 1
  fi

  cleanupFolders

  readKeystorePassword

  # ------------
  # CA
  # ------------

  mkdir $CA_DIR/certs $CA_DIR/crl $CA_DIR/newcerts $CA_DIR/private
  chmod 700 $CA_DIR/private
  touch $CA_DIR/index.txt
  echo 1000 > $CA_DIR/serial

  openssl genrsa -aes256 -passout pass:$KEYSTORE_PASS -out $CA_DIR/private/ca.key.pem $KEY_SIZE
  chmod 400 $CA_DIR/private/ca.key.pem

  subjectAlternativeNames $CA_SERVER_NAME

  openssl req -config $SCRIPT_DIR/openssl.cnf \
        -key $CA_DIR/private/ca.key.pem \
        -new -x509 -days $VALIDITY_DURATION -sha256 -extensions v3_ca \
        -out $CA_DIR/certs/ca.cert.pem \
        -subj "$CA_DNAME" \
        -passin pass:$KEYSTORE_PASS
  chmod 444 $CA_DIR/certs/ca.cert.pem
}

# EXECUTION
# Parse params from command line
while test $# -gt 0
do
    case "$1" in
        # 1024, 2048, 4096, ...
        -keysize)
            KEY_SIZE=$2
            shift
        ;;
        # Password for keystore and private key
        -keystorepass)
            KEYSTORE_PASS=$2
            shift
        ;;
        # DName for CA issuing the certificates
        -cacertdname)
            CA_DNAME="$2"
            shift
        ;;
        # DNS name for CA Server
        -caservername)
            CA_SERVER_NAME="$2"
            shift
        ;;
        # Validity of Root CA certificate in days
        -cavalidityduration)
            VALIDITY_DURATION="$2"
            shift
        ;;
        *)
            echo "An invalid parameter was received: $1"
            echo "Allowed parameters:"
            echo "  -keysize"
            echo "  -keystorepass"
            echo "  -cacertdname"
            echo "  -caservername"
            echo "  -cavalidityduration"
            exit 1
        ;;
    esac
    shift
done

# Generating CA
generate