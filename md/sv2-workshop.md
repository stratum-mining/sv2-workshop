---
marp: true
theme: sv2-theme
---

<style scoped>
h1 {
  text-align: center;
}
</style>

![center](../img/sv2-logo.png)

# A step towards mining decentralization.

---

Slides available at

http://185.130.45.51:8888/html/sv2-workshop.html

---

## Workshop support

Supported OSs:
- Linux (vanilla distros, if you're on an exotic distro, good luck!)
- MacOS

Non-supported OSs:
- Windows (you might still try, but we didn't test it!)

Supported archs:
- x86-64
- arm64

---

## Software pre-requisites

1. Rust
2. capnproto
3. sv2-apps repository
4. cpuminer

---

## Rust

If you don't already have it, make sure you have Rust installed:
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

## capnproto

This is a pre-requisite for building SRI crates.

On ubuntu:
```
sudo apt-get install capnproto libcapnp-dev
```

On macOS:
```
brew install capnp
```

---

## Stratum V2: Specs

Can be read at [`stratumprotocol.org/specification`](http://stratumprotocol.org/specification)

Can be improved at [`github.com/stratum-mining/sv2-spec`](http://github.com/stratum-mining/sv2-spec)

---

## SV2 Roles

One of the main conceptual entity in SV2 is the notion of **Roles**.

They are involved in data flow and can be labeled as downstream or upstream in relationship to eachother.

---

## Template Provider (TP)

(Usually) a Bitcoin Core node, responsible for creation of Block Templates.

Deployed on both Pool and Miner infrastructure.

On this workshop specifically, we're going to use a Bitcoin Core node. It will connect to the other Sv2 roles via IPC over a UNIX socket.

---

## Pool

A Pool is where the hashrate produced by Mining Devices is consumed.

It is the most upstream role.

## Job Declarator Server (JDS)

Deployed on the Pool infrastructure.

It receives and manages the custom block templates (on behalf of the Pool) declared by Job Declarator Clients (JDCs).

---

## Job Declarator Client (JDC)

Deployed on Miner infrastructure.

It creates new mining jobs from the templates received by the Template Provider and declares them to the JDS.

It's also able to automatically fallback to backup Pools in case of custom jobs refused by JDS (which is Pool side) or to switch to Solo Mining as a solution of last-resort.

## Translator Proxy (tProxy)

Responsible for translating the communication between SV1 Mining Devices and an SV2 Pool or Proxy.

It enables legacy SV1-only firmware to interact with SV2-based mining infrastructure.

---

Miner runs a **JDC**, and Pool runs a **JDS**.

Transactions are chosen by the **Miner's Template Provider**.

Mining Devices have legacy SV1 compatible firmware, connected to a **Translator Proxy**.

---

![center w:600 h:400](../img/sri-config-d.png)

---

# Hands On!

---

Split in pairs. One will be the pool, the other will be the miner.

Instructions available at http://185.130.45.51:8888/html/sv2-workshop.html

---

## Custom Signet

Which network should we do our workshop?

- `testnet3`? Well, Lopp broke it.
- `signet`? Well, we need the audience to be able to mine blocks.
- `testnet4`? Well, we want a controlled hashrate environment.

We will mine on a custom signet that does not require coinbase signatures. This way, the audience can deploy pools + hashers and emulate a confined hashrate environment.

---

## Connect to Workshop Wifi

Connect to this WiFi:
- SSID: `sv2-workshop`
- Password: `proofofwork`

---

## Download Bitcoin Core

Download v30 from https://bitcoincore.org/en/download/

Note: if you're on macOS, make sure you get the `.tar.gz`, and not `.zip`!

```
wget https://bitcoincore.org/bin/bitcoin-core-30.0/bitcoin-30.0-<arch>-<OS>.tar.gz
tar xvf bitcoin-30.0-<arch>-<OS>.tar.gz
```

---

## Configure Bitcoin Core

Edit the `bitcoin.conf` on the default path of your system:
- macOS: `/Users/<username>/Library/Application Support/Bitcoin/bitcoin.conf`
- linux: `/home/<username>/.bitcoin/bitcoin.conf`

```conf
[signet]
# OP_TRUE
signetchallenge=51
server=1
connect=185.130.45.51 # genesis node
rpcuser=username
rpcpassword=password
rpcbind=0.0.0.0
rpcallowip=0.0.0.0/0
```

---

## Start Bitcoin Core

```sh
./bitcoin-30.0/bin/bitcoin -m node -ipcbind=unix -signet
```

Wait for IBD, but you can still navigate the following slides while you wait.

---

## Navigate `mempool.space`

There's a `mempool.space` block explorer available at:

http://185.130.45.51:8080/

---

## Clone sv2-apps

```sh
git clone https://github.com/stratum-mining/sv2-apps -b mauritius-25-workshop
```

---

## Pool-only steps

Miners can jump to slide 28.

---

On a new terminal:

## Create wallet (Pool)

```
./bitcoin-30.0/bin/bitcoin-cli -signet createwallet sv2-workshop
```

## Generate address (Pool)

```
./bitcoin-30.0/bin/bitcoin-cli -signet getnewaddress sv2-workshop-address
```

---

## Edit JDS config file

only these fields, do not touch the other ones:

```
...
coinbase_reward_script = "addr(your_wallet_address)" # paste the address generated via bitcoin-cli inside the addr()
...
```
---

## Launch JDS

```
cd pool-apps/jd-server
cargo run -- -c config-examples/jds-config.toml
```

---

## Edit Pool config file

only these fields, do not touch the other ones:
```
...
coinbase_reward_script = "addr(your_wallet_address)" # paste the address generated via bitcoin-cli inside the addr()
...
# Bitcoin Core IPC config
# on linux, this is probably: /home/<username>/.bitcoin/signet/node.sock
# on macOS, this is probably: /Users/<username>/Library/Application Support/Bitcoin/signet/node.sock
[template_provider_type.BitcoinCoreIpc]
unix_socket_path = "/path/to/node.sock" # <---- this line
```

---

## Launch Pool

```
cd pool-apps/pool
cargo run -- -c config-examples/pool-config.toml
```

---

## Miner-only steps

---

Ask for your **pool colleagues** for their IP in the `sv2-workshop` WiFi LAN.

---

## Edit JDC config file

only these fields, do not touch the other ones:
```
...
# string to be added into the Coinbase scriptSig
jdc_signature = "your_miner_signature"
...
pool_address = "X.Y.Z.W" # IP address you took from a pool colleague
...
jds_address = "X.Y.Z.W" # IP address you took from a pool colleague
...
# Bitcoin Core IPC config
# on linux, this is probably: /home/<username>/.bitcoin/signet/node.sock
# on macOS, this is probably: /Users/<username>/Library/Application Support/Bitcoin/signet/node.sock
[template_provider_type.BitcoinCoreIpc]
unix_socket_path = "/path/to/node.sock" # <---- this line
...
```

---

## Launch JDC

```
cd miner-apps/jd-client
cargo run -- -c config-examples/jdc-config.toml 
```

---

## Launch tProxy

```
cd miner-apps/translator
cargo run -- -c config-examples/tproxy-config.toml
```

---

## CPU miner

Download a release for your platform from:

https://github.com/stratum-mining/cpuminer/releases/tag/v2.5.1

---

## Start CPU mining

```sh
./minerd -a sha256d -o stratum+tcp://localhost:34255 -q -D -P -t 1
```

---

![center w:240 h:180](../img/sv2-logo.png)
<br>
# Q&A 

---

# Thank you
