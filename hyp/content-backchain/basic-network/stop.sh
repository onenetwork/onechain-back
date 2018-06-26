#!/bin/bash
#
# Copyright One Network Enterprises. All Rights Reserved
#
#
# Exit on first error, print all commands.
set -ev

# Shut down the Docker containers that might be currently running.
docker-compose -f docker-compose.yml stop
docker rm -f $(docker ps -aq)
docker network prune -f

pkill node
echo
