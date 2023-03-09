@ECHO OFF

REM Open script through new cmd, to not save password inputs in command line history
IF "%~1"=="-clearhistory" GOTO :scriptStart
CMD /S /C "%~f0 -clearhistory %*"
EXIT /b

:scriptStart
setlocal EnableDelayedExpansion

REM This script is a follow up to run.sh script (it generates the CA that will be required here).
REM It is responsible for sets of keystores and truststores for additional services to be used in mTLS approach.

SET PASSWORD_PLACEHOLDER="<password>"

REM ----------
REM PARAMETERS
REM ----------

REM Using "current" format by default (only available from ACS 7.0+)
SET ALFRESCO_FORMAT=current

REM Service name, to be used as folder name where results are generated to
SET SERVICE_NAME=service
REM Alias of private key
SET ALIAS=%SERVICE_NAME%
REM Role to be fulfilled by the keystore key (both/client/server)
SET ROLE=both
REM Distinguished name of the CA
SET SERVICE_CERT_DNAME=/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Service
REM Service server name, to be used as Alternative Name in the certificates
SET SERVICE_SERVER_NAME=localhost

SET KEYSTORES_DIR=keystores
SET CERTIFICATES_DIR=certificates

REM Root CA Password
SET ROOT_CA_PASS=
REM RSA key length (1024, 2048, 4096)
SET KEY_SIZE=2048
REM Keystore format (PKCS12, JKS, JCEKS)
SET KEYSTORE_TYPE=JCEKS
REM Default password for every keystore and private key
SET KEYSTORE_PASS=%PASSWORD_PLACEHOLDER%

REM Truststore format (JKS, JCEKS)
SET TRUSTSTORE_TYPE=JCEKS
REM Default password for every truststore
SET TRUSTSTORE_PASS=%PASSWORD_PLACEHOLDER%

REM Parse params from command line
:loop
IF NOT "%1"=="" (
  IF "%1"=="-clearhistory" (
    REM clearhistory is a helper parameter for not storing passwords in command line history
	SHIFT
	GOTO loop
  )
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
  IF "%1"=="-rootcapass" (
    SHIFT
    SET ROOT_CA_PASS=%2
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
  ECHO   -rootcapass
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

ECHO ---Run Additional Script Execution for %SERVICE_NAME%---

IF "%ROOT_CA_PASS%" == "" (
  ECHO "Root CA password [parameter: rootcapass] is mandatory"
  EXIT /b 1
)

ECHO Warning: If passwords will be provided at runtime, they will be visibe at input.
CALL :readKeystorePassword
IF ERRORLEVEL 1 ( EXIT /b 1 )
CALL :readTruststorePassword
IF ERRORLEVEL 1 ( EXIT /b 1 )

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
SET SERVICE_KEYSTORES_DIR=%KEYSTORES_DIR%\%SERVICE_NAME%

REM Create folders for truststores, keystores and certificates
IF NOT EXIST "%SERVICE_KEYSTORES_DIR%" (
  mkdir %SERVICE_KEYSTORES_DIR%
)

CALL :subjectAlternativeNames

REM Generate key and CSR
openssl req -newkey rsa:%KEY_SIZE% -nodes -out %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.csr -keyout %CERTIFICATES_DIR%\%SERVICE_NAME%%FILE_SUFFIX%.key -subj "%SERVICE_CERT_DNAME%"

REM Sign CSR with CA
openssl ca -config openssl.cnf -extensions %EXTENSION% -passin pass:%ROOT_CA_PASS% -batch -notext ^
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

REM End of processing
GOTO :eof

REM Password reading functions
:verifyPasswordConditions
  SET CHECK_FAILED=false

  CALL :strLen PASSWORD PASSWORD_LENGTH
  IF %PASSWORD_LENGTH% LSS 6 (
    ECHO Password must have at least 6 characters and no more than 1023
    SET CHECK_FAILED=true
  ) ELSE IF %PASSWORD_LENGTH% GTR 1023 (
    ECHO Password must have at least 6 characters and no more than 1023
    SET CHECK_FAILED=true
  )
GOTO :eof

:readPassword
  SET /p "PASSWORD=Please enter password for %1: "

  CALL :verifyPasswordConditions
  IF !CHECK_FAILED! == true (
    SET PASSWORD=%PASSWORD_PLACEHOLDER%
    GOTO :readPassword
  )

  SET /p "PASSWORD_CHECK=Please repeat pass phrase : "
  IF NOT "%PASSWORD%" == "%PASSWORD_CHECK%" (
    ECHO Password verification failed
    SET PASSWORD=%PASSWORD_PLACEHOLDER%
    GOTO :readPassword
  )
GOTO :eof

:askForPasswordIfNeeded
IF NOT "%PASSWORD%" == "%PASSWORD_PLACEHOLDER%" (
  ECHO Verifying password provided for %1
  CALL :verifyPasswordConditions
  IF !CHECK_FAILED! == true (
    EXIT /B 1
  ) ELSE (
    EXIT /B 0
  )
)
CALL :readPassword %2
GOTO :eof

:readKeystorePassword
SET PASSWORD=%KEYSTORE_PASS%
CALL :askForPasswordIfNeeded keystore "[service name] %SERVICE_NAME%, [role] %ROLE%, keystore"
IF ERRORLEVEL 1 ( EXIT /b 1 )
SET KEYSTORE_PASS=!PASSWORD!
GOTO :eof

:readTruststorePassword
SET PASSWORD=%TRUSTSTORE_PASS%
CALL :askForPasswordIfNeeded truststore "[service name] %SERVICE_NAME%, [role] %ROLE%, truststore"
IF ERRORLEVEL 1 ( EXIT /b 1 )
SET TRUSTSTORE_PASS=!PASSWORD!
GOTO :eof

REM Subject Alternative Name provided through config file substitution
:subjectAlternativeNames
IF DEFINED SERVICE_SERVER_NAME (
  REM Clear existing DNS.X lines in openssl.cnf file
  powershell -Command "(gc -Encoding utf8 openssl.cnf) | Foreach-Object {$_ -replace '^DNS\..*', ''} | Set-Content openssl.cnf"

  REM Split given server names by "," separator
  REM Create a string that would place every hostname as a separate DNS.{counter} = {hostname} line
  SET COUNTER=0

  FOR %%HOSTNAME IN (%SERVICE_SERVER_NAME%) do (
    SET /a COUNTER=COUNTER+1
    SET "SED_HOSTNAMES=!SED_HOSTNAMES!`nDNS.!COUNTER! = %%HOSTNAME"
  )

  REM Place that string in openssl.cnf file under [alt_names]
  powershell -Command "(gc -Encoding utf8 openssl.cnf) | Foreach-Object {$_ -replace '\[alt_names\]', '[alt_names]`n!SED_HOSTNAMES!'} | Set-Content openssl.cnf"

  powershell -Command "(gc -Encoding utf8 openssl.cnf) | Foreach-Object {$_ -replace '\xEF\xBB\xBF', ''} | Set-Content openssl.cnf"
)
GOTO :eof

:strLen
setlocal enabledelayedexpansion

:strLen_Loop
   IF NOT "!%1:~%len%!"=="" SET /A len+=1 & goto :strLen_Loop
(endlocal & SET %2=%len%)
GOTO :eof