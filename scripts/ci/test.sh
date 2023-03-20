#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source ${SCRIPT_DIR}/../../ssl-tool/utils.sh

# SETTINGS
ALFRESCO_FORMAT=current

echo "Generate: CA, Repository, Solr, Zeppelin"
#CA
bash ${SCRIPT_DIR}/../../ssl-tool/run_ca.sh -keysize 2048 -keystorepass capass -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA" -servername localhost
#Alfresco Repository
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename alfresco -alias repository -rootcapass capass -keysize 2048 -keystoretype JCEKS -keystorepass alfrescokeystorepass -truststoretype PKCS12 -truststorepass alfrescotruststorepass -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#Alfresco Metadata encryption
bash ${SCRIPT_DIR}/../../ssl-tool/run_encryption.sh -subfoldername alfresco -servicename encryption -encstorepass encryptionpass -encmetadatapass oKIWzVdEdA -alfrescoformat $ALFRESCO_FORMAT
#Solr
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename solr -rootcapass capass -keysize 2048 -keystoretype JCEKS -keystorepass solrkeystorepass -truststoretype JCEKS -truststorepass solrtruststorepass -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository Client" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#Zeppelin (copy of Solr)
ZEPPELIN_DIR=$KEYSTORES_DIR/zeppelin
if [ -d $ZEPPELIN_DIR ]; then
  rm -rf $ZEPPELIN_DIR/*
else
  mkdir $ZEPPELIN_DIR
fi
cp $KEYSTORES_DIR/solr/solr.keystore $ZEPPELIN_DIR/zeppelin.keystore
cp $KEYSTORES_DIR/solr/solr.truststore $ZEPPELIN_DIR/zeppelin.truststore
#Solr browser
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -subfoldername client -servicename browser -role client -rootcapass capass -keysize 2048 -keystoretype PKCS12 -keystorepass browserkeystorepass -notruststore -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Browser Client" -alfrescoformat $ALFRESCO_FORMAT


echo "Generate sharedFileStore"
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename sharedFileStore -rootcapass capass -keysize 2048 -keystoretype PKCS12 -keystorepass sharedfilestorekeystorepass -truststoretype JKS -truststorepass sharedfilestoretruststorepass -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store" -servername localhost,test -alfrescoformat $ALFRESCO_FORMAT

#Transform Router
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename transformRouter -alias transformRouter_client -role client -rootcapass capass -keysize 2048 -keystoretype JCEKS -keystorepass transformrouterclientpass -truststoretype JCEKS -truststorepass transformrouterclientpass -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router Client" -alfrescoformat $ALFRESCO_FORMAT
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename transformRouter -alias transformRouter_server -role server -rootcapass capass -keysize 2048 -keystoretype JCEKS -keystorepass transformrouterserverpass -truststoretype JCEKS -truststorepass transformrouterserverpass -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT

#--------------------------------------------------------

echo "Verifying results"
source ${SCRIPT_DIR}/test_utils.sh

echo "Checking repository"
validateKeystore keystores/alfresco/alfresco.keystore alfrescokeystorepass JCEKS "repository" "ssl.alfresco.ca"
validateTruststore keystores/alfresco/alfresco.truststore alfrescotruststorepass PKCS12 "alfresco.ca"
validateCertificate keystores/alfresco/alfresco.keystore alfrescokeystorepass "Owner: CN=Custom Alfresco Repository, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/alfresco/alfresco.keystore alfrescokeystorepass "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"
echo "Checking encryption"
validateEncryption keystores/alfresco/encryption.keystore encryptionpass PKCS12 "metadata"
echo "Checking solr"
validateKeystore keystores/solr/solr.keystore solrkeystorepass JCEKS "solr" "ssl.alfresco.ca"
validateTruststore keystores/solr/solr.truststore solrtruststorepass JCEKS "alfresco.ca"
validateCertificate keystores/solr/solr.keystore solrkeystorepass "Owner: CN=Custom Alfresco Repository Client, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/solr/solr.keystore solrkeystorepass "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"
echo "Checking solr browser"
validateKeystore keystores/client/browser_client.keystore browserkeystorepass PKCS12 "browser"
validateCertificate keystores/client/browser_client.keystore browserkeystorepass browser "Owner: CN=Custom Browser Client, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/client/browser_client.keystore browserkeystorepass browser "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"

echo "Checking sharedFileStore"
validateKeystore keystores/sharedFileStore/sharedFileStore.keystore sharedfilestorekeystorepass PKCS12 "sharedfilestore" "ssl.alfresco.ca"
validateTruststore keystores/sharedFileStore/sharedFileStore.truststore sharedfilestoretruststorepass JKS "alfresco.ca"
validateCertificate keystores/sharedFileStore/sharedFileStore.keystore sharedfilestorekeystorepass "Owner: CN=Shared File Store, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/sharedFileStore/sharedFileStore.keystore sharedfilestorekeystorepass "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"

echo "Checking transformRouter client"
validateKeystore keystores/transformRouter/transformRouter_client.keystore transformrouterclientpass JCEKS "transformrouter_client" "ssl.alfresco.ca"
validateTruststore keystores/transformRouter/transformRouter_client.truststore transformrouterclientpass JCEKS "alfresco.ca"
validateCertificate keystores/transformRouter/transformRouter_client.keystore transformrouterclientpass "Owner: CN=Transform Router Client, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/transformRouter/transformRouter_client.keystore transformrouterclientpass "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"

echo "Checking transformRouter server"
validateKeystore keystores/transformRouter/transformRouter_server.keystore transformrouterserverpass JCEKS "transformrouter_server" "ssl.alfresco.ca"
validateTruststore keystores/transformRouter/transformRouter_server.truststore transformrouterserverpass JCEKS "alfresco.ca"
validateCertificate keystores/transformRouter/transformRouter_server.keystore transformrouterserverpass "Owner: CN=Transform Router Server, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/transformRouter/transformRouter_server.keystore transformrouterserverpass "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"

echo "Success"