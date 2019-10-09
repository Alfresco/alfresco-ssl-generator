# Alfresco SSL Generator へようこそ

これはリポジトリと SOLR 間の相互 TLS 認証を使用して、Alfresco の設定に必要な `keystores`、`truststores` およびブラウザ `certificates` を生成するための自動化スクリプトです。これらの同じファイルは、他の暗号化ツールを使用して手動で取得することもできます。

このプロジェクトは、Alfresco の独自のセキュリティ構成を構築するためのサンプルを提供するだけなので、Alfresco は公式にサポートしていません。ただし、プルリクエストを提供するか、プロジェクトのクローンを作成して特定のニーズに合わせて変更することにより、誰でもこのツールを改善できます。

異なる Alfresco のサービス間で HTTP 呼び出しが発生するため、次の関係を満たす必要があります:

* リポジトリは SOLR のクライアントです

  * リポジトリキーを生成し、*リポジトリのキーストア* に含める必要があります
  * リポジトリ公開証明書は *SOLR のトラストストア* に含まれている必要があります

* SOLR はリポジトリと SOLR のクライアントです

  * SOLR キーを生成し、*SOLR のキーストア* に含める必要があります
  * リポジトリおよび *SOLR のトラストストア* に SOLR 公開証明書を含める必要があります

* Zeppelin はリポジトリのクライアントです (Zeppelin は Insight Engine Enterprise でのみ使用可能な製品です)

  * Zeppelin キーを生成し、*Zeppelin のキーストア* に含める必要があります
  * Zeppelin の公開証明書は、*Repository truststore* に含まれている必要があります
  * このスクリプトツールは、SOLR と Zeppelin の両方がリポジトリのクライアントであるため、同じキー証明書を使用することに注意してください

* ブラウザから SOLR にアクセスする場合、ブラウザは SOLR のクライアントです

  * SOLR の Web コンソールにアクセスするには、ブラウザにブラウザキーをインストールする必要があります


さらに、Alfresco の *暗号化* 機能をサポートするためにメタデータ暗号化キーが生成され、リポジトリで使用される *keystore* に含まれます。


## 使い方

証明書生成スクリプト `run.sh` は `OpenSSL` および Java の `keytool` プログラムに基づいており、さまざまなシナリオで使用できます:

* Linux OS のローカル bash スクリプトとして、*Bash Shell Script Standalone* を使用できます。シェルスクリプトと OpenSSL 設定ファイルは `ssl-tool` フォルダで利用可能です
* Windows OS のローカルバッチスクリプトとして *Windows Batch Script Standalone* を使用できます。バッチスクリプトと OpenSSL 設定ファイルは `ssl-tool-win` フォルダで利用可能です
* 環境変数の値から `keystores` フォルダを生成するローカルコンテナとして、Docker Standalone で使用できます。Linux、Windows、および Mac OS X から利用できます
* 環境変数の値から `keystores` フォルダを作成する Docker サービスとして、Docker Compose で使用できます。Linux、Windows、および Mac OS X から利用できます

## 必要条件

生成スクリプトを実行するには、システムパスで `OpenSSL` プログラムと Java `keytool` プログラムをインストールし、使用可能にする必要があります。

**OpenSSL**

OpenSSL は、認証局、秘密鍵、および証明書 (使用ポリシーを含む) を生成する暗号化ソフトウェアです。

多くの **Linux** のディストリビューションには、パッケージとして `OpenSSL` が含まれているため、他のプログラムとしてインストールできます。

*Ubuntu*

```
$ sudo apt-get install openssl
```

*CentOS*

```
$ yum -y install openssl openssl-devel
```

**Mac OS X** では、[Homebrew](https://brew.sh) などのパッケージマネージャを使用できます:

```
$ brew install openssl
```

**Windows** を使用する場合、OpenSSL Web ページからバイナリ配布を使用できます:

https://wiki.openssl.org/index.php/Binaries


>> システムパスに `openssl` プログラムを追加することを忘れないでください。

**Keytool**

Keytool は、`keystores` と `truststores` を構築するための標準 Java ログラムです。

keytool ユーティリティは JRE に含まれています。

Oracle JRE 11 と OpenJDK JRE 11 の両方を使用できます。運用システムのインストール手順に従ってください。

>> システムパスに `keytool` プログラムを追加することを忘れないでください。


## パラメータ

コマンドラインスクリプトと Docker Image リソースのいずれも、外部パラメータの値を使用してパラメータ化できます。次の表に、さまざまなオプションを示します。

| スクリプトパラメータ名 | Docker パラメータ名 | 説明                  | 値                      |
|-|-|-|-|
| -alfrescoversion      | ALFRESCO_VERSION      | Alfresco バージョンのタイプ     | `enterprise` もしくは `community` |
| -keysize              | KEY_SIZE              | RSA 鍵の長さ               | `1024`, `2048`, `4096`...   |
| -keystoretype         | KEYSTORE_TYPE         | キーストアのタイプ (秘密鍵を含む)  | `PKCS12`, `JKS`, `JCEKS` |
| -truststoretype       | TRUSTSTORE_TYPE       | トラストストアのタイプ (公開鍵を含む) | `JKS`, `JCEKS`           |
| -keystorepass         | KEYSTORE_PASS         | キーストアのパスワード   | 任意の文字列                  |
| -truststorepass       | TRUSTSTORE_PASS       | トラストストアのパスワード | 任意の文字列                  |
| -encstorepass         | ENC_STORE_PASS        | *暗号化* キーストアのパスワード | 任意の文字列        |
| -encmetadatapass      | ENC_METADATA_PASS     | *暗号化* メタデータのパスワード | 任意の文字列        |
| -cacertdname          | CA_CERT_DNAME         | スラッシュで始まり、引用符付きの CA 証明書の識別名 | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco CA" |
| -repocertdname        | REPO_CERT_DNAME       | スラッシュで始ま理、引用符付きの リポジトリ証明書の識別名 | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository" |
| -solrcertdname        | SOLR_CERT_DNAME       | スラッシュで始まり、引用符付きの SOLR 証明書の識別名 | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Alfresco Repository Client" |
| -browsercertdname     | BROWSER_CERT_DNAME       | スラッシュで始まり、引用符付きの BROWSER 証明書の識別名 | "/C=GB/ST=UK/L=Maidenhead/O=Alfresco Software Ltd./OU=Unknown/CN=Custom Browser Client" |
| -caservername         | CA_SERVER_NAME        | CA サーバの DNS 名       | 任意の文字列。デフォルトは `localhost`        |
| -alfrescoservername   | ALFRESCO_SERVER_NAME  | Alfresco サーバの DNS 名 | 任意の文字列。デフォルトは `localhost`        |
| -solrservername       | SOLR_SERVER_NAME      | SOLR サーバの DNS 名     | 任意の文字列。デフォルトは `localhost`        |

内部ネットワークで Alfresco を使用する場合、各サーバには異なる名前を付ける必要があります。この名前は、`*servername` という名前のパラメータで設定できます。ブラウザが証明書について警告を出すのを避けるため、証明書に `Alternative Name` としてサーバの名前を含めることをお勧めします。このアプリケーションは、この構成を使用する場合は `https` でのみ使用できるため、少なくとも SOLR Web コンソールには必要です。Web プロキシの下で作業している場合、`*servername` パラメータにこのプロキシの名前を使用します。

## Bash Shell Script Standalone (Linux, Mac OS X)

*Linux* マシンで作業する場合、シェルスクリプト `ssl-tool/run.sh` をコマンドラインから直接使用できます。環境で `OpenSSL` および `keytool` プログラムを使用できるようにする必要があります。

上記のパラメータは、コマンドラインから使用できます。

たとえば、次のコマンドは、Alfresco Enterprise の 2048 ビットの RSA キー長を使用して、`keystores` という名前のホストフォルダに `keystores` フォルダを作成します。

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

証明書にカスタム *DNames* を使用する場合、値を引用符で設定する必要があります。

```bash
$ ./run.sh -cacertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Linux Alfresco CA" \
-repocertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Repo" \
-solrcertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Solr" \
-browsercertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Browser"
```

`keystores` フォルダが空でない場合、キーストアまたはトラストストアを作成せずプログラムがそのままであることに注意してください。


## Batch Script Standalone (Windows)

*Windows* マシンで作業する場合、コマンドラインからシェルスクリプト `ssl-tool-win/run.cmd` を直接使用できます。*PATH* で `OpenSSL` と `keytool` プログラムを利用できるようにする必要があります。

上記のパラメータは、コマンドラインから使用できます。

たとえば、次のコマンドは、Alfresco Community の 2048 ビットの RSA キー長を使用して、`keystores` という名前のホストフォルダに `keystores` フォルダを作成します。

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

証明書にカスタム *DNames* を使用する場合、値を引用符で設定する必要があります。

```bash
C:\> run.cmd -cacertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Windows Alfresco CA" ^
-repocertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Repo" ^
-solrcertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Solr" ^
-browsercertdname "/C=GB/ST=UK/L=Maidenhead/O=Alfresco/OU=Unknown/CN=Browser"
```

`keystores` フォルダが空でない場合、キーストアまたはトラストストアを作成せずプログラムがそのままであることに注意してください。


## ブラウザ証明書のインストール

デフォルトで [https://localhost:8983/solr](https://localhost:8983/solr) で利用可能な SOLR Web コンソールにアクセスするには、ブラウザ証明書をマシンにインストールする必要があります。

*Windows* システムの場合、`client\browser.p12` ファイルを新しいプライベート証明書として `Windows Certificates` アプリケーションにインポートする必要があります。

*Mac OS X* システムの場合、`client/browser.p12` ファイルを `Keychain Access` アプリケーションにインポートする必要があります。

また、この証明書でこれらのアプリケーションの正しいオプションを *trust* に設定する必要があります。

証明書がインストールされると、Solr Web Consoleにアクセスするときにブラウザーに次のメッセージが表示されます。:

```
Your connection is not private
Attackers might be trying to steal your information from localhost (for example, passwords, messages or credit cards). Learn more
NET::ERR_CERT_AUTHORITY_INVALID
```

証明書は `localhost` 用に生成されているため、この警告が予想されます。`Advanced >> Proceed` をクリックし、ブラウザ証明書を使用して Solr Web コンソールにアクセスするだけです。

## Docker Standalone

**Docker イメージのビルド**

このイメージは [alfresco-docker-base-java](https://github.com/Alfresco/alfresco-docker-base-java) イメージに依存します。これは [Quay](https://quay.io/repository/alfresco/alfresco-base-java) (プライベート) および [Docker Hub](https://hub.docker.com/r/alfresco/alfresco-base-java/) (パブリック) で利用できます。

このイメージを構築するには、次のスクリプトを実行します:

```bash
docker build -t alfresco/alfresco-base-ssl .
```

これらの結果を取得するためにホストマウントフォルダを使用して、ストアと証明書を作成するために、イメージを `docker run` 経由で使用できます。

**ボリューム**

次のフォルダはボリュームにマウントできます:

* `/keystores` フォルダには `alfresco`、`solr` 、`zeppelin` サービス用に生成されたキーストアとトラストストアが含まれます
* `/ca` フォルダには、OpenSSL で作成された CA が使用する内部情報 (CRL、CA キー...) が含まれています
* `/certificates` フォルダには、キーストアとトラストストアの構築に使用される未加工の証明書が含まれています

Alfresco サービスに必要なフォルダを取得するには、`keystores` フォルダをマウントするだけです。CA および証明書フォルダもマウントできますが、これらのファイルは Alfresco 構成には使用されません。

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

**パラメータ**

Docker コンテナは、上記で定義したパラメータの一部を使用して起動できます。

たとえば、次のコマンドは、Alfresco Enterpris の 2048 ビットの RSA キー長を使用して、`keystores` という名前のホストフォルダに `keystores` フォルダを作成します。

```bash
$ docker run -v $PWD/keystores:/keystores -e KEY_SIZE=2048 -e ALFRESCO_VERSION=enterprise alfresco/alfresco-base-ssl
```

`keystores` フォルダが空でない場合、キーストアまたはトラストストアを作成せずプログラムがそのままであることに注意してください。


### Docker Compose

この Docker イメージは Docker Compose サービスとして使用でき、前述の環境変数に同じパラメータをとります。

たとえば、次のコマンドは、Alfresco Enterprise の 2048 ビットの RSA キー長を使用して、`keystores` という名前のホストフォルダに `keystores` フォルダを作成します。

```
ssl:
    image: alfresco/ssl-base
    environment:
        ALFRESCO_VERSION: enterprise
        KEY_SIZE: 2048
    volumes:
        - ./keystores:/keystores
```

*Alfresco Enterprise* および *Alfresco Community* のサンプル設定は、`docker-compose` フォルダで提供されています。


## 既知の問題

**Firefox で SOLR Web コンソールにアクセスする際の "SEC_ERROR_REUSED_ISSUER_AND_SERIAL" エラー**

テストまたは開発に Alfresco SSL Generator を使用していて、同じ CA 証明書を複数回発行した場合、Firefox は SOLR Web コンソール (デフォルトでは [https://localhost:8983/solr](https://localhost:8983/solr)) にアクセスしようとすると警告を発します。

この問題は Bugzilla で説明されています:

[https://bugzilla.mozilla.org/show_bug.cgi?id=435013](https://bugzilla.mozilla.org/show_bug.cgi?id=435013)

この問題を修正するには、提供されている回避策 (Firefox プロファイルフォルダから `cert8.db` または `cert9.db` ファイルを削除するなど) を適用します。
