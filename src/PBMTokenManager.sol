// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";


contract PBMTokenManager is Ownable {

    // Public Variables
    mapping(uint => TokenType) private _tokenIdToTokenTypeMapping;
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

    constructor() {
        
    }

    function createTokenType(
        uint denomination, // 
        uint amount, // mint amount
        uint tokenExpiry, // expiry date in unix timestamp
        string calldata creator, 
        string calldata tokenURI, 
        uint _pbmExpiry
        ) public onlyOwner {
        TokenType memory newTokenType = TokenType(denomination, amount, tokenExpiry, creator, tokenURI);
        _tokenTypes.push(newTokenType);
        pbmExpiry = _pbmExpiry;
    }

    function getTokenTypes() public view returns (TokenType[] memory){
        return _tokenTypes;
    }
}