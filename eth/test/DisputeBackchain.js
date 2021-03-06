var DisputeBackchain = artifacts.require("./DisputeBackchain.sol");

contract('DisputeBackchain', function(accounts) {

    it("should be initialized with a orchestrator and no hashes", function() {
        var dbk;
        return DisputeBackchain.deployed().then(function(instance) {
            dbk = instance;
            return dbk.getOrchestrator.call();
        }).then(function(orchestrator) {
            assert.equal(orchestrator.toString(), accounts[0], "DisputeBackchain should be initialized with an orchestraotr");
            assert.notEqual(orchestrator.toString(), accounts[1], "DisputeBackchain should be initialized with a orchestrator");
            return dbk.getDisputeHeader.call("0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480");
        }).then(function() {
            return Promise.reject("Exception anticipated");
        }).catch(function(reason) {
            if ((reason.message || reason).indexOf("disputing party") > -1) {
                assert.fail(reason.message);
            }
        });
    });

    it("should accept posts from the disputing party", function() {
        var dbk;
        return DisputeBackchain.deployed().then(function(instance) {
            dbk = instance;
            return dbk.submitDispute("0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", accounts[0], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4481", ["0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4482", "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4483"], "HASH_NOT_FOUND", {
                from: accounts[0]
            });
        }).then(function() {
            return dbk.getDisputeHeader.call("0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480");
        }).then(function(disputeHeader) {
            assert.equal(disputeHeader[0], accounts[0], "DisputingParty should match ");
            assert.equal(disputeHeader[1], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4481", "disputedTransactionId should match ");
            return dbk.submitDispute("0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", accounts[0], "0xbfef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", ["0xcfef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "0xdfef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480"], "HASH_NOT_FOUND", {
                from: accounts[0]
            });
        }).then(function() {
            return dbk.getDisputeHeader.call("0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480");
        }).then(function(disputeHeader) {
            assert.equal(disputeHeader[0], accounts[0], "DisputingParty should match ");
            assert.equal(disputeHeader[1], "0xbfef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "disputedTransactionId should match ");
            return dbk.submitDispute("0x1fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", accounts[1], "0x2fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", ["0x3fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "0x4fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480"], "HASH_NOT_FOUND", {
                from: accounts[1]
            });
        }).then(function() {
            return dbk.getDisputeHeader.call("0x1fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480");
        }).then(function(disputeHeader) {
            assert.equal(disputeHeader[0], accounts[1], "DisputingParty should match ");
            assert.equal(disputeHeader[1], "0x2fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "disputedTransactionId should match ");
            return dbk.submitDispute("", accounts[1], "0x2fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", ["0x3fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "0x4fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480"], "HASH_NOT_FOUND", {
                from: accounts[1]
            });
        }).then(function() {
            return dbk.filterDisputesByState.call([], [0]);
        }).then(function(disputeIds) {
            assert.equal(disputeIds.length, 4, "the length of disputeID should be 4  " + disputeIds);
            return dbk.submitDispute("0x6fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", accounts[0], "0x2fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", ["0x3fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "0x4fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480"], "HASH_NOT_FOUND", {
                from: accounts[1]
            });
        }).then(function() {
            return Promise.reject("Exception anticipated");
        }).catch(function(reason) {
            if ((reason.message || reason).indexOf("disputing party") > -1) {
                assert.fail(reason.message);
            }
        });
    });

    it("should get Dispute by DisputeID", function() {
        var dbk;
        var disputeIDArray = [];
        return DisputeBackchain.deployed().then(function(instance) {
            dbk = instance;
            return dbk.filterDisputeByHeaders.call([],[],[],[], [accounts[0]])
        }).then(function(disputeIds) {
            assert.equal(disputeIds.length, 4, "the length of disputeID should be 2");
            assert.equal(disputeIds[0], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "hash should be 0x5fef7");
            dbk.getDisputeHeader.call(disputeIds[0]).then(function(result) {
                assert.equal(result[0], accounts[0], "disputing party address did not matched" + result);
                assert.equal(result[1], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4481", "disputed TransactionID did not matched");
                assert.equal(result[2][0], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4482", "disputing party address did not matched");
                assert.equal(result[2][1], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4483", "disputedBusinessTransactionIDs did not matched");
            });
            assert.equal(disputeIds[1], "0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "hash should be 0xafef7");
            dbk.getDisputeHeader.call(disputeIds[1]).then(function(result) {
                assert.equal(result[0], accounts[0], "disputing party address did not matched" + result);
                assert.equal(result[1], "0xbfef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "disputed TransactionID did not matched");
                assert.equal(result[2][0], "0xcfef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "disputing party address did not matched");
                assert.equal(result[2][1], "0xdfef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "disputedBusinessTransactionIDs did not matched");
            });
            return dbk.filterDisputeByHeaders.call([],[],[],[], [accounts[1]])
        }).then(function(disputeIds) {
            assert.equal(disputeIds.length, 4, "the length of disputeID should be 2");
            assert.equal(disputeIds[0], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "hash should be 0x5fef74575d");
            dbk.getDisputeHeader.call(disputeIds[0]).then(function(result) {
                assert.equal(result[0], accounts[0], "disputing party address did not matched" + result);
                assert.equal(result[1], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4481", "disputed TransactionID did not matched");
                assert.equal(result[2][0], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4482", "disputing party address did not matched");
                assert.equal(result[2][1], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4483", "disputedBusinessTransactionIDs did not matched");
            });
        });
    });

    it("should filter Dispute", function() {
        var dbk;
        var disputeIDArray = [];
        return DisputeBackchain.deployed().then(function(instance) {
            dbk = instance;
            return dbk.filterDisputeByHeaders.call([],[],[],[], [accounts[0]])
        }).then(function(disputeIds) {
            assert.equal(disputeIds.length, 4, "the length of disputeID should be 4");
            assert.equal(disputeIds[0], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "hash should be 0x5fef7");
            assert.equal(disputeIds[1], "0xafef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "hash should be 0xafef7");
            return dbk.filterDisputeByHeaders.call([],[],[],[], [accounts[1]])
        }).then(function(disputeIds) {
            assert.equal(disputeIds.length, 4, "the length of disputeID should be 4");
            assert.equal(disputeIds[0], "0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", "hash should be 0x5fef74575");
            return dbk.filterDisputeByHeaders.call([],[],[],[], [0]);
        }).then(function(disputeIds) {
            assert.equal(disputeIds.length, 4, "the length of disputeID should be 4");
            return dbk.closeDispute("0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480", {
                from: accounts[0]
            });
        }).then(function() {
            return dbk.getDisputeDetail.call("0x5fef74575dfb567cd95678f80c8c2681d2c084da2a95b3643cf6e13e739f4480");
        }).then(function(result) {
            assert.equal(result[2], "CLOSED", "dispute state did not matched " + result);
            return dbk.filterDisputeByHeaders.call([],[],[],[], [1]);
        }).then(function(disputeIds) {
            assert.equal(disputeIds.length, 4, "the length of disputeID should be 4");
        });
    });
});