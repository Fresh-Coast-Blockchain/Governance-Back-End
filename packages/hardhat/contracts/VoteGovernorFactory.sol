// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./VoteTimelock.sol";
import "./VoteGovernorAlpha.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteGovernorFactory is Ownable {
    event GovernorCreated(address indexed govOwner, address govAddress, string govName);

    address public voteTokenAddr;
    mapping (address => address) public ownerToGovMap;

    constructor(address _voteTokenAddr) {
        voteTokenAddr = _voteTokenAddr;
    }

    function createGovernor(string memory  _governorName, uint256 _timelockDelay, uint256 _votingDelay, uint256 _votingPeriod, 
            uint256 _proposalThreshold, uint256 _votingThreshold) public payable returns (address) {
        require(bytes(_governorName).length > 0, "Governor instance name is empty");
        require(ownerToGovMap[msg.sender] == address(0), "A Governance instance already exists for this address");
        require(_timelockDelay > 0, "Time lock delay parameter is 0");
        require(_votingDelay > 0, "Voting delay parameter is 0");
        require(_votingPeriod > 0, "Voting period parameter is 0");
        require(voteTokenAddr != address(0), "Vote token contract address not set");
        require(_proposalThreshold >= 1, "Proposal threshold can't be less than one");
        require(_votingThreshold >= 1, "Voting threshold can't be less than one");

        VoteTimelock voteTimeLock = new VoteTimelock(msg.sender, _timelockDelay);
        require(address(voteTimeLock) != address(0), "Time lock contract not created");
        //console.log("VoteTimelock created at address: %s", address(voteTimeLock));
        VoteGovernorAlpha governor = new VoteGovernorAlpha(_governorName, address(voteTimeLock), voteTokenAddr, msg.sender, _votingDelay, 
                _votingPeriod, _proposalThreshold, _votingThreshold);
        require(address(governor) != address(0), "Governor Contract not created");
        //console.log("VoteGovernorAlpha created at address: %s", address(governor));
        ownerToGovMap[msg.sender] = address(governor);
        //console.log("ownerToGovMap set for owner: %s --> the governor address is: %s", msg.sender, ownerToGovMap[msg.sender]);
        emit GovernorCreated(msg.sender, address(governor), _governorName);
        //console.log("GovernorCreated event emitted");
        return address(governor);
    }

    function getGovernorAddress(address _owner) public view returns (address) {
        require(_owner != address(0), "Can not use the zero address");
        return ownerToGovMap[_owner];
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send balance to the withdrawal address");
    }
}