#! /bin/bash

rm -rd ca
rm -rd certificates
rm -rd keystores
#CA, Repository, Solr, Zeppelin
./run.sh -alfrescoversion community -keysize 2048 -keystoretype JCEKS -truststoretype JCEKS -keystorepass kT9X6oe68t -truststorepass kT9X6oe68t -encstorepass mp6yc0UD9e -encmetadatapass oKIWzVdEdA -alfrescoformat current

#Shared file store
./run_additional.sh -servicename sharedFileStore -alias sharedFileStore_server -role server -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store Server" -servername localhost -alfrescoformat current

#Transform Router
./run_additional.sh -servicename transformRouter -alias transformRouter_client -role client -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router Client" -servername localhost -alfrescoformat current
./run_additional.sh -servicename transformRouter -alias transformRouter_server -role server -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router Server" -servername localhost -alfrescoformat current

#T-Engine AIO
./run_additional.sh -servicename tengineAIO -alias tengineAIO_client -role client -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO Client" -servername localhost -alfrescoformat current
./run_additional.sh -servicename tengineAIO -alias tengineAIO_server -role server -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO Server" -servername localhost -alfrescoformat current

#T-Engine Imagemagick
./run_additional.sh -servicename tengineImageMagick -alias tengineImageMagick_client -role client -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick Client" -servername localhost -alfrescoformat current
./run_additional.sh -servicename tengineImageMagick -alias tengineImageMagick_server -role server -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick Server" -servername localhost -alfrescoformat current
#T-Engine Libreoffice
./run_additional.sh -servicename tengineLibreOffice -alias tengineLibreOffice_client -role client -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice Client" -servername localhost -alfrescoformat current
./run_additional.sh -servicename tengineLibreOffice -alias tengineLibreOffice_server -role server -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice Server" -servername localhost -alfrescoformat current
#T-Engine Pdfrenderer
./run_additional.sh -servicename tenginePdfRenderer -alias tenginePdfRenderer_client -role client -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer Client" -servername localhost -alfrescoformat current
./run_additional.sh -servicename tenginePdfRenderer -alias tenginePdfRenderer_server -role server -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer Server" -servername localhost -alfrescoformat current
#T-Engine Tika
./run_additional.sh -servicename tengineTika -alias tengineTika_client -role client -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika Client" -servername localhost -alfrescoformat current
./run_additional.sh -servicename tengineTika -alias tengineTika_server -role server -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika Server" -servername localhost -alfrescoformat current
#T-Engine Misc
./run_additional.sh -servicename tengineMisc -alias tengineMisc_client -role client -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc Client" -servername localhost -alfrescoformat current
./run_additional.sh -servicename tengineMisc -alias tengineMisc_server -role server -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc Server" -servername localhost -alfrescoformat current

#Custom T-Engine
./run_additional.sh -servicename tengineCustom -alias tengineCustom_client -role client -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Custom Client" -servername localhost -alfrescoformat current
./run_additional.sh -servicename tengineCustom -alias tengineCustom_server -role server -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Custom Server" -servername localhost -alfrescoformat current
