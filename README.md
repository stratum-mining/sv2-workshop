This repository contains materials for a [StratumV2 Reference Implementation](https://github.com/stratum-mining/stratum) workshop.

# Slides
Slides leverage [`marp`](https://marp.app/). They are compiled from `md` to `html` via `marp.sh` (which assumes nix flakes are available on your system).

The slides can be served via:
```
cd html
python3 -m http.server 8888
```

# Custom Signet
Which network should we do our workshop?

- `testnet3`? Well, [Lopp broke it](https://blog.lopp.net/griefing-bitcoin-testnet/).
- `signet`? Well, we need the audience to be able to mine blocks.
- `testnet4`? Well, we want a controlled hashrate environment.

Therefore, this workshop is based on a custom signet that does not require coinbase signatures. This way, the audience can deploy pools + hashers and emulate a confined hashrate environment.

The `signet_genesis_node.sh` is responsible for:
- Deploy a local signet.
- Mine 16 blocks as bootstrapping for the SRI pool.

In order to use this script, you should first export some environment variables. For example:
```
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