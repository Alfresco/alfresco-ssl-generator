# Welcome to Alfresco Docker Base SSL

This is a script automation for the generation of the required `keystores`, `truststores` and browser `certificates` for Alfresco configuration using Mutual TLS Authentication between Repository and SOLR. These same files can be obtained manually by using any other cryptographic tools.

This project is not officially supported by Alfresco, as it provides just a sample to build your own security configuration for Alfresco. However, anyone can improve this tool by providing pull requests or by cloning the project and changing it accordingly to suit particular needs.

As HTTPs invocations happen between different Alfresco services, following relationships must be satisfied:

* Repository is client of SOLR

  * Repository key must be generated and must be included in *Repository keystore*
  * Repository public certificate must be included in *SOLR truststore*

* SOLR is client of Repository and SOLR

  * SOLR key must be generated and must be included in *SOLR keystore*
  * SOLR public certificate must be included in Repository and *SOLR truststore*

* Zeppelin is client of Repository (Zeppelin is a product only available for Insight Engine Enterprise)

  * Zeppelin key must be generated and must be included in *Zeppelin keystore*
  * Zeppelin public certificate must be included in *Repository truststore*
  * Note that this script tool uses the same key certificates for SOLR and Zeppelin, as both are clients of the Repository

* When accessing SOLR from a browser, the browser is client of SOLR

  * Repository key must be installed on the browser in order to access SOLR Web Console


Additionally, to support Alfresco *encryption* feature, a metadata cyphering key is generated and included on a *keystore* to be used by the Repository.


## Usage

Certificates generation script `run.sh` is based in `OpenSSL` and Java `keytool` programs, and it can be used in different scenarios:

* *Bash Shell Script Standalone*, as a local bash script from Linux operative systems. The shell script and the OpenSSL configuration file are available in `ssl-tool` folder.
* *Windows Batch Script Standalone*, as a local batch script from Windows operative systems. The batch script and the OpenSSL configuration file are available in `ssl-tool-win` folder.
* *Docker Standalone*, as a local container generating `keystores` folder from environment variable values. Available from Linux, Windows and Mac OS X.
* *Docker Compose*, as a Docker service creating `keystores` folder from environment variable values. Available from Linux, Windows and Mac OS X.

## Requisites

Running the generation script requires having `OpenSSL` and Java `keytool` programs installed and available in the system path.

**OpenSSL**

OpenSSL is a cryptographic software to generate certification authorities, private keys and certificates (including usage policies).

Many distributions of **Linux** include `OpenSSL` as a package, so you can install it as any other program.

*Ubuntu*

```
$ sudo apt-get install openssl
```

*CentOS*

```
$ yum -y install openssl openssl-devel
```

For **Mac OS X**, some package manager like [Homebrew](https://brew.sh) can be used:

```
$ brew install openssl
```

When using **Windows**, binaries distribution from OpenSSL web page can be used:

https://wiki.openssl.org/index.php/Binaries


>> Remember to add `openssl` program to system path.


**Keytool**

Keytool is a standard Java program to build `keystores` and `truststores`.

The keytool utility is included with the JRE.

Both Oracle JRE 11 and OpenJDK JRE 11 can be used, just follow the installation instructions for your operative system.

>> Remember to add `keytool` program to system path.


## Parameters

Both command line scripts and Docker Image resources can be parametrised by using external parameter values. Different options are described in the table below.

| Script parameter name | Docker Parameter name | Description                  | Values                      |
|-|-|-|-|
| -alfrescoversion      | ALFRESCO_VERSION      | Type of Alfresco Version     | `enterprise` or `community` |
| -keysize              | KEY_SIZE              | RSA key length               | `1024`, `2048`, `4096`...   |
| -keystoretype         | KEYSTORE_TYPE         | Type of the keystores (containing private keys)  | `PKCS12`, `JKS`, `JCEKS` |
| -truststoretype       | TRUSTSTORE_TYPE       | Type of the truststores (containing public keys) | `JKS`, `JCEKS`           |
| -keystorepass         | KEYSTORE_PASS         | Password for the keystores   | Any string                  |
| -truststorepass       | TRUSTSTORE_PASS       | Password for the truststores | Any string                  |
| -encstorepass         | ENC_STORE_PASS        | Password for the *encryption* keystore | Any string        |
| -encmetadatapass      | ENC_METADATA_PASS     | Password for the *encryption* metadata | Any string        |
| -cacertdname          | CA_CERT_DNAME         | Distinguished Name of the CA certificate, starting with slash and quoted | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA" |
| -repocertdname        | REPO_CERT_DNAME       | Distinguished Name of the Repository certificate, starting with slash and quoted | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository" |
| -solrcertdname        | SOLR_CERT_DNAME       | Distinguished Name of the SOLR certificate, starting with slash and quoted | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository Client" |


## Bash Shell Script Standalone (Linux, Mac OS X)

When working on a *Linux* machine, shell script `ssl-tool/run.sh` can be used directly from command line. It's required to have `OpenSSL` and `keytool` programs available in the environment.

The parameters described above, can be used from command line.

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


## Batch Script Standalone (Windows)

When working on a *Windows* machine, shell script `ssl-tool-win/run.cmd` can be used directly from command line. It's required to have `OpenSSL` and `keytool` programs available in the *PATH*.

The parameters described above, can be used from command line.

For instance, the following command will produce `keystores` folder in a host folder named `keystores` using RSA key length of 2048 bits for Alfresco Community.

```bash
C:\> cd ssl-tool-win

C:\> run.cmd -keysize 2048 -alfrescoversion community

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


## Docker Standalone

**Building the Docker Image**

This image depends on the [alfresco-docker-base-java](https://github.com/Alfresco/alfresco-docker-base-java) image, which is also available (privately) on [Quay](https://quay.io/repository/alfresco/alfresco-base-java) and (publicly) on [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-base-java/).

To build this image, run the following script:

```bash
docker build -t alfresco/alfresco-base-ssl .
```

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

Docker Container can be started using some of the parameters defined above.

For instance, the following command will produce `keystores` folder in a host folder named `keystores` using RSA key length of 2048 bits for Alfresco Enterprise.

```bash
$ docker run -v $PWD/keystores:/keystores -e KEY_SIZE=2048 -e ALFRESCO_VERSION=enterprise alfresco/alfresco-base-ssl
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

Sample configurations for *Alfresco Enterprise* and *Alfresco Community* have been provided at `docker-compose` folder.
