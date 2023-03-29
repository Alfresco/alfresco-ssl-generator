@ECHO OFF

REM This script is generating metadata encryption keystore

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

SET SERVICE_NAME=encryption
SET SUBFOLDER_NAME=

REM Using "current" format by default (only available from ACS 7.0+)
SET ALFRESCO_FORMAT=current

REM Encryption secret key passwords
SET KEYSTORE_PASS=password_placeholder
SET KEY_PASS=password_placeholder

REM Parse params from command line
:loop
IF NOT "%1"=="" (
  IF "%1"=="-clearhistory" (
    REM clearhistory is a helper parameter for not storing passwords in command line history
	SHIFT
	GOTO loop
  )
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
    SET KEYSTORE_PASS=%2
    SHIFT
    GOTO loop
  )
  IF "%1"=="-encmetadatapass" (
    SHIFT
    SET KEY_PASS=%2
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
  ECHO   -subfoldername
  ECHO   -servicename
  ECHO   -encstorepass
  ECHO   -encmetadatapass
  ECHO   -alfrescoformat
  EXIT /b
)

IF "%SUBFOLDER_NAME%"=="" (
  SET SUBFOLDER_NAME=%SERVICE_NAME%
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

SET DESTINATION_DIR=%KEYSTORES_DIR%\%SUBFOLDER_NAME%
IF NOT EXIST "%DESTINATION_DIR%" (
  mkdir %DESTINATION_DIR%
)

setlocal enabledelayedexpansion

CALL :readKeystorePassword
IF ERRORLEVEL 1 ( EXIT /b 1 )
CALL :readKeyPassword
IF ERRORLEVEL 1 ( EXIT /b 1 )

REM Generate Encryption Secret Key
keytool -genseckey -alias metadata -keypass !KEY_PASS! -storepass !KEYSTORE_PASS! -keystore %DESTINATION_DIR%\%SERVICE_NAME%.keystore ^
-storetype %ENC_STORE_TYPE% %ENC_KEY_ALG%

IF NOT "%ALFRESCO_FORMAT%" == "current" (
  REM Create Alfresco Encryption password file
  ECHO aliases=metadata>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
  ECHO keystore.password=!KEYSTORE_PASS!>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
  ECHO metadata.keyData=>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
  ECHO metadata.algorithm=DESede>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
  ECHO metadata.password=!KEY_PASS!>> %DESTINATION_DIR%\%SERVICE_NAME%-keystore-passwords.properties
)

endlocal
GOTO :eof


:readKeystorePassword
  SET PASSWORD=%KEYSTORE_PASS%
  CALL ./utils_password_prompt.cmd "Encryption Keystore"
  IF ERRORLEVEL 1 ( EXIT /b 1 )
  SET KEYSTORE_PASS=!PASSWORD!
GOTO :eof

:readKeyPassword
  SET PASSWORD=%KEY_PASS%
  CALL ./utils_password_prompt.cmd "Encryption Key"
  IF ERRORLEVEL 1 ( EXIT /b 1 )
  SET KEY_PASS=!PASSWORD!
GOTO :eof