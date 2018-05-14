var ContentBackchain = artifacts.require("./ContentBackchain.sol");

contract('ContentBackchain', function(accounts) {

  it("should be initialized with a orchestrator and no hashes", function() {
    var bk;
    return ContentBackchain.deployed().then(function(instance) {
      bk = instance;
      return bk.hashCount.call();
    }).then(function(hashCount) {
      assert.equal(hashCount.toNumber(), 0, "ContentBackchain should initially be empty");
      return bk.orchestrator.call();
    }).then(function(orchestrator) {
      assert.equal(orchestrator.toString(), accounts[0], "ContentBackchain should be initialized with an orchestraotr");
      assert.notEqual(orchestrator.toString(), accounts[1], "ContentBackchain should be initialized with a orchestrator");
      return bk.verify.call("0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480");
    }).then(function(verified) {
      assert.isFalse(verified, false, "Hash 0xafef... should not have been verified");
    });
  });

  it("should accept posts from the orchestrator", function() {
    var bk;
    var lastHashCount = 0;
    return ContentBackchain.deployed().then(function(instance) {
      bk = instance;
      return bk.post("0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", { from: accounts[0] });
    }).then(function() {
      return bk.hashCount.call();
    }).then(function(hashCount) {
      assert.equal(hashCount.toNumber(), 1, "ContentBackchain should have added one hash");
      return bk.verify.call("0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480");
    }).then(function(verified) {
      assert.equal(verified, true, "Hash 0x5fef... should have been verified");
      return bk.verify.call("0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480");
    }).then(function(verified) {
      assert.equal(verified, false, "Hash 0xafef... should not have been verified");
      return bk.post("0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", { from: accounts[0] });
    }).then(function() {
      return bk.verify.call("0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480");
    }).then(function(verified) {
      assert.equal(verified, true, "Hash 0xafef... should have been verified");
      return bk.hashCount.call();
    }).then(function(hashCount) {
      lastHashCount = hashCount;
      assert.equal(hashCount.toNumber(), 2, "ContentBackchain should have added one hash");
      return bk.post("0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", { from: accounts[0] });
    }).then(function() {
      return bk.hashCount.call();
    }).then(function(hashCount) {
      assert.equal(hashCount.toNumber(), 2, "Should NOT have added a new hash because it was a dupe");
      return bk.getHash.call(0);
    }).then(function(hash) {
      assert.equal(hash, "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "Hash 0x5fef expected at position 0");
    });
  });
  
  it("should reject posts not from the orchestrator", function() {
    var bk;
    return ContentBackchain.deployed().then(function(instance) {
      bk = instance;
      return bk.post("0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", { from: accounts[1] });
    }).then(function() {
      return Promise.reject("Exception anticipated");
    }).catch(function(reason) {
      if ((reason.message || reason).indexOf("Test failed") > -1) {
        assert.fail(reason.message);
      }
    });
  });

});
