rd /s /q ca
rd /s /q certificates
rd /s /q keystores

REM CA, Repository, Solr, Zeppelin
call run.cmd -alfrescoversion community -keysize 2048 -keystoretype JCEKS -truststoretype JCEKS -keystorepass kT9X6oe68t -truststorepass kT9X6oe68t -encstorepass mp6yc0UD9e -encmetadatapass oKIWzVdEdA -alfrescoformat current

REM Shared file store
call run_additional.cmd -servicename sharedFileStore -alias sharedFileStore -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store" -servername localhost -alfrescoformat current
REM Transform Router
call run_additional.cmd -servicename transformRouter -alias transformRouter -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router" -servername localhost -alfrescoformat current
REM T-Engine AIO
call run_additional.cmd -servicename tengineAIO -alias tengineAIO -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO" -servername localhost -alfrescoformat current
REM T-Engine Imagemagick
call run_additional.cmd -servicename tengineImageMagick -alias tengineImageMagick -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick" -servername localhost -alfrescoformat current
REM T-Engine Libreoffice
call run_additional.cmd -servicename tengineLibreOffice -alias tengineLibreOffice -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice" -servername localhost -alfrescoformat current
REM T-Engine Pdfrenderer
call run_additional.cmd -servicename tenginePdfRenderer -alias tenginePdfRenderer -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer" -servername localhost -alfrescoformat current
REM T-Engine Tika
call run_additional.cmd -servicename tengineTika -alias tengineTika -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika" -servername localhost -alfrescoformat current
REM T-Engine Misc
call run_additional.cmd -servicename tengineMisc -alias tengineMisc -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc" -servername localhost -alfrescoformat current

REM Custom T-Engine
call run_additional.cmd -servicename tengineCustom -alias tengineCustom -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname  "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Custom" -servername localhost -alfrescoformat current
