# Docker Templates for Community Edition

This project includes default configuration for ACS Enterprise 6.1 and Insight Engine 1.1 using Mutual TLS communication between Repository and SOLR

Every *truststores*, *keystores* and *certificates* are copied from sources.

## Components

* **.env** specifying releases of services

* **alfresco** includes a `Dockerfile` with *Tomcat Connector* configuration and *Keystore* folder mapping as it's required for Connector. Default stores and certificates from source code (`alfresco-repository`) have been copied in keystore folder.

* **docker-compose.yml** includes a Docker Composition for ACS 6.1 and Insight Engine 1.1 using Mutual TLS

* **solr6** includes a `Dockerfile` to set *https* communications and to provide a volume for the keystore. The keystore folder includes default certificates for SOLR server copied from source code (`alfresco-search`)

* **zeppelin** includes a `Dockerfile` to provide a volume for the keystore. The keystore folder includes default certificates for SOLR server copied from source code (`alfresco-search`)

```
├── .env
├── alfresco
│   ├── Dockerfile
│   └── keystore
│       ├── keystore
│       ├── keystore-passwords.properties
│       ├── ssl-keystore-passwords.properties
│       ├── ssl-truststore-passwords.properties
│       ├── ssl.keystore
│       └── ssl.truststore
├── docker-compose-ssl.yml
├── docker-compose.yml
├── solr6
│   ├── Dockerfile
│   └── keystore
│       ├── ssl-keystore-passwords.properties
│       ├── ssl-truststore-passwords.properties
│       ├── ssl.repo.client.keystore
│       └── ssl.repo.client.truststore
└── zeppelin
    ├── Dockerfile
    └── keystore
        ├── ssl.repo.client.keystore
        └── ssl.repo.client.truststore
```


## Running Docker Compose

Docker can be started selecting SSL Docker Compose file.

```bash
$ docker-compose up --build
```

Alfresco will be available at:

http://localhost:8080/alfresco

https://localhost:8443/alfresco

http://localhost:8080/share

https://localhost:8083/solr

http://localhost:9090/zeppelin

SSL Communication from SOLR and Zeppelin (JDBC Driver) is targeted inside Docker Network to https://alfresco:8443/alfresco

## Generation Tool for custom SSL Certificates

A simple Script has been included in `ssl-tool` folder in order to generate custom *truststores*, *keystores* and *certificates*.
