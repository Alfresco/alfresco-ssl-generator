@ECHO OFF

rd /s /q ca
rd /s /q certificates
rd /s /q keystores

REM SETTINGS
REM Alfresco Format: "classic" / "current" is supported only from 7.0
SET ALFRESCO_FORMAT=current

REM CA, Repository, Solr, Zeppelin
call run.cmd -alfrescoversion community -keysize 2048 -keystoretype JCEKS -truststoretype JCEKS -keystorepass kT9X6oe68t -truststorepass kT9X6oe68t -encstorepass mp6yc0UD9e -encmetadatapass oKIWzVdEdA -alfrescoformat %ALFRESCO_FORMAT% -cavalidityduration 1

REM Shared file store
call run_additional.cmd -servicename sharedFileStore -alias sharedFileStore_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Shared File Store Server" -servername localhost -alfrescoformat %ALFRESCO_FORMAT%

REM Transform Router
call run_additional.cmd -servicename transformRouter -alias transformRouter_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router Client" -alfrescoformat %ALFRESCO_FORMAT%
call run_additional.cmd -servicename transformRouter -alias transformRouter_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Transform Router Server" -servername localhost -alfrescoformat %ALFRESCO_FORMAT%

REM T-Engine AIO
call run_additional.cmd -servicename tengineAIO -alias tengineAIO_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO Client" -alfrescoformat %ALFRESCO_FORMAT%
call run_additional.cmd -servicename tengineAIO -alias tengineAIO_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine AIO Server" -servername localhost -alfrescoformat %ALFRESCO_FORMAT%

REM T-Engine Imagemagick
call run_additional.cmd -servicename tengineImageMagick -alias tengineImageMagick_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick Client" -alfrescoformat %ALFRESCO_FORMAT%
call run_additional.cmd -servicename tengineImageMagick -alias tengineImageMagick_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine ImageMagick Server" -servername localhost -alfrescoformat %ALFRESCO_FORMAT%
REM T-Engine Libreoffice
call run_additional.cmd -servicename tengineLibreOffice -alias tengineLibreOffice_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice Client" -alfrescoformat %ALFRESCO_FORMAT%
call run_additional.cmd -servicename tengineLibreOffice -alias tengineLibreOffice_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine LibreOffice Server" -servername localhost -alfrescoformat %ALFRESCO_FORMAT%
REM T-Engine Pdfrenderer
call run_additional.cmd -servicename tenginePdfRenderer -alias tenginePdfRenderer_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer Client" -alfrescoformat %ALFRESCO_FORMAT%
call run_additional.cmd -servicename tenginePdfRenderer -alias tenginePdfRenderer_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine PdfRenderer Server" -servername localhost -alfrescoformat %ALFRESCO_FORMAT%
REM T-Engine Tika
call run_additional.cmd -servicename tengineTika -alias tengineTika_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika Client" -alfrescoformat %ALFRESCO_FORMAT%
call run_additional.cmd -servicename tengineTika -alias tengineTika_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Tika Server" -servername localhost -alfrescoformat %ALFRESCO_FORMAT%
REM T-Engine Misc
call run_additional.cmd -servicename tengineMisc -alias tengineMisc_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc Client" -alfrescoformat %ALFRESCO_FORMAT%
call run_additional.cmd -servicename tengineMisc -alias tengineMisc_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Misc Server" -servername localhost -alfrescoformat %ALFRESCO_FORMAT%

REM Custom T-Engine
call run_additional.cmd -servicename tengineCustom -alias tengineCustom_client -role client -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Custom Client" -alfrescoformat %ALFRESCO_FORMAT%
call run_additional.cmd -servicename tengineCustom -alias tengineCustom_server -role server -rootcapass kT9X6oe68t -keysize 2048 -keystoretype JCEKS -keystorepass kT9X6oe68t -truststoretype JCEKS -truststorepass kT9X6oe68t -certdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=T-Engine Custom Server" -servername "localhost,additional" -alfrescoformat %ALFRESCO_FORMAT%
