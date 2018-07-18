#! /bin/bash

export PS1="\[\e]0;\w\a\]\n\[\e[34m\]*\h* \[\e[33m\]\w\[\e[0m\]\n\$ "

export PATH=$PATH:/home/vagrant/onechain-back/hyp/content-backchain/basic-network/bin

alias e=vim
export LS_COLORS='ow=01;36;40'
export COMPOSE_PROJECT_NAME=net

cd /home/vagrant/onechain-back/hyp/content-backchain/basic-network
sudo chmod +x ./generate.sh ./start.sh ./stop.sh ./runServer.sh

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
    less +F ../server/server.log
  elif [ "$1" = 'start' ]; then
    echo "Starting Hyperledger Fabric ..."
    ./start.sh
    
  elif [ "$1" = 'stop' ]; then
   ./stop.sh
    echo "Stopped"
    rm -f ../server/server.log
  else
    echo "usage: bk <command>"
    echo
    echo "Commands are:"
    echo "  help    show this help message"
    echo "  log     open the test server logs in less with follow mode enabled"
    echo "  start   start the test server (Hyperledger Fabric) to host the Backchain for testing purposes"
    echo "  stop    stop the test server process"
    if [ "$1" = 'help' ]; then
      return 0
    else
      return 1
    fi
  fi
}
