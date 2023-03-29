#! /bin/bash

function checkIfRecordExists {
  result=$(sed -n "/^$2.*$3/p" <<< "$1")
}

function validateKeystore {
  content=$(keytool -list -keystore $1 -storepass $2)

  checkIfRecordExists "$content" "Keystore type:" "$3"
  if [ -z "$result" ]; then
    echo "Invalid/Missing Keystore type $3"
    exit 1
  fi

  checkIfRecordExists "$content" "$4" "PrivateKeyEntry"
  if [ -z "$result" ]; then
    echo "Invalid/Missing Keystore private key $4"
    exit 1
  fi

  if [ -n "${5-}" ]; then
    checkIfRecordExists "$content" "$5" "trustedCertEntry"
    if [ -z "$result" ]; then
      echo "Invalid/Missing Keystore certificate $5"
      exit 1
    fi
  fi
}

function validateTruststore {
  content=$(keytool -list -keystore $1 -storepass $2)

  checkIfRecordExists "$content" "Keystore type:" "$3"
  if [ -z "$result" ]; then
    echo "Invalid/Missing Truststore type $3"
    exit 1
  fi

  checkIfRecordExists "$content" "$4" "trustedCertEntry"
  if [ -z "$result" ]; then
    echo "Invalid/Missing Keystore certificate $4"
    exit 1
  fi
}

function validateEncryption {
  content=$(keytool -list -keystore $1 -storepass $2)

  checkIfRecordExists "$content" "Keystore type:" "$3"
  if [ -z "$result" ]; then
    echo "Invalid/Missing Keystore type $3"
    exit 1
  fi

  checkIfRecordExists "$content" "$4" "SecretKeyEntry"
  if [ -z "$result" ]; then
    echo "Invalid/Missing Keystore private key $4"
    exit 1
  fi
}

function validateCertificate {
  content=$(keytool -list -v -keystore $1 -storepass $2)
  result=$(sed -n "/^$3/p" <<< "$content")
  if [ -z "$result" ]; then
    echo "Invalid/Missing certificate $3"
    exit 1
  fi
}

function checkSingleSANExists {
  dns_line="  DNSName: $2"
  result=$(sed -n "/^$dns_line/p" <<< "$1")
  if [ -z "$result" ]; then
    echo "Expected SAN not found $2"
    exit 1
  fi
}

function checkSingleSANDoesntExist {
  dns_line="  DNSName: $2"
  result=$(sed -n "/^$dns_line/p" <<< "$1")
  if [ -n "$result" ]; then
    echo "Not expected SAN found $2"
    exit 1
  fi
}

function validateSubjectAlternativeNames {
  content=$(keytool -list -v -keystore $1 -storepass $2)

  checkSingleSANExists "$content" $3
  if [ -n "${4-}" ]; then
    checkSingleSANExists "$content" $4
  fi
  if [ -n "${5-}" ]; then
    checkSingleSANExists "$content" $5
  fi
}

function validateSubjectAlternativeNamesNotFound {
  content=$(keytool -list -v -keystore $1 -storepass $2)

  checkSingleSANDoesntExist "$content" $3
  if [ -n "${4-}" ]; then
    checkSingleSANDoesntExist "$content" $4
  fi
  if [ -n "${5-}" ]; then
    checkSingleSANDoesntExist "$content" $5
  fi
}