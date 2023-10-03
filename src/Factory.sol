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
  mapping(uint => PBMToken) private _pbmTokens;
  
  function deploy(
    uint _pbmExpiry, 
    bool _isTransferable, 
    address underlyingTokenAddress
  ) public returns (uint) {
    address pbmTokenManagerAddress = address(new PBMTokenManager(_pbmExpiry, msg.sender));
    address pbmLogicAddress = address(new PBMLogic(_isTransferable, msg.sender));
    address pbmTokenWrapperAddress = address(
      new PBMTokenWrapper(
        pbmLogicAddress,
        pbmTokenManagerAddress,
        underlyingTokenAddress,
        _pbmExpiry,
        msg.sender
      )
    );
    PBMToken memory newPBMToken = PBMToken(pbmTokenManagerAddress, pbmTokenWrapperAddress, pbmLogicAddress);
    _pbmTokens[count] = newPBMToken;
    count++;
    return count-1;
  }

  function getPBMToken (uint id) public view returns (PBMToken memory) {
    return _pbmTokens[id];
  }
}