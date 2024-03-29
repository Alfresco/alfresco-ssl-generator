ARG ALFRESCO_TAG
FROM alfresco/alfresco-content-repository-community:${ALFRESCO_TAG}

ARG TRUSTSTORE_TYPE
ARG TRUSTSTORE_PASS
ARG KEYSTORE_TYPE
ARG KEYSTORE_PASS

ENV TRUSTSTORE_TYPE=$TRUSTSTORE_TYPE \
    TRUSTSTORE_PASS=$TRUSTSTORE_PASS \
    KEYSTORE_TYPE=$KEYSTORE_TYPE \
    KEYSTORE_PASS=$KEYSTORE_PASS

ARG TOMCAT_DIR=/usr/local/tomcat
ARG ALF_DATA_DIR=${TOMCAT_DIR}/alf_data

# Expose keystore folder
VOLUME ["${ALF_DATA_DIR}/keystore"]

# Default value in "repository.properties" is "dir.keystore=classpath:alfresco/keystore"
USER root
RUN echo -e "\n\
dir.keystore=${ALF_DATA_DIR}/keystore\n\
alfresco.encryption.ssl.keystore.type=${TRUSTSTORE_TYPE}\n\
alfresco.encryption.ssl.truststore.type=${KEYSTORE_TYPE}\n\
" >> ${TOMCAT_DIR}/shared/classes/alfresco-global.properties

### Enable SSL by adding the proper Connector to server.xml
RUN sed -i "s/\
    <\/Engine>/\n\
    <\/Engine>\n\
    <Connector port=\"8443\" protocol=\"org.apache.coyote.http11.Http11Protocol\"\n\
          SSLEnabled=\"true\" maxThreads=\"150\" scheme=\"https\"\n\
          keystoreFile=\"\/usr\/local\/tomcat\/alf_data\/keystore\/ssl.keystore\"\n\
          keystorePass=\"${KEYSTORE_PASS}\" keystoreType=\"${KEYSTORE_TYPE}\" secure=\"true\" connectionTimeout=\"240000\"\n\
          truststoreFile=\"\/usr\/local\/tomcat\/alf_data\/keystore\/ssl.truststore\"\n\
          truststorePass=\"${TRUSTSTORE_PASS}\" truststoreType=\"${TRUSTSTORE_TYPE}\" clientAuth=\"want\" sslProtocol=\"TLS\">\n\
      <\/Connector>/g" ${TOMCAT_DIR}/conf/server.xml
