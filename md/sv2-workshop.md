---
marp: true
theme: sv2-workshop
---

![center](../img/sv2-logo.png)

# a step towards mining decentralization

---

Slides available at:
- [`github.com/plebhash/sv2-workshop`](`http://github.com/plebhash/sv2-workshop.git`): markdown source
- [`http://75.119.150.111:8888/html/sv2-workshop.html`](http://75.119.150.111:8888/html/sv2-workshop.html): hosted

SSID: `sv2-workshop`
Password: `proofofwork`

---

## Stratum V2: Specs

Can be read at [`stratumprotocol.org/specification`](http://stratumprotocol.org/specification)

Can be improved at [`github.com/stratum-mining/sv2-spec`](http://github.com/stratum-mining/sv2-spec)

---

## SV2 Roles

One of the main conceptual entity in SV2 is the notion of **Roles**.

They are involved in data flow and can be labeled as downstream or upstream in relationship to eachother.

---

## Pool

A Pool is where the hashrate produced by Mining Devies is consumed.

It is the most upstream role.

## Job Declarator Server (JDS)

Deployed on the Pool infrastructure.

It receives and manages the custom block templates (on behalf of the Pool) declared by Job Declarator Clients (JDCs).

---

## Template Provider (TP)

A custom `bitcoind` node which aims to be merged in Bitcoin Core ([PR #29432](https://github.com/bitcoin/bitcoin/pull/29432)).

Responsible for creation of Block Templates.

Deployed on both Pool and Miner infrastructure.

---

## Job Declarator Client (JDC)

Deployed on Miner infrastructure.

It creates new mining jobs from the templates received by the Template Provider and declares them to the JDS.

It's also able to automatically fallback to backup Pools in case of custom jobs refused by JDS (which is Pool side) or to switch to Solo Mining as a solution of last-resort.

## Translator Proxy (tProxy)

Responsible for translating the communication between SV1 Mining Devices and an SV2 Pool or Proxy.

It enables legacy SV1-only firmware to interact with SV2-based mining infrastructure.

---

## Stratum Reference Implementation (SRI)

Since 2020, a group of independent developers started to work on a fully open-source implementation of Stratum V2, called SRI (Stratum Reference Implementation).

The purpose of SRI group is to build, beginning from the SV2 specs, a community-based implementation, while discussing and cooperating with as many people of the Bitcoin community as possible.

The Rust codebase can be found at [`github.com/stratum-mining/stratum`](http://github.com/stratum-mining/stratum)

---

## SRI: Possible Configurations

Thanks to all these different roles and sub-protocols, SV2 can be used in many different mining contexts.

Today we are going to setup the **Config A**, referenced at [`stratumprotocol.org`](http://stratumprotocol.org/)

---

## Config A

Miner runs a **JDC**, and Pool runs a **JDS**.

Transactions are chosen by the **Miner's Template Provider**.

Mining Devices have legacy SV1 compatible firmware, connected to a **Translator Proxy**.

---

# Config A

![center w:600 h:400](../img/sri-config-d.png)

---

# Hands On!

---

Split in pairs. One will be the pool, the other will be the miner.

Instructions available at [`75.119.150.111:8888/html/sv2-workshop.html`](http://75.119.150.111:8888/html/sv2-workshop.html)

Start at slide 15

---

## Custom Signet

Which network should we do our workshop?

- `testnet3`? Well, Lopp broke it.
- `signet`? Well, we need the audience to be able to mine blocks.

- `testnet4`? Well, we want a controlled hashrate environment.

We will mine on a custom signet that does not require coinbase signatures. This way, the audience can deploy pools + hashers and emulate a confined hashrate environment.

---

## Prerequisites

### Clone SRI

```
cd $HOME
git clone https://github.com/stratum-mining/stratum
git checkout workshop
```

### Install Rust:
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

Or alternatively, just drop a `nix-shell` inside the `stratum` repository.

---

## Get a release from Sjors' Bitcoin Core fork

On Config A, both pool and miner run a Template Provider (`bitcoind`).

We will use `@Sjors`' fork.

Grab a release from https://github.com/plebhash/bitcoin/releases/tag/btc-prague


Or alternatively via `nix` (linux only, no darwin yet 😢):
```
cd $HOME
git clone https://github.com/plebhash/nix-bitcoin-core-archive
cd nix-bitcoin-core-archive/fork/sv2
nix-build
# the executables are available at `result/bin`
```

---

## Connect to Workshop Wifi

Connect to this WiFi:
- SSID: `sv2-workshop`
- Password: `proofofwork`

---

## Configure Template Provider

Create a workshop datadir for `bitcoind` (Template Provider).

```
mkdir $HOME/.bitcoin-sv2-workshop
```

Use this configuration file to connect to our workshop signet.

```
nano $HOME/.bitcoin-sv2-workshop/bitcoin.conf

[signet]
# OP_TRUE
signetchallenge=51
server=1
connect=75.119.150.111 # genesis node
rpcuser=username
rpcpassword=password
sv2port=8442
debug=rpc
debug=sv2
loglevel=sv2:debug
printtoconsole=1
```

---

## Start `bitcoind` Template Provider

assuming `$TP` is the path to `bitcoind`

```
cd bitcoin-sv2
$TP -datadir=$HOME/.bitcoin-sv2-workshop -signet -sv2
```

---

## Pool-only steps

Miners can jump to slide 26

---

## Create wallet (Pool)

assuming `$CLI` is the path to `bitcoin-cli`

```
cd bitcoin
$CLI -signet -datadir=$HOME/.bitcoin-sv2-workshop createwallet sv2-workshop
```

## Generate address (Pool)

assuming `$TP` is the path to `bitcoind`
```
$CLI -signet -datadir=$HOME/.bitcoin-sv2-workshop getnewaddress sv2-workshop-address
```

---

## Get pubkey (Pool)

```
$CLI -signet -datadir=$HOME/.bitcoin-sv2-workshop getaddressinfo <sv2-workshop-address>
```

⚠️ Take note of the `pubkey` value so you can use it on the next step, and also to check your mining rewards on mempool later.

---

## Add pubkey to coinbase config (Pool)

Edit `stratum/roles/jd-server/jds-config-sv2-workshop.toml` to add the `pubkey` from the previous step into `coinbase_outputs.output_script_value`.

---

### Add a Pool Signature

Edit `stratum/roles/pool/pool-config-sv2-workshop.toml` to make sure the `pool_signature` has some custom string to identify the pool in the coinbase of the blocks it mines.

⚠️ Take note of this string because all miners connected to you will need it for their own configs.

---

## Start the Pool Server (Pool)

On a new terminal:
```
cd stratum/roles/pool
cargo run -- -c pool-config-sv2-workshop.toml
```

## Start Job Declarator Server (Pool)

```
cd stratum/roles/jd-server
cargo run -- -c jds-config-sv2-workshop.toml
```


---

## Miner-only steps

---

## Edit JDC Config (Miner)

Ask for your **pool colleagues** for their IP in the `sv2-workshop` WiFi LAN.

Edit `stratum/roles/jd-client/jdc-config-sv2-workshop.toml` to make sure:
- `pool_address` and `jd_address` have their IP
- `pool_signature` is identical to what your pool colleague put on their config. Putting the wrong value here will result in your templates being rejected by JDS.

---

## Start Job Declarator Client (Miner)

```
cd stratum/roles/jd-client
cargo run -- -c jdc-config-sv2-workshop.toml
```

## start Translator Proxy (Miner)

On a new terminal:
```
cd stratum/roles/translator
cargo run -- -c tproxy-config-sv2-workshop.toml
```

---

## Start CPU mining

Setup the correct CPUMiner for your OS.

- downloadable binaries: [`https://sourceforge.net/projects/cpuminer/files/`](https://sourceforge.net/projects/cpuminer/files/)
- buildable source: [`https://github.com/pooler/cpuminer`](https://github.com/pooler/cpuminer)
- nix: `nix-shell -p cpuminer`

To start mining:

```
minerd -a sha256d -o stratum+tcp://localhost:34255 -q -D -P
```

---

## Supporters

![center w:600 h:400](../img/supporters.png)

---

![center w:240 h:180](../img/sv2-logo.png)
<br>
# Q&A 

 

---

# Thank you