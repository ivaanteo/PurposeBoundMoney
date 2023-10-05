// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Factory} from "../src/Factory.sol";
import {PBMTokenWrapper} from "../src/PBMTokenWrapper.sol";
import {PBMTokenManager} from "../src/PBMTokenManager.sol";
import {PBMLogic} from "../src/PBMLogic.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract PBMTokenWrapperTest is Test {
    Factory public factory;
    PBMLogic public pbmLogic;
    PBMTokenManager public pbmTokenManager;
    PBMTokenWrapper public pbmTokenWrapper;
    MockUSDC public underlyingToken;

    function setUp() public {
      underlyingToken = new MockUSDC();
      address usdcAddress = address(underlyingToken);

      factory = new Factory();
      uint id = factory.deploy(
        1896249508, 
        true, 
        usdcAddress
      );
      pbmLogic = PBMLogic(factory.getPBMToken(id).pbmLogicAddress);
      pbmTokenManager = PBMTokenManager(factory.getPBMToken(id).pbmTokenManagerAddress);
      pbmTokenWrapper = PBMTokenWrapper(factory.getPBMToken(id).pbmTokenWrapperAddress);
      
      pbmTokenManager.createTokenType(
      1,
      2,
      1896208, // expiry date in unix timestamp
      "bobby",
      "https://shitcoin.com"
      );
      pbmTokenManager.createTokenType(
      2,
      3,
      1896208, // expiry date in unix timestamp
      "charlie",
      "https://shitcoin2.com"
      );
    }

    function testMint() public {
      address alice = address(1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);
      
      pbmTokenWrapper.mint(alice, 1, 1, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 1);
      
      pbmTokenWrapper.mint(alice, 1, 2, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 3);
      
      assertEq(pbmTokenWrapper.balanceOf(alice, 2), 0);

      address zero = address(0);
      vm.expectRevert(bytes("ERC1155: mint to the zero address"));
      pbmTokenWrapper.mint(zero, 1, 1, "");
    }

    function testMintBatch() public {
      address alice = address(1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);

      uint[] memory ids = new uint[](2);
      ids[0] = 1;
      ids[1] = 2;
      uint[] memory amounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 2;
      pbmTokenWrapper.mintBatch(alice, ids, amounts, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 2), 2);

      address zero = address(0);
      vm.expectRevert(bytes("ERC1155: mint to the zero address"));
      pbmTokenWrapper.mintBatch(zero, ids, amounts, "");
    }

    function testBurn() public {
      address alice = address(1);
      uint[] memory ids = new uint[](2);
      ids[0] = 1;
      ids[1] = 2;
      uint[] memory amounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 2;
      pbmTokenWrapper.mintBatch(alice, ids, amounts, "");

      vm.prank(alice);
      pbmTokenWrapper.setApprovalForAll(address(this), true);
      pbmTokenWrapper.burn(alice, 1, 1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);
      assertEq(pbmTokenWrapper.balanceOf(alice, 2), 2);

      //increase totalSupply so error message below is correct
      pbmTokenWrapper.mint(address(2), 2, 1, "");

      vm.expectRevert(bytes("ERC1155: burn amount exceeds balance"));
      pbmTokenWrapper.burn(alice, 2, 3);
    }

    function testTransferFrom() public {
      address alice = address(1);
      address bob = address(2);
      uint[] memory ids = new uint[](2);
      ids[0] = 1;
      ids[1] = 2;
      uint[] memory amounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 2;
      pbmTokenWrapper.mintBatch(alice, ids, amounts, "");

      vm.expectRevert(bytes("ERC1155: caller is not token owner or approved"));
      pbmTokenWrapper.safeTransferFrom(alice, bob, 1, 1, "");

      vm.prank(alice);
      pbmTokenWrapper.setApprovalForAll(address(this), true);
      pbmTokenWrapper.safeTransferFrom(alice, bob, 1, 1, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);
      assertEq(pbmTokenWrapper.balanceOf(bob, 1), 1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 2), 2);
      assertEq(pbmTokenWrapper.balanceOf(bob, 2), 0);

      vm.expectRevert(bytes("ERC1155: insufficient balance for transfer"));
      pbmTokenWrapper.safeTransferFrom(alice, bob, 2, 3, "");

      pbmLogic.setTransferable(false);
      vm.expectRevert(bytes("TokenWrapper: Token is not transferable"));
      pbmTokenWrapper.safeTransferFrom(alice, bob, 2, 2, "");
      
      pbmLogic.setTransferable(true);
      pbmTokenWrapper.safeTransferFrom(alice, bob, 2, 2, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 2), 0);
      assertEq(pbmTokenWrapper.balanceOf(bob, 2), 2);
    }

    function testTransferFromWhenWhitelisted() public {
      // Given
      address alice = address(1);
      address bob = address(2);
      uint[] memory ids = new uint[](2);
      ids[0] = 0;
      ids[1] = 1;
      uint[] memory amounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 2;
      pbmTokenWrapper.mintBatch(alice, ids, amounts, "");
      
      // Setup
      pbmLogic.addToWhitelist(bob);
      assertEq(pbmLogic.isAddressWhitelisted(bob), true);
      underlyingToken.mint(address(pbmTokenWrapper), 100000000);

      // When
      vm.prank(alice);
      pbmTokenWrapper.setApprovalForAll(address(this), true);
      pbmTokenWrapper.safeTransferFrom(alice, bob, 0, 1, "");
      
      // Then
      assertEq(pbmTokenWrapper.balanceOf(alice, 0), 0);
      assertEq(pbmTokenWrapper.balanceOf(bob, 0), 0); // Bob's balance should be 0 since token is burnt
      assertEq(underlyingToken.balanceOf(bob), 1);
      
      // Tear Down
      pbmLogic.removeFromWhitelist(bob);
    }

    function testBatchTransferFromWhenWhitelisted() public {

    }

    function testBatchTransferFrom() public {
      address alice = address(1);
      address bob = address(2);
      uint[] memory ids = new uint[](2);
      ids[0] = 1;
      ids[1] = 2;
      uint[] memory amounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 2;
      pbmTokenWrapper.mintBatch(alice, ids, amounts, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 2), 2);

      uint[] memory transferIDs = new uint[](2);
      ids[0] = 1;
      ids[1] = 2;
      uint[] memory transferAmounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 0;
      vm.expectRevert(bytes("ERC1155: caller is not token owner or approved"));
      pbmTokenWrapper.safeBatchTransferFrom(alice, bob, transferIDs, transferAmounts, "");
      
      vm.prank(alice);
      pbmTokenWrapper.setApprovalForAll(address(this), true);
      pbmTokenWrapper.safeBatchTransferFrom(alice, bob, transferIDs, transferAmounts, "");
      console2.log("ALICE TOKEN 2 BALANCe", pbmTokenWrapper.balanceOf(alice, 2));
      console2.log("ALICE TOKEN 1 BALANCe", pbmTokenWrapper.balanceOf(alice, 1));
      console2.log("BOB TOKEN 1 BALANCe", pbmTokenWrapper.balanceOf(bob, 1));
      console2.log("Bob TOKEN 2 BALANCe", pbmTokenWrapper.balanceOf(bob, 2));
      // assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);
      // assertEq(pbmTokenWrapper.balanceOf(bob, 1), 1);
      // assertEq(pbmTokenWrapper.balanceOf(alice, 2), 2);
      // assertEq(pbmTokenWrapper.balanceOf(bob, 2), 1);
    }

    function testOnlyOwner() public {
      vm.expectRevert(bytes("TokenWrapper: Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.setPbmLogic(address(0));
      
      vm.expectRevert(bytes("TokenWrapper: Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.setPbmTokenManager(address(0));
      
      vm.expectRevert(bytes("TokenWrapper: Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.setUnderlyingToken(address(0));
      
      vm.expectRevert(bytes("TokenWrapper: Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.setURI("TESTURI");
      
      vm.expectRevert(bytes("TokenWrapper: Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.pause();
      
      vm.expectRevert(bytes("TokenWrapper: Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.unpause();
      
      vm.expectRevert(bytes("TokenWrapper: Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      pbmTokenWrapper.mint(address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F), 1, 1, "");
      
      vm.expectRevert(bytes("TokenWrapper: Only owner can call this function."));
      vm.prank(address(0)); //changes function caller to 0 address
      uint[] memory ids = new uint[](1);
      ids[0] = 1;
      uint[] memory amounts = new uint[](1);
      amounts[0] = 1;
      pbmTokenWrapper.mintBatch(address(0x07865c6E87B9F70255377e024ace6630C1Eaa37F), ids, amounts, "");
    }

}
