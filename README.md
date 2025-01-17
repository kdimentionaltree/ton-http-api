![splash_http_api](https://user-images.githubusercontent.com/1449561/154847286-989a6c51-1615-45e1-b40f-aec7c13014fa.png)

# HTTP API for [The Open Network](https://ton.org)

Since TON nodes uses its own ADNL binary transport protocol, a intermediate service is needed for an HTTP connection.

TON HTTP API is such a intermediate service, receiving requests via HTTP, it accesses the lite servers of the TON network using `tonlibjson`.

You can use the ready-made [toncenter.com](https://toncenter.com) service or start your own instance.

## Building and running

Recommended hardware: 
- HTTP API only: 1 vCPU, 2 GB RAM.
- HTTP API with cache enabled: 2 vCPUs, 4 GB RAM.

There are two ways to run TON HTTP API:
- __Docker Compose__: works on any x86_64 and arm64 OS with Docker available.
- __Local__ *(experimental)*: works on following platforms: Ubuntu Linux (x86_64, arm64), MacOSX (Intel x86_64, Apple M1 arm64) and Windows (x86_64). 

### Docker Compose
  - (First time) Install required tools: `docker`, `docker-compose`, `curl`. 
    - For Ubuntu: run `scripts/setup.sh` from the root of the repo.
    - For MacOS and Windows: install [Docker Desktop](https://www.docker.com/products/docker-desktop/).
    - **Note:** we recommend to use Docker Compose V2.
  - Download TON configuration files to private folder:
    ```bash
    mkdir private
    curl -sL https://ton-blockchain.github.io/global.config.json > private/mainnet.json
    curl -sL https://ton-blockchain.github.io/testnet-global.config.json > private/testnet.json
    ```
  - Run `./configure.py` to create `.env` file with necessary environment variables (see [Configuration](#Configuration) for details).
  - Build services: `docker-compose build`.
  - Run services: `docker-compose up -d`.
  - Stop services: `docker-compose down`.

### Local run *(experimental)*
  - Go to `ton-http-api` folder from the root of the repo.
  - (First time) Install rependencies: `pip3 install -r requirements.txt`.
    - We recommend you to upgrade packages sometimes: `pip3 install -U -r requirements.txt`.
  - (Windows only, first time) Install OpenSSL v1.1.1 for win64 from [here](https://slproweb.com/products/Win32OpenSSL.html).
  - Run service with `uvicorn pyTON.main:app`. This command will run service with [mainnet](https://ton.org/global-config.json) configuration.
  - To change settings you can use environment variables (see [Configuration](#Configuration) section).
    

## Configuration

Configuration process is different in case of local and Docker run:

- In case of local run you can pass parameters using environment variables: 
  - Windows: run command `set variable=value` in CMD or `$env:variable = 'value'` in PowerShell. 
  - Linux and MacOS: run command `export variable=value` or path variable inplace: `variable=value uvicorn pyTON.main:app`.
- In case of Docker you should specify environment parameters and run `./configure.py` to create `.env` file.
    ```bash
    export TON_API_LITESERVER_CONFIG=private/testnet.json
    ./configure.py
    ```

The service supports the following environment variables for configuration:
#### Webserver settings
- `TON_API_HTTP_PORT` *(default: 80)*

  Port for HTTP connections of API service.

- `TON_API_ROOT_PATH` *(default: /)*

  If you use a proxy server such as Nginx or Traefik you might change the default API path prefix (e.g. `/api/v2`). If so you have to pass the path prefix to the API service in this variable.

- `TON_API_WEBSERVERS_WORKERS` *(default: 1)*

  Number of webserver processes. If your server is under high load try increase this value to increase RPS. We recommend setting it to number of CPU cores / 2.

- `TON_API_GET_METHODS_ENABLED` *(default: 1)*

  Enables `runGetMethod` endpoint.

- `TON_API_JSON_RPC_ENABLED` *(default: 1)*

  Enables `jsonRPC` endpoint.

- `TON_API_LOGS_JSONIFY` *(default: 0)*

  Enables printing all logs in json format.

- `TON_API_LOGS_LEVEL` *(default: ERROR)*

  Defines log verbosity level. Values allowed: `DEBUG`,`INFO`,`WARNING`,`ERROR`,`CRITICAL`.

#### Tonlib settings
- `TON_API_TONLIB_LITESERVER_CONFIG` *(default docker: private/mainnet.json local: https://ton.org/global-config.json)*

  Path to config file with lite servers information. In case of native run you can pass URL to download config. Docker support only path to file.

- `TON_API_TONLIB_KEYSTORE` *(default docker: /tmp/ton_keystore local: ./ton_keystore/)*
  
  Path to tonlib keystore.

- `TON_API_TONLIB_PARALLEL_REQUESTS_PER_LITESERVER` *(default: 50)*

  Number of maximum parallel requests count per worker.

- `TON_API_TONLIB_CDLL_PATH` *(default: empty)*

  Path to tonlibjson binary. It could be useful if you want to run service on unsupported platform and have built the `libtonlibjson` library manually.

- `TON_API_TONLIB_REQUEST_TIMEOUT` *(default: 10)*

  Timeout for liteserver requests.


#### Cache configuration
- `TON_API_CACHE_ENABLED` *(default: 0)*

  Enables caching lite server responses with Redis.

- `TON_API_CACHE_REDIS_ENDPOINT` *(default: localhost, docker: cache_redis)*

  Redis cache service host.

- `TON_API_CACHE_REDIS_PORT` *(default: 6379)*

  Redis cache service port.

- `TON_API_CACHE_REDIS_TIMEOUT` *(default: 1)*

  Redis cache service port.


## FAQ
#### How to point the service to my own lite server?

To point the HTTP API to your own lite server you should set `TON_API_TONLIB_LITESERVER_CONFIG` to config file with your only lite server.

- If you use MyTonCtrl on your node you can generate config file with these commands: 
    ```
    $ mytonctrl
    MyTonCtrl> installer
    MyTonInstaller> clcf
    ```
    Config file will be saved at `/usr/bin/ton/local.config.json`.
- If you don't use MyTonCtrl: copy `private/mainnet.json` and overwrite section `liteservers` with your liteservers ip, port and public key. To get public key from `liteserver.pub` file use the following script:
    ```
    python -c 'import codecs; f=open("liteserver.pub", "rb+"); pub=f.read()[4:]; print(str(codecs.encode(pub,"base64")).replace("\n",""))'
    ```
- Once config file is created assign variable `TON_API_TONLIB_LITESERVER_CONFIG` to its path, run `./configure.py` and rebuild the project.

#### How to run multiple API instances on single machine?

- Clone the repo as many times as many instances you need to the folders with different names (otherwise docker compose containers will conflict). 
- Configure each instance to use unique port (env variable `TON_API_HTTP_PORT`)
- Build and run every instance.

#### How to update tonlibjson library?

Binary file `libtonlibjson` now moved to [pytonlib](https://github.com/toncenter/pytonlib). 
- Docker Compose: `docker-compose build --no-cache`.
- Local run: `cd ton-http-api && pip install -U -r requirements.txt`.
