#! /bin/bash

rm -rd ca
rm -rd certificates
rm -rd keystores
#CA, Repository, Solr, Zeppelin
./run.sh -alfrescoversion community -keysize 2048 -keystoretype JCEKS -truststoretype JCEKS -keystorepass kT9X6oe68t -truststorepass kT9X6oe68t -encstorepass mp6yc0UD9e -encmetadatapass oKIWzVdEdA -alfrescoformat current

#Shared file store
./run_additional.sh -servicename sharedFileStore -alias sharedFileStore -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store" -servername localhost -alfrescoformat current
#Transform Router
./run_additional.sh -servicename transformRouter -alias transformRouter -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router" -servername localhost -alfrescoformat current
#T-Engine AIO
./run_additional.sh -servicename tengineAIO -alias tengineAIO -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO" -servername localhost -alfrescoformat current
#T-Engine Imagemagick
./run_additional.sh -servicename tengineImageMagick -alias tengineImageMagick -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick" -servername localhost -alfrescoformat current
#T-Engine Libreoffice
./run_additional.sh -servicename tengineLibreOffice -alias tengineLibreOffice -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice" -servername localhost -alfrescoformat current
#T-Engine Pdfrenderer
./run_additional.sh -servicename tenginePdfRenderer -alias tenginePdfRenderer -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer" -servername localhost -alfrescoformat current
#T-Engine Tika
./run_additional.sh -servicename tengineTika -alias tengineTika -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika" -servername localhost -alfrescoformat current
#T-Engine Misc
./run_additional.sh -servicename tengineMisc -alias tengineMisc -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc" -servername localhost -alfrescoformat current

#Custom T-Engine
./run_additional.sh -servicename tengineCustom -alias tengineCustom -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Custom" -servername localhost -alfrescoformat current
