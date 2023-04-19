# Welcome to Alfresco SSL Generator

This is a script automation for the generation of the required `keystores`, `truststores` and browser `certificates` for Alfresco configuration using Mutual TLS Authentication between Repository and SOLR. These same files can be obtained manually by using any other cryptographic tools.

This project is not officially supported by Alfresco, as it provides just a sample to build your own security configuration for Alfresco. However, anyone can improve this tool by providing pull requests or by cloning the project and changing it accordingly to suit particular needs.

As HTTPs invocations happen between different Alfresco services, following relationships must be satisfied:

* Repository is client of SOLR and Transform Services

  * Repository key must be generated and must be included in *Repository keystore*
  * ~~Repository public certificate must be included in *SOLR truststore*~~
  * Root CA certificate must be included in *Repository truststore*

* SOLR is client of Repository and SOLR

  * SOLR key must be generated and must be included in *SOLR keystore*
  * ~~SOLR public certificate must be included in Repository and *SOLR truststore*~~
  * Root CA certificate must be included in *SOLR truststore*

* Zeppelin is client of Repository (Zeppelin is a product only available for Insight Engine Enterprise)

  * Zeppelin key must be generated and must be included in *Zeppelin keystore*
  * ~~Zeppelin public certificate must be included in *Repository truststore*~~
  * Root CA certificate must be included in *Zeppelin truststore*
  * Note that this script tool uses the same key certificates for SOLR and Zeppelin, as both are clients of the Repository

* When accessing SOLR from a browser, the browser is client of SOLR

  * Browser key must be installed on the browser in order to access SOLR Web Console

* Transform Services (Transform Router, T-Engines, Transform Aspose, AI Renditions, Shared File Store)

  * Transform Service key must be generated and must be included in *Transform Service keystore* for every Transform Service present
  * Root CA certificate must be included in *Transform Service truststore* for every Transform Service present

Additionally, to support Alfresco *encryption* feature, a metadata cyphering key is generated and included on a *keystore* to be used by the Repository.


## Usage

Certificates generation script `run.sh` is based in `OpenSSL` and Java `keytool` programs, and it can be used in different scenarios:

* *Bash Shell Script Standalone*, as a local bash script from Linux operative systems. The shell script and the OpenSSL configuration file are available in `ssl-tool` folder.
* *Windows Batch Script Standalone*, as a local batch script from Windows operative systems. The batch script and the OpenSSL configuration file are available in `ssl-tool-win` folder.
* *Docker Standalone*, as a local container generating `keystores` folder from environment variable values. Available from Linux, Windows and Mac OS X.
* *Docker Compose*, as a Docker service creating `keystores` folder from environment variable values. Available from Linux, Windows and Mac OS X.

New certificates generation scripts `run_ca.sh`, `run_encryption.sh` and `run_additional.sh` have been created to respond to the need of adding a varying number of additional services to mTLS. They also provide more granularity and control over passwords and other settings. They are currently unavailable for use in *Docker Standalone* and *Docker Compose*

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

| Script `run` parameter name | Docker Parameter name | Description                  | Values                      |
|-|-|-|-|
| -alfrescoversion      | ALFRESCO_VERSION      | Type of Alfresco Version     | `enterprise` or `community` |
| -keysize              | KEY_SIZE              | RSA key length               | `2048`, `4096`..., by default `2048`   |
| -keystoretype         | KEYSTORE_TYPE         | Type of the keystores (containing private keys)  | `PKCS12`, `JKS`, `JCEKS` |
| -truststoretype       | TRUSTSTORE_TYPE       | Type of the truststores (containing public keys) | `JKS`, `JCEKS`           |
| -keystorepass         | KEYSTORE_PASS         | Password for the keystores   | Any string                  |
| -truststorepass       | TRUSTSTORE_PASS       | Password for the truststores | Any string                  |
| -encstorepass         | ENC_STORE_PASS        | Password for the *encryption* keystore | Any string        |
| -encmetadatapass      | ENC_METADATA_PASS     | Password for the *encryption* metadata | Any string        |
| -cacertdname          | CA_CERT_DNAME         | Distinguished Name of the CA certificate, starting with slash and quoted | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA" |
| -repocertdname        | REPO_CERT_DNAME       | Distinguished Name of the Repository certificate, starting with slash and quoted | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository" |
| -solrcertdname        | SOLR_CERT_DNAME       | Distinguished Name of the SOLR certificate, starting with slash and quoted | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository Client" |
| -browsercertdname     | BROWSER_CERT_DNAME       | Distinguished Name of the BROWSER certificate, starting with slash and quoted | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Browser Client" |
| -caservername         | CA_SERVER_NAME        | DNS Name for CA Server       | Any string, `localhost` by default        |
| -alfrescoservername   | ALFRESCO_SERVER_NAME  | DNS Name for Alfresco Server | Any string, `localhost` by default        |
| -solrservername       | SOLR_SERVER_NAME      | DNS Name for SOLR Server     | Any string, `localhost` by default        |
| -alfrescoformat       | ALFRESCO_FORMAT       | Default format for certificates, truststores and keystores | `classic` or `current` (only supported from ACS 7.0) |
| -cavalidityduration   | CA_VALIDITY_DURATION  | Validity duration of the Root CA in days | Positive integer, `7300` by default |

| Script `run_ca` parameter name | Description                  | Values                      |
|-|-|-|
| -keysize              | RSA key length               | `2048`, `4096`...   |
| -keystorepass         | Password for the keystores   | Any string between 6 to 1023 characters, if not provided a prompt will be displayed                  |
| -certdname            | Distinguished Name of the CA certificate, starting with slash and quoted | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA" |
| -servername           | DNS Name for CA Server       | Any string, `localhost` by default        |
| -validityduration     | Validity duration of the Root CA in days | Positive integer, `365` by default |

| Script `run_encryption` parameter name | Description                  | Values                      |
|-|-|-|
| -servicename          | Service name, will be used for keystore file name and key alias | Any string, by default `encryption`        |
| -subfoldername        | Name of a subfolder where the *encryption* keystore will be placed | Any string, by default the same as value of `servicename` parameter        |
| -encstorepass         | Password for the *encryption* keystore | Any string between 6 to 1023 characters, if not provided a prompt will be displayed        |
| -encmetadatapass      | Password for the *encryption* metadata | Any string between 6 to 1023 characters, if not provided a prompt will be displayed        |
| -alfrescoformat       | Default format for certificates, truststores and keystores | `classic` or `current` (only supported from ACS 7.0) |

| Script `run_additional` parameter name | Description                  | Values                      |
|-|-|-|
| -servicename          | Service name, will be used for keystore file name and key alias | Any string, by default `service`        |
| -subfoldername        | Name of a subfolder where the *service* keystore will be placed | Any string, by default the same as value of `servicename` parameter        |
| -alias                | Key alias                    | Any string, by default the same as value of `servicename` parameter        |
| -role                 | Role to be fulfilled by the keystore key, different roles correspond to dedicated settings in openssl.cnf file | `client`, `server`, `both`, by default `both`        |
| -rootcapass           | Password set for Root CA, is required for signing the additional keystores | Any string. Lack of this parameter will result with an exception.       |
| -keysize              | RSA key length               | `2048`, `4096`..., by default `2048`   |
| -keystoretype         | Type of the keystores (containing private keys)  | `PKCS12`, `JKS`, `JCEKS`, by default `JCEKS` |
| -keystorepass         | Password for the keystores   | Any string between 6 to 1023 characters, if not provided a prompt will be displayed                  |
| -notruststore         | Flag for blocking truststore generation | N/A, providing the flag turns off truststore generation           |
| -truststoretype       | Type of the truststores (containing public keys) | `JKS`, `JCEKS`, by default `JCEKS`           |
| -truststorepass       | Password for the truststores | Any string between 6 to 1023 characters, if not provided a prompt will be displayed                  |
| -certdname            | Distinguished Name of the CA certificate, starting with slash and quoted | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Service" |
| -servername           | DNS Name for CA Server       | Any string, `localhost` by default        |
| -alfrescoformat       | Default format for certificates, truststores and keystores | `classic` or `current` (only supported from ACS 7.0) |

When using Alfresco on an internal network, each server should have a different name. This names can be configured on the parameters named as `*servername`. In order to avoid browser complains about certificates, it's recommended to include the name of the server as `Alternative Name` in the certificate. This should be at least required for SOLR Web Console, as this application is only available in `https` when using this configuration. If you are working under a Web Proxy, use the name of this proxy for the `*servername` parameters.
Scripts have been updated to handle multiple Service Alternative Names. To provide multiple of them seperate them with `,`, example: `-servername localhost,additionalSAN`. For Windows variant the value needs to be enclosed in double quotes.

## Bash Shell Script Standalone (Linux, Mac OS X)

When working on a *Linux* machine, shell scripts can be used directly from command line. It's required to have `OpenSSL` and `keytool` programs available in the environment.

The scripts parameters can be set through command line.

For instance, the following command will produce `keystores` folder in a host folder named `keystores` using RSA key length of 2048 bits for Alfresco Enterprise.

```bash
$ cd ssl-tool

$ ./run.sh -keysize 2048 -alfrescoversion enterprise -alfrescoformat classic

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
$ ./run.sh -cacertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Linux Alfresco CA" \
-repocertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Repo" \
-solrcertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Solr" \
-browsercertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Browser"
```

Note that when `keystores` folder is not empty, the program exists without producing any keystore or truststore.

When using `current` Alfresco format (default option), instead of `classic`, following output is generated.

```bash
$ cd ssl-tool

$ ./run.sh -keysize 2048 -alfrescoversion enterprise

$ tree keystores/
keystores/
├── alfresco
│   ├── keystore
│   ├── ssl.keystore
│   └── ssl.truststore
├── client
│   └── browser.p12
├── solr
│   ├── ssl-repo-client.keystore
│   └── ssl-repo-client.truststore
└── zeppelin
    ├── ssl-repo-client.keystore
    └── ssl-repo-client.truststore
```

For the `current` format all the passwords are passed to the applications using Java Environment Variables, so the password files are not required any more.

If you desire more control and granularity, or need to add other services into the mTLS mix, then you might want to consider using `run_ca.sh`, `run_encryption.sh` and `run_additional.sh` in place of `run.sh` script or only `run_additional.sh` as an addition. 
`run_ca.sh` - script responsible for preparing folders (ca, certificates, keystores) and generating the Root CA,
`run_encryption.sh` - script responsible for generating the metadata encryption keystore
`run_additional.sh` - script using the previously generated CA (with `run.sh` or `run_ca.sh` script) to generate additional sets of keystore and truststore.

Samples of using these scripts and how they replace the `run.sh` functionality or add on to it can be found in `ssl-tool\samples` folder of this project. 
Keep in mind that some locations of generated scripts or names of keystores might differ between the samples of new approach (`run_ca.sh` + `run_encryption.sh` + `run_additional.sh`) and legacy approach (`run.sh` + `run_additional.sh`). 


## Batch Script Standalone (Windows)

When working on a *Windows* machine, shell script `ssl-tool-win/run.cmd` can be used directly from command line. It's required to have `OpenSSL` and `keytool` programs available in the *PATH*.

The parameters described above, can be used from command line.

For instance, the following command will produce `keystores` folder in a host folder named `keystores` using RSA key length of 2048 bits for Alfresco Community.

```bash
C:\> cd ssl-tool-win

C:\> run.cmd -keysize 2048 -alfrescoversion community -alfrescoformat classic

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
-solrcertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Solr" ^
-browsercertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Browser"
```

Note that when `keystores` folder is not empty, the program exists without producing any keystore or truststore.

When using `current` Alfresco format (default option), instead of `classic`, following output is generated.

```bash
C:\> cd ssl-tool-win

C:\> run.cmd -keysize 2048 -alfrescoversion community

C:\> tree /F keystores
├───alfresco
│       keystore
│       ssl.keystore
│       ssl.truststore
│
├───client
│       browser.p12
│
└───solr
        ssl.repo.client.keystore
        ssl.repo.client.truststore
```

For the `current` format all the passwords are passed to the applications using Java Environment Variables, so the password files are not required any more.

If you desire more control and granularity, or need to add other services into the mTLS mix, then you might want to consider using `run_ca.cmd`, `run_encryption.cmd` and `run_additional.cmd` in place of `run.cmd` script or only `run_additional.cmd` as an addition.
`run_ca.cmd` - script responsible for preparing folders (ca, certificates, keystores) and generating the Root CA,
`run_encryption.cmd` - script responsible for generating the metadata encryption keystore
`run_additional.cmd` - script using the previously generated CA (with `run.cmd` or `run_ca.cmd` script) to generate additional sets of keystore and truststore.

Samples of using these scripts and how they replace the `run.cmd` functionality or add on to it can be found in `ssl-tool-win\samples` folder of this project.
Keep in mind that some locations of generated scripts or names of keystores might differ between the samples of new approach (`run_ca.cmd` + `run_encryption.cmd` + `run_additional.cmd`) and legacy approach (`run.cmd` + `run_additional.cmd`).

## Installing Browser certificate

In order to access to SOLR Web Console, available by default at [https://localhost:8983/solr](https://localhost:8983/solr), browser certificate must be installed in your machine.

For *Windows* systems, `client\browser.p12` file must be imported as new private certificate to `Windows Certificates` application.

For *Mac OS X* systems, `client/browser.p12` file must be imported to `Keychain Access` application.

Also setting the right options in these application to *trust* in this certificate is required.

Once the certificate is installed, the following message should be showed by your browser when accessing to Solr Web Console:

```
Your connection is not private
Attackers might be trying to steal your information from localhost (for example, passwords, messages or credit cards). Learn more
NET::ERR_CERT_AUTHORITY_INVALID
```

As the certificate has been generated for `localhost`, this warning is expected. Just click on `Advanced >> Proceed` and use your browser certificate to access Solr Web Console.

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
│   ├── ssl.keystore
│   └── ssl.truststore
├── client
│   └── browser.p12
├── solr
│   ├── ssl-repo-client.keystore
│   └── ssl-repo-client.truststore
└── zeppelin
    ├── ssl-repo-client.keystore
    └── ssl-repo-client.truststore
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


## Known issues

**"SEC_ERROR_REUSED_ISSUER_AND_SERIAL" error when accessing SOLR Web Console in Firefox***

If you are using Alfresco SSL Generator for testing or developing and you issued the same CA Certificate more than one time, Firefox will complain when trying to access to SOLR Web Console ([https://localhost:8983/solr](https://localhost:8983/solr) by default).

This problem is described at Bugzilla:

[https://bugzilla.mozilla.org/show_bug.cgi?id=435013](https://bugzilla.mozilla.org/show_bug.cgi?id=435013)

Apply any of the workarounds provided (as removing `cert8.db` or `cert9.db` file from your Firefox profile folder) in order to fix this problem.

## Using Custom Certificates

When using certificates from external CAs, not the one provided by this project, building the `keystores` and `truststores` for Repository and SOLR is required. `keytool` or any other tool can be used in order to build these stores. Details on the content of every related file is available in [Alfresco MTLS Configuration Deep Dive](https://hub.alfresco.com/t5/alfresco-content-services-blog/alfresco-mtls-configuration-deep-dive/ba-p/296422).

Note that every intermediate CA public key must be included in every `truststore`.

`keytool` can be used to get this certificate chain.

```
$ keytool -list -alias alfresco.ca -keystore ssl.repo.client.keystore -rfc
Alias name: alfresco.ca
Creation date: 20 Feb 2020
Entry type: PrivateKeyEntry
Certificate chain length: 2
Certificate[1]:
-----BEGIN CERTIFICATE-----
MIIFNTCCBB2gAwIBAgIQDZAM1h0f9komm5D7ivokHTANBgkqhkiG9w0BAQsFADBe
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMR0wGwYDVQQDExRHZW9UcnVzdCBSU0EgQ0EgMjAxODAe
Fw0xODAxMDIwMDAwMDBaFw0yMTAxMDExMjAwMDBaMIGaMQswCQYDVQQGEwJVUzEQ
MA4GA1UECBMHSW5kaWFuYTEVMBMGA1UEBxMMSW5kaWFuYXBvbGlzMSwwKgYDVQQK
EyNPbmVBbWVyaWNhIEZpbmFuY2lhbCBQYXJ0bmVycywgSW5jLjEZMBcGA1UECxMQ
TmV0d29yayBTZXJ2aWNlczEZMBcGA1UEAwwQKi5vbmVhbWVyaWNhLmNvbTCCASIw
DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALYdHOLovHc2j5xQfBngerSsIFJa
VGOwsPQplUkQJ1P/V/gq9ihCtC/CqMFsQJRKJyoQ9Ii+CxsZLjeNVoPUl74AEoUX
gO+Mv1BpEAdV0KvC8gF9jUk0Rv/u9Mebt08uoGPKW6bb+XkphboopwhqNt42Ypk6
gwHW/HCyuCFXzWWT5ipcuK9vMpiNlZbBipicsX716AzYdOZ9uDSKpWbtxPriwsUe
Kbgkm5b2y3dH42bxjRs7ErNcVWF8jPiFUeDRFhA2gV2vbVfPr9jZV9be34xHJXv8
O3SDLjgdvay5128jqOhHOt8seNVW6+I3qpWjePPwWZs+FrgcMwOxBO+S+CkCAwEA
AaOCAbAwggGsMB8GA1UdIwQYMBaAFJBY/7CcdahRVHex7fKjQxY4nmzFMB0GA1Ud
DgQWBBRXtA41zjBtnwIQMyDegWj9frpzTjArBgNVHREEJDAighAqLm9uZWFtZXJp
Y2EuY29tgg5vbmVhbWVyaWNhLmNvbTAOBgNVHQ8BAf8EBAMCBaAwHQYDVR0lBBYw
FAYIKwYBBQUHAwEGCCsGAQUFBwMCMD4GA1UdHwQ3MDUwM6AxoC+GLWh0dHA6Ly9j
ZHAuZ2VvdHJ1c3QuY29tL0dlb1RydXN0UlNBQ0EyMDE4LmNybDBMBgNVHSAERTBD
MDcGCWCGSAGG/WwBATAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2Vy
dC5jb20vQ1BTMAgGBmeBDAECAjB1BggrBgEFBQcBAQRpMGcwJgYIKwYBBQUHMAGG
Gmh0dHA6Ly9zdGF0dXMuZ2VvdHJ1c3QuY29tMD0GCCsGAQUFBzAChjFodHRwOi8v
Y2FjZXJ0cy5nZW90cnVzdC5jb20vR2VvVHJ1c3RSU0FDQTIwMTguY3J0MAkGA1Ud
EwQCMAAwDQYJKoZIhvcNAQELBQADggEBACvC+8nlAtCo7AMSP0ajPyobbNGOg/Ix
gVIKzQV8mnAntxjWn+SqnHGeWMqhvbsAeRDWkDc/XDq4Qq+QJMDM2ZyePENGDnvV
IjMPVHS+Nu1vc1JC9zn8vi9XKfB7OOcVOIJAp7ZZP9zAZLk79I0F6q6BeKj/d6my
jEZO//4QLK5FA+Bz8Ah0XP5Nt90x+pPi76yRbUuxgkJd5va9JfX2GM5cpw/BphjN
JeUhgFD8Gw8wxELwqNtc5QUlE0WlJSBrbRL9y+xuHcSYRlCsd3nEZ3h5PCtgjplz
iRxoB7R8KED+wH+MlWDSMbe+BtQ3rp9dPK2FYSZhQ3pIH4pR0+S+13Q=
-----END CERTIFICATE-----
Certificate[2]:
-----BEGIN CERTIFICATE-----
MIIEizCCA3OgAwIBAgIQBUb+GCP34ZQdo5/OFMRhczANBgkqhkiG9w0BAQsFADBh
MQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3
d3cuZGlnaWNlcnQuY29tMSAwHgYDVQQDExdEaWdpQ2VydCBHbG9iYWwgUm9vdCBD
QTAeFw0xNzExMDYxMjIzNDVaFw0yNzExMDYxMjIzNDVaMF4xCzAJBgNVBAYTAlVT
MRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5j
b20xHTAbBgNVBAMTFEdlb1RydXN0IFJTQSBDQSAyMDE4MIIBIjANBgkqhkiG9w0B
AQEFAAOCAQ8AMIIBCgKCAQEAv4rRY03hGOqHXegWPI9/tr6HFzekDPgxP59FVEAh
150Hm8oDI0q9m+2FAmM/n4W57Cjv8oYi2/hNVEHFtEJ/zzMXAQ6CkFLTxzSkwaEB
2jKgQK0fWeQz/KDDlqxobNPomXOMJhB3y7c/OTLo0lko7geG4gk7hfiqafapa59Y
rXLIW4dmrgjgdPstU0Nigz2PhUwRl9we/FAwuIMIMl5cXMThdSBK66XWdS3cLX18
4ND+fHWhTkAChJrZDVouoKzzNYoq6tZaWmyOLKv23v14RyZ5eqoi6qnmcRID0/i6
U9J5nL1krPYbY7tNjzgC+PBXXcWqJVoMXcUw/iBTGWzpwwIDAQABo4IBQDCCATww
HQYDVR0OBBYEFJBY/7CcdahRVHex7fKjQxY4nmzFMB8GA1UdIwQYMBaAFAPeUDVW
0Uy7ZvCj4hsbw5eyPdFVMA4GA1UdDwEB/wQEAwIBhjAdBgNVHSUEFjAUBggrBgEF
BQcDAQYIKwYBBQUHAwIwEgYDVR0TAQH/BAgwBgEB/wIBADA0BggrBgEFBQcBAQQo
MCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBCBgNVHR8E
OzA5MDegNaAzhjFodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRHbG9i
YWxSb290Q0EuY3JsMD0GA1UdIAQ2MDQwMgYEVR0gADAqMCgGCCsGAQUFBwIBFhxo
dHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMA0GCSqGSIb3DQEBCwUAA4IBAQAw
8YdVPYQI/C5earp80s3VLOO+AtpdiXft9OlWwJLwKlUtRfccKj8QW/Pp4b7h6QAl
ufejwQMb455OjpIbCZVS+awY/R8pAYsXCnM09GcSVe4ivMswyoCZP/vPEn/LPRhH
hdgUPk8MlD979RGoUWz7qGAwqJChi28uRds3thx+vRZZIbEyZ62No0tJPzsSGSz8
nQ//jP8BIwrzBAUH5WcBAbmvgWfrKcuv+PyGPqRcc4T55TlzrBnzAzZ3oClo9fTv
O9PuiHMKrC6V6mgi0s2sa/gbXlPCD9Z24XUMxJElwIVTDuKB0Q4YMMlnpN/QChJ4
B0AFsQ+DU0NCO+f78Xf7
-----END CERTIFICATE-----
```

In the sample above, `Certificate[2]` content could be saved as `alfresco-ca-root.cer` to be imported in the repository truststore.
