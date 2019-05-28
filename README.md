# Welcome to Alfresco Docker Base SSL

## Introduction

This repository contains the `Dockerfile` used to create the keystores, truststores and certificates required to configure SSL/TLS Mutual Authentication between different services of the Alfresco Digital Business Platform: Repository, SOLR and Zeppelin.

HTTPs invocations happen between different Alfresco services, so keystores and truststores are built in order to satisfy following relationships:

* Repository is client of SOLR
* SOLR is client of Repository and SOLR
* Zeppelin is client of Alfresco


## How to Build

This image depends on the [alfresco-docker-base-java](https://github.com/Alfresco/alfresco-docker-base-java) image, which is also available (privately) on [Quay](https://quay.io/repository/alfresco/alfresco-base-java) and (publicly) on [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-base-java/).

To build this image, run the following script:

```bash
docker build -t alfresco/alfresco-base-ssl .
```

## Usage

Certificates generation script `run.sh` is based in `OpenSSL` and Java `keytool` programs, and it can be used in different scenarios:

* *Docker Standalone*, as a local container generating `keystores` folder from environment variable values. Available from Linux, Windows and Mac OS X.
* *Bash Shell Script Standalone*, as a local bash script from Linux operative systems.
* *Windows Batch Script Standalone*, as a local bash script from Windows operative systems.
* *Docker Compose*, as a Docker service creating `keystores` folder from environment variable values. Available from Linux, Windows and Mac OS X.


### Docker Standalone

The image can be used via `docker run` to create stores and certificates, using a host mounted folder to obtain these results.

**Volumes**

Following folders are available to be mounted on volumes:

* `/keystores` folder contains the keystores and truststores generated for `alfresco`, `solr` and `zeppelin` services
* `/ca` folder contains internal information (CRL, CA key...) used by the CA created with OpenSSL
* `/certificates` folder contains raw certificates used to build the keystores and the truststores

To obtain the required folder for Alfresco services, it's only required to mount `keystores` folder. CA and certificates folder can be also mounted, but those files are not used for Alfresco configuration.

```bash
$ docker run -v $PWD/keystores:/keystores alfresco/alfresco-base-ssl

$ tree keystores
keystores
├── alfresco
│   ├── keystore
│   ├── keystore-passwords.properties
│   ├── ssl-keystore-passwords.properties
│   ├── ssl-truststore-passwords.properties
│   ├── ssl.keystore
│   └── ssl.truststore
├── client
│   └── browser.p12
├── solr
│   ├── ssl-keystore-passwords.properties
│   ├── ssl-truststore-passwords.properties
│   ├── ssl.repo.client.keystore
│   └── ssl.repo.client.truststore
└── zeppelin
    ├── ssl.repo.client.keystore
    └── ssl.repo.client.truststore
```    

**Parameters**

Docker Container can be started using some of the following parameters:

* ALFRESCO_VERSION to set the type of Alfresco Version: `enterprise` or `community`
* KEY_SIZE to specify the RSA key length: `1024`, `2048`, `4096`...
* KEYSTORE_TYPE to set the type of the keystores (containing private keys): `PKCS12`, `JKS`, `JCEKS`
* TRUSTSTORE_TYPE to set the type of the truststores (containing public keys): `JKS`, `JCEKS`
* KEYSTORE_PASS to specify the password for the keystores
* TRUSTSTORE_PASS to specify the password for the truststores
* ENC_STORE_PASS to specify the password for the *encryption* keystore
* ENC_METADATA_PASS to specify the password for the *encryption* metadata
* CA_CERT_DNAME to set the Distinguished Name of the CA certificate, starting with slash, like "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA"
* REPO_CERT_DNAME to set the Distinguished Name of the Repository certificate, starting with slash, like "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository" \
* SOLR_CERT_DNAME to set the Distinguished Name of the SOLR certificate, starting with slash, like "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository Client"

For instance, the following command will produce `keystores` folder in a host folder named `keystores` using RSA key length of 2048 bits for Alfresco Enterprise.

```bash
$ docker run -v $PWD/keystores:/keystores -e KEY_SIZE=2048 -e ALFRESCO_VERSION=enterprise alfresco/alfresco-base-ssl
```

Note that when `keystores` folder is not empty, the program exists without producing any keystore or truststore.


### Bash Shell Script Standalone

When working on a *Linux* machine, shell script `ssl-tool/run.sh` can be used directly from command line. It's required to have `OpenSSL` and `keytool` programs available in the environment.

The parameters described above, can be used also from command line, but using following keywords:

*  `-alfrescoversion` with the same values of ALFRESCO_VERSION
*  `-keysize` with the same values of KEY_SIZE
*  `-keystoretype` with the same values of KEYSTORE_TYPE
*  `-keystorepass` with the same values of KEYSTORE_PASS
*  `-truststoretype` with the same values of TRUSTSTORE_TYPE
*  `-truststorepass` with the same values of TRUSTSTORE_PASS
*  `-encstorepass` with the same values of ENC_STORE_PASS
*  `-encmetadatapass` with the same values of ENC_METADATA_PASS
*  `-cacertdname` with the same values of CA_CERT_DNAME
*  `-repocertdname` with the same values of REPO_CERT_DNAME
*  `-solrcertdname` with the same values of SOLR_CERT_DNAME

For instance, the following command will produce `keystores` folder in a host folder named `keystores` using RSA key length of 2048 bits for Alfresco Enterprise.

```bash
$ cd ssl-tool

$ ./run.sh -keysize 2048 -alfrescoversion enterprise

$ tree keystores/
keystores/
├── alfresco
│   ├── keystore
│   ├── keystore-passwords.properties
│   ├── ssl-keystore-passwords.properties
│   ├── ssl-truststore-passwords.properties
│   ├── ssl.keystore
│   └── ssl.truststore
├── client
│   └── browser.p12
├── solr
│   ├── ssl-keystore-passwords.properties
│   ├── ssl-truststore-passwords.properties
│   ├── ssl.repo.client.keystore
│   └── ssl.repo.client.truststore
└── zeppelin
    ├── ssl.repo.client.keystore
    └── ssl.repo.client.truststore
```

When using custom *DNames* for certificates, values must be set in quotes.

```bash
$ ./run.sh -cacertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Windows Alfresco CA" \
-repocertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Repo" \
-solrcertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Solr"
```

Note that when `keystores` folder is not empty, the program exists without producing any keystore or truststore.


### Windows Batch Script Standalone

When working on a *Windows* machine, shell script `ssl-tool-win/run.cmd` can be used directly from command line. It's required to have `OpenSSL` and `keytool` programs available in the *PATH*.

The parameters described above, can be used also from command line, but using following keywords:

*  `-alfrescoversion` with the same values of ALFRESCO_VERSION
*  `-keysize` with the same values of KEY_SIZE
*  `-keystoretype` with the same values of KEYSTORE_TYPE
*  `-keystorepass` with the same values of KEYSTORE_PASS
*  `-truststoretype` with the same values of TRUSTSTORE_TYPE
*  `-truststorepass` with the same values of TRUSTSTORE_PASS
*  `-encstorepass` with the same values of ENC_STORE_PASS
*  `-encmetadatapass` with the same values of ENC_METADATA_PASS
*  `-cacertdname` with the same values of CA_CERT_DNAME
*  `-repocertdname` with the same values of REPO_CERT_DNAME
*  `-solrcertdname` with the same values of SOLR_CERT_DNAME

For instance, the following command will produce `keystores` folder in a host folder named `keystores` using RSA key length of 2048 bits for Alfresco Enterprise.

```bash
C:\> cd ssl-tool-win

C:\> run.cmd -keysize 2048 -alfrescoversion enterprise

C:\> tree /F keystores
├───alfresco
│       keystore
│       keystore-passwords.properties
│       ssl-keystore-passwords.properties
│       ssl-truststore-passwords.properties
│       ssl.keystore
│       ssl.truststore
│
├───client
│       browser.p12
│
└───solr
        ssl-keystore-passwords.properties
        ssl-truststore-passwords.properties
        ssl.repo.client.keystore
        ssl.repo.client.truststore
```

When using custom *DNames* for certificates, values must be set in quotes.

```bash
C:\> run.cmd -cacertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Windows Alfresco CA" ^
-repocertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Repo" ^
-solrcertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Solr"
```

Note that when `keystores` folder is not empty, the program exists without producing any keystore or truststore.


### Docker Compose

This Docker Image can be used as a Docker Compose service, accepting the same parameters for environment variables described before.

For instance, the following command will produce `keystores` folder in a host folder named `keystores` using RSA key length of 2048 bits for Alfresco Enterprise.

```
ssl:
    image: alfresco/ssl-base
    environment:
        ALFRESCO_VERSION: enterprise
        KEY_SIZE: 2048
    volumes:
        - ./keystores:/keystores
```

Sample configurations for *Alfresco Enterprise* and *Alfresco Community* has been provided at `docker-compose` folder.
