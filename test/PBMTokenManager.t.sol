// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {PBMTokenWrapper} from "../src/PBMTokenWrapper.sol";
import {PBMTokenManager} from "../src/PBMTokenManager.sol";
import {PBMLogic} from "../src/PBMLogic.sol";

contract PBMTokenManagerTest is Test {
    Factory public factory;
    PBMLogic public pbmLogic;
    PBMTokenManager public pbmTokenManager;
    PBMTokenWrapper public pbmTokenWrapper;

    function setUp() public {
        factory = new Factory();
        uint id = factory.deploy(
          1896249508, 
          true, 
          address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F)
        );
        pbmLogic = PBMLogic(factory.getPBMToken(id).pbmLogicAddress);
        pbmTokenManager = PBMTokenManager(factory.getPBMToken(id).pbmTokenManagerAddress);
        pbmTokenWrapper = PBMTokenWrapper(factory.getPBMToken(id).pbmTokenWrapperAddress);
    }

    function testPBMExpiry() public {
      assertEq(pbmTokenManager.isPbmExpired(), false);
    }

    function testCreateTokenType() public {
      vm.prank(address(1));
      vm.expectRevert(bytes("TokenManager: Only owner can call this function."));
      pbmTokenManager.createTokenType(1, 2, 3, "creator", "uri");
      
      uint id = pbmTokenManager.createTokenType(1, 2, 0, "creator", "uri");
      assertEq(pbmTokenManager.getTokenType(id).denomination, 1);
      assertEq(pbmTokenManager.getTokenType(id).amount, 2);
      assertEq(pbmTokenManager.getTokenType(id).expiryDate, 0);
      assertEq(pbmTokenManager.getTokenType(id).creator, "creator");
      assertEq(pbmTokenManager.getTokenType(id).tokenURI, "uri");
      assertEq(pbmTokenManager.isTokenExpired(id), true);
    }

    function testIncreaseSupply() public {
      uint id = pbmTokenManager.createTokenType(1, 2, 0, "creator", "uri");
      assertEq(pbmTokenManager.getTokenType(id).amount, 2);
      
      vm.prank(address(1));
      vm.expectRevert(bytes("TokenManager: Only owner can call this function."));
      pbmTokenManager.increaseSupply(id, 3);
      
      pbmTokenManager.increaseSupply(id, 3);
      assertEq(pbmTokenManager.getTokenType(id).amount, 5);
    }

    function testDecreaseSupply() public {
      uint id = pbmTokenManager.createTokenType(1, 2, 0, "creator", "uri");
      assertEq(pbmTokenManager.getTokenType(id).amount, 2);
      
      vm.expectRevert(bytes("TokenManager: Only token wrapper can call this function."));
      pbmTokenManager.decreaseSupply(id, 3);
      
      vm.prank(address(pbmTokenWrapper));
      pbmTokenManager.decreaseSupply(id, 1);
      assertEq(pbmTokenManager.getTokenType(id).amount, 1);
    }

    function testGetTokenValue() public {
      uint id = pbmTokenManager.createTokenType(4, 2, 0, "creator", "uri");
      assertEq(pbmTokenManager.getTokenValue(id, 2), 8);
    }

    
}
