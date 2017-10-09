# onechain-back

Provides both the smart contract and client API for One Network Enterprises' Backchain.
The Backchain is a blockchain used to verify transactions in a supply chain network where
transient trust is delegated to an Orchestrator.

Licensed under the [Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).


## Setup

Setup for Windows environments:
 * install [VirtualBox](https://www.virtualbox.org/)
 * install [Vagrant](https://www.vagrantup.com/)
 * Run `vagrant plugin install vagrant-vbguest`
 * Clone the onechain-back repo using `git clone https://github.com/onenetwork/onechain-back.git`
 * cd to the `onechain-back` directory in the cloned folder
 * Modify the file `Vagrant`, repointing "E:/views/onechain-back" to your cloned onechain-back directory in the line: `config.vm.synced_folder "E:/views/onechain-back", "/vagrant"`
 * Run `vagrant up` to provision and start the VM
 * Run `vagrant ssh` to connect to the VM
 * This will put you in `/vagrant`, which is bound to your local `onechain-back` directory, and should be your location for executing commands and doing work
 * Run `bk help` for further instructions

## Developing

The current version provides an [Ethereum](https://ethereum.org/)-based implementation of the blockchain.

Start the test server by executing:
```
bk start
```

Navigate to the `/vagrant/eth` directory, where the contract definitions and testcases are kept.  To deploy the contract
and execute the unit tests, run:
```
truffle compile
truffle migrate
truffle test
```

The client API is in its initial phases of development and is available under `/vagrant/client` directory.
To build it, run:

```
npm install --no-bin-links
```
