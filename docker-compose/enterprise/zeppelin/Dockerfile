ARG ZEPPELIN_TAG
FROM quay.io/alfresco/insight-zeppelin:${ZEPPELIN_TAG}

ARG TRUSTSTORE_TYPE
ARG TRUSTSTORE_PASS
ARG KEYSTORE_TYPE
ARG KEYSTORE_PASS

ENV TRUSTSTORE_TYPE=$TRUSTSTORE_TYPE \
    TRUSTSTORE_PASS=$TRUSTSTORE_PASS \
    KEYSTORE_TYPE=$KEYSTORE_TYPE \
    KEYSTORE_PASS=$KEYSTORE_PASS

RUN mkdir ${ZEPPELIN_HOME}/keystore \
 && chown -R zeppelin:zeppelin ${ZEPPELIN_HOME}/keystore

### Add SSL Configuration to Zeppelin Interpreter
RUN sed -i '/"zeppelin.jdbc.principal":/i \
       "alfresco.enable.ssl": { \n\
         "value": "true", \n\
         "type": "string" \n\
       },\n\
       "solr.ssl.checkPeerName": {\n\
         "value": "false",\n\
         "type": "string"\n\
       },\n\
       "javax.net.ssl.keyStore": {\n\
         "value": "/zeppelin/keystore/ssl.repo.client.keystore",\n\
         "type": "string"\n\
       },\n\
       "javax.net.ssl.keyStorePassword": {\n\
         "value": "${KEYSTORE_PASS}",\n\
         "type": "string"\n\
       },\n\
       "javax.net.ssl.keyStoreType": {\n\
         "value": "${KEYSTORE_TYPE}",\n\
         "type": "string"\n\
       },\n\
       "javax.net.ssl.trustStore": {\n\
         "value": "/zeppelin/keystore/ssl.repo.client.truststore",\n\
         "type": "string"\n\
       },\n\
       "javax.net.ssl.trustStorePassword": {\n\
         "value": "${TRUSTSTORE_PASS}",\n\
         "type": "string"\n\
       },\n\
       "javax.net.ssl.trustStoreType": {\n\
         "value": "${TRUSTSTORE_TYPE}",\n\
         "type": "string"\n\
       \n},\
' ${ZEPPELIN_HOME}/conf/interpreter.json
