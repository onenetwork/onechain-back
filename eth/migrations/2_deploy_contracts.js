var ContentBackchain = artifacts.require("./ContentBackchain.sol");

module.exports = function(deployer) {
  deployer.deploy(ContentBackchain);
};
