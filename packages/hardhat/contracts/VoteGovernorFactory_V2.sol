// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./VoteTimelock.sol";
import "./VoteGovernorAlpha.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteGovernorFactory_V2 is Ownable {
    event GovernorCreated(address indexed govOwner, address govAddress, string govName);

    struct GovContractDetails {
        string govName;
        address govAddress;
        string govTokenSymbol;
        address govTokenAddress;
        bool isSet;
    }

    //mapping (address => address) public ownerToGovMap;
    //mapping (address => address) public ownerToGovTokenMap;
    mapping (address => GovContractDetails) public ownerToGovDetailsMap;

    function createGovernor(string memory  _governorName, uint256 _timelockDelay, uint256 _votingDelay, uint256 _votingPeriod, 
            uint256 _proposalThreshold, uint256 _votingThreshold, address _govTokenAddr) public payable returns (address) {
        require(bytes(_governorName).length > 0, "Governor instance name is empty");
        GovContractDetails storage govDetails = ownerToGovDetailsMap[msg.sender];
        require(!govDetails.isSet, "A Governance instance already exists for this address");
        require(_timelockDelay > 0, "Time lock delay parameter is 0");
        require(_votingDelay > 0, "Voting delay parameter is 0");
        require(_votingPeriod > 0, "Voting period parameter is 0");
        require(_govTokenAddr != address(0), "Vote token contract address not set");
        require(_proposalThreshold >= 1, "Proposal threshold can't be less than one");
        require(_votingThreshold >= 1, "Voting threshold can't be less than one");
        
        govDetails.isSet = true;
        govDetails.govTokenAddress = _govTokenAddr;
        govDetails.govName = _governorName;
        
        VoteTimelock voteTimeLock = new VoteTimelock(msg.sender, _timelockDelay);
        require(address(voteTimeLock) != address(0), "Time lock contract not created");
        //console.log("VoteTimelock created at address: %s", address(voteTimeLock));
        VoteGovernorAlpha governor = new VoteGovernorAlpha(_governorName, address(voteTimeLock), _govTokenAddr, msg.sender, _votingDelay, 
                _votingPeriod, _proposalThreshold, _votingThreshold);
        require(address(governor) != address(0), "Governor Contract not created");
        //console.log("VoteGovernorAlpha created at address: %s", address(governor));
        govDetails.govAddress = address(governor);
        //console.log("ownerToGovMap set for owner: %s --> the governor address is: %s", msg.sender, ownerToGovMap[msg.sender]);
        emit GovernorCreated(msg.sender, address(governor), _governorName);
        //console.log("GovernorCreated event emitted");
        return address(governor);
    }

    function getGovernorAddress(address _owner) public view returns (address) {
        require(_owner != address(0), "Can not use the zero address");
        GovContractDetails storage govDetails = ownerToGovDetailsMap[_owner];
        require(govDetails.isSet, "No governance contract exists for this address");
        return govDetails.govAddress;
    }

    function getGovernorDetails(address _owner) public view returns (
            string memory govName, address govAddress, string memory govTokenSymbol, address govTokenAddress) {
        require(_owner != address(0), "Can not use the zero address");
        GovContractDetails storage govDetails = ownerToGovDetailsMap[_owner];
        require(govDetails.isSet, "No governance contract exists for this address");
        govName = govDetails.govName;
        govAddress = govDetails.govAddress;
        govTokenSymbol = govDetails.govTokenSymbol;
        govTokenAddress = govDetails.govTokenAddress;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send balance to the withdrawal address");
    }
}