#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

# This script generates certificates for Repository and SOLR TLS/SSL Mutual Auth Communication:
#
# * CA Entity to issue all required certificates
# * Server Certificate for Alfresco
# * Server Certificate for SOLR
#
# "openssl.cnf" file is provided for CA Configuration.
#
# Following resources are generated in ${KEYSTORES_DIR}
# .
# ├── alfresco
# │ ├── ssl.keystore
# │ └── ssl.truststore
# ├── client
# │ └── browser.p12
# └── solr
#   ├── ssl-repo-client.keystore
#   └── ssl-repo-client.truststore
#
# "alfresco" files must be copied to "alfresco/keystore" folder
# "solr" files must be copied to "solr6/keystore"
# "client" files can be used from a browser to access the server using HTTPS in port 8983

# Load common functions and variables
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source ${SCRIPT_DIR}/../utils.sh

cd ..
SCRIPT_DIR="$(pwd)"
cd samples


# PARAMETERS

# Version of Alfresco: enterprise, community
ALFRESCO_VERSION=community

# Using "current" format by default (only available from ACS 7.0+)
ALFRESCO_FORMAT=current

# Distinguished name of the CA
CA_DNAME="/C=US/ST=OH/L=Cleveland/O=Hyland/OU=Alfresco/CN=Alfresco CA"
# Distinguished name of the Server Certificate for Alfresco
REPO_CERT_DNAME="/C=US/ST=OH/L=Cleveland/O=Hyland/OU=Alfresco/CN=Repository"
# Distinguished name of the Server Certificate for Search
SOLR_CLIENT_CERT_DNAME="/C=US/ST=OH/L=Cleveland/O=Hyland/OU=Alfresco/CN=Search"
# Distinguished name of the Browser Certificate for Search
BROWSER_CLIENT_CERT_DNAME="/C=US/ST=OH/L=Cleveland/O=Hyland/OU=Alfresco/CN=Search Client"

# Alfresco and SOLR server names, to be used as Alternative Name in the certificates
CA_SERVER_NAME=localhost
ALFRESCO_SERVER_NAME=localhost
SOLR_SERVER_NAME=localhost

# RSA key length (2048 or 3072)
KEY_SIZE=2048

# Keystore format (PKCS12 is recommended)
KEYSTORE_TYPE=PKCS12
# Truststore format (PKCS12 is recommended)
TRUSTSTORE_TYPE=PKCS12

# Default password for every keystore and private key
KEYSTORE_PASS=keystore
# Default password for every truststore
TRUSTSTORE_PASS=truststore

# Folder where keystores, truststores and cerfiticates are generated
KEYSTORES_DIR=keystores
ALFRESCO_KEYSTORES_DIR=keystores/alfresco
SOLR_KEYSTORES_DIR=keystores/solr
ZEPPELIN_KEYSTORES_DIR=keystores/zeppelin
CLIENT_KEYSTORES_DIR=keystores/client
CERTIFICATES_DIR=certificates

#Root CA validity, left as 7300 for backwards compatibility
CA_VALIDITY_DURATION=7300

# SCRIPT
# Generates every keystore, trustore and certificate required for Alfresco SSL configuration
function generate {

  # If target folder for Keystores is not empty, skip generation
  if [ "$(ls -A $KEYSTORES_DIR)" ]; then
    echo "Keystores folder is not empty, skipping generation process..."
    exit 1
  fi

  # Remove previous working directories and certificates
  if [ -d ca ]; then
      rm -rf ca/*
  fi

  # Create folders for truststores, keystores and certificates
  if [ ! -d "$ALFRESCO_KEYSTORES_DIR" ]; then
    mkdir -p $ALFRESCO_KEYSTORES_DIR
  else
    rm -rf $ALFRESCO_KEYSTORES_DIR/*
  fi

  if [ ! -d "$SOLR_KEYSTORES_DIR" ]; then
    mkdir -p $SOLR_KEYSTORES_DIR
  else
    rm -rf $SOLR_KEYSTORES_DIR/*
  fi

  if [ ! -d "$CLIENT_KEYSTORES_DIR" ]; then
    mkdir -p $CLIENT_KEYSTORES_DIR
  else
    rm -rf $CLIENT_KEYSTORES_DIR/*
  fi

  if [ ! -d "$CERTIFICATES_DIR" ]; then
    mkdir -p $CERTIFICATES_DIR
  else
    rm -rf $CERTIFICATES_DIR/*
  fi

  #
  # CA
  #

  # Generate a new CA Entity
  if [ ! -d ca ]; then
    mkdir ca
  fi

  mkdir ca/certs ca/crl ca/newcerts ca/private
  chmod 700 ca/private
  touch ca/index.txt
  RAND=$(od -N 4 -t uL -An /dev/urandom | tr -d " ")
  echo "${RAND}" > ca/serial
  
  openssl genrsa -aes256 -passout pass:$KEYSTORE_PASS -out ca/private/ca.key.pem $KEY_SIZE
  chmod 400 ca/private/ca.key.pem

  subjectAlternativeNames $CA_SERVER_NAME

  openssl req -config ../openssl.cnf \
       -key ca/private/ca.key.pem \
       -new -x509 -days $CA_VALIDITY_DURATION -sha256 -extensions v3_ca \
       -out ca/certs/ca.cert.pem \
       -subj "$CA_DNAME" \
       -passin pass:$KEYSTORE_PASS
  chmod 444 ca/certs/ca.cert.pem

  # Generate Server Certificate for Alfresco (issued by just generated CA)
  subjectAlternativeNames $ALFRESCO_SERVER_NAME

  openssl req -newkey rsa:$KEY_SIZE -nodes -out $CERTIFICATES_DIR/repository.csr -keyout $CERTIFICATES_DIR/repository.key -subj "$REPO_CERT_DNAME"

  openssl ca -config ../openssl.cnf -extensions clientServer_cert -passin pass:$KEYSTORE_PASS -batch -notext \
  -in $CERTIFICATES_DIR/repository.csr -out $CERTIFICATES_DIR/repository.cer

  openssl pkcs12 -export -out $CERTIFICATES_DIR/repository.p12 -inkey $CERTIFICATES_DIR/repository.key \
  -in $CERTIFICATES_DIR/repository.cer -password pass:$KEYSTORE_PASS -certfile ca/certs/ca.cert.pem

  # Server Certificate for SOLR (issued by just generated CA)
  subjectAlternativeNames $SOLR_SERVER_NAME

  openssl req -newkey rsa:$KEY_SIZE -nodes -out $CERTIFICATES_DIR/solr.csr -keyout $CERTIFICATES_DIR/solr.key -subj "$SOLR_CLIENT_CERT_DNAME"

  openssl ca -config ../openssl.cnf -extensions clientServer_cert -passin pass:$KEYSTORE_PASS -batch -notext \
  -in $CERTIFICATES_DIR/solr.csr -out $CERTIFICATES_DIR/solr.cer

  openssl pkcs12 -export -out $CERTIFICATES_DIR/solr.p12 -inkey $CERTIFICATES_DIR/solr.key \
  -in $CERTIFICATES_DIR/solr.cer -password pass:$KEYSTORE_PASS -certfile ca/certs/ca.cert.pem

  # Client Certificate for SOLR (issued by just generated CA)
  openssl req -newkey rsa:$KEY_SIZE -nodes -out $CERTIFICATES_DIR/browser.csr -keyout $CERTIFICATES_DIR/browser.key \
  -subj "$BROWSER_CLIENT_CERT_DNAME"

  openssl ca -config ../openssl.cnf -extensions client_cert -passin pass:$KEYSTORE_PASS -batch -notext \
  -in $CERTIFICATES_DIR/browser.csr -out $CERTIFICATES_DIR/browser.cer

  openssl pkcs12 -export -out $CERTIFICATES_DIR/browser.p12 -inkey $CERTIFICATES_DIR/browser.key \
  -in $CERTIFICATES_DIR/browser.cer -password pass:$KEYSTORE_PASS -certfile ca/certs/ca.cert.pem

  #
  # SOLR
  #

  # Include CA and Alfresco certificates in SOLR Truststore
  keytool -import -trustcacerts -noprompt -alias alfresco.ca -file ca/certs/ca.cert.pem \
  -keystore ${SOLR_KEYSTORES_DIR}/ssl.repo.client.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  keytool -importcert -noprompt -alias ssl.repo -file $CERTIFICATES_DIR/repository.cer \
  -keystore ${SOLR_KEYSTORES_DIR}/ssl.repo.client.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  # Include Solr Certificate in Solr Keystore
  keytool -importkeystore \
  -srckeystore $CERTIFICATES_DIR/solr.p12 -destkeystore ${SOLR_KEYSTORES_DIR}/ssl.repo.client.keystore \
  -srcstoretype PKCS12 -deststoretype $KEYSTORE_TYPE \
  -srcstorepass $KEYSTORE_PASS -deststorepass $KEYSTORE_PASS \
  -srcalias 1 -destalias ssl.repo.client \
  -srckeypass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS \
  -noprompt

  #
  # ALFRESCO
  #

  # Include CA and SOLR certificates in Alfresco Truststore
  keytool -import -trustcacerts -noprompt -alias alfresco.ca -file ca/certs/ca.cert.pem \
  -keystore ${ALFRESCO_KEYSTORES_DIR}/ssl.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  keytool -importcert -noprompt -alias ssl.repo.client -file $CERTIFICATES_DIR/solr.cer \
  -keystore ${ALFRESCO_KEYSTORES_DIR}/ssl.truststore -storetype $TRUSTSTORE_TYPE -storepass $TRUSTSTORE_PASS

  # Include Alfresco Certificate in Alfresco Keystore
  keytool -importkeystore \
  -srckeystore $CERTIFICATES_DIR/repository.p12 -destkeystore ${ALFRESCO_KEYSTORES_DIR}/ssl.keystore \
  -srcstoretype PKCS12 -deststoretype $KEYSTORE_TYPE \
  -srcstorepass $KEYSTORE_PASS -deststorepass $KEYSTORE_PASS \
  -srcalias 1 -destalias ssl.repo \
  -srckeypass $KEYSTORE_PASS -destkeypass $KEYSTORE_PASS \
  -noprompt

  #
  # CLIENT
  #

  # Create client (browser) certificate
  cp $CERTIFICATES_DIR/browser.p12 $CLIENT_KEYSTORES_DIR/browser.p12

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
        # 2048, 4096, ...
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
            SOLR_CLIENT_CERT_DNAME="$2"
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
        # Validity of Root CA certificate in days
        -cavalidityduration)
            CA_VALIDITY_DURATION="$2"
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
            echo "  -cavalidityduration"
            exit 1
        ;;
    esac
    shift
done

# Generating keystores, truststores and certificates
generate
