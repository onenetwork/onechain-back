pragma solidity ^0.4.0;

contract DisputeBackchain {

  enum State { OPEN, CLOSED}
  enum Reason { INVALID }


  struct Dispute {
    bytes32 disputeId;
    address disputeParty;
    bytes32 disputedTransactionId;
    bytes32[] disputedBusinessTransactionIds;
    uint submittedDate;
    uint closeDate;
    State state;
    Reason reason;
  }

  /// The Orchestrator is the only entity permitted to post hashes
  address private orchestrator;
  bytes32[] private disputeIDHashArray;
  mapping (bytes32 => Dispute) private disputeIdToDisputeMapping;
  mapping (bytes32 => bool) public hashMapping;
  uint disputeSubmissionWindowInMinutes;

  /// The creator of the contract will become the Orchestrator
  function DisputeBackchain() {
    orchestrator = msg.sender;
  }

  function setDisputeSubmissionWindowInMinutes(uint valInMinute) public {
    require(msg.sender == orchestrator);
    disputeSubmissionWindowInMinutes = valInMinute;
  }
  
  function getDisputeSubmissionWindowInMinutes() public constant returns(uint) {
    return disputeSubmissionWindowInMinutes;
  }
  
  /// Places a new hash on the Backchain. Only the Orchestrator may post a hash.
  function submitDispute(bytes32 disputeID, address disputePartyAddress, bytes32 disputedTransactionID, bytes32[] disputedBusinessTransactionIDs, string reasonCode) {
    require(msg.sender == orchestrator);
    if (hashMapping[disputeID]) return;
    Reason reasonValue = getReasonValue(reasonCode);
    disputeIdToDisputeMapping[disputeID] = Dispute({disputeId:disputeID, disputeParty:disputePartyAddress, disputedTransactionId:disputedTransactionID, disputedBusinessTransactionIds:disputedBusinessTransactionIDs, submittedDate:now, closeDate:0, state:State.OPEN, reason:reasonValue});
    hashMapping[disputeID] = true;
    disputeIDHashArray.push(disputeID);
  }

  function closeDispute(bytes32 hashID) public {
    if(hashMapping[hashID] && disputeIdToDisputeMapping[hashID].state == State.OPEN) {
      disputeIdToDisputeMapping[hashID].closeDate = now;
      disputeIdToDisputeMapping[hashID].state = State.CLOSED;
    }
  }

  function verify(bytes32 hashID) public constant returns(bool) {
    return hashMapping[hashID];
  }

  function getDisputeCount() public constant returns(uint){
    return disputeIDHashArray.length;
  }

  function getDisputIDs() public constant returns(bytes32[]){
    return disputeIDHashArray;
  }

  function getDisputeBasicDetail(bytes32 hashID) public constant returns(address, bytes32, bytes32[]) {
   if (hashMapping[hashID]) {
     return (disputeIdToDisputeMapping[hashID].disputeParty, disputeIdToDisputeMapping[hashID].disputedTransactionId, disputeIdToDisputeMapping[hashID].disputedBusinessTransactionIds);
   }
   return (0x0, 0, new bytes32[](0));
  }

  function getDisputedSummaryDetails(bytes32 hashID) public constant returns(uint, uint, string, string) {
   if (hashMapping[hashID]) {
     return (disputeIdToDisputeMapping[hashID].submittedDate, disputeIdToDisputeMapping[hashID].closeDate, getStateStringValue(disputeIdToDisputeMapping[hashID].state), getReasonStringValue(disputeIdToDisputeMapping[hashID].reason));
   }
   return (0, 0, "", "");
  }

  function findDispute(bytes32[] hashIDs, address disputingParty) public constant returns(bytes32[]) {
    if (hashIDs.length > 0){
      uint[] memory locationPointer = new uint[](hashIDs.length);
      uint count=0;
      for (uint i = 0; i < hashIDs.length; i++) {
        if (hashMapping[hashIDs[i]] && (disputeIdToDisputeMapping[hashIDs[i]].disputeParty == disputingParty)) {
          locationPointer[count] = i;
          count++;
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = hashIDs[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDHashArray.length > 0) {
      return findDispute(disputeIDHashArray, disputingParty);
    }
    return new bytes32[](0);
  }

  function findDispute(bytes32[] hashIDs, bytes32 disputedTransactionID) public constant returns(bytes32[]) {
    if (hashIDs.length > 0){
      uint[] memory locationPointer = new uint[](hashIDs.length);
      uint count=0;
      for (uint i = 0; i < hashIDs.length; i++) {
        if (hashMapping[hashIDs[i]] && (disputeIdToDisputeMapping[hashIDs[i]].disputedTransactionId == disputedTransactionID)) {
          locationPointer[count] = i;
          count++;
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = hashIDs[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDHashArray.length > 0) {
      return findDispute(disputeIDHashArray, disputedTransactionID);
    }
    return new bytes32[](0);
  }

  function findDispute(bytes32[] hashIDs, address disputePartyAddress, bytes32 disputedTransactionID, bytes32[] disputedBusinessTransactionIDs) public constant returns(bytes32[]) {
    if (hashIDs.length > 0){
      bytes32[] memory returnDisputeIDs = hashIDs;
      if (disputePartyAddress != 0x0) {
        returnDisputeIDs = findDispute(returnDisputeIDs, disputePartyAddress);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (disputedTransactionID.length > 0) {
        returnDisputeIDs = findDispute(returnDisputeIDs, disputedTransactionID);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (disputedBusinessTransactionIDs.length > 0) {
        returnDisputeIDs = findDispute(returnDisputeIDs, disputedBusinessTransactionIDs);
      }
      return returnDisputeIDs;
    }
    if (disputeIDHashArray.length > 0) {
      return findDispute(disputeIDHashArray, disputePartyAddress, disputedTransactionID, disputedBusinessTransactionIDs);
    }
    return new bytes32[](0);
  }

  function findDispute(bytes32[] hashIDs, uint submittedDateStart, uint submittedDateEnd, uint closedDateStart, uint closedDateEnd, string stateValue, string reasonValue) public constant returns(bytes32[]) {
    if (hashIDs.length > 0){
      bytes32[] memory returnDisputeIDs = hashIDs;
      if ((submittedDateStart == 0 && submittedDateStart != submittedDateEnd) || (closedDateStart == 0 && closedDateStart != closedDateEnd)) {
        returnDisputeIDs = findDispute(returnDisputeIDs, submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (!stringsEqual(stateValue,"") || !stringsEqual(reasonValue,"")) {
        returnDisputeIDs = findDispute(returnDisputeIDs, stateValue, reasonValue);
      }
      return returnDisputeIDs;
    }
    if (disputeIDHashArray.length > 0) {
      return findDispute(disputeIDHashArray, submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd, stateValue, reasonValue);
    }
    return new bytes32[](0);
  }

  function findDispute(bytes32[] hashIDs, bytes32[] disputedBusinessTransactionIds) public constant returns(bytes32[]) {
    if (hashIDs.length > 0){
      uint[] memory locationPointer = new uint[](hashIDs.length);
      uint count=0;
      for (uint i = 0; i < hashIDs.length; i++) {
        if (hashMapping[hashIDs[i]]) {
          for (uint j = 0; j < disputeIdToDisputeMapping[hashIDs[i]].disputedBusinessTransactionIds.length; j++) {
            if (disputeIdToDisputeMapping[hashIDs[i]].disputedBusinessTransactionIds[j] == disputedBusinessTransactionIds[j]) {
              locationPointer[count] = i;
              count++;
              break;
            }
          }
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = hashIDs[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDHashArray.length > 0) {
      return findDispute(disputeIDHashArray, disputedBusinessTransactionIds);
    }
    return new bytes32[](0);
  }

  function findDispute(bytes32[] hashIDs, uint submittedDateStart, uint submittedDateEnd,uint closedDateStart, uint closedDateEnd) public constant returns(bytes32[]) {
    if (hashIDs.length > 0){
      uint[] memory locationPointer = new uint[](hashIDs.length);
      uint count=0;
      byte bitCheck = 0x0;
      if (submittedDateStart == 0 && submittedDateStart != submittedDateEnd) bitCheck = bitCheck | 0x1;
      if (closedDateStart == 0 && closedDateStart != closedDateEnd) bitCheck = bitCheck | 0x2;
      for (uint i = 0; i < hashIDs.length; i++) {
        if (hashMapping[hashIDs[i]]) {
          if ((bitCheck & 0x1) != 0) {
            if(!(disputeIdToDisputeMapping[hashIDs[i]].closeDate >= closedDateStart && disputeIdToDisputeMapping[hashIDs[i]].closeDate <= closedDateEnd)) {
              continue;
            }
          }
          if ((bitCheck & 0x2) != 0) {
            if(!(disputeIdToDisputeMapping[hashIDs[i]].closeDate >= closedDateStart && disputeIdToDisputeMapping[hashIDs[i]].closeDate <= closedDateEnd)) {
              continue;
            }
          }
          locationPointer[count] = i;
          count++;
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = hashIDs[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDHashArray.length > 0) {
      return findDispute(disputeIDHashArray, submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd);
    }
    return new bytes32[](0);
  }

  function findDispute(bytes32[] hashIDs, string stateValue, string reasonValue) public constant returns(bytes32[]) {
    if (hashIDs.length > 0){
      uint[] memory locationPointer = new uint[](hashIDs.length);
      uint count=0;
      byte bitCheck = 0x0;
      if (!stringsEqual(stateValue,"")) bitCheck = bitCheck | 0x1;
      if (!stringsEqual(reasonValue,"")) bitCheck = bitCheck | 0x2;
      State state;
      if ((bitCheck & 0x1) != 0) {
        state = getStateValue(stateValue);
      }
      Reason reason;
      if ((bitCheck & 0x2) != 0) {
        reason = getReasonValue(reasonValue);
      }
      for (uint i = 0; i < hashIDs.length; i++) {
        if (hashMapping[hashIDs[i]]) {
          if ((bitCheck & 0x1) != 0) {
            if(!(disputeIdToDisputeMapping[hashIDs[i]].state == state)) {
              continue;
            }
          }
          if ((bitCheck & 0x2) != 0) {
            if(!(disputeIdToDisputeMapping[hashIDs[i]].reason == reason)) {
              continue;
            }
          }
          locationPointer[count] = i;
          count++;
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = hashIDs[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDHashArray.length > 0) {
      return findDispute(disputeIDHashArray, stateValue, reasonValue);
    }
    return new bytes32[](0);
  }

  function getReasonStringValue(Reason reason) private constant returns (string){
    if(reason == Reason.INVALID) {
      return "INVALID";
    }
    revert();
  }

  function getStateStringValue(State state) private constant returns (string){
    if(state == State.OPEN) {
      return "OPEN";
    }
    if(state == State.CLOSED) {
      return "CLOSED";
    }
    revert();
  }

  function getStateValue(string state) private constant returns (State){
    if(stringsEqual(state,"OPEN")) {
      return State.OPEN;
    }
    if(stringsEqual(state,"CLOSED")) {
      return State.CLOSED;
    }
    revert();
  }

  function getReasonValue(string reason) private constant returns (Reason){
    if(stringsEqual(reason,"INVALID")) {
      return Reason.INVALID;
    }
    revert();
  }

   /// Check string are equal
  function stringsEqual(string _a, string _b) private constant returns (bool) {
    bytes memory a = bytes(_a);
    bytes memory b = bytes(_b);
    if(a.length != b.length) {
      return false;
    }
    for(uint i = 0; i < a.length; i++) {
      if(a[i] != b[i]) return false;
    }
    return true;
  }

}
