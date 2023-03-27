@ECHO OFF

REM This script is generating a Root CA

REM Open script through new cmd, to not save password inputs in command line history
IF "%~1"=="-clearhistory" GOTO :scriptStart
CMD /S /C "%~f0 -clearhistory %*"
EXIT /b

:scriptStart

REM ----------
REM DIRECTORIES
REM ----------
SET CA_DIR=ca
SET KEYSTORES_DIR=keystores
SET CERTIFICATES_DIR=certificates

REM ----------
REM PARAMETERS
REM ----------

REM Distinguished name of the CA
SET CA_DNAME=/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA

REM Alfresco and SOLR server names, to be used as Alternative Name in the certificates
SET CA_SERVER_NAME=localhost

REM RSA key length (1024, 2048, 4096)
SET KEY_SIZE=2048
REM Default password for every keystore and private key
SET KEYSTORE_PASS=password_placeholder

REM If not set, assume it's a testing environment, Root CA of a testing environment shouldn't last more than a day
SET VALIDITY_DURATION=1

REM Parse params from command line
:loop
IF NOT "%1"=="" (
  IF "%1"=="-clearhistory" (
    REM clearhistory is a helper parameter for not storing passwords in command line history
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
  REM Password for keystore and private key
  IF "%1"=="-keystorepass" (
    SHIFT
    SET KEYSTORE_PASS=%2
    SHIFT
    GOTO loop
  )
  REM DName for CA issuing the certificates
  IF "%1"=="-cacertdname" (
    SHIFT
    SET CA_DNAME=%~2
    SHIFT
    GOTO loop
  )
  REM DNS name for CA Server
  IF "%1"=="-caservername" (
    SHIFT
    SET CA_SERVER_NAME=%~2
    SHIFT
    GOTO loop
  )
  REM Validity of Root CA certificate in days
  IF "%1"=="-cavalidityduration" (
    SHIFT
    SET VALIDITY_DURATION=%2
    SHIFT
    GOTO loop
  )
  ECHO An invalid parameter was received: %1
  ECHO Allowed parameters:
  ECHO   -keysize
  ECHO   -keystorepass
  ECHO   -cacertdname
  ECHO   -caservername
  ECHO   -cavalidityduration
  EXIT /b
)

IF %VALIDITY_DURATION% LSS 1 (
  ECHO Minimum validity of Root CA is 1 day
  EXIT /b 1
)

REM If target folder for Keystores is not empty, skip generation
FOR /F %%A in ('dir /b /a %KEYSTORES_DIR%') DO (
  ECHO Keystores folder is not empty, skipping generation process...
  EXIT /b
)

setlocal enabledelayedexpansion

CALL :cleanupFolders

CALL :readKeystorePassword
IF ERRORLEVEL 1 ( EXIT /b 1 )

REM ------------
REM CA
REM ------------

mkdir %CA_DIR%\certs %CA_DIR%\crl %CA_DIR%\newcerts %CA_DIR%\private
TYPE nul > %CA_DIR%\index.txt
ECHO 1000 > %CA_DIR%\serial

openssl genrsa -aes256 -passout pass:!KEYSTORE_PASS! -out %CA_DIR%\private\ca.key.pem %KEY_SIZE%

CALL ./utils_san.cmd "%CA_SERVER_NAME%"

openssl req -config openssl.cnf ^
      -key %CA_DIR%\private\ca.key.pem ^
      -new -x509 -days %VALIDITY_DURATION% -sha256 -extensions v3_ca ^
      -out %CA_DIR%\certs\ca.cert.pem ^
      -subj "%CA_DNAME%" ^
      -passin pass:!KEYSTORE_PASS!
	  
endlocal
	  
GOTO :eof

:readKeystorePassword
  SET PASSWORD=%KEYSTORE_PASS%
  CALL ./utils_password_prompt.cmd "Root CA"
  IF ERRORLEVEL 1 ( EXIT /b 1 )
  SET KEYSTORE_PASS=!PASSWORD!
GOTO :eof

:cleanupFolders
  REM Remove previous working directories and certificates
  IF EXIST "%CA_DIR%" (
    rmdir /s /q %CA_DIR%
  )
  mkdir %CA_DIR%

  IF NOT EXIST "%KEYSTORES_DIR%" (
    mkdir %KEYSTORES_DIR%
  )

  IF EXIST "%CERTIFICATES_DIR%" (
    rmdir /s /q %CERTIFICATES_DIR%
  )
  mkdir %CERTIFICATES_DIR%
GOTO :eof
