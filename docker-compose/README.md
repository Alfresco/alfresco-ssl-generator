# Docker Compose samples for Alfresco SSL/TLS with custom certificates

Community and Enterprise Docker Compose templates are provided in order to describe the use of Alfresco Base SSL Image in this scenario.

## Environment variables

Shared environment variable values are included in `.env` file in the root folder.

```
$ cat .env

# SSL Env Variables
ALFRESCO_VERSION=community
KEY_SIZE=1024
KEYSTORE_TYPE=JCEKS
TRUSTSTORE_TYPE=JCEKS
KEYSTORE_PASS=keystore
TRUSTSTORE_PASS=truststore
```

These values are used in Docker Compose service description.

*Alfresco* service uses truststore and keystore type and password.

```
alfresco:
    build:
      context: ./alfresco
      args:
        TRUSTSTORE_TYPE: ${TRUSTSTORE_TYPE}
        TRUSTSTORE_PASS: ${TRUSTSTORE_PASS}
        KEYSTORE_TYPE: ${KEYSTORE_TYPE}
        KEYSTORE_PASS: ${KEYSTORE_PASS}
```

*SOLR* service uses truststore and keystore type and password. And also truststore and keystore files location.

```
solr6:
    build:
      context: ./solr6
      args:
        TRUSTSTORE_TYPE: ${TRUSTSTORE_TYPE}
        KEYSTORE_TYPE: ${KEYSTORE_TYPE}
    environment:
        SOLR_SSL_TRUST_STORE: "/opt/alfresco-search-services/keystore/ssl.repo.client.truststore"
        SOLR_SSL_TRUST_STORE_PASSWORD: "${TRUSTSTORE_PASS}"
        SOLR_SSL_TRUST_STORE_TYPE: "${TRUSTSTORE_TYPE}"
        SOLR_SSL_KEY_STORE: "/opt/alfresco-search-services/keystore/ssl.repo.client.keystore"
        SOLR_SSL_KEY_STORE_PASSWORD: "${KEYSTORE_PASS}"
        SOLR_SSL_KEY_STORE_TYPE: "${KEYSTORE_TYPE}"
        "
```

*Zeppelin* service uses truststore and keystore type and password. And also truststore and keystore files location.

```
zeppelin:
    build:
      context: ./zeppelin
      args:
        TRUSTSTORE_TYPE: ${TRUSTSTORE_TYPE}
        KEYSTORE_TYPE: ${KEYSTORE_TYPE}
    environment:
        JAVA_OPTS: "
            -Djavax.net.ssl.keyStore=/zeppelin/keystore/ssl.repo.client.keystore
            -Djavax.net.ssl.keyStorePassword=${KEYSTORE_PASS}
            -Djavax.net.ssl.keyStoreType=${KEYSTORE_TYPE}
            -Djavax.net.ssl.trustStore=/zeppelin/keystore/ssl.repo.client.truststore
            -Djavax.net.ssl.trustStorePassword=${TRUSTSTORE_PASS}
            -Djavax.net.ssl.trustStoreType=${TRUSTSTORE_TYPE}
        "
```

These values are also used by *Alfresco Base SSL* Container to produce keystores, truststores and certificates.

```
ssl:
    image: alfresco/ssl-base
    environment:
        ALFRESCO_VERSION: ${ALFRESCO_VERSION}
        KEY_SIZE: ${KEY_SIZE}
        TRUSTSTORE_TYPE: ${TRUSTSTORE_TYPE}
        TRUSTSTORE_PASS: ${TRUSTSTORE_PASS}
        KEYSTORE_TYPE: ${KEYSTORE_TYPE}
        KEYSTORE_PASS: ${KEYSTORE_PASS}
```

## Mounted volumes

*Alfresco Base SSL* service will produce `keystores` folder on a mounted volume, what allows to share every specific configuration with Alfresco, SOLR and Zeppelin services.

```
ssl:
    image: alfresco/ssl-base
    volumes:
        - ./keystores:/keystores

alfresco:
    build:
      context: ./alfresco
    volumes:
        - ./keystores/alfresco:/usr/local/tomcat/alf_data/keystore

solr6:
    build:
      context: ./solr6
    volumes:
        - ./keystores/solr:/opt/alfresco-insight-engine/keystore

zeppelin:
    build:
      context: ./zeppelin
    volumes:
        - ./keystores/zeppelin:/zeppelin/keystore

```

*Alfresco Base SSL* will produce `keystores` folder only when this folder is empty, so it can be used safely during re-starts. To generate new certificates, `keystores` folder can be removed and a new configuration will be created when starting Docker Compose again.


## Custom Dockerfiles

Several customisations have been added to default Alfresco Docker images to include specific settings from `keystores`.

**Alfresco Dockerfile**

Environment variable values are used in Alfresco Dockerfile to set SSL properties in `alfresco-global.properties` and Tomcat SSL Connector.

**SOLR Dockerfile**

Environment variable values are used in SOLR Dockerfile to set SSL properties in `solrcore.properties` from rerank template, what is used as template to generate `alfresco` and `archive` SOLR cores.

**Zeppelin Dockerfile**

Environment variable values are used in Zeppelin Dockerfile to set SSL properties in `interpreter.json`, what defines the communication with Alfresco Repository.
