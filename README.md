# sv2-workshop
This repository contains materials for a [StratumV2 Reference Implementation](https://github.com/stratum-mining/stratum) workshop.

* For useful materials see the [materials/](https://github.com/stratum-mining/sv2-workshop/blob/main/materials) directory.

These instructions cover the setup required for the instructor running the Stratum V2 workshop.

1. Configuring and hosting the slides to be accessible by the participants.
2. Configuring a publicly accessible Genesis node for participants to sync their nodes.
3. Configuring the block explorer to display participants' mined blocks.
4. Setting up a reproducible build for participants using Docker.

## Slides

### Config
Files under `html` directory are built with [`marp`](https://marp.app/), based on the files under `md`.

```sh
marp md/sv2-workshop.md -o html/sv2-workshop.html --theme-set css/sv2-theme.css
marp md/sv2-intro.md -o html/sv2-intro.html --theme-set css/sv2-theme.css
```

Or, if using `nix`, run (assuming nix flakes are available):

```sh
nix run github:tweag/nix-marp -- md/sv2-workshop.md -o html/sv2-workshop.html --theme-set css/sv2-theme.css
nix run github:tweag/nix-marp -- md/sv2-intro.md -o html/sv2-intro.html --theme-set css/sv2-theme.css
```

### Run
Serve the slides:

```sh
python3 -m http.server 8888
```

To make the slides accessible on the SRI VPS for participants to view on their machines:

1. Remote into the SRI VPS.
2. Create a new `tmux` session.
3. `cd ~/sv2-workshop`.
4. Make sure the correct `workshop` branch (or branch of your choosing) is checked out.
5. Run the HTTP server.

> Note: This can be done on any machine, however the slides specifically point the user to the SRI
VPS URL. If you choose to host the slides on another machine, remember to update the slides with the
update endpoint.

## Custom Signet
This workshop uses a custom `signet` for the following reasons:

- We want a confined hashrate environment, so `mainnet`, `testnet3`, `testnet4` and the public `signet` are ill suited.
- `regtest` is too isolated and requires manual block generation, which is not practical for a collaborative workshop setting.
- We will mine on a custom `signet` that does not require coinbase signatures.
- This way, we can deploy pools + hashers and emulate a confined hashrate environment.

Participants will connect to this Genesis node to sync their blocks.

### Genesis Node
The instructor can use the existing Genesis node hosted on the SRI VPS, or spin up their own. The
Genesis node should be configured via the [materials/signet-genesis-node.sh](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/signet-genesis-node.sh) script which:

* Deploys a local signet.
* Mines 16 blocks as bootstrapping for the SRI pool.

Before executing the script, ensure the following environment variables are defined on `materials/env.sh`:

- `$BITCOIND`: path to `bitcoind`
- `$BITCOIN_CLI`: path to `bitcoin-cli`
- `$BITCOIN_UTIL`: path to `bitcoin-util`
- `$MINER`: path to `miner`, usually `bitcoin/contrib/signet/miner`
- `$BITCOIN_DATA_DIR`: path to bitcoin data dir

#### SRI Node
A Genesis node that is publicly accessible is needed for participants to sync their Bitcoin nodes.
This can be set up by the instructor or use the existing SRI VPS node.

If using the SRI hosted Genesis node, verify it is running by remoting into the SRI VPS and finding
its process:

```sh
ps -ef | grep -i bitcoind
> sri 3935787 1 0 Jun29 ? 01:19:13 /home/sri/btc_prague_workshop/bitcoin/src/bitcoind -signet -datadir=/home/sri/btc_prague_workshop/bitcoin_data_dir/ -fallbackfee=0.01 -daemon -sv2 -sv2port=38442
```

If spinning up a new node, see the instructions to install `bitcoin-core` in the Block Explorer
section below.

## Block Explorer
A block explorer is needed to display participants' mined blocks on the custom `signet`. A custom
`signet` Bitcoin node, [`electrs`](https://github.com/romanz/electrs), and
[`mempool.space`](https://github.com/mempool/mempool) is used for this purpose.

> Note: The steps for deploying a local `mempool.space` have not yet been automated and will need to
be performed manually.

> Note: The Genesis node can also be used for this purpose. A second Bitcoin node for the block
explorer only is needed if the instructor is running the block explorer on another machine (like
their local machine).

> Note: The steps documented here have only been tested on an Ubuntu environment. It will likely not work
> properly on different environments (e.g.: MacOS).

### Custom Signet `bitcoin-core`

#### Install
Install the required `bitcoin-core` fork by building from
[Sjors's `sv2-tp-0.1.9` tag](https://github.com/Sjors/bitcoin/tree/sv2-tp-0.1.9):

  ```sh
  git clone https://github.com/Sjors/bitcoin.git
  cd bitcoin
  git fetch --all
  git checkout sv2-tp-0.1.9
  cmake -B build
  cmake --build build  # use "-j N" for N parallel jobs
  ```

#### Config
Ensure the [`bitcoin.conf`](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/block-explorer-bitcoin.conf)
in the `datadir` contains:

```conf
[signet]
signetchallenge=51      # OP_TRUE
prune=0
txindex=1
server=1
connect=185.130.45.51  # Genesis Node
rpcallowip=0.0.0.0/0
rpcbind=0.0.0.0
rpcuser=mempool
rpcpassword=mempool
```

#### Run
Add the Bitcoin binaries to `$PATH`:
```sh
echo 'export PATH="$HOME/bitcoin/src:$PATH"' >> ~/.bashrc && export PATH="$HOME/bitcoin/src:$PATH"
```

Start the Bitcoin node:

```sh
bitcoind -datadir=$HOME/.bitcoin-sv2-workshop -signet -sv2
```

### `electrs`

#### Install
Clone, checkout the `v0.10.5` branch, and configure:

```sh
git clone https://github.com/romanz/electrs
cd electrs
git checkout v0.10.5
cat << EOF > electrs.toml
network="signet"
auth="mempool:mempool"
EOF
```

#### Run
Run the server:

```sh
cargo run -- --signet-magic=54d26fbd
```

### `mempool.space`

#### Install
Clone and checkout the `v3.0.0` branch:

```sh
git clone https://github.com/mempool/mempool
cd mempool
git checkout v3.0.0
```

#### Config
The Docker deployment requires some adjustments to the `docker/docker-compose.yml`.

You can automate these adjustments by:
- creating a `sv2-workshop.patch` file with the content below
- running `git apply sv2-workshop.patch` inside the `mempool` repo directory.

```sh
diff --git a/docker/docker-compose.yml b/docker/docker-compose.yml
index 4e1094306..a47388f8e 100644
--- a/docker/docker-compose.yml
+++ b/docker/docker-compose.yml
@@ -11,12 +11,15 @@ services:
     stop_grace_period: 1m
     command: "./wait-for db:3306 --timeout=720 -- nginx -g 'daemon off;'"
     ports:
-      - 80:8080
+      - 8080:8080
   api:
     environment:
-      MEMPOOL_BACKEND: "none"
-      CORE_RPC_HOST: "172.27.0.1"
-      CORE_RPC_PORT: "8332"
+      MEMPOOL_BACKEND: "electrum"
+      ELECTRUM_HOST: "host.docker.internal"
+      ELECTRUM_PORT: "60601"
+      ELECTRUM_TLS_ENABLED: "false"
+      CORE_RPC_HOST: "host.docker.internal"
+      CORE_RPC_PORT: "38332"
       CORE_RPC_USERNAME: "mempool"
       CORE_RPC_PASSWORD: "mempool"
       DATABASE_ENABLED: "true"
@@ -30,6 +33,8 @@ services:
     restart: on-failure
     stop_grace_period: 1m
     command: "./wait-for-it.sh db:3306 --timeout=720 --strict -- ./start.sh"
+    extra_hosts:
+      - "host.docker.internal:host-gateway"
     volumes:
       - ./data:/backend/cache
   db:
```

#### Run
Start the Docker container:

```sh
cd docker
docker compose up
```

Navigate to the machine's URL at port 8080.

## Docker Build For Participants
The [`materials/Dockerfile`](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/Dockerfile)
contain the Docker image with the following installed, configured, and built:

1. [Sjors's `sv2-tp-0.1.9`](https://github.com/Sjors/bitcoin/tree/sv2-tp-0.1.9): Used for the Pool and Miner Roles.
2. [`cpuminer` `v2.5.1`](https://github.com/pooler/cpuminer/releases/tag/v2.5.1): Used as hasher for the Miner Role.
3. [`stratum` - `workshop` branch](https://github.com/stratum-mining/stratum/tree/workshop): The `roles/` crates are used to run the Pool and Miner Roles.

To support participants opening multiple terminal sessions, `tmux` is used. A `tmux.conf` is
instantiated by the Docker image with the [`materials/setup-tmux.sh`](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/tmux-setup.sh).
This `tmux.conf` will allow users to navigate between `tmux` panes with a mouse click and also
includes a few more customizations for ease of use.


### Build/Update Docker Image (Instructor Only)

> Note: This is connected to the `rrybarczyk` Docker Hub account and should eventually be
  transferred to a SRI Docker Hub account.

### Local Build and Run
Build the image for both AMD64 and ARM architectures then run the image locally:

```sh
cp materials/setup-tmux.sh /usr/local/bin/setup-tmux.sh
docker buildx build --platform linux/amd64,linux/arm64 -t sv2-workshop:latest .
docker run -it --rm sv2-workshop:latest
```

For a faster local build time, use:
```sh
docker build -t sv2-workshop:latest .
```

### Production Docker Hub
Initial setup request login and establishing the tag (after locally building):

```sh
docker login
docker tag sv2-workshop:latest rrybarczyk/sv2-workshop:latest
```

Push to [Docker Hub](https://hub.docker.com/r/rrybarczyk/sv2-workshop):

```sh
docker push rrybarczyk/sv2-workshop:latest
```

A single command to build and push to [Docker Hub](https://hub.docker.com/r/rrybarczyk/sv2-workshop):

```sh
docker buildx build --platform linux/amd64,linux/arm64 -t rrybarczyk/sv2-workshop:latest --push .
```
