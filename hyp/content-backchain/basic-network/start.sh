#!/bin/bash

#
# Copyright One Network Enterprises. All Rights Reserved
#
#
# Exit on first error
set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)
LANGUAGE=${1:-"golang"}
CC_SRC_PATH=github.com/onenetwork
if [ "$LANGUAGE" = "node" -o "$LANGUAGE" = "NODE" ]; then
	CC_SRC_PATH=/opt/gopath/src/github.com/onenetwork/node
fi

# clean the keystore
rm -rf ./hfc-key-store

# launch network; create channel and join peer to channel
cd ../basic-network

docker-compose -f docker-compose.yml up -d ca.contentbackchain.com orderer.contentbackchain.com peer0.orchestratororg.contentbackchain.com peer0.participantorg.contentbackchain.com couchdb

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=10
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=OrchestratorOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@orchestratororg.contentbackchain.com/msp" peer0.orchestratororg.contentbackchain.com peer channel create -o orderer.contentbackchain.com:7050 -c contentbackchainchannel -f /etc/hyperledger/configtx/channel.tx

# Join peer0.orchestratororg.contentbackchain.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=OrchestratorOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@orchestratororg.contentbackchain.com/msp" peer0.orchestratororg.contentbackchain.com peer channel join -b contentbackchainchannel.block

# Join peer0.participantorg.contentbackchain.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=ParticipantOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/participantorg/msp/users/Admin@participantorg.contentbackchain.com/msp" -e "CORE_PEER_ADDRESS=peer0.participantorg.contentbackchain.com:7051" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/participantorg.contentbackchain.com/peers/peer0.participantorg.contentbackchain.com/tls/ca.crt" peer0.orchestratororg.contentbackchain.com peer channel join -b contentbackchainchannel.block

# Now launch the CLI container in order to install, instantiate chaincode
# and prime the ledger with our 10 cars
docker-compose -f ./docker-compose.yml up -d cli

docker exec -e "CORE_PEER_LOCALMSPID=OrchestratorOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/orchestratororg.contentbackchain.com/users/Admin@orchestratororg.contentbackchain.com/msp" cli peer chaincode install -n ContentBackChain -v 1.0 -p "$CC_SRC_PATH" -l "$LANGUAGE"

docker exec -e "CORE_PEER_LOCALMSPID=OrchestratorOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/orchestratororg.contentbackchain.com/users/Admin@orchestratororg.contentbackchain.com/msp" cli peer chaincode instantiate -o orderer.contentbackchain.com:7050 -C contentbackchainchannel -n ContentBackChain -l "$LANGUAGE" -v 1.0 -c '{"Args":[""]}' -P "OR ('OrchestratorOrgMSP.member','ParticipantOrgMSP.member')"


docker exec -e "CORE_PEER_LOCALMSPID=ParticipantOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/participantorg.contentbackchain.com/users/Admin@participantorg.contentbackchain.com/msp" -e "CORE_PEER_ADDRESS=peer0.participantorg.contentbackchain.com:7051" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/participantorg.contentbackchain.com/peers/peer0.participantorg.contentbackchain.com/tls/ca.crt" cli peer chaincode install -n ContentBackChain -v 1.0 -p "$CC_SRC_PATH" -l "$LANGUAGE"

sleep 10

printf "\nTotal setup execution time : $(($(date +%s) - starttime)) secs ...\n\n\n"
printf "Start by installing required packages run 'npm install'\n"
