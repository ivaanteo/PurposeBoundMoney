// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {PBMTokenWrapper} from "../src/PBMTokenWrapper.sol";
import {PBMTokenManager} from "../src/PBMTokenManager.sol";
import {PBMLogic} from "../src/PBMLogic.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PBMTokenManagerTest is Test {
    Factory public factory;
    PBMLogic public pbmLogic;
    PBMTokenManager public pbmTokenManager;
    PBMTokenWrapper public pbmTokenWrapper;
    MockUSDC public underlyingToken;

    function setUp() public {
        factory = new Factory();
        underlyingToken = new MockUSDC();
        uint id = factory.deploy(
          1896249508, 
          true, 
          address(underlyingToken)
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
      
      underlyingToken.mint(address(this), 10000);
      underlyingToken.approve(address(pbmTokenManager), 10000);
      uint id = pbmTokenManager.createTokenType(1, 2, 0, "creator", "uri");
      assertEq(underlyingToken.balanceOf(address(pbmTokenWrapper)), 2);
      assertEq(underlyingToken.balanceOf(address(this)), 9998);
      
      assertEq(pbmTokenManager.getTokenType(id).denomination, 1);
      assertEq(pbmTokenManager.getTokenType(id).amount, 2);
      assertEq(pbmTokenManager.getTokenType(id).expiryDate, 0);
      assertEq(pbmTokenManager.getTokenType(id).creator, "creator");
      assertEq(pbmTokenManager.getTokenType(id).tokenURI, "uri");
      assertEq(pbmTokenManager.isTokenExpired(id), true);
    }

    function testIncreaseSupply() public {
      underlyingToken.mint(address(this), 3);
      underlyingToken.approve(address(pbmTokenManager), 3);
      uint id = pbmTokenManager.createTokenType(1, 2, 0, "creator", "uri");
      assertEq(pbmTokenManager.getTokenType(id).amount, 2);
      
      
      vm.expectRevert(bytes("ERC20: insufficient allowance"));
      pbmTokenManager.increaseSupply(id, 3);
      
      vm.prank(address(1));
      vm.expectRevert(bytes("TokenManager: Only owner can call this function."));
      pbmTokenManager.increaseSupply(id, 1);
      
      pbmTokenManager.increaseSupply(id, 1);
      assertEq(pbmTokenManager.getTokenType(id).amount, 3);
    }

    function testGetTokenValue() public {
      underlyingToken.mint(address(this), 8);
      underlyingToken.approve(address(pbmTokenManager), 8);
      uint id = pbmTokenManager.createTokenType(4, 2, 0, "creator", "uri");
      assertEq(pbmTokenManager.getTokenValue(id, 2), 8);
    }

    
}
