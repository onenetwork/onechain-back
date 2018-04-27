var DisputeBackchain = artifacts.require("./DisputeBackchain.sol");

module.exports = function(deployer) {
  deployer.deploy(DisputeBackchain);
};
