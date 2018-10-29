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


ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/trade.com/orderers/orderer.trade.com/msp/tlscacerts/tlsca.trade.com-cert.pem
PEER0_EXPORTERORG_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/exporterorg.trade.com/peers/peer0.exporterorg.trade.com/tls/ca.crt
PEER1_EXPORTERORG_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/exporterorg.trade.com/peers/peer1.exporterorg.trade.com/tls/ca.crt
PEER0_EXPORTERBANKORG_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/exporterbankorg.trade.com/peers/peer0.exporterbankorg.trade.com/tls/ca.crt
PEER0_IMPORTERORG_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/importerorg.trade.com/peers/peer0.importerorg.trade.com/tls/ca.crt
PEER1_IMPORTERORG_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/importerorg.trade.com/peers/peer1.importerorg.trade.com/tls/ca.crt
PEER0_IMPORTERBANKORG_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/importerbankorg.trade.com/peers/peer0.importerbankorg.trade.com/tls/ca.crt
PEER0_EXPORTINGENTITYORG_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/exportingentityorg.trade.com/peers/peer0.exportingentityorg.trade.com/tls/ca.crt
PEER0_CARRIERORG_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/carrierorg.trade.com/peers/peer0.carrierorg.trade.com/tls/ca.crt
PEER0_REGULATORORG_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/regulatororg.trade.com/peers/peer0.regulatororg.trade.com/tls/ca.crt

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals PEER0 exporterorg ExporterOrgMSP $PEER0_EXPORTERORG_CA

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.trade.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/$CHANNEL_NAME.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.trade.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/$CHANNEL_NAME.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel '$CHANNEL_NAME' created ===================== "
	echo
}

joinChannel () {
	joinChannelWithRetry PEER0 exporterorg ExporterOrgMSP $PEER0_EXPORTERORG_CA
	joinChannelWithRetry PEER1 exporterorg ExporterOrgMSP $PEER1_EXPORTERORG_CA
	joinChannelWithRetry PEER0 exporterbankorg ExporterBankOrgMSP $PEER0_EXPORTERBANKORG_CA
	joinChannelWithRetry PEER0 importerorg ImporterOrgMSP $PEER0_IMPORTERORG_CA
	joinChannelWithRetry PEER1 importerorg ImporterOrgMSP $PEER1_IMPORTERORG_CA
	joinChannelWithRetry PEER0 importerbankorg ImporterBankOrgMSP $PEER0_IMPORTERBANKORG_CA
	joinChannelWithRetry PEER0 exportingentityorg ExportingEntityOrgMSP $PEER0_EXPORTINGENTITYORG_CA
	joinChannelWithRetry PEER0 carrierorg CarrierOrgMSP $PEER0_CARRIERORG_CA
	joinChannelWithRetry PEER0 regulatororg RegulatorOrgMSP $PEER0_REGULATORORG_CA
}

updateAnchorPeers(){
	## Set the anchor peers for each org in the channel
	updateAnchorPeer PEER0 exporterorg ExporterOrgMSP $PEER0_EXPORTERORG_CA
	updateAnchorPeer PEER0 exporterbankorg ExporterBankOrgMSP $PEER0_EXPORTERBANKORG_CA
	updateAnchorPeer PEER0 importerorg ImporterOrgMSP $PEER0_IMPORTERORG_CA
	updateAnchorPeer PEER0 importerbankorg ImporterBankOrgMSP $PEER0_IMPORTERBANKORG_CA
	updateAnchorPeer PEER0 exportingentityorg ExportingEntityOrgMSP $PEER0_EXPORTINGENTITYORG_CA
	updateAnchorPeer PEER0 carrierorg CarrierOrgMSP $PEER0_CARRIERORG_CA
	updateAnchorPeer PEER0 regulatororg RegulatorOrgMSP $PEER0_REGULATORORG_CA
}

installChaincodeOnPeers(){
	## Install chaincode on peer0.exporter and peer0.importerorg
	installChaincode PEER0 exporterorg ExporterOrgMSP $PEER0_EXPORTERORG_CA
	installChaincode PEER1 exporterorg ExporterOrgMSP $PEER1_EXPORTERORG_CA
	installChaincode PEER0 exporterbankorg ExporterBankOrgMSP $PEER0_EXPORTERBANKORG_CA
	installChaincode PEER0 importerorg ImporterOrgMSP $PEER0_IMPORTERORG_CA
	installChaincode PEER1 importerorg ImporterOrgMSP $PEER1_IMPORTERORG_CA
	installChaincode PEER0 importerbankorg ImporterBankOrgMSP $PEER0_IMPORTERBANKORG_CA
	installChaincode PEER0 exportingentityorg ExportingEntityOrgMSP $PEER0_EXPORTINGENTITYORG_CA
	installChaincode PEER0 carrierorg CarrierOrgMSP $PEER0_CARRIERORG_CA
	installChaincode PEER0 regulatororg RegulatorOrgMSP $PEER0_REGULATORORG_CA
}

## Create channel
echo "Creating channel..."
createChannel
## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

echo "update anchor peers"
updateAnchorPeers

installChaincodeOnPeers

# Instantiate chaincode on peer0.importerorg
echo "Instantiating chaincode on peer0.importerorg..."
instantiateChaincode PEER0 importerorg ImporterOrgMSP $PEER0_IMPORTERORG_CA

# Query chaincode on peer0.exporter
echo "Querying chaincode on peer0.exporterorg..."
chaincodeQuery PEER0 exporterorg ExporterOrgMSP $PEER0_EXPORTERORG_CA 100

# Query chaincode on peer0.exportingentityorg
echo "Querying chaincode on peer0.exportingentityorg..."
chaincodeQuery PEER0 exporterbankorg ExporterBankOrgMSP $PEER0_EXPORTERBANKORG_CA 100

# Query chaincode on peer0.carrierorg
echo "Querying chaincode on peer0.carrierorg..."
chaincodeQuery PEER0 carrierorg CarrierOrgMSP $PEER0_CARRIERORG_CA 100

# Query chaincode on peer0.regulatororg
echo "Querying chaincode on peer0.regulatororg..."
chaincodeQuery PEER0 regulatororg RegulatorOrgMSP $PEER0_REGULATORORG_CA 100

# Invoke chaincode on peer0.exporter and peer0.importerorg
echo "Sending invoke transaction on peer0.exporter to peer0.importerorg..."
chaincodeInvoke

chaincodeQuery PEER0 exporterorg ExporterOrgMSP $PEER0_EXPORTERORG_CA 90

## Install chaincode on peer1.importerorg
#echo "Installing chaincode on peer1.importerorg..."
installChaincode PEER1 importerorg ImporterOrgMSP $PEER0_IMPORTERORG_CA

# Query on chaincode on peer1.importerorg, check if the result is 90
echo "Querying chaincode on peer1.importerorg..."
chaincodeQuery PEER1 importerorg ImporterOrgMSP $PEER0_IMPORTERORG_CA 90

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
