#!/bin/sh
# @note alpine doesn't have bash
# @NOTICE
#	THIS IS FOR USAGE IN TESTING ENV
#
#  - OPENMEV_MINER                   enable mining. value is coinbase address.
#  - OPENMEV_MINER_EXTRA             extra-data field to set for newly minted blocks
#  - OPENMEV_SKIP_POW                if set, skip PoW verification during block import
#  - OPENMEV_LOGLEVEL		         client loglevel (0-5)
#  - OPENMEV_GRAPHQL_ENABLED         enables graphql on port 8545

# Immediately abort the script on any error encountered
set -e

geth=/usr/local/bin/geth
FLAGS="--pcscdpath=\"\""

if [ "$OPENMEV_LOGLEVEL" != "" ]; then
    FLAGS="$FLAGS --verbosity=$OPENMEV_LOGLEVEL"
fi

# It doesn't make sense to dial out, use only a pre-set bootnode.
FLAGS="$FLAGS --bootnodes=$OPENMEV_BOOTNODE"

if [ "$OPENMEV_SKIP_POW" != "" ]; then
	FLAGS="$FLAGS --fakepow"
fi

# If a specific network ID is requested, use that
if [ "$OPENMEV_NETWORK_ID" != "" ]; then
	FLAGS="$FLAGS --networkid $OPENMEV_NETWORK_ID"
else
    # Unless otherwise specified by OPENMEV, we try to avoid mainnet networkid. If geth detects mainnet network id,
    # then it tries to bump memory quite a lot
    FLAGS="$FLAGS --networkid 1337"
fi

# If the client is to be run in testnet mode, flag it as such
if [ "$OPENMEV_TESTNET" == "1" ]; then
	FLAGS="$FLAGS --testnet"
fi

# Handle any client mode or operation requests
if [ "$OPENMEV_NODETYPE" == "full" ]; then
	FLAGS="$FLAGS --syncmode fast "
fi
if [ "$OPENMEV_NODETYPE" == "light" ]; then
	FLAGS="$FLAGS --syncmode light "
fi

# Configure the chain.
mv /genesis.json /genesis-input.json
jq -f /mapper.jq /genesis-input.json > /genesis.json

# Dump genesis
echo "Supplied genesis state:"
cat /genesis.json

# Initialize the local testchain with the genesis state
echo "Initializing database with genesis state..."
$geth "$FLAGS" init /genesis.json

# Don't immediately abort, some imports are meant to fail
set +e

# Load the test chain if present
echo "Loading initial blockchain..."
if [ -f /chain.rlp ]; then
	$geth "$FLAGS" --gcmode=arcOPENMEV import /chain.rlp
else
	echo "Warning: chain.rlp not found."
fi

# Load the remainder of the test chain
echo "Loading remaining individual blocks..."
if [ -d /blocks ]; then
	(cd /blocks && $geth "$FLAGS" --gcmode=arcOPENMEV --verbosity="$OPENMEV_LOGLEVEL" --nocompaction import $(ls | sort -n))
else
	echo "Warning: blocks folder not found."
fi

set -e

# Import clique signing key.
if [ "$OPENMEV_CLIQUE_PRIVATEKEY" != "" ]; then
    # Create password file.
    echo "Importing clique key..."
    echo "secret" > /geth-password-file.txt
    $geth --nousb account import --password /geth-password-file.txt <(echo "$OPENMEV_CLIQUE_PRIVATEKEY")

    # Ensure password file is used when running geth in mining mode.
    if [ "$OPENMEV_MINER" != "" ]; then
        FLAGS="$FLAGS --password /geth-password-file.txt --unlock $OPENMEV_MINER --allow-insecure-unlock"
    fi
fi

# Configure any mining operation
if [ "$OPENMEV_MINER" != "" ]; then
	FLAGS="$FLAGS --mine --miner.threads 1 --miner.etherbase $OPENMEV_MINER"
fi
if [ "$OPENMEV_MINER_EXTRA" != "" ]; then
	FLAGS="$FLAGS --miner.extradata $OPENMEV_MINER_EXTRA"
fi
FLAGS="$FLAGS --miner.gasprice 16000000000"

# Configure RPC.
FLAGS="$FLAGS --http --http.addr=0.0.0.0 --http.port=8545 --http.api=admin,debug,eth,miner,net,personal,txpool,web3"
FLAGS="$FLAGS --ws --ws.addr=0.0.0.0 --ws.origins \"*\" --ws.api=admin,debug,eth,miner,net,personal,txpool,web3"
if [ "$OPENMEV_GRAPHQL_ENABLED" != "" ]; then
	FLAGS="$FLAGS --graphql"
fi
# used for the graphql to allow submission of unprotected tx
if [ "$OPENMEV_ALLOW_UNPROTECTED_TX" != "" ]; then
 	FLAGS="$FLAGS --rpc.allow-unprotected-txs"
fi

# Run the go-ethereum implementation with the requested flags.
FLAGS="$FLAGS --nat=none"
echo "Running go-ethereum with flags $FLAGS"
$geth "$FLAGS"
