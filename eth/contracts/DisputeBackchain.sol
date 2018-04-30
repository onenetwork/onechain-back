pragma solidity ^0.4.0;

contract DisputeBackchain {

  enum State { OPEN, CLOSED}
  enum Reason { INVALID }


  struct Dispute {
    bytes32 disputeId;
    address disputingParty;
    bytes32 disputedTransactionId;
    bytes32[] disputedBusinessTransactionIds;
    uint submittedDate;
    uint closeDate;
    State state;
    Reason reason;
  }

  /// The Orchestrator is the only entity permitted to post hashes
  address private orchestrator;
  bytes32[] private disputeIDs;
  mapping (bytes32 => Dispute) private disputeIdToDisputeMapping;
  uint disputeSubmissionWindowInMinutes;

  function getOrchestrator() public constant returns(address) {
    return orchestrator;
  }

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
  function submitDispute(bytes32 disputeID, address disputingPartyAddress, bytes32 disputedTransactionID, bytes32[] disputedBusinessTransactionIDs, string reasonCode) {
    require(msg.sender == disputingPartyAddress);
    if (verify(disputeID)) return;
    Reason reasonValue = getReasonValue(reasonCode);
    disputeIdToDisputeMapping[disputeID] = Dispute({disputeId:disputeID, disputingParty:disputingPartyAddress, disputedTransactionId:disputedTransactionID, disputedBusinessTransactionIds:disputedBusinessTransactionIDs, submittedDate:now, closeDate:0, state:State.OPEN, reason:reasonValue});
    disputeIDs.push(disputeID);
  }

  function closeDispute(bytes32 id) public {
    Dispute storage dispute = disputeIdToDisputeMapping[id];
    if(verify(dispute, id)) {
      if(dispute.state == State.OPEN) {
        dispute.state = State.CLOSED;
        dispute.closeDate = now;
        require(disputeIdToDisputeMapping[id].state == State.CLOSED);
      }
    }
  }

  function verify(bytes32 id) public constant returns(bool) {
    return verify(disputeIdToDisputeMapping[id], id);
  }


  function verify(Dispute dispute, bytes32 id) private constant returns(bool) {
    if(dispute.disputeId == id) return true;
    return false;
  }

  function getDisputIDs() public constant returns(bytes32[]){
    return disputeIDs;
  }

  function getDisputeBasicDetail(bytes32 id) public constant returns(address, bytes32, bytes32[]) {
    Dispute memory dispute = disputeIdToDisputeMapping[id];
    if (verify(dispute, id)) {
      return (dispute.disputingParty, dispute.disputedTransactionId, dispute.disputedBusinessTransactionIds);
    }
    revert();
  }

  function getDisputedSummaryDetails(bytes32 id) public constant returns(uint, uint, string, string) {
    Dispute memory dispute = disputeIdToDisputeMapping[id];
    if (verify(dispute, id)) {
      return (dispute.submittedDate, dispute.closeDate, getStateStringValue(dispute.state), getReasonStringValue(dispute.reason));
    }
    revert();
  }

  function filterDisputesByDisputingParty(bytes32[] ids, address disputingParty) public constant returns(bytes32[]) {
    if (ids.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      for (uint i = 0; i < ids.length; i++) {
        if (verify(ids[i]) && (disputeIdToDisputeMapping[ids[i]].disputingParty == disputingParty)) {
          locationPointer[count] = i;
          count++;
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = ids[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDs.length > 0) {
      return filterDisputesByDisputingParty(disputeIDs, disputingParty);
    }
    return new bytes32[](0);
  }

  function filterDisputesByDisputedTransactionIDs(bytes32[] ids, bytes32 disputedTransactionID) public constant returns(bytes32[]) {
    if (ids.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      for (uint i = 0; i < ids.length; i++) {
        if (verify(ids[i]) && (disputeIdToDisputeMapping[ids[i]].disputedTransactionId == disputedTransactionID)) {
          locationPointer[count] = i;
          count++;
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = ids[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDs.length > 0) {
      return filterDisputesByDisputedTransactionIDs(disputeIDs, disputedTransactionID);
    }
    return new bytes32[](0);
  }

  function filterDisputesByDisputedBusinessTransactionIDs(bytes32[] ids, bytes32[] disputedBusinessTransactionIds) public constant returns(bytes32[]) {
    if (ids.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      Dispute memory dispute;
      for (uint i = 0; i < ids.length; i++) {
        if (verify(ids[i])) {
          dispute = disputeIdToDisputeMapping[ids[i]];
          for (uint j = 0; j < dispute.disputedBusinessTransactionIds.length; j++) {
            if (dispute.disputedBusinessTransactionIds[j] == disputedBusinessTransactionIds[j]) {
              locationPointer[count] = i;
              count++;
              break;
            }
          }
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = ids[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDs.length > 0) {
      return filterDisputesByDisputedBusinessTransactionIDs(disputeIDs, disputedBusinessTransactionIds);
    }
    return new bytes32[](0);
  }

  function findDispute(bytes32[] ids, address disputingPartyAddress, bytes32 disputedTransactionID, bytes32[] disputedBusinessTransactionIDs) public constant returns(bytes32[]) {
    if (ids.length > 0){
      bytes32[] memory returnDisputeIDs = ids;
      if (disputingPartyAddress != 0x0) {
        returnDisputeIDs = filterDisputesByDisputingParty(returnDisputeIDs, disputingPartyAddress);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (disputedTransactionID.length > 0) {
        returnDisputeIDs = filterDisputesByDisputedTransactionIDs(returnDisputeIDs, disputedTransactionID);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (disputedBusinessTransactionIDs.length > 0) {
        returnDisputeIDs = filterDisputesByDisputedBusinessTransactionIDs(returnDisputeIDs, disputedBusinessTransactionIDs);
      }
      return returnDisputeIDs;
    }
    if (disputeIDs.length > 0) {
      return findDispute(disputeIDs, disputingPartyAddress, disputedTransactionID, disputedBusinessTransactionIDs);
    }
    return new bytes32[](0);
  }

  function findDispute(bytes32[] ids, uint submittedDateStart, uint submittedDateEnd, uint closedDateStart, uint closedDateEnd, string stateValue, string reasonValue) public constant returns(bytes32[]) {
    if (ids.length > 0){
      bytes32[] memory returnDisputeIDs = ids;
      if ((submittedDateStart == 0 && submittedDateStart != submittedDateEnd) || (closedDateStart == 0 && closedDateStart != closedDateEnd)) {
        returnDisputeIDs = filterDisputesByDates(returnDisputeIDs, submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (!stringsEqual(stateValue,"")) {
        returnDisputeIDs = filterDisputesByState(returnDisputeIDs, stateValue);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (!stringsEqual(stateValue,"") || !stringsEqual(reasonValue,"")) {
        returnDisputeIDs = filterDisputesByReason(returnDisputeIDs, reasonValue);
      }
      return returnDisputeIDs;
    }
    if (disputeIDs.length > 0) {
      return findDispute(disputeIDs, submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd, stateValue, reasonValue);
    }
    return new bytes32[](0);
  }

  function filterDisputesByDates(bytes32[] ids, uint submittedDateStart, uint submittedDateEnd,uint closedDateStart, uint closedDateEnd) public constant returns(bytes32[]) {
    if (ids.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      byte bitCheck = 0x0;
      if (submittedDateStart == 0 && submittedDateStart != submittedDateEnd) bitCheck = bitCheck | 0x1;
      if (closedDateStart == 0 && closedDateStart != closedDateEnd) bitCheck = bitCheck | 0x2;
      Dispute memory dispute;
      for (uint i = 0; i < ids.length; i++) {
        dispute = disputeIdToDisputeMapping[ids[i]];
        if (verify(dispute, ids[i])) {
          if ((bitCheck & 0x1) != 0) {
            if(!(dispute.submittedDate >= submittedDateStart && dispute.submittedDate <= submittedDateEnd)) {
              continue;
            }
          }
          if ((bitCheck & 0x2) != 0) {
            if(!(dispute.closeDate >= closedDateStart && dispute.closeDate <= closedDateEnd)) {
              continue;
            }
          }
          locationPointer[count] = i;
          count++;
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = ids[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDs.length > 0) {
      return filterDisputesByDates(disputeIDs, submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd);
    }
    return new bytes32[](0);
  }

  function filterDisputesByState(bytes32[] ids, string stateValue) public constant returns(bytes32[]) {
    if (ids.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      bool isStateValueExist = false;
      if (!stringsEqual(stateValue,"")) isStateValueExist = true;
      State state;
      if (isStateValueExist) {
        state = getStateValue(stateValue);
      }
      for (uint i = 0; i < ids.length; i++) {
        if (isStateValueExist && verify(ids[i]) && (disputeIdToDisputeMapping[ids[i]].state == state)) {
          locationPointer[count] = i;
          count++;
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = ids[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDs.length > 0) {
      return filterDisputesByState(disputeIDs, stateValue);
    }
    return new bytes32[](0);
  }

  function filterDisputesByReason(bytes32[] ids, string reasonValue) public constant returns(bytes32[]) {
    if (ids.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      bool isReasonValueExist = false;
      if (!stringsEqual(reasonValue,"")) isReasonValueExist = true;
      Reason reason;
      if (isReasonValueExist) {
        reason = getReasonValue(reasonValue);
      }
      for (uint i = 0; i < ids.length; i++) {
        if (isReasonValueExist  && verify(ids[i]) && (disputeIdToDisputeMapping[ids[i]].reason == reason)) {
          locationPointer[count] = i;
          count++;
        }
      }
      bytes32[] memory returnDisputeIDs = new bytes32[](count);
      for (uint k = 0; k < count; k++) {
        returnDisputeIDs[k] = ids[locationPointer[k]];
      }
      return returnDisputeIDs;
    }
    if (disputeIDs.length > 0) {
      return filterDisputesByReason(disputeIDs, reasonValue);
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
