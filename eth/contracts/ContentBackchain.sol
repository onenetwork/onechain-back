pragma solidity ^0.4.0;

/// ONE's Backchain smart contract allows an "Orchestrator"
/// to post SHA256 hashes.  The hashes are formed from JSON messages capturing 
/// business transactions executed in the Orchestrator's supply chain system.  
/// The JSON messages are shared point-to-point (outside of the block chain) with 
/// participating organizations, who can then hash and verify them later against
/// the block chain to ensure they posted with the claimed content at the claimed time.
/// This provides a mechanism for "transient trust" of the Orchestrator.
contract ContentBackchain {

  /// The Orchestrator is the only entity permitted to post hashes
  address public orchestrator;

  mapping (bytes32 => bool) public hashMapping;
  bytes32[] hashes;

  /// The creator of the contract will become the Orchestrator
  function ContentBackchain() {
    orchestrator = msg.sender;
  }

  /// Places a new hash on the Backchain. Only the Orchestrator may post a hash.
  function post(bytes32 hash) {
    require(msg.sender == orchestrator);
    if (hashMapping[hash]) return;
    hashMapping[hash] = true;
    hashes.push(hash);
  }

  /// Returns the total number of hashes on the Backchain.
  function hashCount() constant returns (uint) {
    return hashes.length;
  }
  
  /// Returns true if the given has is in the Backchain (and is therefore "verified"),
  /// returns false otherwise
  function verify(bytes32 hash) constant returns (bool) {
    return hashMapping[hash];
  }

  /// Hashes are stored in a sequential list, starting from zero
  /// and ending at hashCount() - 1.
  /// This function returns the hash at the given index.
  function getHash(uint index) constant returns (bytes32) {
    return hashes[index];
  }
  
}
