@ECHO OFF

REM This script is a follow up to run.sh script.
REM It is responsible for sets of keystores and truststores for additional services to be used in mTLS approach.

REM Open script through new cmd, to not save password inputs in command line history
IF "%~1"=="-clearhistory" GOTO :scriptStart
CMD /S /C "%~f0 -clearhistory %*"
EXIT /b

:scriptStart
setlocal EnableDelayedExpansion


SET PASSWORD_PLACEHOLDER=password_placeholder

REM ----------
REM DIRECTORIES
REM ----------
SET CA_DIR=ca
SET KEYSTORES_DIR=keystores
SET CERTIFICATES_DIR=certificates

REM ----------
REM PARAMETERS
REM ----------

REM Using "current" format by default (only available from ACS 7.0+)
SET ALFRESCO_FORMAT=current

REM Service name, to be used as folder name where results are generated to
SET SERVICE_NAME=service
REM Folder name to place results of script in
SET SUBFOLDER_NAME=
REM Alias of private key
SET ALIAS=
REM Role to be fulfilled by the keystore key (both/client/server)
SET ROLE=both
REM Distinguished name of the CA
SET SERVICE_CERT_DNAME=/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Service
REM Service server name, to be used as Alternative Name in the certificates
SET SERVICE_SERVER_NAME=localhost

REM Root CA Password
SET ROOT_CA_PASS=
REM RSA key length (1024, 2048, 4096)
SET KEY_SIZE=2048
REM Keystore format (PKCS12, JKS, JCEKS)
SET KEYSTORE_TYPE=JCEKS
REM Default password for keystore and private key
SET KEYSTORE_PASS=%PASSWORD_PLACEHOLDER%

SET NO_TRUSTSTORE=false
REM Truststore format (JKS, JCEKS)
SET TRUSTSTORE_TYPE=JCEKS
REM Default password for truststore
SET TRUSTSTORE_PASS=%PASSWORD_PLACEHOLDER%

REM Parse params from command line
:loop
IF NOT "%1"=="" (
  REM clearhistory is a helper parameter for not storing passwords in command line history
  IF "%1"=="-clearhistory" (
    SHIFT
    GOTO loop
  )
  REM Service name
  IF "%1"=="-servicename" (
    SHIFT
    SET SERVICE_NAME=%2
    SHIFT
    GOTO loop
  )
  REM Subfolder name, useful multiple keystores per service, if unset will take on -servicename value
  IF "%1"=="-subfoldername" (
    SHIFT
    SET SUBFOLDER_NAME=%2
    SHIFT
    GOTO loop
  )
  REM Private Key alias
  IF "%1"=="-alias" (
    SHIFT
    SET ALIAS=%2
    SHIFT
    GOTO loop
  )
  REM Role: server, client, both (default)
  IF "%1"=="-role" (
    SHIFT
    SET ROLE=%2
    SHIFT
    GOTO loop
  )
  REM Root CA password
  IF "%1"=="-rootcapass" (
    SHIFT
    SET ROOT_CA_PASS=%2
    SHIFT
    GOTO loop
  )
  REM 1024, 2048, 4096, ...
  IF "%1"=="-keysize" (
    SHIFT
    SET KEY_SIZE=%2
    SHIFT
    GOTO loop
  )
  REM PKCS12, JKS, JCEKS
  IF "%1"=="-keystoretype" (
    SHIFT
    SET KEYSTORE_TYPE=%2
    SHIFT
    GOTO loop
  )
  REM Password for keystore and private key
  IF "%1"=="-keystorepass" (
    SHIFT
    SET KEYSTORE_PASS=%2
    SHIFT
    GOTO loop
  )
  REM Flag blocking generating of a truststore
  IF "%1"=="-notruststore" (
    SHIFT
    SET NO_TRUSTSTORE=true
    GOTO loop
  )
  REM JKS, JCEKS
  IF "%1"=="-truststoretype" (
    SHIFT
    SET TRUSTSTORE_TYPE=%2
    SHIFT
    GOTO loop
  )
  REM Password for truststore
  IF "%1"=="-truststorepass" (
    SHIFT
    SET TRUSTSTORE_PASS=%2
    SHIFT
    GOTO loop
  )
  REM DName for Service certificate
  IF "%1"=="-certdname" (
    SHIFT
    SET SERVICE_CERT_DNAME=%~2
    SHIFT
    GOTO loop
  )
  REM DNS name for Service
  IF "%1"=="-servername" (
    SHIFT
    SET SERVICE_SERVER_NAME=%~2
    SHIFT
    GOTO loop
  )
  REM Alfresco Format: "classic" / "current" is supported only from 7.0
  IF "%1"=="-alfrescoformat" (
    SHIFT
    SET ALFRESCO_FORMAT=%~2
    SHIFT
    GOTO loop
  )

  ECHO An invalid parameter was received: %1
  ECHO Allowed parameters:
  ECHO   -servicename
  ECHO   -subfoldername
  ECHO   -alias
  ECHO   -role
  ECHO   -rootcapass
  ECHO   -keysize
  ECHO   -keystoretype
  ECHO   -keystorepass
  ECHO   -notruststore
  ECHO   -truststoretype
  ECHO   -truststorepass
  ECHO   -certdname
  ECHO   -servername
  ECHO   -alfrescoformat

  EXIT /b 1
)

ECHO ---Run Additional Script Execution for %SERVICE_NAME%---

IF "%ROOT_CA_PASS%" == "" (
  ECHO Root CA password [parameter: rootcapass] is mandatory
  EXIT /b 1
)

IF "%ALIAS%" == "" (
  SET ALIAS=%SERVICE_NAME%
)

IF "%SUBFOLDER_NAME%" == "" (
  SET SUBFOLDER_NAME=%SERVICE_NAME%
)

REM Set settings based on role
IF "%ROLE%" == "client" (
  SET EXTENSION=client_cert
  SET FILE_SUFFIX=_client
  ECHO Warning: For client role, servername parameter will be unused even if provided.
  SET SERVICE_SERVER_NAME=
) ELSE IF "%ROLE%" == "server" (
  SET EXTENSION=server_cert
  SET FILE_SUFFIX=_server
) ELSE IF "%ROLE%" == "both" (
  SET EXTENSION=clientServer_cert
  SET FILE_SUFFIX=
) ELSE IF "%ROLE%" == "" (
  ECHO Warning: No role provided, using default role: 'both'
  SET ROLE=both
  SET EXTENSION=clientServer_cert
  SET FILE_SUFFIX=
) ELSE (
  ECHO Unsupported role provided %ROLE%, valid roles are client/server/both
  EXIT /b 1
)

ECHO Warning: If passwords will be provided at runtime, they will be visibe at input.
CALL :readKeystorePassword
IF ERRORLEVEL 1 ( EXIT /b 1 )

IF "%NO_TRUSTSTORE%" == "false" (
  CALL :readTruststorePassword
  IF ERRORLEVEL 1 ( EXIT /b 1 )
)

REM Generates service keystore, trustore and certificate required for Alfresco SSL configuration
SET SERVICE_KEYSTORES_DIR=%KEYSTORES_DIR%\%SUBFOLDER_NAME%
IF NOT EXIST "%SERVICE_KEYSTORES_DIR%" (
  mkdir %SERVICE_KEYSTORES_DIR%
)

IF NOT "%ROLE%" == "client" (
  CALL ./utils_san.cmd "%SERVICE_SERVER_NAME%"
)

SET FILE_NAME=%SERVICE_NAME%%FILE_SUFFIX%

REM Generate key and CSR
openssl req -newkey rsa:%KEY_SIZE% -nodes -out %CERTIFICATES_DIR%\%FILE_NAME%.csr -keyout %CERTIFICATES_DIR%\%FILE_NAME%.key -subj "%SERVICE_CERT_DNAME%"

REM Sign CSR with CA
openssl ca -config openssl.cnf -extensions %EXTENSION% -passin pass:%ROOT_CA_PASS% -batch -notext ^
-in %CERTIFICATES_DIR%\%FILE_NAME%.csr -out %CERTIFICATES_DIR%\%FILE_NAME%.cer

REM Export keystore with key and certificate
openssl pkcs12 -export -out %CERTIFICATES_DIR%\%FILE_NAME%.p12 -inkey %CERTIFICATES_DIR%\%FILE_NAME%.key ^
-in %CERTIFICATES_DIR%\%FILE_NAME%.cer -password pass:!KEYSTORE_PASS! -certfile %CA_DIR%\certs\ca.cert.pem

REM Convert keystore to desired format, set alias
keytool -importkeystore ^
-srckeystore %CERTIFICATES_DIR%\%FILE_NAME%.p12 -destkeystore %SERVICE_KEYSTORES_DIR%\%FILE_NAME%.keystore ^
-srcstoretype PKCS12 -deststoretype %KEYSTORE_TYPE% ^
-srcstorepass !KEYSTORE_PASS! -deststorepass !KEYSTORE_PASS! ^
-srcalias 1 -destalias %ALIAS% ^
-srckeypass !KEYSTORE_PASS! -destkeypass !KEYSTORE_PASS! ^
-noprompt

REM Import CA certificate into Service keystore, for complete certificate chain
keytool -importcert -noprompt -alias alfresco.ca -file ca\certs\ca.cert.pem ^
-keystore %SERVICE_KEYSTORES_DIR%\%FILE_NAME%.keystore -storetype %KEYSTORE_TYPE% -storepass !KEYSTORE_PASS!

REM Create Keystore password file
ECHO keystore.password=!KEYSTORE_PASS!>> %SERVICE_KEYSTORES_DIR%\%FILE_NAME%-keystore-passwords.properties
ECHO aliases=%ALIAS%>> %SERVICE_KEYSTORES_DIR%\%FILE_NAME%-keystore-passwords.properties
ECHO %ALIAS%.password=!KEYSTORE_PASS!>> %SERVICE_KEYSTORES_DIR%\%FILE_NAME%-keystore-passwords.properties

IF "%NO_TRUSTSTORE%" == "false" (
  REM Include CA certificates in Service Truststore
  keytool -import -trustcacerts -noprompt -alias alfresco.ca -file ca\certs\ca.cert.pem ^
  -keystore %SERVICE_KEYSTORES_DIR%\%FILE_NAME%.truststore -storetype %TRUSTSTORE_TYPE% -storepass !TRUSTSTORE_PASS!

  REM Create TrustStore password file
  ECHO keystore.password=!TRUSTSTORE_PASS!>> %SERVICE_KEYSTORES_DIR%\%FILE_NAME%-truststore-passwords.properties
  ECHO aliases=alfresco.ca>> %SERVICE_KEYSTORES_DIR%\%FILE_NAME%-truststore-passwords.properties
)

REM Removing files for current Alfresco Format
IF "%ALFRESCO_FORMAT%" == "current" (
  del %SERVICE_KEYSTORES_DIR%\%FILE_NAME%-keystore-passwords.properties
  IF "%NO_TRUSTSTORE%" == "false" (
    del %SERVICE_KEYSTORES_DIR%\%FILE_NAME%-truststore-passwords.properties
  )
)

REM End of processing
GOTO :eof

:readKeystorePassword
SET PASSWORD=%KEYSTORE_PASS%
CALL ./utils_password_prompt.cmd "[service name] %SERVICE_NAME%, [role] %ROLE%, keystore"
IF ERRORLEVEL 1 ( EXIT /b 1 )
SET KEYSTORE_PASS=!PASSWORD!
GOTO :eof

:readTruststorePassword
SET PASSWORD=%TRUSTSTORE_PASS%
CALL ./utils_password_prompt.cmd "[service name] %SERVICE_NAME%, [role] %ROLE%, truststore"
IF ERRORLEVEL 1 ( EXIT /b 1 )
SET TRUSTSTORE_PASS=!PASSWORD!
GOTO :eof