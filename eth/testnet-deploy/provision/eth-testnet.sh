sudo yum install -y wget unzip mlocate
sudo updatedb
cd /tmp
wget https://gethstore.blob.core.windows.net/builds/geth-linux-amd64-1.8.12-37685930.tar.gz
gunzip geth*
tar xvf geth*
sudo mv geth-linux-amd64-1.8.12-37685930/geth /usr/bin
rm -Rf geth*

sudo mkdir /etc/testnet
sudo chmod a+rw /etc/testnet

export ONE_TESTNET_ID=9901
export ONE_TESTNET_DATA=/etc/testnet/one-testnet-data

echo 8ad0132f808d0830c533d7673cd689b7fde2d349ff0610e5c04ceb9d6efb4eb1 > /etc/testnet/orchestrator-private-key
echo 'one-orch3strator!' > /etc/testnet/orchestrator-password
ORCHESTRATOR_ADDR=$(geth account import /etc/testnet/orchestrator-private-key --datadir $ONE_TESTNET_DATA --password /etc/testnet/orchestrator-password 2>&1 | grep -o 'Address.*' | sed 's/Address: {//g' | sed 's/}//g')
echo Orchestrator Address: $ORCHESTRATOR_ADDR

echo 69bc764651de75758c489372c694a39aa890f911ba5379caadc08f44f8173051 > /etc/testnet/participant-private-key
echo 'one-p@rticipant#' > /etc/testnet/participant-password
PARTICIPANT_ADDR=$(geth account import /etc/testnet/participant-private-key --datadir $ONE_TESTNET_DATA --password /etc/testnet/participant-password 2>&1 | grep -o 'Address.*' | sed 's/Address: {//g' | sed 's/}//g')
echo Participant Address: $PARTICIPANT_ADDR

geth removedb --datadir $ONE_TESTNET_DATA

sudo printf '{
    "config": {
      "chainId": %s,
      "homesteadBlock": 0,
      "eip155Block": 0,
      "eip158Block": 0
    },
    "difficulty": "0x400",
    "gasLimit": "0x8000000",
    "alloc": {
      "0x%s": { "balance": "0x1337000000000000000000" }     
    }
}' $ONE_TESTNET_ID $ORCHESTRATOR_ADDR > /etc/testnet/CustomGenesis.json

geth --datadir $ONE_TESTNET_DATA init /etc/testnet/CustomGenesis.json

sudo mkdir /var/log/testnet
sudo chmod a+rw /var/log/testnet

printf '
export ONE_TESTNET_ID=9901
export ONE_TESTNET_DATA=/etc/testnet/one-testnet-data
testnet() {
  if [ "$1" = "log" ]; then
    less +F /var/log/testnet/testnet.log
  elif [ "$1" = "start" ]; then
    echo "Starting geth ..."
    rm -f /var/log/testnet/testnet.log
    nohup geth \
      --gcmode=archive \
      --mine --minerthreads=1 \
      --identity "ONETestNet" --nodiscover --networkid $ONE_TESTNET_ID \
      --datadir $ONE_TESTNET_DATA \
      --rpc \
      --rpcapi web3,net,eth,personal \
      --rpccorsdomain "*" \
      --rpcaddr 0.0.0.0 \
      >> /var/log/testnet/testnet.log 2>&1 </dev/null &
  elif [ "$1" = "attach" ]; then
    geth --identity \"ONETestNet\" --networkid $ONE_TESTNET_ID --datadir $ONE_TESTNET_DATA attach
  elif [ "$1" = "stop" ]; then
    BKPROC=$(ps -ef | grep geth | grep -v grep | awk '"'"'{print $2;}'"'"')
    if [ ! -z "$BKPROC" ]
    then
      kill -9 $BKPROC
      echo $(date) : Stopped >> /var/log/testnet/testnet.log
    fi
    echo "Stopped"
  else
    echo "usage: testnet <command>"
    echo
    echo "Commands are:"
    echo "  help    show this help message"
    echo "  log     open the testnet server logs in less with follow mode enabled"
    echo "  attach  attach to console of running testnet (geth) process"
    echo "  start   start the testnet server (geth)"
    echo "  stop    stop the testnet server process"
    if [ "$1" = "help" ]; then
      return 0
    else
      return 1
    fi
  fi
}
' > /etc/testnet/env.sh

sudo iptables -I INPUT -p tcp --dport 8545 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -I OUTPUT -p tcp --sport 8545 -m state --state ESTABLISHED -j ACCEPT
