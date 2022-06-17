# alf-genssl

## About

alf-genssl is an alternative for [alfresco-ssl-generator](https://github.com/Alfresco/alfresco-ssl-generator) to generate a custom CA, certificates and keystores required in a Alfresco installation. The script is developed for the [ecm4u Alfresco Virtual Appliance](https://www.ecm4u.de/was-wir-tun/produkte/alfresco/alfresco-virtual-appliance) but could be used in any linux based Alfresco installation. So it is shared here in the hope it 

Main differences to alfresco-ssl-generator:
* alf-genssl generates only required artifacts. e.g. if the CA is already set up it must not be replaced. Therefore the logic is encapsulated in separate bash functions.
* when recreating the metadata encryption keystore (which may never be required if the key is not compromised), the old keystore is automatically configured in the backup keystore not to break Alfresco
* alf-genssl takes care of all required configuration changes. No need for manual interaction
* the keystores are reduced to what is really required. e.g. the truststore only needs to trust the CA not the server certs. The original Alfresco keystores and previous generation scripts created too much config not needed and not increasing security or functionality.
* alf-genssl is focused on the Alfresco Community edition, so we don't generate certs for Zeppelin but that could be easily added if required

## Configuration

It is expected to configure your environment first before you run alf-genssl. `alf-gensslrc` loads defaults for the ecm4u Alfresco Virtual Appliance but you could set all the required paths by environment variables. Just check `alf-gensslrc` to understand which variables you want to set in your own environment. You could also set the variable `ALF_GENSSL_CUSTOM_CONFIG` to point to your own overwrites:
````
ALF_GENSSL_CUSTOM_CONFIG=${ALF_GENSSL_CUSTOM_CONFIG:=/opt/alfresco/scripts/scriptenv-alf}
````

## Requirements

openssl and keytool are expected to be available in your PATH

## Usage

just run the script without any parameter to see the supported commands:

````
./alf-genssl
Usage: /opt/alfresco/scripts/tools/alf-genssl/alf-genssl.sh {keystores|createcsr|createcert|importcert|exportclientcerts|updateconfig|cadirs|cleanup-ca|create-ca-key|create-ca-cert|metadatakeystore }
````

The most common use case would be to (re)generate only the keystores required to secure communication between the Alfresco Repository and Alfresco Search Services (Solr):
````
./alf-genssl.sh keystores
````

## Known Restrictions, Next Steps

At the moment alf-genssl expects all services to be controlled by systemd services and tries to stop the services accordingly. We may extend the scripts/config to take care of other deployments.

Other ideas, requirements:
* Since we already have a simple working working CA next step would be to also create certificates for the nginx reverse proxy
* We already separated private key generation, cert signing request and cert generation so we may also add commands to create the cert(s) from another CA and import them afterwards.

## Copyright

&copy; 2022 [ecm4u GmbH](https://www.ecm4u.de)