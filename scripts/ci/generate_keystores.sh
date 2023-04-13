#! /bin/bash

# SETTINGS
# Alfresco Format: "classic" / "current" is supported only from 7.0
ALFRESCO_FORMAT=current

#Contains directory settings
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
source ${SCRIPT_DIR}/../../ssl-tool/utils.sh

# SETTINGS
# Alfresco Format: "classic" / "current" is supported only from 7.0
ALFRESCO_FORMAT=current

#CA
bash ${SCRIPT_DIR}/../../ssl-tool/run_ca.sh -keysize 2048 -keystorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA" -servername localhost -validityduration 1
#Alfresco
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename alfresco -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository" -servername localhost,alfresco -alfrescoformat $ALFRESCO_FORMAT
#Alfresco Metadata encryption
bash ${SCRIPT_DIR}/../../ssl-tool/run_encryption.sh -subfoldername alfresco -servicename encryption -encstorepass mp6yc0UD9e -encmetadatapass oKIWzVdEdA -alfrescoformat $ALFRESCO_FORMAT
#T-Engine AIO
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename tengineAIO -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO" -servername localhost,transform-core-aio -alfrescoformat $ALFRESCO_FORMAT
#Shared file store
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename sharedFileStore -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store" -servername localhost,shared-file-store -alfrescoformat $ALFRESCO_FORMAT
#Transform Router
bash ${SCRIPT_DIR}/../../ssl-tool/run_additional.sh -servicename transformRouter -rootcapass password -keysize 2048 -keystoretype JCEKS -keystorepass password -truststoretype JCEKS -truststorepass password -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router" -servername localhost,transform-router -alfrescoformat $ALFRESCO_FORMAT
