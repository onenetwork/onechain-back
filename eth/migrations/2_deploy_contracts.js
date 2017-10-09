var Backchain = artifacts.require("./Backchain.sol");

module.exports = function(deployer) {
  deployer.deploy(Backchain);
};
