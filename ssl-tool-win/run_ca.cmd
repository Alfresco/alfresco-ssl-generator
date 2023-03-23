@ECHO OFF

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
SET KEYSTORE_PASS=keystore

SET VALIDITY_DURATION=1

REM Parse params from command line
:loop
IF NOT "%1"=="" (
  IF "%1"=="-keysize" (
    SHIFT
    SET KEY_SIZE=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-keystorepass" (
    SHIFT
    SET KEYSTORE_PASS=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-certdname" (
    SHIFT
    SET CA_DNAME=%~2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-servername" (
    SHIFT
    SET CA_SERVER_NAME=%~2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-validityduration" (
    SHIFT
    SET VALIDITY_DURATION=%~2
    SHIFT
    GOTO loop
  )
  ECHO "An invalid parameter was received: %1"
  EXIT /b
)

REM Folder where keystores, truststores and cerfiticates are generated
SET KEYSTORES_DIR=keystores
SET CERTIFICATES_DIR=certificates

REM If target folder for Keystores is not empty, skip generation
IF EXIST "%KEYSTORES_DIR%" (
  ECHO "Keystores folder is not empty, skipping generation process..."
  EXIT /b
)

CALL :readKeystorePassword

REM Remove previous working directories and certificates
IF EXIST "ca" (
  del /q ca\*
) ELSE (
  mkdir ca
)

IF NOT EXIST "%KEYSTORES_DIR%" (
  mkdir %KEYSTORES_DIR%
) ELSE (
  del /q %KEYSTORES_DIR%/*
)

IF NOT EXIST "%CERTIFICATES_DIR%" (
  mkdir %CERTIFICATES_DIR%
) ELSE (
  del /q %CERTIFICATES_DIR%/*
)

REM ------------
REM CA
REM ------------

mkdir ca\certs ca\crl ca\newcerts ca\private
TYPE nul > ca\index.txt
ECHO 1000 > ca\serial

openssl genrsa -aes256 -passout pass:%KEYSTORE_PASS% -out ca\private\ca.key.pem %KEY_SIZE%

CALL :subjectAlternativeNames %CA_SERVER_NAME%
openssl req -config openssl.cnf ^
      -key ca\private\ca.key.pem ^
      -new -x509 -days 7300 -sha256 -extensions v3_ca ^
      -out ca\certs\ca.cert.pem ^
      -subj "%CA_DNAME%" ^
      -passin pass:%KEYSTORE_PASS%
GOTO :eof

:readKeystorePassword
  SET PASSWORD=%KEYSTORE_PASS%
  CALL ./utils_password_prompt.cmd "Root CA"
  SET KEYSTORE_PASS=!PASSWORD!
GOTO :eof
