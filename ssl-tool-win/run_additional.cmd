@ECHO OFF

REM This script is a follow up to run.sh script (it generates the CA that will be required here).
REM It is responsible for sets of keystores and truststores for additional services to be used in mTLS approach.

REM ----------
REM PARAMETERS
REM ----------

REM Using "current" format by default (only available from ACS 7.0+)
SET ALFRESCO_FORMAT=current

REM Service name, to be used as folder name where results are generated to
SET SERVICE_NAME=service
REM Alias of private key
SET ALIAS=$SERVICE_NAME
REM Role to be fulfilled by the keystore key (both/client/server)
SET ROLE=both

REM Distinguished name of the CA
SET SERVICE_CERT_DNAME=/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Service

REM Service server name, to be used as Alternative Name in the certificates
SET SERVICE_SERVER_NAME=localhost

REM RSA key length (1024, 2048, 4096)
SET KEY_SIZE=2048

REM Keystore format (PKCS12, JKS, JCEKS)
SET KEYSTORE_TYPE=JCEKS
REM Default password for every keystore and private key
SET KEYSTORE_PASS=keystore

REM Truststore format (JKS, JCEKS)
SET TRUSTSTORE_TYPE=JCEKS
REM Default password for every truststore
SET TRUSTSTORE_PASS=truststore

SET KEYSTORES_DIR=keystores
SET CERTIFICATES_DIR=certificates

REM Parse params from command line
:loop
IF NOT "%1"=="" (
  IF "%1"=="-servicename" (
    SHIFT
    SET SERVICE_NAME=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-alias" (
    SHIFT
    SET ALIAS=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-role" (
    SHIFT
    SET ROLE=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-keysize" (
    SHIFT
    SET KEY_SIZE=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-keystoretype" (
    SHIFT
    SET KEYSTORE_TYPE=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-keystorepass" (
    SHIFT
    SET KEYSTORE_PASS=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-truststoretype" (
    SHIFT
    SET TRUSTSTORE_TYPE=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-truststorepass" (
    SHIFT
    SET TRUSTSTORE_PASS=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-certdname" (
    SHIFT
    SET SERVICE_CERT_DNAME=%~2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-servername" (
    SHIFT
    SET SERVICE_SERVER_NAME=%~2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-alfrescoformat" (
    SHIFT
    SET ALFRESCO_FORMAT=%~2
    SHIFT
    GOTO loop
  )

  ECHO An invalid parameter was received: %1
  ECHO Allowed parameters:
  ECHO   -servicename
  ECHO   -alias
  ECHO   -role
  ECHO   -keysize
  ECHO   -keystoretype
  ECHO   -keystorepass
  ECHO   -truststoretype
  ECHO   -truststorepass
  ECHO   -certdname
  ECHO   -servername
  ECHO   -alfrescoformat

  EXIT /b
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
) ELSE (
  ECHO Warning: Unsupported role provided, using 'both' as value
  SET ROLE=both
  SET EXTENSION=clientServer_cert
  SET FILE_SUFFIX=
)

REM Generates service keystore, trustore and certificate required for Alfresco SSL configuration

ECHO
ECHO ---Script Execution---
ECHO

SET SERVICE_KEYSTORES_DIR=%KEYSTORES_DIR%\%SERVICE_NAME%

REM Create folders for truststores, keystores and certificates
IF NOT EXIST "%SERVICE_KEYSTORES_DIR%" (
  mkdir %SERVICE_KEYSTORES_DIR%
)

REM Subject Alternative Name provided through config file substitution
powershell -Command "(gc -Encoding utf8 openssl.cnf) -replace '(^DNS.*\.).*', 'DNS.1=%SERVICE_SERVER_NAME%' | Out-File -Encoding utf8 openssl.cnf"
powershell -Command "(gc -Encoding utf8 openssl.cnf) | Foreach-Object {$_ -replace '\xEF\xBB\xBF', ''} | Set-Content openssl.cnf"

REM Generate key and CSR
openssl req -newkey rsa:%KEY_SIZE% -nodes -out %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.csr -keyout %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.key -subj "%SERVICE_CERT_DNAME%"

REM Sign CSR with CA
openssl ca -config openssl.cnf -extensions %EXTENSION% -passin pass:%KEYSTORE_PASS% -batch -notext ^
-in %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.csr -out %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.cer

REM Export keystore with key and certificate
openssl pkcs12 -export -out %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.p12 -inkey %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.key ^
-in %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.cer -password pass:%KEYSTORE_PASS% -certfile ca\certs\ca.cert.pem

REM Convert keystore to desired format, set alias
keytool -importkeystore ^
-srckeystore %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.p12 -destkeystore %SERVICE_KEYSTORES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.keystore ^
-srcstoretype PKCS12 -deststoretype %KEYSTORE_TYPE% ^
-srcstorepass %KEYSTORE_PASS% -deststorepass %KEYSTORE_PASS% ^
-srcalias 1 -destalias %ALIAS% ^
-srckeypass %KEYSTORE_PASS% -destkeypass %KEYSTORE_PASS% ^
-noprompt

REM Import CA certificate into Service keystore, for complete certificate chain
REM TODO check alias usage. ssl.alfresco.ca vs alfresco.ca !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
keytool -importcert -noprompt -alias alfresco.ca -file ca\certs\ca.cert.pem ^
-keystore %SERVICE_KEYSTORES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.keystore -storetype %KEYSTORE_TYPE% -storepass %KEYSTORE_PASS%

REM Create Keystore password file
ECHO aliases=%ALIAS%>> %SERVICE_KEYSTORES_DIR%\keystore-passwords.properties
ECHO %ALIAS%.password=%KEYSTORE_PASS%>> %SERVICE_KEYSTORES_DIR%\keystore-passwords.properties

REM Include CA certificates in Service Truststore
keytool -import -trustcacerts -noprompt -alias alfresco.ca -file ca\certs\ca.cert.pem ^
-keystore %SERVICE_KEYSTORES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.truststore -storetype %TRUSTSTORE_TYPE% -storepass %TRUSTSTORE_PASS%

REM Create TrustStore password file
ECHO aliases=alfresco.ca>> %SERVICE_KEYSTORES_DIR%\truststore-passwords.properties
ECHO alfresco.ca.password=%TRUSTSTORE_PASS%>> %SERVICE_KEYSTORES_DIR%\truststore-passwords.properties

REM Removing files for current Alfresco Format
IF "%ALFRESCO_FORMAT%" == "current" (
  del %SERVICE_KEYSTORES_DIR%\keystore-passwords.properties
  del %SERVICE_KEYSTORES_DIR%\truststore-passwords.properties
)