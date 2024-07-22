# sv2-workshop
This repository contains materials for a [StratumV2 Reference Implementation](https://github.com/stratum-mining/stratum) workshop.

* For useful materials see the [materials/](https://github.com/stratum-mining/sv2-workshop/blob/main/materials) directory.

These instructions cover the setup required for the instructor running the Stratum V2 workshop.

1. Configuring and hosting the slides to be accessible by the participants.
2. Configuring a publicly accessible Genesis node for participants to sync their nodes.
3. Configuring the block explorer to display participants' mined blocks.

## Slides

### Config
The `html/index.html` is built with [`marp`](https://marp.app/) and is based on the
[`md/sv2-workshop.md`](https://github.com/stratum-mining/sv2-workshop/blob/main/md/sv2-workshop.md)
file, and is committed to this repo.
To generate the `html/index.html` file on changes to `sv2-workshop.md`, install `marp` on your
system and run:

```sh
marp md/sv2-workshop.md -o html/sv2-workshop.html --theme-set css/sv2-workshop.css
```

Or, if using `nix`, run (assuming nix flakes are available):

```sh
nix run github:tweag/nix-marp -- md/sv2-workshop.md -o html/sv2-workshop.html --theme-set css/sv2-workshop.css
```

### Run
Serve the slides:

```sh
python3 -m http.server 8080
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

## Custom Signet
This workshop uses a custom `signet` for the following reasons:

- We want a confined hashrate environment, so `mainnet`, `testnet3`, `testnet4` and the public `signet` are ill suited.
- `regtest` is too isolated and requires manual block generation, which is not practical for a collaborative workshop setting.
- We will mine on a custom `signet` that does not require coinbase signatures.
- This way, we can deploy pools + hashers and emulate a confined hashrate environment.

Participants will connect to this Genesis node to sync their blocks.

### Genesis Node
The instructor can use the existing Genesis node hosted on the SRI VM, or spin up their own. The
Genesis node should be configured via the [materials/signet-genesis-node.sh](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/signet-genesis-node.sh) script which:

* Deploys a local signet.
* Mines 16 blocks as bootstrapping for the SRI pool.

Before executing the script, ensure the following environment variables are defined:

```sh
$ export BITCOIND=$HOME/bitcoin/src/bitcoind
$ export BITCOIN_CLI=$HOME/bitcoin/src/bitcoin-cli
$ export BITCOIN_UTIL=$HOME/bitcoin/src/bitcoin-util
$ export MINER=$HOME/bitcoin/contrib/signet/miner
$ export BITCOIN_DATA_DIR=$HOME/.bitcoin
```

#### SRI Node
A Genesis node that is publicly accessible is needed for participants to sync their Bitcoin nodes.
This can be set up by the instructor or use the existing SRI VM node.

If using the SRI hosted Genesis node, verify it is running by remoting into the SRI VM and finding
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

### Custom Signet `bitcoin-core`

#### Install
Install the required `bitcoin-core` fork by building from
[Sjors's `sv2-tp-0.1.3` tag](https://github.com/Sjors/bitcoin/tree/sv2-tp-0.1.3):

  ```sh
  git clone https://github.com/Sjors/bitcoin.git
  cd bitcoin
  git fetch --all
  git checkout sv2-tp-0.1.3
  ./autogen.sh
  ./configure --disable-tests --disable-bench --enable-wallet --with-gui=no
  make  # or `make -j <num cores>`
  ```

Or alternatively via `nix`:
  ```sh
  git clone https://github.com/plebhash/nix-bitcoin-core-archive
  cd nix-bitcoin-core-archive/fork/sv2
  nix-build   # the executables are available at `result/bin`
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
connect=75.119.150.111  # Genesis Node
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
Clone and checkout the `v2.5.0` branch:

```sh
git clone https://github.com/mempool/mempool
cd mempool
git checkout v2.5.0
```

#### Config
The docker deployment is used with the following adjustments to the `docker/docker-compose.yml`:

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

#### Run
Start the docker container:

```sh
docker-compose up
```

Navigate to the exposed `localhost` endpoint.
