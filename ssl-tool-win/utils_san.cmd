@ECHO OFF

REM Subject Alternative Name provided through config file substitution
setlocal EnableDelayedExpansion
SET SERVICE_SERVER_NAME=%~1
ECHO SERVICE_SERVER_NAME %SERVICE_SERVER_NAME%
SET SED_HOSTNAMES=
IF DEFINED SERVICE_SERVER_NAME (
  REM Clear existing DNS.X lines in openssl.cnf file
  powershell -Command "(gc -Encoding utf8 openssl.cnf) | Where-Object {$_ -notmatch '^DNS\.'} | Set-Content openssl.cnf"
  ECHO Removed DNS. occurences from openssl.cnf
  REM Split given server names by "," separator
  REM Create a string that would place every hostname as a separate DNS.{counter} = {hostname} line
  SET COUNTER=0
  FOR %%a IN (%SERVICE_SERVER_NAME%) DO (
    SET /a COUNTER=COUNTER+1
    SET "SED_HOSTNAMES=!SED_HOSTNAMES!`nDNS.!COUNTER! = %%a"
  )

  REM Place that string in openssl.cnf file under [alt_names]
  powershell -Command "(gc -Encoding utf8 openssl.cnf) -replace '\[alt_names\]', \"[alt_names]!SED_HOSTNAMES!\" | Out-File -Encoding utf8 openssl.cnf"
  ECHO Added new occurences !SED_HOSTNAMES!
  REM Remove BOM
  powershell -Command "(gc -Encoding utf8 openssl.cnf) | Foreach-Object {$_ -replace '\xEF\xBB\xBF', ''} | Set-Content openssl.cnf"
)
endlocal
GOTO :eof