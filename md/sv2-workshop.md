---
marp: true
theme: sv2-workshop
---

![center](../img/sv2-logo.png)

# A step towards mining decentralization.

---

Slides available at

http://75.119.150.111:8888/html/sv2-workshop.html

---

## Prerequisites
The required programs are:
1. `bitcoin-core` fork with Sv2 support.
2. `stratum` repo with roles logic.
3. `cpuminer` to act as a hasher (miner) (Miner Role only).

There are two ways to get setup:
1. With a Docker image that contains all the required packages and programs (recommended).
2. By manually installing the required packages and programs.

---

## Method 1: Docker (Recommended)
1. Install [Docker](https://docs.docker.com/engine/install/).
2. Configure Docker with the following minimum resource allocations:
    - CPU limit: 4
    - Memory limit: 8GB
    - Swap: 2GB
    - Virtual disk limit: 128 GB
3. Run the image:
    ```sh
    docker pull rrybarczyk/sv2-workshop:latest
    docker run -it --rm rrybarczyk/sv2-workshop:latest
    ```
---

## Method 2: Manual
1. Install Rust
    ```sh
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    ```
2. Clone & Build SRI:
    ```
    cd $HOME
    git clone https://github.com/stratum-mining/stratum
    cd stratum
    git checkout workshop
    ```
---

## Method 2: Manual (continued)
3. Install the required `bitcoin-core` fork via one of the following options:

- Download the release binary [Sjors's `sv2-tp-0.1.3` tag](https://github.com/Sjors/bitcoin/releases/tag/sv2-tp-0.1.3) (not recommended for Mac).
- Build from [Sjors's `sv2-tp-0.1.3` tag](https://github.com/Sjors/bitcoin/tree/sv2-tp-0.1.3):
    ```sh
    git clone https://github.com/Sjors/bitcoin.git
    cd bitcoin
    git fetch --all
    git checkout sv2-tp-0.1.3
    ./autogen.sh
    ./configure --disable-tests --disable-bench --enable-wallet --with-gui=no
    make  # or `make -j <num cores>`
    ```
- `nix`:

  ```sh
  git clone https://github.com/plebhash/nix-bitcoin-core-archive
  cd nix-bitcoin-core-archive/fork/sv2
  nix-build   # the executables are available at `result/bin`
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

A custom `bitcoind` node which aims to be merged in Bitcoin Core:
- [PR #29432](https://github.com/bitcoin/bitcoin/pull/29432)
- [PR #29346](https://github.com/bitcoin/bitcoin/pull/29346)

Responsible for creation of Block Templates.

Deployed on both Pool and Miner infrastructure.

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

## Stratum Reference Implementation (SRI)

Since 2020, a group of independent developers started to work on a fully open-source implementation of Stratum V2, called SRI (Stratum Reference Implementation).

The purpose of SRI group is to build, beginning from the SV2 specs, a community-based implementation, while discussing and cooperating with as many people of the Bitcoin community as possible.

The Rust codebase can be found at [`github.com/stratum-mining/stratum`](http://github.com/stratum-mining/stratum)

---

## Supporters

![center w:600 h:400](../img/supporters.png)

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

Instructions available at http://75.119.150.111:8888/html/sv2-workshop.html

Start at slide 20

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
```

---

## Start `bitcoind` Template Provider

Add the Bitcoin binaries to `$PATH`:
```sh
echo 'export PATH="$HOME/bitcoin/src:$PATH"' >> ~/.bashrc && export PATH="$HOME/bitcoin/src:$PATH"
```

Start the Bitcoin node:

```sh
bitcoind -datadir=$HOME/.bitcoin-sv2-workshop -signet -sv2
```

> If using docker, create a new `tmux` instance by typing `tmux` and run the `bitcoind` command in the resulting pane.

---

## Navigate `mempool.space`

There's a local `mempool.space` block explorer available at:

http://192.168.163.178


---

## Pool-only steps

Miners can jump to slide 30

---

## Create wallet (Pool)

```
bitcoin-cli -signet -datadir=$HOME/.bitcoin-sv2-workshop createwallet sv2-workshop
```

## Generate address (Pool)

```
bitcoin-cli -signet -datadir=$HOME/.bitcoin-sv2-workshop getnewaddress sv2-workshop-address
```

If in a `tmux` session, open a new session with `ctrl+b` + `"`. To navigate to the new right pane, click on it. Run all `bitcoin-cli` commands in this pane.

To copy the `address` in `tmux`:
1. Press `ctrl-b` then `[`.
2. Using your arrow keys, navigate to the beginning of the `address`.
3. Press `space`.
4. Use arrow keys to highlight the entire `address`. Press `Enter` to complete the copy.

---

## Get pubkey (Pool)

```
bitcoin-cli -signet -datadir=$HOME/.bitcoin-sv2-workshop getaddressinfo <sv2-workshop-address>
```

⚠️ Take note of the `pubkey` value so you can use it on the next step, and also to check your mining rewards on mempool later.

To copy the `pubkey` in `tmux`:
1. Press `ctrl-b` then `[`.
2. Using your arrow keys, navigate to the beginning of the `pubkey`.
3. Press `space`.
4. Use arrow keys to highlight the entire `pubkey`. Press `Enter` to complete the copy.

---

## Add pubkey to coinbase config (Pool)

Edit `stratum/roles/jd-server/jds-config-sv2-workshop.toml` to add the `pubkey` from the previous step into `coinbase_outputs.output_script_value`.

> If in a `tmux` session, open a new window with `ctrl+b` + `n`. Run the `jd-server` commands in this window. To navigate back to the previous window, click on it in the lower left of the terminal.

---

### Add a Pool Signature

Edit `stratum/roles/pool/pool-config-sv2-workshop.toml` to make sure the `pool_signature` has some custom string to identify the pool in the coinbase of the blocks it mines.

⚠️ Take note of this string because all miners connected to you will need it for their own configs.

> If in a `tmux` session, open a new pane with `ctrl+b` + `"`. Run the `pool` commands in this window.

---

## Start the Pool Server (Pool)
In a new terminal (or in the already created `tmux` pane for the pool):

```
cd stratum/roles/pool
cargo run -- -c pool-config-sv2-workshop.toml
```

## Start Job Declarator Server (Pool)
In a new terminal (or in the already created `tmux` pane for the js-server):

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

> If in a `tmux` session, open a new window with `ctrl+b` + `n`. Run the `jd-client` commands in this window. To navigate back to the previous window, click on it in the lower left of the terminal.

---

## Start Job Declarator Client (Miner)
In a new terminal (or in the already created `tmux` pane for the jd-client):

```
cd stratum/roles/jd-client
cargo run -- -c jdc-config-sv2-workshop.toml
```

## Start Translator Proxy (Miner)
In a new terminal (or create a new `tmux` split for the translator with `ctrl+b` + `"`):

```
cd stratum/roles/translator
cargo run -- -c tproxy-config-sv2-workshop.toml
```

---

## Start CPU mining

If not using Docker, setup the correct CPUMiner for your OS:
- [Download the binary](https://sourceforge.net/projects/cpuminer/files/)
- [Build from source](https://github.com/pooler/cpuminer)
- Use `nix`: `nix-shell -p cpuminer`

Start mining:

```
minerd -a sha256d -o stratum+tcp://localhost:34255 -q -D -P
```

---

![center w:240 h:180](../img/sv2-logo.png)
<br>
# Q&A 

 

---

# Thank you
