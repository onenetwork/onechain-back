// Copyright (c) 2003-2009, One Network Enterprises, Inc. All rights reserved.

package main

import (
        "fmt"
        "strconv"
        "github.com/hyperledger/fabric/core/chaincode/shim"
        sc "github.com/hyperledger/fabric/protos/peer"
)

/*
 * ONE's Backchain smart contract allows an "Orchestrator"
 * to post SHA256 hashes. The hashes are formed from JSON messages capturing 
 * business transactions executed in the Orchestrator's supply chain system.  
 * The JSON messages are shared point-to-point (outside of the block chain) with 
 * participating organizations, who can then hash and verify them later against
 * the block chain to ensure they posted with the claimed content at the claimed time.
 * This provides a mechanism for "transient trust" of the Orchestrator.
 */
type ContentBackChain struct {
}

// Key for persisting number of hash count in ledger
const NUMBER_OF_HASHES string = "NumberOfHashes"

// Key for persisting Orchestrator public key in ledger
const ORCHESTRATOR string = "Orchestrator"

/*
 * The Init method is called when the Smart Contract "ContentBackChain" is instantiated by the blockchain network
 */
func (s *ContentBackChain) Init(APIstub shim.ChaincodeStubInterface) sc.Response {
        hashCountAsBytes, _ := APIstub.GetState(NUMBER_OF_HASHES)
        if hashCountAsBytes == nil {
                APIstub.PutState(NUMBER_OF_HASHES, []byte("0"))
        }
        
        // Persist orchestrator 
        args := APIstub.GetArgs()
        APIstub.PutState(ORCHESTRATOR, []byte(args[0]))
  
        return shim.Success(nil)
}

/*
 * The Invoke method is called as a result of an application request to run the Smart Contract "ContentBackChain"
 * The calling application program has also specified the particular smart contract function to be called, with arguments
 */
func (s *ContentBackChain) Invoke(APIstub shim.ChaincodeStubInterface) sc.Response {

        // Retrieve the requested Smart Contract function and arguments
        function, args := APIstub.GetFunctionAndParameters()

        if function == "post" {
                return s.post(APIstub, args)
        } else if function == "verify" {
                return s.verify(APIstub, args)
        } else if function == "hashCount" {
		return s.hashCount(APIstub, args)
	}

        return shim.Error("Invalid chaincode request.")
}

// Places a new hash on the Backchain. Only the Orchestrator can post a hash. 
func (s *ContentBackChain) post(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {  
        if len(args) != 2 {
                return shim.Error("Incorrect number of arguments. Expecting 2.")
        }

        // Validate Creator should be Orchestrator
	creator := args[1]	
        orchestratorAsBytes, _ := APIstub.GetState(ORCHESTRATOR)
	orchestrator := string(orchestratorAsBytes)
        if(creator != orchestrator){
                return shim.Error("Only the Orchestrator may post a hash.") 
        }
 
        APIstub.PutState(args[0], []byte(args[0]))

        // Increment NUMBER_OF_HASHES count by 1
        hashCountAsBytes, _ := APIstub.GetState(NUMBER_OF_HASHES)
        hashCountAsString := string(hashCountAsBytes)
        hashCount, _ := strconv.ParseInt(hashCountAsString, 10, 64)
        hashCount = hashCount + 1
        hashCountAsString = strconv.FormatInt(hashCount, 10) 

        APIstub.PutState(NUMBER_OF_HASHES, []byte(hashCountAsString))

        return shim.Success(nil)
}

// Returns the total number of hashes on the Backchain.
func (s *ContentBackChain) hashCount(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
        hashCountAsBytes, _ := APIstub.GetState(NUMBER_OF_HASHES)
        return shim.Success(hashCountAsBytes)
}

/*
 * Returns true if the given has is in the Backchain (and is therefore "verified"),
 * returns false otherwise
 */
func (s *ContentBackChain) verify(APIstub shim.ChaincodeStubInterface, args []string) sc.Response {
        if len(args) != 1 {
                return shim.Error("Incorrect number of arguments. Expecting 1.")
        }

        hashAsBytes, _ := APIstub.GetState(args[0])
	if hashAsBytes == nil {
                return shim.Success([]byte(strconv.FormatBool(false)))
	} else {
                return shim.Success([]byte(strconv.FormatBool(true)))
        }
 }

 func main() {
        err := shim.Start(new(ContentBackChain))
        if err != nil {
                fmt.Printf("Error creating new Smart Contract: %s", err)
        }
}
