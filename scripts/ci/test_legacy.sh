#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source ${SCRIPT_DIR}/../../ssl-tool/utils.sh

# SETTINGS
# Alfresco Format: "classic" / "current" is supported only from 7.0
ALFRESCO_FORMAT=current

echo "Generate: CA, Repository, Solr, Zeppelin"
bash ${SCRIPT_DIR}/../../ssl-tool/run.sh -alfrescoversion community -keysize 2048 -keystoretype JCEKS -truststoretype JCEKS -keystorepass keystorepass -truststorepass truststorepass -encstorepass encryption -encmetadatapass encryption -alfrescoservername localhost,test -alfrescoformat $ALFRESCO_FORMAT -cavalidityduration 1

echo "Generate sharedFileStore"
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename sharedFileStore -rootcapass keystorepass -keysize 2048 -keystoretype PKCS12 -keystorepass additionalkeystorepass -truststoretype JKS -truststorepass additionaltruststorepass -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store" -servername localhost,test -alfrescoformat $ALFRESCO_FORMAT

echo
echo "-------------Verifying results-------------"
echo

source ${SCRIPT_DIR}/test_utils.sh

echo "Checking repository"
validateKeystore keystores/alfresco/ssl.keystore keystorepass JCEKS "ssl.repo" "ssl.alfresco.ca"
validateTruststore keystores/alfresco/ssl.truststore truststorepass JCEKS "alfresco.ca"
validateCertificate keystores/alfresco/ssl.keystore keystorepass "Owner: CN=Custom Alfresco Repository, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/alfresco/ssl.keystore keystorepass "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"
validateSubjectAlternativeNames keystores/alfresco/ssl.keystore keystorepass localhost test
echo "Checking encryption"
validateEncryption keystores/alfresco/keystore encryption PKCS12 "metadata"
echo "Checking solr"
validateKeystore keystores/solr/ssl-repo-client.keystore keystorepass JCEKS "ssl.repo.client" "ssl.alfresco.ca"
validateTruststore keystores/solr/ssl-repo-client.truststore truststorepass JCEKS "alfresco.ca"
validateCertificate keystores/solr/ssl-repo-client.keystore keystorepass "Owner: CN=Custom Alfresco Repository Client, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/solr/ssl-repo-client.keystore keystorepass "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"
validateSubjectAlternativeNames keystores/solr/ssl-repo-client.keystore keystorepass localhost
validateSubjectAlternativeNamesNotFound keystores/solr/ssl-repo-client.keystore keystorepass test
echo "Checking solr browser"
validateKeystore keystores/client/browser.p12 keystorepass PKCS12 "1"
validateCertificate keystores/client/browser.p12 keystorepass "Owner: CN=Custom Browser Client, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/client/browser.p12 keystorepass "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"

echo "Checking sharedFileStore"
validateKeystore keystores/sharedFileStore/sharedFileStore.keystore additionalkeystorepass PKCS12 "sharedfilestore" "ssl.alfresco.ca"
validateTruststore keystores/sharedFileStore/sharedFileStore.truststore additionaltruststorepass JKS "alfresco.ca"
validateCertificate keystores/sharedFileStore/sharedFileStore.keystore additionalkeystorepass "Owner: CN=Shared File Store, OU=Unknown, O=Alfresco Software Ltd., ST=UK, C=GB"
validateCertificate keystores/sharedFileStore/sharedFileStore.keystore additionalkeystorepass "Issuer: CN=Custom Alfresco CA, OU=Unknown, O=Alfresco Software Ltd., L=Maidenhead, ST=UK, C=GB"
validateSubjectAlternativeNames keystores/sharedFileStore/sharedFileStore.keystore additionalkeystorepass localhost test
echo "Success"