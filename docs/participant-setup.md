# Participant Instruction Manual
Participants are grouped into two categories:

1. Pool Role: Acts as a mining pool and receives shares from the Mining Role.
2. Miner Role: Acts as a miner and submits shares to the Pool Role.

## Prerequisites
The participants should have the following installed on their machines:

* If using manual method: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`.
* If using the docker method: [Docker](https://docs.docker.com/engine/install/).

## Setup
There are two ways for the participant to setup:
1. Manual: Install all required programs manually.
2. Docker: Use the [`materials/Dockerfile`](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/Dockerfile).

### Manual Method
1. Install `bitcoin-core`.
2. Install `stratum` roles.
3. Install `cpuminer`.

#### `bitcoin-core`
Used for the Pool Role's JDS and the Miner Role's JDC to connect to.

##### Install
There are three ways to install the required `bitcoin-core` fork:

1. Download the release binary: [Plebhash's fork of Sjors's sv2-tp-0.1.3 tag](https://github.com/plebhash/bitcoin/releases/tag/btc-prague).
2. `nix`
  ```
  git clone https://github.com/plebhash/nix-bitcoin-core-archive
  cd nix-bitcoin-core-archive/fork/sv2
  nix-build   # the executables are available at `result/bin`
  ```
3. Build from Source: [Sjors's `sv2-tp-0.1.3` tag](https://github.com/Sjors/bitcoin/tree/sv2-tp-0.1.3):
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

##### Config
Make a new Bitcoin data directory at `~/.bitcoin-sv2-workshop` and ensure the
[`bitcoin.conf`](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/participant-bitcoin.conf)
in the data directory contains:

```conf
[signet]
signetchallenge=51      # OP_TRUE
connect=75.119.150.111  # Genesis node
server=1
rpcuser=username
rpcpassword=password
sv2port=8442
debug=rpc
debug=sv2
loglevel=sv2:debug
```

##### Run
Add the Bitcoin binaries to `$PATH` and start the Bitcoin node:

```sh
bitcoind -datadir=$HOME/.bitcoin-sv2-workshop -signet -sv2
```

#### Sv2 Roles
The Pool Role uses the following roles:
* [`stratum/roles/pool`](https://github.com/stratum-mining/stratum/tree/main/roles/pool)
* [`stratum/roles/jd-server`](https://github.com/stratum-mining/stratum/tree/main/roles/jd-server)

The Miner Role uses the following roles:
* [`stratum/roles/translator`](https://github.com/stratum-mining/stratum/tree/main/roles/translator)
* [`stratum/roles/jd-client`](https://github.com/stratum-mining/stratum/tree/main/roles/jd-client)

##### Install

```sh
git clone https://github.com/stratum-mining/stratum
cd stratum
git checkout workshop
cd roles
cargo build
```

### Docker Method
The [`materials/Dockerfile`](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/Dockerfile)
contain the docker image with the following installed, configured, and built:

1. [Plebhash's fork of Sjors's `sv2-tp-0.1.3`](https://github.com/plebhash/bitcoin/releases/tag/btc-prague): Used for the Pool and Miner Roles.
2. [`cpuminer` `v2.5.1`](https://github.com/pooler/cpuminer/releases/tag/v2.5.1): Used as hasher for the Miner Role.
3. [`stratum` - `workshop` branch](https://github.com/stratum-mining/stratum/tree/workshop): The `roles/` crates are used to run the Pool and Miner Roles.

#### Build Docker Image (Instructor Only)
To support participants opening multiple terminal sessions, `tmux` is used. A `tmux.conf` is
instantiated by the docker image with the [`materials/setup-tmux.sh`](https://github.com/stratum-mining/sv2-workshop/blob/main/materials/tmux-setup.sh).
This `tmux.conf` will allow users to navigate between `tmux` panes with a mouse click and also
includes a few more customizations for ease of use.

Build the docker image:

```
cp materials/setup_tmux.sh /usr/local/bin/setup_tmux.sh
docker build -t sv2-workshop:latest .
```

#### Connect to Docker Image (Participant)
Connect to the docker image:

```sh
docker run -it --rm sv2-workshop:latest
```
