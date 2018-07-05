#! /bin/bash
# Run this before running 'node deploy-all.js'
pushd .
cd /vagrant/eth/contracts
rm -Rf ../build/contracts/combined
mkdir -p ../build/contracts/combined
solc ContentBackchain.sol --combined-json abi,asm,ast,bin,bin-runtime,clone-bin,devdoc,interface,opcodes,srcmap,srcmap-runtime,userdoc > ../build/contracts/combined/ContentBackchain.json
solc DisputeBackchain.sol --combined-json abi,asm,ast,bin,bin-runtime,clone-bin,devdoc,interface,opcodes,srcmap,srcmap-runtime,userdoc > ../build/contracts/combined/DisputeBackchain.json
popd
