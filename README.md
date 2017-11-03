# onechain-back

Provides both the smart contract for One Network Enterprises' Backchain.
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

A test server is started by default when you start the vagrant box.  At the end of provisioning, you will see something like this, which tells you the IP/port, smart contract address, and private key values:
```
==> default: Test backchain server available at http://192.168.201.55:8545
==> default: Backchain contract address is 0xc5d4b021858a17828532e484b915149af5e1b138
==> default: Orchestrator private key is 0x8ad0132f808d0830c533d7673cd689b7fde2d349ff0610e5c04ceb9d6efb4eb1
==> default: Participant private key is 0x69bc764651de75758c489372c694a39aa890f911ba5379caadc08f44f8173051
```
This should give you enough information to connect to the backchain using a client such as [onechain-back-client](https://github.com/onenetwork/onechain-back-client).


To view the test server logs, type:
```
bk log
```

You can re-start the test server by executing:
```
bk stop
bk start
```

To modify, deploy and test the smart contract, navigate to the `/vagrant/eth` directory.  The solidity code lives in `contracts`.  After modifying these files, you may run these commands to compile, deploy and test the updated contract:
```
truffle compile
truffle migrate
truffle test
```
