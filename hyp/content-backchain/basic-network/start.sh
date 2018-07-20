#!/bin/bash

#
# Copyright One Network Enterprises. All Rights Reserved
#
#

echo "Stopping server if it is already up ..."
./stop.sh &> /dev/null

sleep 10

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

# launch network; create channel and join peer to channel
docker-compose -f docker-compose.yml up -d orchestrator-ca.contentbackchain.com participant-ca.contentbackchain.com orderer.contentbackchain.com peer0.orchestratororg.contentbackchain.com peer0.participantorg.contentbackchain.com couchdb


# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
sleep 15

# Create the channel
docker exec -e "CORE_PEER_LOCALMSPID=OrchestratorOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@orchestratororg.contentbackchain.com/msp" peer0.orchestratororg.contentbackchain.com peer channel create -o orderer.contentbackchain.com:7050 -c contentbackchainchannel -f /etc/hyperledger/configtx/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/tlscacerts/tlsca.contentbackchain.com-cert.pem

# Join peer0.orchestratororg.contentbackchain.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=OrchestratorOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@orchestratororg.contentbackchain.com/msp" peer0.orchestratororg.contentbackchain.com peer channel join -b contentbackchainchannel.block

# Join peer0.participantorg.contentbackchain.com to the channel.
docker exec -e "CORE_PEER_LOCALMSPID=ParticipantOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/participantorg/msp/users/Admin@participantorg.contentbackchain.com/msp" -e "CORE_PEER_ADDRESS=peer0.participantorg.contentbackchain.com:7051" -e "CORE_PEER_TLS_ROOTCERT_FILE=/etc/hyperledger/crypto/peerParticipantOrg/tls/ca.crt" peer0.orchestratororg.contentbackchain.com peer channel join -b contentbackchainchannel.block

# Now launch the CLI container in order to install, instantiate chaincode
# and prime the ledger with our 10 cars
docker-compose -f ./docker-compose.yml up -d cli

docker exec -e "CORE_PEER_LOCALMSPID=OrchestratorOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/orchestratororg.contentbackchain.com/users/Admin@orchestratororg.contentbackchain.com/msp" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/orchestratororg.contentbackchain.com/peers/peer0.orchestratororg.contentbackchain.com/tls/ca.crt" cli peer chaincode install -n ContentBackChain -v 1.0 -p "$CC_SRC_PATH" -l "$LANGUAGE"


docker exec -e "CORE_PEER_LOCALMSPID=ParticipantOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/participantorg.contentbackchain.com/users/Admin@participantorg.contentbackchain.com/msp" -e "CORE_PEER_ADDRESS=peer0.participantorg.contentbackchain.com:7051" -e "CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/participantorg.contentbackchain.com/peers/peer0.participantorg.contentbackchain.com/tls/ca.crt" cli peer chaincode install -n ContentBackChain -v 1.0 -p "$CC_SRC_PATH" -l "$LANGUAGE"

CURRENT_DIR=$PWD

#Start server
./runServer.sh &

#Register users
sleep 10
ORG1_TOKEN=$(curl -s -X POST \
  		http://localhost:4000/users \
	  	-H "content-type: application/x-www-form-urlencoded" \
  		-d 'username=OrchestratorUser&orgName=OrchestratorOrg')

ORCHESTRATOR_PKEY=$(echo $ORG1_TOKEN | jq ".publicKey" | sed "s/\"//g")

ORG1_TOKEN=$(echo $ORG1_TOKEN | jq ".token" | sed "s/\"//g")
	
ORG2_TOKEN=$(curl -s -X POST \
 		http://localhost:4000/users \
	  	-H "content-type: application/x-www-form-urlencoded" \
  		-d 'username=ParticipantUser&orgName=ParticipantOrg')
ORG2_TOKEN=$(echo $ORG2_TOKEN | jq ".token" | sed "s/\"//g")

cd "$CURRENT_DIR"
#Initialize chaincode
ARGS='{"Args":["'$ORCHESTRATOR_PKEY'"]}'
docker exec -e "CORE_PEER_LOCALMSPID=OrchestratorOrgMSP" -e "CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/orchestratororg.contentbackchain.com/users/Admin@orchestratororg.contentbackchain.com/msp" cli peer chaincode instantiate -o orderer.contentbackchain.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/contentbackchain.com/orderers/orderer.contentbackchain.com/msp/tlscacerts/tlsca.contentbackchain.com-cert.pem -C contentbackchainchannel -n ContentBackChain -l "$LANGUAGE" -v 1.0 -c "$ARGS" -P "OR ('OrchestratorOrgMSP.member','ParticipantOrgMSP.member')"


printf "\nTotal setup executon time : $(($(date +%s) - starttime)) secs ...\n"

echo
echo "OrchestratorOrg User token - $ORG1_TOKEN"
echo
echo "ParticipantOrg User token - $ORG2_TOKEN"
echo
echo "Url - http://localhost:4000"

