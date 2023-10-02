// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {PBMTokenWrapper} from "../src/PBMTokenWrapper.sol";
import {PBMTokenManager} from "../src/PBMTokenManager.sol";
import {PBMLogic} from "../src/PBMLogic.sol";

contract PBMLogicTest is Test {
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

    function testTransferable() public {
        assertEq(pbmLogic.isTransferable(), true);
        pbmLogic.setTransferable(false);
        assertEq(pbmLogic.isTransferable(), false);
    }

    function testAddAndRemoveFromWhitelist() public {
        assertEq(pbmLogic.isAddressWhitelisted(address(this)), false);
        pbmLogic.addToWhitelist(address(this));
        assertEq(pbmLogic.isAddressWhitelisted(address(this)), true);
        pbmLogic.removeFromWhitelist(address(this));
        assertEq(pbmLogic.isAddressWhitelisted(address(this)), false);
    }
}
