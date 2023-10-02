// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";

contract FactoryTest is Test {
    Factory public factory;

    function setUp() public {
        factory = new Factory(1896249508, true, address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F));
    }

    function testDeploy() public {
        assertNotEq(factory.pbmLogicAddress(), address(0));
        assertNotEq(factory.pbmTokenManagerAddress(), address(0));
        assertNotEq(factory.pbmTokenWrapperAddress(), address(0));
    }
}
