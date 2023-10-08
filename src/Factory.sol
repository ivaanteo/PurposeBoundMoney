// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PBMTokenManager.sol";
import "./PBMTokenWrapper.sol";
import "./PBMLogic.sol";

contract Factory {
  
  struct PBMToken {
    address pbmTokenManagerAddress;
    address pbmTokenWrapperAddress;
    address pbmLogicAddress;
  }

  uint count;
  PBMToken[] private _pbmTokens;
  
  function deploy(
    uint _pbmExpiry, 
    bool _isTransferable, 
    address underlyingTokenAddress
  ) public returns (uint) {
    require(_pbmExpiry > block.timestamp, "Factory: Invalid expiry");
    require(underlyingTokenAddress != address(0), "Factory: Invalid underlying token address");
    require(underlyingTokenAddress != address(this), "Factory: Invalid underlying token address");

    address pbmLogicAddress = address(new PBMLogic(_isTransferable, msg.sender));
    address pbmTokenManagerAddress = address(new PBMTokenManager(_pbmExpiry, msg.sender));
    address pbmTokenWrapperAddress = address(
      new PBMTokenWrapper(
        pbmLogicAddress,
        pbmTokenManagerAddress,
        underlyingTokenAddress,
        _pbmExpiry,
        msg.sender
      )
    );
    PBMTokenManager(pbmTokenManagerAddress).setTokenWrapperAddress(pbmTokenWrapperAddress);
    PBMToken memory newPBMToken = PBMToken(pbmTokenManagerAddress, pbmTokenWrapperAddress, pbmLogicAddress);
    _pbmTokens.push(newPBMToken);
    return _pbmTokens.length - 1;
  }

  function getPBMToken (uint id) public view returns (PBMToken memory) {
    require(id < _pbmTokens.length, "Factory: Invalid id");
    return _pbmTokens[id];
  }
}