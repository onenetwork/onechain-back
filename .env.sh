#! /bin/bash

export PS1="\[\e]0;\w\a\]\n\[\e[34m\]*\h* \[\e[33m\]\w\[\e[0m\]\n\$ "

echo
echo
echo "--- ONE Backchain Environment ---"
echo
echo "For help, type: bk help"
echo

alias e=vim

bk() {
  if [ "$1" = 'log' ]; then
    less +F /home/vagrant/log/testrpc.log
  elif [ "$1" = 'start' ]; then
    echo "Starting testrpc ..."
    testrpc 2>&1 >> /home/vagrant/log/testrpc.log &
  elif [ "$1" = 'stop' ]; then
    kill -9 $(ps -ef | grep testrpc | grep -v grep | awk '{print $2;}')
    echo "Stoppped"
  else
    echo "usage: bk <command>"
    echo
    echo "Commands are:"
    echo "  help    show this help message"
    echo "  log     open the test server logs in less with follow mode enabled"
    echo "  start   start the test server (testrpc) to host the Backchain for testing purposes"
    echo "  stop    stop the test server process"
    if [ "$1" = 'help' ]; then
      return 0
    else
      return 1
    fi
  fi
}
