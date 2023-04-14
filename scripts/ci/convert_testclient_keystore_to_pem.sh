#! /bin/bash

CI_WORKSPACE=$1

#Convert keystore and truststore format to PEM (only PEM is accepted by curl)
TEST_CLIENT_PATH="${CI_WORKSPACE}/keystores/testClient"
TEST_CLIENT_CURL_KEYSTORE="testClient_keystore"
TEST_CLIENT_CURL_TRUSTSTORE="testClient_truststore"

keytool -noprompt -importkeystore -srckeystore ${TEST_CLIENT_PATH}/testClient.keystore -destkeystore ${TEST_CLIENT_PATH}/${TEST_CLIENT_CURL_KEYSTORE}.p12 -srcstoretype JCEKS -deststoretype PKCS12 -deststorepass password -srcstorepass password
openssl pkcs12 -in ${TEST_CLIENT_PATH}/${TEST_CLIENT_CURL_KEYSTORE}.p12 -nokeys -out ${TEST_CLIENT_PATH}/client-cert.pem -password pass:password
openssl pkcs12 -in ${TEST_CLIENT_PATH}/${TEST_CLIENT_CURL_KEYSTORE}.p12 -password pass:password -nocerts -out ${TEST_CLIENT_PATH}/client-key.pem -passout pass:password

keytool -noprompt -importkeystore -srckeystore ${TEST_CLIENT_PATH}/testClient.truststore -destkeystore ${TEST_CLIENT_PATH}/${TEST_CLIENT_CURL_TRUSTSTORE}.p12 -srcstoretype JCEKS -deststoretype PKCS12 -deststorepass password -srcstorepass password
openssl pkcs12 -in ${TEST_CLIENT_PATH}/${TEST_CLIENT_CURL_TRUSTSTORE}.p12 -out ${TEST_CLIENT_PATH}/${TEST_CLIENT_CURL_TRUSTSTORE}.pem -password pass:password -passout pass:password