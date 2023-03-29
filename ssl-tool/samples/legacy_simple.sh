#! /bin/bash

set -o errexit
set -o pipefail
set -o nounset

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source ${SCRIPT_DIR}/../utils.sh

# SETTINGS
# Alfresco Format: "classic" / "current" is supported only from 7.0
ALFRESCO_FORMAT=current

#CA, Repository, Solr, Zeppelin
bash ${SCRIPT_DIR}/../run.sh -alfrescoversion community -keysize 2048 -keystoretype JCEKS -truststoretype JCEKS -keystorepass kT9X6oe68t -truststorepass kT9X6oe68t -encstorepass mp6yc0UD9e -encmetadatapass oKIWzVdEdA -alfrescoformat $ALFRESCO_FORMAT -cavalidityduration 1

#Shared file store
bash ${SCRIPT_DIR}/../run_additional.sh -servicename sharedFileStore -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#Transform Router
bash ${SCRIPT_DIR}/../run_additional.sh -servicename transformRouter -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine AIO
bash ${SCRIPT_DIR}/../run_additional.sh -servicename tengineAIO -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Imagemagick
bash ${SCRIPT_DIR}/../run_additional.sh -servicename tengineImageMagick -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Libreoffice
bash ${SCRIPT_DIR}/../run_additional.sh -servicename tengineLibreOffice -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Pdfrenderer
bash ${SCRIPT_DIR}/../run_additional.sh -servicename tenginePdfRenderer -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Tika
bash ${SCRIPT_DIR}/../run_additional.sh -servicename tengineTika -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Misc
bash ${SCRIPT_DIR}/../run_additional.sh -servicename tengineMisc -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc" -servername localhost -alfrescoformat $ALFRESCO_FORMAT

#Custom T-Engine
bash ${SCRIPT_DIR}/../run_additional.sh -servicename tengineCustom -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Custom" -servername localhost,additional -alfrescoformat $ALFRESCO_FORMAT
