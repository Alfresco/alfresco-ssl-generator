#! /bin/bash

#This script is used in MTLS test in different repositories.
#Be cautions when manipulating with it.

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
bash ${SCRIPT_DIR}/../../ssl-tool/run_ca.sh -keysize 2048 -keystorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA" -servername test
#Shared file store
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename sharedFileStore -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store" -servername test -alfrescoformat $ALFRESCO_FORMAT
#Transform Router
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename transformRouter -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router" -servername test -alfrescoformat $ALFRESCO_FORMAT
#T-Engine AIO
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineAIO -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO" -servername test -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Imagemagick
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineImageMagick -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick" -servername test -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Libreoffice
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineLibreOffice -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice" -servername test -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Pdfrenderer
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tenginePdfRenderer -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer" -servername test -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Tika
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineTika -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika" -servername test -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Misc
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineMisc -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc" -servername test -alfrescoformat $ALFRESCO_FORMAT

#HttpClient used in tests
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename testClient -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Test Client" -servername test -alfrescoformat $ALFRESCO_FORMAT
