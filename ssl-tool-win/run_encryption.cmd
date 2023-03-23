@ECHO OFF

SET KEYSTORES_DIR=keystores

REM ----------
REM PARAMETERS
REM ----------

SET SERVICE_NAME=encryption
SET SUBFOLDER_NAME=%SERVICE_NAME%

REM Using "current" format by default (only available from ACS 7.0+)
SET ALFRESCO_FORMAT=current

REM Encryption secret key passwords
SET ENC_STORE_PASS=password_placeholder
SET ENC_METADATA_PASS=password_placeholder

REM Parse params from command line
:loop
IF NOT "%1"=="" (
  IF "%1"=="-subfoldername" (
    SHIFT
    SET SUBFOLDER_NAME=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-servicename" (
    SHIFT
    SET SERVICE_NAME=%2
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
  IF "%1"=="-alfrescoformat" (
    SHIFT
    SET ALFRESCO_FORMAT=%~2
    SHIFT
    GOTO loop
  )
  ECHO "An invalid parameter was received: %1"
  EXIT /b
)

REM Encryption keystore format: PKCS12 (default for "current"), JCEKS (default for "classic")
IF "%ALFRESCO_FORMAT%" == "current" (
  SET ENC_STORE_TYPE=PKCS12
) ELSE (
  SET ENC_STORE_TYPE=JCEKS
)

REM Key algorithm: AES (default for "current"), DESede (default for "classic")
IF "%ALFRESCO_FORMAT%" == "current" (
  SET ENC_KEY_ALG=-keyalg AES -keysize 256
) ELSE (
  SET ENC_KEY_ALG=-keyalg DESede
)

SET DESTINATION_DIR=%KEYSTORES_DIR%/%SUBFOLDER_NAME%
IF NOT EXIST "%DESTINATION_DIR%" (
  mkdir %KEYSTORES_DIR%
)

setlocal EnableDelayedExpansion
CALL :readEncStorePassword
CALL :readEncKeyPassword

REM Generate Encryption Secret Key
keytool -genseckey -alias metadata -keypass !ENC_METADATA_PASS! -storepass !ENC_STORE_PASS! -keystore %DESTINATION_DIR%\%SERVICE_NAME%.keystore ^
-storetype %ENC_STORE_TYPE% %ENC_KEY_ALG%

IF "%ALFRESCO_FORMAT%" != "current" (
  REM Create Alfresco Encryption password file
  ECHO aliases=metadata>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
  ECHO keystore.password=!ENC_STORE_PASS!>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
  ECHO metadata.keyData=>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
  ECHO metadata.algorithm=DESede>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
  ECHO metadata.password=!ENC_METADATA_PASS!>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
)
endlocal
GOTO :eof

:readEncStorePassword
  SET PASSWORD=%ENC_STORE_PASS%
  CALL ./utils_password_prompt.cmd "Encryption Keystore"
  SET ENC_STORE_PASS=!PASSWORD!
GOTO :eof

:readEncKeyPassword
  SET PASSWORD=%ENC_STORE_PASS%
  CALL ./utils_password_prompt.cmd "Encryption Key"
  SET ENC_STORE_PASS=!PASSWORD!
GOTO :eof