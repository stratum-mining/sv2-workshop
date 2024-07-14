# Setup Instruction Manual

These instructions cover the setup required for the instructor running the Stratum V2 workshop.

1. Configuring and hosting the slides to be accessible by the participants.
2. Configuring a publicly accessible Genesis node for participants to sync their nodes.
3. Configuring the block explorer to display participants' mined blocks.

## Slides

### Config
The `html/index.html` is built with [`marp`](https://marp.app/), is based on the
[`md/sv2-workshop.md`](https://github.com/stratum-mining/sv2-workshop/blob/main/md/sv2-workshop.md)
file, and is committed to this repo.

If changes are made to the `md/sv2-workshop.md` slides, update the `html/index.html` with
[`marp`](https://marp.app/) in the repo's root:

```sh
marp md/sv2-workshop.md -o html/sv2-workshop.html --theme-set css/sv2-workshop.css
```

Or, if using `nix`, run:

```sh
nix run github:tweag/nix-marp -- md/sv2-workshop.md -o html/sv2-workshop.html --theme-set css/sv2-workshop.css
```

Restart the `python` server and reload the page to view the updates.

### Run
The slides are served via:

```sh
python3 -m http.server 8888
```

To make the slides accessible on the SRI VM for participants to view on their machines:

1. Remote into the SRI VM.
2. Create a new `tmux` session.
3. `cd ~/sv2-workshop`.
4. Make sure the correct `workshop` branch (or branch of your choosing) is checked out.
5. Run the HTTP server.

> Note: This can be done on any machine, however the slides specifically point the user to the SRI
VM URL. If you choose to host the slides on another machine, remember to update the slides with the
update endpoint.

## `bitcoin-core`

### Purpose
A Bitcoin node is needed for:
1. Syncing participants' Bitcoin nodes with a Genesis node.
2. Running a block explorer to view mined blocks.

### Install
There are two ways to install the required `bitcoin-core` fork:

1. Release Binary: [Plebhash's fork of Sjors's sv2-tp-0.1.3 tag](https://github.com/plebhash/bitcoin/releases/tag/btc-prague).
2. Build from Source: [Sjors's `sv2-tp-0.1.3` tag](https://github.com/Sjors/bitcoin/tree/sv2-tp-0.1.3):

```sh
git clone https://github.com/Sjors/bitcoin.git
cd bitcoin
git fetch --all
git checkout sv2-tp-0.1.3
./autogen.sh
./configure --disable-tests --disable-bench --enable-wallet --with-gui=no
make  # or `make -j <num cores>`
```

> Note: For mac users, it is highly recommended to build from source.

### Config

#### Genesis Node
The Genesis node should be configured via the [materials/signet-genesis-node.sh](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/signet-genesis-node.sh).

Before executing the script, ensure the following environment variables are defined:

```sh
$ export BITCOIND=$HOME/bitcoin/src/bitcoind
$ export BITCOIN_CLI=$HOME/bitcoin/src/bitcoin-cli
$ export BITCOIN_UTIL=$HOME/bitcoin/src/bitcoin-util
$ export MINER=$HOME/bitcoin/contrib/signet/miner
$ export BITCOIN_DATA_DIR=$HOME/.bitcoin
```

This script:
- Deploys a local signet.
- Mines 16 blocks as bootstrapping for the SRI pool.

A Genesis node that is publicly accessible is needed for participants to sync their Bitcoin nodes. This can be set up by the instructor or use the existing SRI VM node.

Verify the node is running:

```sh
ps -ef | grep -i bitcoind
> sri 3935787 1 0 Jun29 ? 01:19:13 /home/sri/btc_prague_workshop/bitcoin/src/bitcoind -signet -datadir=/home/sri/btc_prague_workshop/bitcoin_data_dir/ -fallbackfee=0.01 -daemon -sv2 -sv2port=38442
```

Ensure the `bitcoin.conf` in the `datadir` contains:

```conf
[signet]
signetchallenge=51    # OP_TRUE
prune=0
txindex=1
server=1
rpcallowip=0.0.0.0/0
rpcbind=0.0.0.0
rpcuser=mempool
rpcpassword=mempool
rpcport=38332
```

#### Block Explorer Node
A `signet` block explorer is needed to display participants' mined blocks.

> Note: The Genesis node can also be used for this purpose. A second Bitcoin node for the block
explorer only is needed if the instructor is running the block explorer on another machine (like
their local machine).


Ensure the `bitcoin.conf` in the `datadir` contains:

```
[signet]
signetchallenge=51      # OP_TRUE
prune=0
txindex=1
server=1
connect=75.119.150.111  # Genesis Node
rpcallowip=0.0.0.0/0
rpcbind=0.0.0.0
rpcuser=mempool
rpcpassword=mempool
```

Run the Bitcoin node:

```sh
bitcoind -datadir=$HOME/.bitcoin-sv2-workshop -signet -sv2
```

## `electrs`

### Install
Clone and configure:

```sh
git clone https://github.com/romanz/electrs
cd electrs
git checkout v0.10.5
cat << EOF > electrs.toml
network="signet"
auth="mempool:mempool"
EOF
```

### Run
Run the server:

```sh
cargo run -- --signet-magic=54d26fbd
```

## `mempool.space`

### Install
Clone the repository:

```sh
git clone https://github.com/mempool/mempool
cd mempool
git checkout v2.5.0
```

### Config
Update `mempool/docker/docker-compose.yaml`:

```sh
git diff docker/docker-compose.yml
diff --git a/docker/docker-compose.yml b/docker/docker-compose.yml
index 68e73a1c8..300aa3d80 100644
--- a/docker/docker-compose.yml
+++ b/docker/docker-compose.yml
@@ -14,9 +14,12 @@ services:
       - 80:8080
   api:
     environment:
-      MEMPOOL_BACKEND: "none"
+      MEMPOOL_BACKEND: "electrum"
+      ELECTRUM_HOST: "host.docker.internal"  # or the IP address of the Electrum server
+      ELECTRUM_PORT: "60601"  # match this with the port on which electrs is listening
+      ELECTRUM_TLS_ENABLED: "false"
-      CORE_RPC_HOST: "172.27.0.1"
+      CORE_RPC_HOST: "host.docker.internal"
-      CORE_RPC_PORT: "8332"
+      CORE_RPC_PORT: "38332"
       CORE_RPC_USERNAME: "mempool"
       CORE_RPC_PASSWORD: "mempool"
       DATABASE_ENABLED: "true"
```

### Run
```sh
docker-compose up
```
