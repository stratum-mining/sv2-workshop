{
  description = "A flake with an environment for a StratumV2 Reference Implementation (SRI) Workshop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    flakebox = {
      url = "github:rustshop/flakebox";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flakebox, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        flakeboxLib = flakebox.lib.${system} { };
        pkgs = import nixpkgs { inherit system; };

        sv2_workshop_dir = "/tmp/sv2_workshop";
        bitcoin_sv2_dir = sv2_workshop_dir + "/bitcoin_sv2";
        bitcoin_data_dir = sv2_workshop_dir + "/bitcoin_data_dir";
      in
      {
        devShells = flakeboxLib.mkShells {
          buildInputs = [
            pkgs.pkg-config
            pkgs.autoreconfHook
            pkgs.boost
            pkgs.zlib
            pkgs.libevent
            pkgs.sqlite
          ];
        shellHook = ''

        mkdir -p ${sv2_workshop_dir}

        # clone and build Bitcoin Core SV2
        if [ ! -d "${bitcoin_sv2_dir}" ]; then
          git clone https://github.com/Sjors/bitcoin ${bitcoin_sv2_dir}
          pushd ${bitcoin_sv2_dir}
            ./autogen.sh
            ./configure --enable-wallet
            make -j $(nproc)
          popd
        fi

        # clean up old bitcoin datadir
        rm -rf ${bitcoin_data_dir}

        # set up bitcoin datadir
        mkdir -p ${bitcoin_data_dir}
        cat <<EOT > ${bitcoin_data_dir}/bitcoin.conf
        [signet]
        prune=0
        txindex=1
        server=1
        rpcallowip=0.0.0.0/0
        rpcbind=0.0.0.0
        rpcuser=mempool
        rpcpassword=mempool
        # OP_TRUE
        signetchallenge=51
        EOT

        # set alias + shell variable for bitcoin-cli command
        alias btc="${bitcoin_sv2_dir}/src/bitcoin-cli -signet -datadir=${bitcoin_data_dir}"
        CLI="${bitcoin_sv2_dir}/src/bitcoin-cli -signet -datadir=${bitcoin_data_dir}"

        echo "Killing previous bitcoind"
        pkill -f bitcoind || true

        echo "Starting bitcoind"
        ${bitcoin_sv2_dir}/src/bitcoind -signet -datadir=${bitcoin_data_dir} -fallbackfee=0.01 -daemon -signet -sv2 -sv2port=8442
        sleep 1

        echo "Creating wallet"
        btc createwallet genesis

        # generate blocks (SRI pool requirement)
        MINER="${bitcoin_sv2_dir}/contrib/signet/miner"
        GRIND="${bitcoin_sv2_dir}/src/bitcoin-util grind"
        ADDR=tb1qd7fldeuznuv9jnpadd338lc4unpznuxjmv3na8
        NBITS=1d00ffff

        for ((i=1; i<=16; i++))
        do
          $MINER --cli="$CLI" generate --grind-cmd="$GRIND" --address="$ADDR" --nbits=$NBITS
        done
    
        btc getblockchaininfo

        # todo: electrs
        # todo: mempool

        # serve slides
        pushd html
          python3 -m http.server 8888
        popd

        '';
        };
      });
}
