// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";


contract PBMTokenManager is Ownable {

    // Public Variables
    uint public pbmExpiry;

    // Private Variables
    TokenType[] private _tokenTypes;

    struct TokenType {
        uint denomination;
        uint amount; // total supply
        uint256 expiryDate;
        string creator;
        string tokenURI;
    }

    constructor(uint _pbmExpiry) {
        pbmExpiry = _pbmExpiry;
    }

    function createTokenType(
        uint denomination, // 
        uint amount, // mint amount
        uint tokenExpiry, // expiry date in unix timestamp
        string calldata creator, 
        string calldata tokenURI
        ) 
        public 
        onlyOwner 
        returns (uint256) {
        TokenType memory newTokenType = TokenType(denomination, amount, tokenExpiry, creator, tokenURI);
        _tokenTypes.push(newTokenType);
        return _tokenTypes.length; // this is the token id
    }

    function getTokenType(uint tokenId) public view returns (TokenType memory){
        return _tokenTypes[tokenId];
    }

    function isTokenExpired(uint tokenId) public view returns (bool) {
        return block.timestamp < _tokenTypes[tokenId].expiryDate;
    }

    function isPbmExpired() public view returns (bool) {
        return block.timestamp < pbmExpiry;   
    }

    function increaseSupply(uint tokenId, uint amount) public onlyOwner {
        _tokenTypes[tokenId].amount += amount;
    }

    function decreaseSupply(uint tokenId, uint amount) public onlyOwner {
        require(_tokenTypes[tokenId].amount >= amount);
        _tokenTypes[tokenId].amount -= amount;
    }
}