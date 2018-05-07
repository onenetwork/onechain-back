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

  address private orchestrator;
  bytes32[] private disputeIDs;
  mapping (bytes32 => Dispute) private disputeIdToDisputeMapping;
  uint disputeSubmissionWindowInMinutes;

  /**
   * get orchestrator
   */
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
  
  /// Places a new hash on the DsiputeBackchain.
  function submitDispute(bytes32 disputeID, address disputingPartyAddress, bytes32 disputedTransactionID, bytes32[] disputedBusinessTransactionIDs, string reasonCode) {
    require(msg.sender == disputingPartyAddress);
    require(verify(disputeID) == false);
    Reason reasonValue = getReasonValue(reasonCode);
    if(disputeID.length <= 0) {
      disputeID = keccak256(disputingPartyAddress,disputedTransactionID, disputedBusinessTransactionIDs);
    }
    disputeIdToDisputeMapping[disputeID] = Dispute({disputeId:disputeID, disputingParty:disputingPartyAddress, disputedTransactionId:disputedTransactionID, disputedBusinessTransactionIds:disputedBusinessTransactionIDs, submittedDate:now, closeDate:0, state:State.OPEN, reason:reasonValue});
    disputeIDs.push(disputeID);
  }

  /**
   * close Dispute
   */
  function closeDispute(bytes32 id) public {
    Dispute storage dispute = disputeIdToDisputeMapping[id];
    if(verify(dispute, id)) {
      if(dispute.state == State.OPEN) {
        require(msg.sender == dispute.disputingParty);
        dispute.state = State.CLOSED;
        dispute.closeDate = now;
        require(disputeIdToDisputeMapping[id].state == State.CLOSED);
        return;
      }
    }
    revert();
  }

  function verify(bytes32 id) private constant returns(bool) {
    return verify(disputeIdToDisputeMapping[id], id);
  }


  function verify(Dispute dispute, bytes32 id) private constant returns(bool) {
    return dispute.disputeId == id;
   }

  /**
   * get header information of Dispute (disputingParty,disputedTransactionId, disputedBusinessTransactionIds)
   */
  function getDisputeHeader(bytes32 id) public constant returns(address, bytes32, bytes32[]) {
    Dispute memory dispute = disputeIdToDisputeMapping[id];
    if (verify(dispute, id)) {
      return (dispute.disputingParty, dispute.disputedTransactionId, dispute.disputedBusinessTransactionIds);
    }
    revert();
  }

  /**
   * get Detail information of Dispute (submittedDate, closeDate, state, reason)
   */
  function getDisputeDetail(bytes32 id) public constant returns(uint, uint, string, string) {
    Dispute memory dispute = disputeIdToDisputeMapping[id];
    if (verify(dispute, id)) {
      return (dispute.submittedDate, dispute.closeDate, getStateStringValue(dispute.state), getReasonStringValue(dispute.reason));
    }
    revert();
  }

  /**
   * filter Disputes by disputingParty addresses
   */
  function filterDisputesByDisputingParty(bytes32[] ids, address[] disputingParties) public constant returns(bytes32[]) {
    if (ids.length > 0 && disputingParties.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      Dispute memory dispute;
      for (uint i = 0; i < ids.length; i++) {
        dispute = disputeIdToDisputeMapping[ids[i]];
        if (verify(dispute, ids[i])) {
          for(uint j = 0; j < disputingParties.length; j++) {
            if(dispute.disputingParty == disputingParties[j]) {
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
    if (disputeIDs.length > 0 && disputingParties.length > 0) {
      return filterDisputesByDisputingParty(disputeIDs, disputingParties);
    }
    return new bytes32[](0);
  }

  /**
   * filter Disputes by TransactionIDs 
   */
  function filterDisputesByDisputedTransactionIDs(bytes32[] ids, bytes32[] disputedTransactionIDs) public constant returns(bytes32[]) {
    if (ids.length > 0 && disputedTransactionIDs.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      Dispute memory dispute;
      for (uint i = 0; i < ids.length; i++) {
        dispute = disputeIdToDisputeMapping[ids[i]];
        if (verify(dispute, ids[i])) {
          for(uint j = 0; j < disputedTransactionIDs.length; j++) {
            if(dispute.disputedTransactionId == disputedTransactionIDs[j]) {
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
    if (disputeIDs.length > 0 && disputedTransactionIDs.length > 0) {
      return filterDisputesByDisputedTransactionIDs(disputeIDs, disputedTransactionIDs);
    }
    return new bytes32[](0);
  }

  /**
   * filter Disputes by Business TransactionIDs 
   */
  function filterDisputesByDisputedBusinessTransactionIDs(bytes32[] ids, bytes32[] disputedBusinessTransactionIds) public constant returns(bytes32[]) {
    if (ids.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      Dispute memory dispute;
      for (uint i = 0; i < ids.length; i++) {
        dispute = disputeIdToDisputeMapping[ids[i]];
        if (verify(dispute, ids[i])) {
          for (uint j = 0; j < disputedBusinessTransactionIds.length; j++) {
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

  /**
   * filter Disputes by Headers (disputingParties, disputedTransactionIDs, disputedBusinessTransactionIDs)
   */
  function filterDisputeByHeaders(bytes32[] ids, address[] disputingParties, bytes32[] disputedTransactionIDs, bytes32[] disputedBusinessTransactionIDs) public constant returns(bytes32[]) {
    if (ids.length > 0){
      bytes32[] memory returnDisputeIDs = ids;
      if (disputingParties.length > 0) {
        returnDisputeIDs = filterDisputesByDisputingParty(returnDisputeIDs, disputingParties);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (disputedTransactionIDs.length > 0) {
        returnDisputeIDs = filterDisputesByDisputedTransactionIDs(returnDisputeIDs, disputedTransactionIDs);
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
      return filterDisputeByHeaders(disputeIDs, disputingParties, disputedTransactionIDs, disputedBusinessTransactionIDs);
    }
    return new bytes32[](0);
  }

  /**
   * filter Disputes by Headers (submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd, stateValues, reasonValues)
   */
  function filterDisputeByDetail(bytes32[] ids, uint submittedDateStart, uint submittedDateEnd, uint closedDateStart, uint closedDateEnd, uint[] stateValues, uint[] reasonValues) public constant returns(bytes32[]) {
    if (ids.length > 0){
      bytes32[] memory returnDisputeIDs = ids;
      if ((submittedDateStart == 0 && submittedDateStart != submittedDateEnd) || (closedDateStart == 0 && closedDateStart != closedDateEnd)) {
        returnDisputeIDs = filterDisputesByDates(returnDisputeIDs, submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (stateValues.length > 0) {
        returnDisputeIDs = filterDisputesByState(returnDisputeIDs, stateValues);
      }
      if (returnDisputeIDs.length == 0) {
        return new bytes32[](0);
      }
      if (reasonValues.length > 0) {
        returnDisputeIDs = filterDisputesByReason(returnDisputeIDs, reasonValues);
      }
      return returnDisputeIDs;
    }
    if (disputeIDs.length > 0) {
      return filterDisputeByDetail(disputeIDs, submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd, stateValues, reasonValues);
    }
    return new bytes32[](0);
  }

  /**
   * filter Disputes by start and end dates (submittedDateStart, submittedDateEnd, closedDateStart, closedDateEnd)
   */
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

  /**
   * filter Disputes by state values
   */
  function filterDisputesByState(bytes32[] ids, uint[] stateValues) public constant returns(bytes32[]) {
    if (ids.length > 0 && stateValues.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      Dispute memory dispute;
      for (uint i = 0; i < ids.length; i++) {
        dispute = disputeIdToDisputeMapping[ids[i]];
        if (verify(dispute, ids[i])) {
          for (uint j = 0; j < stateValues.length; j++) {
            if (uint(dispute.state) == stateValues[j]) {
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
    if (disputeIDs.length > 0 && stateValues.length > 0) {
      return filterDisputesByState(disputeIDs, stateValues);
    }
    return new bytes32[](0);
  }

  /**
   * filter Disputes by reason values
   */
  function filterDisputesByReason(bytes32[] ids, uint[] reasonValues) public constant returns(bytes32[]) {
    if (ids.length > 0 && reasonValues.length > 0){
      uint[] memory locationPointer = new uint[](ids.length);
      uint count=0;
      Dispute memory dispute;
      for (uint i = 0; i < ids.length; i++) {
        dispute = disputeIdToDisputeMapping[ids[i]];
        if (verify(dispute, ids[i])) {
          for (uint j = 0; j < reasonValues.length; j++) {
            if (uint(dispute.reason) == reasonValues[j]) {
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
    if (disputeIDs.length > 0 && reasonValues.length > 0) {
      return filterDisputesByReason(disputeIDs, reasonValues);
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
