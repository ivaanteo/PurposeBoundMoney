// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./PBMTokenManager.sol";
import "./PBMTokenWrapper.sol";
import "./PBMLogic.sol";

contract Factory {
  
  address public pbmTokenManagerAddress;
  address public pbmTokenWrapperAddress;
  address public pbmLogicAddress;
  
  constructor(
    uint _pbmExpiry, 
    bool _isTransferable, 
    address underlyingTokenAddress
    ) {
    pbmTokenManagerAddress = address(new PBMTokenManager(_pbmExpiry, msg.sender));
    pbmLogicAddress = address(new PBMLogic(_isTransferable, msg.sender));
    pbmTokenWrapperAddress = address(
      new PBMTokenWrapper(
        pbmLogicAddress,
        pbmTokenManagerAddress,
        underlyingTokenAddress,
        _pbmExpiry,
        msg.sender
      )
    );
  }
}