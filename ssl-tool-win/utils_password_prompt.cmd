@ECHO OFF

REM Password reading functions
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
