// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./PBMLogic.sol";
import "./PBMTokenManager.sol";

contract PBMTokenWrapper is ERC1155, Pausable, ERC1155Burnable, ERC1155Supply {
    
    PBMLogic pbmLogicContract; 
    PBMTokenManager pbmTokenManagerContract;
    ERC20 underlyingTokenContract;

    uint private _pbmExpiry;
    address public owner;

    modifier onlyTransferable() {
        require(
            pbmLogicContract.isTransferable(), 
            "TokenWrapper: Token is not transferable"
        );
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "TokenWrapper: Only owner can call this function.");
        _;
    }

    constructor(
        address pbmLogicAddress_, 
        address pbmTokenManagerAddress_, 
        address underlyingTokenAddress_,
        uint pbmExpiry_,
        address _owner
    ) ERC1155("") {
        owner = _owner;
        _pbmExpiry = pbmExpiry_;
        pbmLogicContract = PBMLogic(pbmLogicAddress_);
        pbmTokenManagerContract = PBMTokenManager(pbmTokenManagerAddress_);
        underlyingTokenContract = ERC20(underlyingTokenAddress_);
    }

    function setPbmLogic(address pbmLogicAddress_) public onlyOwner {
        pbmLogicContract = PBMLogic(pbmLogicAddress_);
    }

    function setPbmTokenManager(address pbmTokenManagerAddress_) public onlyOwner {
        pbmTokenManagerContract = PBMTokenManager(pbmTokenManagerAddress_);
    }

    function setUnderlyingToken(address underlyingTokenAddress_) public onlyOwner {
        underlyingTokenContract = ERC20(underlyingTokenAddress_);
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

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override onlyTransferable {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        if(pbmLogicContract.isAddressWhitelisted(to)) {
            // redemption logic
            uint256[] memory ids = new uint[](1);
            ids[0] = id;
            uint256[] memory amounts = new uint[](1);
            amounts[0] = amount;
            _redeem(from, to, ids, amounts);
        } else {
            _safeTransferFrom(from, to, id, amount, data);
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyTransferable {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        if(pbmLogicContract.isAddressWhitelisted(to)) {
            // redemption logic
            _redeem(from, to, ids, amounts);
        } else {
            _safeBatchTransferFrom(from, to, ids, amounts, data);
        }
        
        
    }

    function _redeem(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) private {
        require(ids.length == amounts.length, "TokenWrapper: Number of IDs does not match amounts");
        require(_pbmExpiry > block.timestamp, "TokenWrapper: PBM has expired"); // pbm expiry
        uint totalValue;
        for (uint i = 0; i < ids.length; i++) {
            require(!pbmTokenManagerContract.isTokenExpired(ids[i]), "TokenWrapper: Token expired"); // token expiry   
            totalValue += pbmTokenManagerContract.getTokenValue(ids[i], amounts[i]);
        }
        underlyingTokenContract.transfer(to, totalValue);
        burnBatch(from, ids, amounts);
        for (uint i = 0; i < ids.length; i++) {
            pbmTokenManagerContract.decreaseSupply(ids[i], amounts[i]);
        }
    }
}
