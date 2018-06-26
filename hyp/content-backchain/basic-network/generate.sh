#!/bin/sh
#
# Copyright One Network Enterprises. All Rights Reserved.
#
#
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=contentbackchainchannel

mkdir -p ../chaincode/hyperledger/fabric/peer/crypto/

# remove previous crypto material and config transactions
rm -fr config/*
rm -fr crypto-config/*

mkdir -p config
mkdir -p crypto-config

# generate crypto material
cryptogen generate --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to generate crypto material..."
  exit 1
fi

# generate genesis block for orderer
configtxgen -profile TwoOrgOrdererGenesis -outputBlock ./config/genesis.block
if [ "$?" -ne 0 ]; then
  echo "Failed to generate orderer genesis block..."
  exit 1
fi

# generate channel configuration transaction
configtxgen -profile TwoOrgChannel -outputCreateChannelTx ./config/channel.tx -channelID $CHANNEL_NAME
if [ "$?" -ne 0 ]; then
  echo "Failed to generate channel configuration transaction..."
  exit 1
fi

# generate anchor peer transaction
configtxgen -profile TwoOrgChannel -outputAnchorPeersUpdate ./config/OrchestratorOrgMSPanchors.tx -channelID $CHANNEL_NAME -asOrg OrchestratorOrgMSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for OrchestratorOrgMSP..."
  exit 1
fi

configtxgen -profile TwoOrgChannel -outputAnchorPeersUpdate ./config/ParticipantOrgMSPanchors.tx -channelID $CHANNEL_NAME -asOrg ParticipantOrgMSP
if [ "$?" -ne 0 ]; then
  echo "Failed to generate anchor peer update for ParticipantOrgMSP..."
  exit 1
fi

# Copy the template to the file that will be modified to add the private key
cp docker-compose-template.yml docker-compose.yml

# The next steps will replace the template's contents with the
# actual values of the private key file names for CAs.
CURRENT_DIR=$PWD
cd crypto-config/peerOrganizations/orchestratororg.contentbackchain.com/ca/
PRIV_KEY=$(ls *_sk)
cd "$CURRENT_DIR"
sed -i "s/CA_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose.yml

# Generate network-config for WebAppServer
cd ../server/artifacts
SERVER_DIR=$PWD
cp network-config-template.yaml network-config.yaml

# Replace the network-config template's contents with the
# actual values of the private key file names for the OrchestraotrOrg and ParticioantOrg Admins.
cd "$CURRENT_DIR"
cd crypto-config/peerOrganizations/orchestratororg.contentbackchain.com/users/Admin@orchestratororg.contentbackchain.com/msp/keystore/
ADMIN1_PRIV_KEY=$(ls *_sk)
cd "$SERVER_DIR"
sed -i "s/ORCHESTRATOR_ADMIN_KEY/${ADMIN1_PRIV_KEY}/g" network-config.yaml

cd "$CURRENT_DIR"
cd crypto-config/peerOrganizations/participantorg.contentbackchain.com/users/Admin@participantorg.contentbackchain.com/msp/keystore/
ADMIN2_PRIV_KEY=$(ls *_sk)
cd "$SERVER_DIR"
sed -i "s/PARTICIPANT_ADMIN_KEY/${ADMIN2_PRIV_KEY}/g" network-config.yaml

cd "$CURRENT_DIR"



