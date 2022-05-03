// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./DAOArchitectGenericToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteTokenFactory is Ownable {
    event GovernorTokenCreated(address indexed govTokenOwner, address govTokenAddress, string govTokenName, string govTokenSymbol);

    mapping (bytes32 => bool) public govTokenSymbolToUsedMap;

    function createGovernorToken(address _tokenOwner, string memory _tokenName, string memory _tokenSymbol, uint256 _tokenInitialSupply) 
            external returns (address) {
        require(_tokenOwner != address(0), "Invalid token owner address");
        require(bytes(_tokenName).length > 0, "The governance token name is empty");
        require(bytes(_tokenSymbol).length > 0, "The governance token symbol is empty");
        bytes32 tokenSymbolHash = keccak256(abi.encode(_tokenSymbol));
        require(govTokenSymbolToUsedMap[tokenSymbolHash] == false, "The token symbol is already used");
        require(_tokenInitialSupply > 0, "The governance token initial supply must be greater than zero");

        //instantiate a new governance token
        govTokenSymbolToUsedMap[tokenSymbolHash] = true;
        DAOArchitectGenericToken govToken = new DAOArchitectGenericToken(_tokenOwner, _tokenName, _tokenSymbol, _tokenInitialSupply);
        require(address(govToken) != address(0), "Governance token contract not created");
        govToken.transferOwnership(_tokenOwner);
        emit GovernorTokenCreated(_tokenOwner, address(govToken), _tokenName, _tokenSymbol);

        return address(govToken);
    }
}