let fs = require("fs");
let Web3 = require('web3');
let web3 = new Web3();
web3.setProvider(new web3.providers.HttpProvider('http://public-lb-ethereum-testnet-477233981.us-east-2.elb.amazonaws.com:8545'));

let orchestratorAcct = process.argv[2];
let orchestratorPass = process.argv[3];

web3.eth.personal.unlockAccount(orchestratorAcct, orchestratorPass, 120).then(function() {
  console.info('Orchestrator account authenticated.');
  let contractNames = ['ContentBackchain', 'DisputeBackchain'];
  contractNames.forEach((contractName) => {
    console.info('Deploying ' + contractName);
    let source = fs.readFileSync("../build/contracts/combined/" + contractName + ".json");
    let contracts = JSON.parse(source)["contracts"];
    let abi = JSON.parse(contracts[contractName + ".sol:" + contractName].abi);
    let code = '0x' + contracts[contractName + ".sol:" + contractName].bin;

    let contract = new web3.eth.Contract(abi);
    let txn = contract.deploy({ data: code });
    txn.send({
      from: orchestratorAcct,
      gas: 6000000,
      gasPrice: '1000000'
    })
    .on('error', function(error){ console.info("Error", error); })
    .then(function(newContractInstance){
      console.log('Deployed ' + contractName + ' to address ' + newContractInstance.options.address);
    });
  });
});
