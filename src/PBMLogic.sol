// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PBMLogic is Ownable {
    mapping (address => bool) private _whitelist;
    bool public isTransferable;

    constructor(bool _isTransferable) {
        isTransferable = _isTransferable;
    }


    function addToWhitelist(address recipient) public onlyOwner {
        _whitelist[recipient] = true;
    }

    function removeFromWhitelist(address recipient) public onlyOwner {
        delete _whitelist[recipient];
    }

    function isAddressWhitelisted(address recipient) public view returns (bool) {
        return _whitelist[recipient];
    }
}