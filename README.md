# sv2-workshop
This repository contains materials for a [StratumV2 Reference Implementation](https://github.com/stratum-mining/stratum) workshop.

* For detailed instructor setup instructions see [docs/setup.md](https://github.com/stratum-mining/sv2-workshop/blob/main/docs/setup.md).

## Quick Start

### Slides
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

Serve the slides:
```
python3 -m http.server 8888
```

### Custom Signet
This workshop uses a custom `signet` for the following reasons:

- We want a confined hashrate environment, so `mainnet`, `testnet3`, `testnet4` and the public `signet` are ill suited.
- `regtest` is too isolated and requires manual block generation, which is not practical for a collaborative workshop setting.
- We will mine on a custom `signet` that does not require coinbase signatures.
- This way, we can deploy pools + hashers and emulate a confined hashrate environment.

Participants will connect to this Genesis node to sync their blocks.
The Genesis node is configured via the [materials/signet-genesis-node.sh](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/signet-genesis-node.sh).

This script:
* Deploys a local signet using the [`bitcoin.conf`](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/genesis-bitcoin.conf).
* Mines 16 blocks as bootstrapping for the SRI pool.

Before executing the script, ensure the following environment variables are defined:

```sh
$ export BITCOIND=$HOME/bitcoin/src/bitcoind
$ export BITCOIN_CLI=$HOME/bitcoin/src/bitcoin-cli
$ export BITCOIN_UTIL=$HOME/bitcoin/src/bitcoin-util
$ export MINER=$HOME/bitcoin/contrib/signet/miner
$ export BITCOIN_DATA_DIR=$HOME/.bitcoin
```

# Blockchain Explorer

In order to allow the audience to explore the blockchain, it's also recommended to provide a blockchain explorer.

The steps for deploying a local `mempool.space` have not yet been automated, so they need to be performed manually.

First, clone and start `electrs`:
```
$ git clone https://github.com/romanz/electrs
$ cd electrs
$ git checkout v0.10.5
$ cat << EOF > electrs.toml
network="signet"
auth="mempool:mempool"
EOF
$ cargo run -- --signet-magic=54d26fbd
```

Then, clone `mempool`:
```
$ git clone https://github.com/mempool/mempool
$ cd mempool
$ git checkout v2.5.0
```

We are going to use the docker deployment, so we need to adjust some configs.
```diff
diff --git a/docker/docker-compose.yml b/docker/docker-compose.yml
index 68e73a1c8..98fa6a174 100644
--- a/docker/docker-compose.yml
+++ b/docker/docker-compose.yml
@@ -14,9 +14,12 @@ services:
       - 80:8080
   api:
     environment:
-      MEMPOOL_BACKEND: "none"
+      MEMPOOL_BACKEND: "electrum"
+      ELECTRUM_HOST: "172.27.0.1"
+      ELECTRUM_PORT: "50002"
+      ELECTRUM_TLS_ENABLED: "false"
       CORE_RPC_HOST: "172.27.0.1"
-      CORE_RPC_PORT: "8332"
+      CORE_RPC_PORT: "38332"
       CORE_RPC_USERNAME: "mempool"
       CORE_RPC_PASSWORD: "mempool"
       DATABASE_ENABLED: "true"
```

From the `docker` directory, you can start it via:
```
$ docker-compose up
```
