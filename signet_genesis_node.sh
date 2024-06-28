#!/bin/bash

# Check if the environment variables are set
if [ -z "$BITCOIND" ] || [ -z "$BITCOIN_CLI" ] || [ -z "$BITCOIN_UTIL" ] || [ -z "$BITCOIN_DATA_DIR" ] || [ -z "$MINER" ]; then
  echo "Please make sure all environment variables (BITCOIND, BITCOIN_CLI, BITCOIN_UTIL, BITCOIN_DATA_DIR, MINER) are properly set. Exiting."
  exit 1
fi

# Check if the specific port is in use
if lsof -i :38332 | grep -q LISTEN; then
  echo "Port 38332 is already being used, which means there's probably a bitcoind already running in signet mode. Exiting."
  exit 1
fi

echo "This script is about to erase some contents of the provided BITCOIN_DATA_DIR. Do you want to continue? (yes/no)"
read -r user_input

if [ "$user_input" != "yes" ]; then
  echo "User did not consent. Exiting."
  exit 1
fi

rm -rf $BITCOIN_DATA_DIR/signet
rm -rf $BITCOIN_DATA_DIR/bitcoin.conf

cat << EOF > $BITCOIN_DATA_DIR/bitcoin.conf
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
EOF

echo "starting bitcoind in daemon mode..."
$BITCOIND -signet -datadir=$BITCOIN_DATA_DIR -fallbackfee=0.01 -daemon -sv2 -sv2port=38442

sleep 1

echo "creating a genesis wallet"
$BITCOIN_CLI -signet -datadir=$BITCOIN_DATA_DIR createwallet genesis

echo "mining some initial blocks"
for ((i=1; i<=16; i++))
do
  $MINER --cli="$BITCOIN_CLI -signet -datadir=$BITCOIN_DATA_DIR" generate --grind-cmd="$BITCOIN_UTIL grind" --address="tb1qmrv47upgrdd0f8rw62rwdtpd8r6qrn8kh7tj5f" --nbits=1d00ffff
done

echo "script finalized... running getblockchaininfo as the last step"
$BITCOIN_CLI -signet -datadir=$BITCOIN_DATA_DIR getblockchaininfo

