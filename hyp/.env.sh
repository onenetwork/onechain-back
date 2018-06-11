#! /bin/bash

export PS1="\[\e]0;\w\a\]\n\[\e[34m\]*\h* \[\e[33m\]\w\[\e[0m\]\n\$ "

export PATH=$PATH:/home/vagrant/onechain-back/hyp/content-backchain/basic-network/bin

alias e=vim
export LS_COLORS='ow=01;36;40'

cd /home/vagrant/onechain-back/hyp/content-backchain/basic-network
sudo chmod +x ./generate.sh ./start.sh ./stop.sh

# Generate certificates and docker-compose-yml file with new key if it is not done yet.
if [[ ! -d "crypto-config" ]]; then
	./generate.sh
fi

echo
echo
echo "--- ONE Backchain Environment ---"
echo
echo "For help, type: bk help"
echo

bk() {
  if [ "$1" = 'log' ]; then
    docker logs -f peer0.orchestratororg.contentbackchain.com
  elif [ "$1" = 'start' ]; then
    echo "Starting Hyperledger Fabric ..."
    ./start.sh
    
    printf "TODO Hyperledger changes : Test backchain server available at http://192.168.201.55:8545
            Orchestrator private key is 0x8ad0132f808d0830c533d7673cd689b7fde2d349ff0610e5c04ceb9d6efb4eb1
            Sample participant private key is 0x69bc764651de75758c489372c694a39aa890f911ba5379caadc08f44f8173051\n"
 
   elif [ "$1" = 'stop' ]; then
   ./stop.sh
    echo "Stopped"
    rm -f /home/vagrant/log/fabric.log
  else
    echo "usage: bk <command>"
    echo
    echo "Commands are:"
    echo "  help    show this help message"
    echo "  log     open the OrchestratorOrg peer logs in less with follow mode enabled"
    echo "  start   start the test server (Hyperledger Fabric) to host the Backchain for testing purposes"
    echo "  stop    stop the test server process"
    if [ "$1" = 'help' ]; then
      return 0
    else
      return 1
    fi
  fi
}
