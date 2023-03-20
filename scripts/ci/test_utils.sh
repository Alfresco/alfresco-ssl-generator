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
  result=$(sed -n "/^$2/p" <<< "$1")
}