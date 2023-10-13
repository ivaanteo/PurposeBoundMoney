// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PBMTokenWrapper.sol";

struct TokenType {
        uint denomination;
        uint amount; // total supply
        uint256 expiryDate;
        string creator;
        string tokenURI;
    }

contract PBMTokenManager {

    // Public Variables
    uint public pbmExpiry;

    // Private Variables
    TokenType[] public _tokenTypes;

    address public owner;
    address public factory;
    address public tokenWrapperAddress;

    modifier onlyOwner() {
        require(msg.sender == owner, "TokenManager: Only owner can call this function.");
        _;
    }

    constructor(uint _pbmExpiry, address _owner) {
        pbmExpiry = _pbmExpiry;
        owner = _owner;
        factory = msg.sender;
    }

    function setTokenWrapperAddress(address _tokenWrapperAddress) public {
        require(msg.sender == factory, "TokenManager: Only factory can call this function.");
        tokenWrapperAddress = _tokenWrapperAddress;
    }

    function createTokenType(
        uint denomination, // value
        uint amount, // mint amount
        uint tokenExpiry, // expiry date in unix timestamp
        string calldata creator, 
        string calldata tokenURI
        ) 
        public 
        onlyOwner 
        returns (uint256) {
        // Owner should transfer underlying into TokenWrapper
        uint totalValue = denomination * amount;
        ERC20 underlyingToken = PBMTokenWrapper(tokenWrapperAddress).underlyingTokenContract();
        underlyingToken.transferFrom(msg.sender, tokenWrapperAddress, totalValue);
        
        TokenType memory newTokenType = TokenType(denomination, amount, tokenExpiry, creator, tokenURI);
        _tokenTypes.push(newTokenType);
        return _tokenTypes.length-1; // this is the token id
    }

    function getTokenType(uint tokenId) public view returns (TokenType memory){
        return _tokenTypes[tokenId];
    }

    function isTokenExpired(uint tokenId) public view returns (bool) {
        return block.timestamp > _tokenTypes[tokenId].expiryDate;
    }

    function isPbmExpired() public view returns (bool) {
        return block.timestamp > pbmExpiry;   
    }

    function sufficientSupply(uint tokenId, uint amount) public view returns (bool) {
        return _tokenTypes[tokenId].amount >= amount;
    }

    function increaseSupply(uint tokenId, uint amount) public onlyOwner {
        uint totalValue = _tokenTypes[tokenId].denomination * amount;
        ERC20 underlyingToken = PBMTokenWrapper(tokenWrapperAddress).underlyingTokenContract();
        underlyingToken.transferFrom(msg.sender, tokenWrapperAddress, totalValue);
        _tokenTypes[tokenId].amount += amount;
    }

    function decreaseSupply(uint tokenId, uint amount) public {
        require(msg.sender == tokenWrapperAddress, "TokenManager: Only token wrapper can call this function.");
        require(_tokenTypes[tokenId].amount >= amount, "TokenManager: Insufficient supply");
        _tokenTypes[tokenId].amount -= amount;
    }

    function getTokenValue(uint tokenId, uint amount) public view returns (uint) {
        return _tokenTypes[tokenId].denomination * amount;
    }
}