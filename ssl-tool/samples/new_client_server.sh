#! /bin/bash

# SETTINGS
# Alfresco Format: "classic" / "current" is supported only from 7.0
ALFRESCO_FORMAT=current

#Contains directory settings
source ./../utils.sh

# Cleanup previous output of script
rm -rd $CA_DIR
rm -rd $KEYSTORES_DIR
rm -rd $CERTIFICATES_DIR

#CA
./../run_ca.sh -keysize 2048 -keystorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA" -servername localhost
#Alfresco
./../run_additional.sh -servicename alfresco -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#Alfresco Metadata encryption
./../run_encryption.sh -subfoldername alfresco -servicename encryption -encstorepass mp6yc0UD9e -encmetadatapass oKIWzVdEdA -alfrescoformat $ALFRESCO_FORMAT
#Solr
./../run_additional.sh -servicename solr -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository Client" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
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
./../run_additional.sh -subfoldername client -servicename browser -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype PKCS12 -keystorepass kT9X6oe68t -notruststore -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Browser Client" -alfrescoformat $ALFRESCO_FORMAT

#Shared file store
./../run_additional.sh -servicename sharedFileStore -alias sharedFileStore_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#Transform Router
./../run_additional.sh -servicename transformRouter -alias transformRouter_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router Client" -alfrescoformat $ALFRESCO_FORMAT
./../run_additional.sh -servicename transformRouter -alias transformRouter_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine AIO
./../run_additional.sh -servicename tengineAIO -alias tengineAIO_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO Client" -alfrescoformat $ALFRESCO_FORMAT
./../run_additional.sh -servicename tengineAIO -alias tengineAIO_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Imagemagick
./../run_additional.sh -servicename tengineImageMagick -alias tengineImageMagick_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick Client" -alfrescoformat $ALFRESCO_FORMAT
./../run_additional.sh -servicename tengineImageMagick -alias tengineImageMagick_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Libreoffice
./../run_additional.sh -servicename tengineLibreOffice -alias tengineLibreOffice_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice Client" -alfrescoformat $ALFRESCO_FORMAT
./../run_additional.sh -servicename tengineLibreOffice -alias tengineLibreOffice_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Pdfrenderer
./../run_additional.sh -servicename tenginePdfRenderer -alias tenginePdfRenderer_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer Client" -alfrescoformat $ALFRESCO_FORMAT
./../run_additional.sh -servicename tenginePdfRenderer -alias tenginePdfRenderer_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Tika
./../run_additional.sh -servicename tengineTika -alias tengineTika_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika Client" -alfrescoformat $ALFRESCO_FORMAT
./../run_additional.sh -servicename tengineTika -alias tengineTika_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT
#T-Engine Misc
./../run_additional.sh -servicename tengineMisc -alias tengineMisc_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc Client" -alfrescoformat $ALFRESCO_FORMAT
./../run_additional.sh -servicename tengineMisc -alias tengineMisc_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT

#Custom T-Engine
./../run_additional.sh -servicename tengineCustom -alias tengineCustom_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Custom Client" -alfrescoformat $ALFRESCO_FORMAT
./../run_additional.sh -servicename tengineCustom -alias tengineCustom_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Custom Server" -servername localhost -alfrescoformat $ALFRESCO_FORMAT