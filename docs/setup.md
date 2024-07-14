# Setup Instruction Manual

These instructions cover the setup required for the instructor running the Stratum V2 workshop.

1. Configuring a publicly accessible Genesis node for participants to sync their nodes.
2. Configuring the block explorer to display participants' mined blocks.
3. Making the slides accessible by the participants.

## Software Compatibility
* `bitcoin-core`:
  * Source: [Sjors's `sv2-tp-0.1.3` tag](https://github.com/Sjors/bitcoin/tree/sv2-tp-0.1.3).
  * Release Binary: [Plebhash's fork of Sjors's sv2-tp-0.1.3 tag](https://github.com/plebhash/bitcoin/releases/tag/btc-prague).
* `cpuminer` `v2.5.1`: [GitHub release](https://github.com/pooler/cpuminer/releases/tag/v2.5.1).
* `stratum` - `workshop` branch: [GitHub repo](https://github.com/stratum-mining/stratum/tree/workshop).

## `bitcoin-core`

### Purpose
A Bitcoin node is needed for:
1. Syncing participants' Bitcoin nodes with a Genesis node.
2. Running a block explorer to view mined blocks.

### Install
There are two ways to install the required `bitcoin-core` fork:

1. Download and extract the binary from [Plebhash's fork](https://github.com/plebhash/bitcoin/releases/tag/btc-prague).
2. Clone and build from Sjors's source:

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

## Host Slides
To make the slides accessible on the SRI VM for participants to view on their machines:

1. Remote into the SRI VM.
2. Create a new `tmux` session.
3. `cd ~/sv2-workshop`.
4. `python -m http.server 8888`.

> Note: This can be done on any machine, however the slides specifically point the user to the SRI
VM URL. If you choose to host the slides on another machine, remember to update the slides.
