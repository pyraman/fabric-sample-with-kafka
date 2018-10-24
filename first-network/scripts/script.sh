#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Build your first network (BYFN) end-to-end test"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
VERBOSE="$5"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
: ${VERBOSE:="false"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer0.trade.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer0.trade.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.org${org} joined channel '$CHANNEL_NAME' ===================== "
		sleep $DELAY
		echo
	    done
	done

	joinChannelWithRetry 0 3
	echo "===================== peer0.org3 joined channel '$CHANNEL_NAME' ===================== "

	joinChannelWithRetry 0 4
	echo "===================== peer0.org4 joined channel '$CHANNEL_NAME' ===================== "
	
	sleep $DELAY
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for exporterorg..."
updateAnchorPeers 0 1
echo "Updating anchor peers for importerorg..."
updateAnchorPeers 0 2

updateAnchorPeers 0 3

updateAnchorPeers 0 4

## Install chaincode on peer0.exporter and peer0.importerorg
echo "Installing chaincode on peer0.exporterorg..."
installChaincode 0 1
echo "Install chaincode on peer0.importerorg..."
installChaincode 0 2

installChaincode 0 3

installChaincode 0 4

# Instantiate chaincode on peer0.importerorg
echo "Instantiating chaincode on peer0.importerorg..."
instantiateChaincode 0 2

# Query chaincode on peer0.exporter
echo "Querying chaincode on peer0.exporterorg..."
chaincodeQuery 0 1 100

# Query chaincode on peer0.exportingentityorg
echo "Querying chaincode on peer0.exportingentityorg..."
chaincodeQuery 0 3 100

# Query chaincode on peer0.carrierorg
echo "Querying chaincode on peer0.carrierorg..."
chaincodeQuery 0 4 100

# Invoke chaincode on peer0.exporter and peer0.importerorg
echo "Sending invoke transaction on peer0.exporter to peer0.importerorg..."
chaincodeInvoke 0 1 0 2

## Install chaincode on peer1.importerorg
echo "Installing chaincode on peer1.importerorg..."
installChaincode 1 2

# Query on chaincode on peer1.importerorg, check if the result is 90
echo "Querying chaincode on peer1.importerorg..."
chaincodeQuery 1 2 90

echo
echo "========= All GOOD, BYFN execution completed =========== "
echo

echo
echo " _____   _   _   ____   "
echo "| ____| | \ | | |  _ \  "
echo "|  _|   |  \| | | | | | "
echo "| |___  | |\  | | |_| | "
echo "|_____| |_| \_| |____/  "
echo

exit 0
