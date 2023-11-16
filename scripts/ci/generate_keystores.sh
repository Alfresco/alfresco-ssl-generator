#! /bin/bash

#This script is used by MTLS tests in many repositories (acs-packaging, community-repo, transform-service, transform-aspose, ai-renditions).
#Be cautious #when manipulating it

# SETTINGS
# Alfresco Format: "classic" / "current" is supported only from 7.0
ALFRESCO_FORMAT=current

#Contains directory settings
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source ${SCRIPT_DIR}/../../ssl-tool/utils.sh

# Cleanup previous output of script
rm -rd $CA_DIR
rm -rd $KEYSTORES_DIR
rm -rd $CERTIFICATES_DIR

#CA
bash ${SCRIPT_DIR}/../../ssl-tool/run_ca.sh -keysize 2048 -keystorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA" -servername localhost -validityduration 1
#Alfresco
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename alfresco -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository" -servername localhost,alfresco -alfrescoformat $ALFRESCO_FORMAT
#Alfresco Metadata encryption
bash ${SCRIPT_DIR}/../../ssl-tool/run_encryption.sh -subfoldername alfresco -servicename encryption -encstorepass mp6yc0UD9e -encmetadatapass oKIWzVdEdA -alfrescoformat $ALFRESCO_FORMAT
#Search Engine
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename searchEngine -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Search Engine" -servername localhost,search,solr,solr4,solr6,elasticsearch,live-indexing,reindexing -alfrescoformat $ALFRESCO_FORMAT
#T-Engine AIO
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineAIO -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO" -servername localhost,transform-core-aio -alfrescoformat $ALFRESCO_FORMAT
#Shared file store
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename sharedFileStore -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store" -servername localhost,shared-file-store -alfrescoformat $ALFRESCO_FORMAT
#Transform Router
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename transformRouter -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router" -servername localhost,transform-router,router -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Imagemagick
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineImageMagick -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick" -servername localhost,imagemagick -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Libreoffice
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineLibreOffice -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice" -servername localhost,libreoffice -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Pdfrenderer
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tenginePdfRenderer -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer" -servername localhost,alfresco-pdf-renderer -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Tika
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineTika -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika" -servername localhost,tika -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Misc
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineMisc -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc" -servername localhost,misc -alfrescoformat $ALFRESCO_FORMAT
#Transform Aspose
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tAspose -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Aspose" -servername localhost,transform-aspose -alfrescoformat $ALFRESCO_FORMAT

#AWS AI
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename awsAi -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=AWS AI" -servername localhost,aws-ai -alfrescoformat $ALFRESCO_FORMAT

#HttpClient used in tests
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename testClient -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Test Client" -servername localhost,test-client -alfrescoformat $ALFRESCO_FORMAT
