// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract PBMLogic {
    mapping (address => bool) private _whitelist;
    bool public isTransferable;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Logic: Only owner can call this function.");
        _;
    }

    constructor(bool _isTransferable, address _owner) {
        owner = _owner;
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

    function setTransferable(bool _isTransferable) public onlyOwner {
        isTransferable = _isTransferable;
    }
}