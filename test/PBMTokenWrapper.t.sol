// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {PBMTokenWrapper} from "../src/PBMTokenWrapper.sol";
import {PBMTokenManager} from "../src/PBMTokenManager.sol";
import {PBMLogic} from "../src/PBMLogic.sol";

contract PBMTokenWrapperTest is Test {
    Factory public factory;
    PBMLogic public pbmLogic;
    PBMTokenManager public pbmTokenManager;
    PBMTokenWrapper public pbmTokenWrapper;

    function setUp() public {
        factory = new Factory(
          1896249508, 
          true, 
          address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F)
          );
        pbmLogic = PBMLogic(factory.pbmLogicAddress());
        pbmTokenManager = PBMTokenManager(factory.pbmTokenManagerAddress());
        pbmTokenWrapper = PBMTokenWrapper(factory.pbmTokenWrapperAddress());
    }

    function testOnlyOwner() public {
      vm.expectRevert(bytes("Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.setPbmLogic(address(0));
      
      vm.expectRevert(bytes("Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.setPbmTokenManager(address(0));
      
      vm.expectRevert(bytes("Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.setUnderlyingToken(address(0));
      
      vm.expectRevert(bytes("Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.setURI("TESTURI");
      
      vm.expectRevert(bytes("Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.pause();
      
      vm.expectRevert(bytes("Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.unpause();
      
      vm.expectRevert(bytes("Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.mint(address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F), 1, 1, "");
      
      vm.expectRevert(bytes("Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      uint[] memory ids = new uint[](1);
      ids[0] = 1;
      uint[] memory amounts = new uint[](1);
      amounts[0] = 1;
      pbmTokenWrapper.mintBatch(address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F), ids, amounts, "");
    }

}
