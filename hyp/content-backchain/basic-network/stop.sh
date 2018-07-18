#!/bin/bash
#
# Copyright One Network Enterprises. All Rights Reserved
#
#
# Exit on first error, print all commands.
set -ev

# Shut down the Docker containers that might be currently running.
docker-compose -f docker-compose.yml down
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
#Cleanup the stores
rm -rf ../server/fabric-client-kv-*
pkill node
