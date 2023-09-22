// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./PBMLogic.sol";
import "./PBMTokenWrapper";

contract PBMTokenWrapper is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {
    address private _pbmLogicAddress;
    address private _pbmTokenManagerAddress;
    address private _underlyingTokenAddress;
    uint private _pbmExpiry;
    
    constructor(
        address pbmLogicAddress_, 
        address pbmTokenManagerAddress_, 
        address underlyingTokenAddress_,
        uint pbmExpiry_
    ) ERC1155("") {
        _pbmLogicAddress = pbmLogicAddress_;
        _pbmTokenManagerAddress = pbmTokenManagerAddress_;
        _underlyingTokenAddress = underlyingTokenAddress_;
        _pbmExpiry = pbmExpiry_;
    }


    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        
        // Call TokenManager's increaseSupply
        pbmLogicContract = new PBMLogic(_pbmLogicAddress);
        pbmLogicContract.increaseSupply(id, amount);

        _mint(account, id, amount, data);
        
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}
