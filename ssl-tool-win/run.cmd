@ECHO OFF

REM This script generates certificates for Repository and SOLR TLS/SSL Mutual Auth Communication:
REM
REM * CA Entity to issue all required certificates (alias alfresco.ca)
REM * Server Certificate for Alfresco (alias ssl.repo)
REM * Server Certificate for SOLR (alias ssl.repo.client)
REM
REM "openssl.cnf" file is provided for CA Configuration.
REM
REM Once this script has been executed successfully, following resources are generated in ${KEYSTORES_DIR} folder:
REM
REM .
REM ├── alfresco
REM │   ├── keystore
REM │   ├── keystore-passwords.properties
REM │   ├── ssl-keystore-passwords.properties
REM │   ├── ssl-truststore-passwords.properties
REM │   ├── ssl.keystore
REM │   └── ssl.truststore
REM ├── client
REM │   └── browser.p12
REM ├── solr
REM │   ├── ssl-keystore-passwords.properties
REM │   ├── ssl-truststore-passwords.properties
REM │   ├── ssl.repo.client.keystore
REM │   └── ssl.repo.client.truststore
REM └── zeppelin
REM     ├── ssl.repo.client.keystore
REM     └── ssl.repo.client.truststore
REM
REM "alfresco" files must be copied to "alfresco/keystore" folder
REM "solr" files must be copied to "solr6/keystore"
REM "zeppelin" files must be copied to "zeppelin/keystore"
REM "client" files can be used from a browser to access the server using HTTPS in port 8443

REM ----------
REM PARAMETERS
REM ----------

REM Version of Alfresco: enterprise, community
SET ALFRESCO_VERSION=enterprise

REM Distinguished name of the CA
SET CA_DNAME=/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA
REM Distinguished name of the Server Certificate for Alfresco
SET REPO_CERT_DNAME=/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository
REM Distinguished name of the Server Certificate for SOLR
SET SOLR_CLIENT_CERT_DNAME=/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository Client

REM RSA key length (1024, 2048, 4096)
SET KEY_SIZE=1024

REM Keystore format (PKCS12, JKS, JCEKS)
SET KEYSTORE_TYPE=JCEKS
REM Truststore format (JKS, JCEKS)
SET TRUSTSTORE_TYPE=JCEKS
REM Encryption keystore format (JCEKS)
SET ENC_STORE_TYPE=JCEKS

REM Default password for every keystore and private key
SET KEYSTORE_PASS=keystore
REM Default password for every truststore
SET TRUSTSTORE_PASS=truststore

REM Encryption secret key passwords
SET ENC_STORE_PASS=password
SET ENC_METADATA_PASS=password

REM Parse params from command line
:loop
IF NOT "%1"=="" (
  IF "%1"=="-alfrescoversion" (
    SHIFT
    SET ALFRESCO_VERSION=%2
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
  IF "%1"=="-truststoretype" (
    SHIFT
    SET TRUSTSTORE_TYPE=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-keystorepass" (
    SHIFT
    SET KEYSTORE_PASS=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-truststorepass" (
    SHIFT
    SET TRUSTSTORE_PASS=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-encstorepass" (
    SHIFT
    SET ENC_STORE_PASS=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-encmetadatapass" (
    SHIFT
    SET ENC_METADATA_PASS=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-cacertdname" (
    SHIFT
    SET CA_DNAME=%~2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-repocertdname" (
    SHIFT
    SET REPO_CERT_DNAME=%~2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-solrcertdname" (
    SHIFT
    SET SOLR_CLIENT_CERT_DNAME=%~2
    SHIFT
    GOTO loop
  )
  ECHO "An invalid parameter was received: %1"
  EXIT /b
)

REM Folder where keystores, truststores and cerfiticates are generated
SET KEYSTORES_DIR=keystores
SET ALFRESCO_KEYSTORES_DIR=keystores\alfresco
SET SOLR_KEYSTORES_DIR=keystores\solr
SET ZEPPELIN_KEYSTORES_DIR=keystores\zeppelin
SET CLIENT_KEYSTORES_DIR=keystores\client
SET CERTIFICATES_DIR=certificates

REM If target folder for Keystores is not empty, skip generation
IF EXIST "%KEYSTORES_DIR%" (
  ECHO "Keystores folder is not empty, skipping generation process..."
  EXIT /b
)

REM Remove previous working directories and certificates
IF EXIST "ca" (
    del /q ca\*
)

IF NOT EXIST "%KEYSTORES_DIR%" (
  mkdir %KEYSTORES_DIR%
) ELSE (
  del /q %KEYSTORES_DIR%/*
)

REM Create folders for truststores, keystores and certificates
IF NOT EXIST "%ALFRESCO_KEYSTORES_DIR%" (
  mkdir %ALFRESCO_KEYSTORES_DIR%
) ELSE (
  del /q %ALFRESCO_KEYSTORES_DIR%/*
)

IF NOT EXIST "%SOLR_KEYSTORES_DIR%" (
  mkdir %SOLR_KEYSTORES_DIR%
) ELSE (
  del /q %SOLR_KEYSTORES_DIR%/*
)

IF "%ALFRESCO_VERSION%" == "enterprise" (
  IF NOT EXIST "%ZEPPELIN_KEYSTORES_DIR%" (
    mkdir %ZEPPELIN_KEYSTORES_DIR%
  ) ELSE (
    del /q %ZEPPELIN_KEYSTORES_DIR%/*
  )
)

IF NOT EXIST "%CLIENT_KEYSTORES_DIR%" (
  mkdir %CLIENT_KEYSTORES_DIR%
) ELSE (
  del /q %CLIENT_KEYSTORES_DIR%/*
)

IF NOT EXIST "%CERTIFICATES_DIR%" (
  mkdir %CERTIFICATES_DIR%
) ELSE (
  del /q %CERTIFICATES_DIR%/*
)

REM ------------
REM CA
REM ------------

REM Generate a new CA Entity
IF NOT EXIST "ca" (
    mkdir ca
)

mkdir ca\certs ca\crl ca\newcerts ca\private
TYPE nul > ca\index.txt
ECHO 1000 > ca\serial

openssl genrsa -aes256 -passout pass:%KEYSTORE_PASS% -out ca\private\ca.key.pem %KEY_SIZE%

openssl req -config openssl.cnf ^
      -key ca\private\ca.key.pem ^
      -new -x509 -days 7300 -sha256 -extensions v3_ca ^
      -out ca\certs\ca.cert.pem ^
      -subj "%CA_DNAME%" ^
      -passin pass:%KEYSTORE_PASS%

REM Generate Server Certificate for Alfresco (issued by just generated CA)
openssl req -newkey rsa:%KEY_SIZE% -nodes -out %CERTIFICATES_DIR%\repository.csr ^
-keyout %CERTIFICATES_DIR%\repository.key -subj "%REPO_CERT_DNAME%"

openssl ca -config openssl.cnf -extensions server_cert -passin pass:%KEYSTORE_PASS% -batch -notext ^
-in %CERTIFICATES_DIR%\repository.csr -out %CERTIFICATES_DIR%\repository.cer

openssl pkcs12 -export -out %CERTIFICATES_DIR%/repository.p12 -inkey %CERTIFICATES_DIR%\repository.key ^
-in %CERTIFICATES_DIR%\repository.cer -password pass:%KEYSTORE_PASS% -certfile ca\certs\ca.cert.pem

REM Server Certificate for SOLR (issued by just generated CA)
openssl req -newkey rsa:%KEY_SIZE% -nodes -out %CERTIFICATES_DIR%\solr.csr ^
-keyout %CERTIFICATES_DIR%\solr.key -subj "%SOLR_CLIENT_CERT_DNAME%"

openssl ca -config openssl.cnf -extensions server_cert -passin pass:%KEYSTORE_PASS% -batch -notext ^
-in %CERTIFICATES_DIR%\solr.csr -out %CERTIFICATES_DIR%\solr.cer

openssl pkcs12 -export -out %CERTIFICATES_DIR%\solr.p12 -inkey %CERTIFICATES_DIR%\solr.key ^
-in %CERTIFICATES_DIR%\solr.cer -password pass:%KEYSTORE_PASS% -certfile ca\certs\ca.cert.pem


REM ------------
REM SOLR
REM ------------

REM Include CA and Alfresco certificates in SOLR Truststore
keytool -import -trustcacerts -noprompt -alias ssl.alfresco.ca -file ca\certs\ca.cert.pem ^
-keystore %SOLR_KEYSTORES_DIR%\ssl.repo.client.truststore -storetype %TRUSTSTORE_TYPE% -storepass %TRUSTSTORE_PASS%

keytool -importcert -noprompt -alias ssl.repo -file %CERTIFICATES_DIR%\repository.cer ^
-keystore %SOLR_KEYSTORES_DIR%\ssl.repo.client.truststore -storetype %TRUSTSTORE_TYPE% -storepass %TRUSTSTORE_PASS%

keytool -importcert -noprompt -alias ssl.repo.client -file %CERTIFICATES_DIR%\solr.cer ^
-keystore %SOLR_KEYSTORES_DIR%\ssl.repo.client.truststore -storetype %TRUSTSTORE_TYPE% -storepass %TRUSTSTORE_PASS%

REM Create SOLR TrustStore password file
ECHO aliases=alfresco.ca,ssl.repo,ssl.repo.client>> %SOLR_KEYSTORES_DIR%\ssl-truststore-passwords.properties
ECHO keystore.password=%TRUSTSTORE_PASS%>> %SOLR_KEYSTORES_DIR%\ssl-truststore-passwords.properties
ECHO alfresco.ca.password=%TRUSTSTORE_PASS%>> %SOLR_KEYSTORES_DIR%\ssl-truststore-passwords.properties
ECHO ssl.repo.password=%TRUSTSTORE_PASS%>> %SOLR_KEYSTORES_DIR%\ssl-truststore-passwords.properties
ECHO ssl.repo.client.password=%TRUSTSTORE_PASS%>> %SOLR_KEYSTORES_DIR%\ssl-truststore-passwords.properties

REM Include SOLR Certificate in SOLR Keystore
keytool -importkeystore ^
-srckeystore %CERTIFICATES_DIR%\solr.p12 -destkeystore %SOLR_KEYSTORES_DIR%\ssl.repo.client.keystore ^
-srcstoretype PKCS12 -deststoretype %KEYSTORE_TYPE% ^
-srcstorepass %KEYSTORE_PASS% -deststorepass %KEYSTORE_PASS% ^
-srcalias 1 -destalias ssl.repo.client ^
-srckeypass %KEYSTORE_PASS% -destkeypass %KEYSTORE_PASS% ^
-noprompt

keytool -importcert -noprompt -alias alfresco.ca -file ca\certs\ca.cert.pem ^
-keystore %SOLR_KEYSTORES_DIR%\ssl.repo.client.keystore -storetype %KEYSTORE_TYPE% -storepass %KEYSTORE_PASS%

REM Create SOLR Keystore password file
ECHO aliases=ssl.alfresco.ca,ssl.repo.client>> %SOLR_KEYSTORES_DIR%\ssl-keystore-passwords.properties
ECHO keystore.password=%KEYSTORE_PASS%>> %SOLR_KEYSTORES_DIR%\ssl-keystore-passwords.properties
ECHO ssl.repo.client.password=%KEYSTORE_PASS%>> %SOLR_KEYSTORES_DIR%\ssl-keystore-passwords.properties
ECHO ssl.alfresco.ca.password=%KEYSTORE_PASS%>> %SOLR_KEYSTORES_DIR%\ssl-keystore-passwords.properties


REM --------------------
REM ZEPPELIN (SOLR JDBC)
REM --------------------

REM Copy ZEPPELIN stores
IF "%ALFRESCO_VERSION%" == "enterprise" (
  copy %SOLR_KEYSTORES_DIR%\ssl.repo.client.keystore %ZEPPELIN_KEYSTORES_DIR%\ssl.repo.client.keystore
  copy %SOLR_KEYSTORES_DIR%\ssl.repo.client.truststore %ZEPPELIN_KEYSTORES_DIR%\ssl.repo.client.truststore
)


REM --------------------
REM ALFRESCO
REM --------------------

REM Include CA and SOLR certificates in Alfresco Truststore
keytool -import -trustcacerts -noprompt -alias alfresco.ca -file ca\certs\ca.cert.pem ^
-keystore %ALFRESCO_KEYSTORES_DIR%\ssl.truststore -storetype %TRUSTSTORE_TYPE% -storepass %TRUSTSTORE_PASS%

keytool -importcert -noprompt -alias ssl.repo.client -file %CERTIFICATES_DIR%\solr.cer ^
-keystore %ALFRESCO_KEYSTORES_DIR%\ssl.truststore -storetype %TRUSTSTORE_TYPE% -storepass %TRUSTSTORE_PASS%

REM Create Alfresco TrustStore password file
ECHO aliases=alfresco.ca,ssl.repo.client>> %ALFRESCO_KEYSTORES_DIR%\ssl-truststore-passwords.properties
ECHO keystore.password=%TRUSTSTORE_PASS%>> %ALFRESCO_KEYSTORES_DIR%\ssl-truststore-passwords.properties
ECHO alfresco.ca.password=%TRUSTSTORE_PASS%>> %ALFRESCO_KEYSTORES_DIR%\ssl-truststore-passwords.properties
ECHO ssl.repo.client=%TRUSTSTORE_PASS%>> %ALFRESCO_KEYSTORES_DIR%\ssl-truststore-passwords.properties

REM Include Alfresco Certificate in Alfresco Keystore
keytool -importkeystore ^
-srckeystore %CERTIFICATES_DIR%\repository.p12 -destkeystore %ALFRESCO_KEYSTORES_DIR%\ssl.keystore ^
-srcstoretype PKCS12 -deststoretype %KEYSTORE_TYPE% ^
-srcstorepass %KEYSTORE_PASS% -deststorepass %KEYSTORE_PASS% ^
-srcalias 1 -destalias ssl.repo ^
-srckeypass %KEYSTORE_PASS% -destkeypass %KEYSTORE_PASS% ^
-noprompt

keytool -importcert -noprompt -alias ssl.alfresco.ca -file ca\certs\ca.cert.pem ^
-keystore %ALFRESCO_KEYSTORES_DIR%\ssl.keystore -storetype %KEYSTORE_TYPE% -storepass %KEYSTORE_PASS%

REM Create Alfresco Keystore password file
ECHO aliases=ssl.alfresco.ca,ssl.repo>> %ALFRESCO_KEYSTORES_DIR%\ssl-keystore-passwords.properties
ECHO keystore.password=%KEYSTORE_PASS%>> %ALFRESCO_KEYSTORES_DIR%\ssl-keystore-passwords.properties
ECHO ssl.repo.password=%KEYSTORE_PASS%>> %ALFRESCO_KEYSTORES_DIR%\ssl-keystore-passwords.properties
ECHO ssl.alfresco.ca.password=%KEYSTORE_PASS%>> %ALFRESCO_KEYSTORES_DIR%\ssl-keystore-passwords.properties

REM Generate Encryption Secret Key
keytool -genseckey -alias metadata -keypass %ENC_METADATA_PASS% -storepass %ENC_STORE_PASS% -keystore %ALFRESCO_KEYSTORES_DIR%\keystore ^
-storetype %ENC_STORE_TYPE% -keyalg DESede

REM Create Alfresco Encryption password file
ECHO aliases=metadata>> %ALFRESCO_KEYSTORES_DIR%\keystore-passwords.properties
ECHO keystore.password=%ENC_STORE_PASS%>> %ALFRESCO_KEYSTORES_DIR%\keystore-passwords.properties
ECHO metadata.keyData=>> %ALFRESCO_KEYSTORES_DIR%\keystore-passwords.properties
ECHO metadata.algorithm=DESede>> %ALFRESCO_KEYSTORES_DIR%\keystore-passwords.properties
ECHO metadata.password=%ENC_METADATA_PASS%>> %ALFRESCO_KEYSTORES_DIR%\keystore-passwords.properties


REM --------------------
REM CLIENT
REM --------------------

REM Create client (browser) certificate
keytool -importkeystore -srckeystore %ALFRESCO_KEYSTORES_DIR%\ssl.keystore ^
-srcstorepass %KEYSTORE_PASS% -srcstoretype %KEYSTORE_TYPE% -srcalias ssl.repo ^
-srckeypass %KEYSTORE_PASS% -destkeystore %CLIENT_KEYSTORES_DIR%\browser.p12 ^
-deststoretype pkcs12 -deststorepass %KEYSTORE_PASS% ^
-destalias ssl.repo -destkeypass %KEYSTORE_PASS%
