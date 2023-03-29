SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# DIRECTORIES
CA_DIR=ca
KEYSTORES_DIR=keystores
CERTIFICATES_DIR=certificates

# PASSWORD RELATED
PASSWORD_PLACEHOLDER="password_placeholder"

function verifyPasswordConditions {
  CHECK_FAILED=false

  PASSWORD_LENGTH=${#PASSWORD}
  if [ $PASSWORD_LENGTH -lt 6 ] || [ $PASSWORD_LENGTH -gt 1023 ]
  then
    printf "\nPassword must have at least 6 characters and no more than 1023\n"
    CHECK_FAILED=true
  fi
}

function readPassword {
  read -s -r -p "Please enter password for $1 (leading and trailing spaces will be removed): " PASSWORD

  verifyPasswordConditions
  if $CHECK_FAILED; then
    PASSWORD=$PASSWORD_PLACEHOLDER
    return
  fi

  read -s -r -p $'\nPlease repeat pass phrase : ' PASSWORD_CHECK

  if [ "$PASSWORD" != "$PASSWORD_CHECK" ]
  then
    echo
    echo "Password verification failed"
    PASSWORD=$PASSWORD_PLACEHOLDER
    return
  fi
}

function askForPasswordIfNeeded {
  if [ "$PASSWORD" != "$PASSWORD_PLACEHOLDER" ]; then
    verifyPasswordConditions
    if $CHECK_FAILED; then
      exit 1
    fi
  fi

  while [ "$PASSWORD" == "$PASSWORD_PLACEHOLDER" ]
  do
    readPassword "$1"
  done

  echo
}

# SUBJECT ALTERNATIVE NAME
function subjectAlternativeNames {
  #Subject Alternative Name provided through config file substitution
  if [ -n "$1" ]; then
    #Clear existing DNS.X lines in openssl.cnf file
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' '/^DNS./d' $SCRIPT_DIR/openssl.cnf
    else
      sed -i '/^DNS./d' $SCRIPT_DIR/openssl.cnf
    fi

    SED_HOSTNAMES=
    COUNTER=0
    #Split given server names by "," separator
    #Create a string that would place every hostname as a separate DNS.{counter} = {hostname} line
    IFS=',' read -ra HOSTNAMES <<< "$1"
    for HOSTNAME in "${HOSTNAMES[@]}"; do
      COUNTER=$((COUNTER + 1))
      SED_HOSTNAMES="$SED_HOSTNAMES\\
DNS.$COUNTER = $HOSTNAME"
    done

    #Place that string in openssl.cnf file under [alt_names]
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "/\[alt_names\]/ {a${SED_HOSTNAMES}
}" $SCRIPT_DIR/openssl.cnf
    else
      sed -i "/\[alt_names\]/ {a${SED_HOSTNAMES}
}" $SCRIPT_DIR/openssl.cnf
    fi
  fi
}