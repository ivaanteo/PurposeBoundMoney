// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";

contract FactoryTest is Test {
    Factory public factory;

    function setUp() public {
        factory = new Factory();
    }

    function testDeploy() public {
        uint id = factory.deploy(1896249508, true, address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F));
        assertNotEq(factory.getPBMToken(id).pbmLogicAddress, address(0));
        assertNotEq(factory.getPBMToken(id).pbmTokenManagerAddress, address(0));
        assertNotEq(factory.getPBMToken(id).pbmTokenWrapperAddress, address(0));
        
    }
}
