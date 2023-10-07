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
      
      underlyingToken.mint(address(this), 100000000);
      underlyingToken.approve(address(pbmTokenManager), 100000000);
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
      assertEq(pbmTokenWrapper.balanceOf(alice, 0), 0);
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);
      
      pbmTokenWrapper.mint(alice, 0, 1, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 0), 1);
      assertEq(pbmTokenManager.getTokenType(0).amount, 1);
      
      pbmTokenWrapper.mint(alice, 1, 2, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 2);

      address zero = address(0);
      vm.expectRevert(bytes("ERC1155: mint to the zero address"));
      pbmTokenWrapper.mint(zero, 1, 1, "");
      
      vm.expectRevert(bytes("TokenWrapper: Insufficient supply"));
      pbmTokenWrapper.mint(alice, 0, 2, "");
    }

    function testMintBatch() public {
      address alice = address(1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);

      uint[] memory ids = new uint[](2);
      ids[0] = 0;
      ids[1] = 1;
      uint[] memory amounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 1;
      pbmTokenWrapper.mintBatch(alice, ids, amounts, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 0), 1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 1);

      uint[] memory ids2 = new uint[](2);
      ids2[0] = 0;
      ids2[1] = 1;
      uint[] memory amounts2 = new uint[](2);
      amounts2[0] = 3;
      amounts2[1] = 3;
      vm.expectRevert(bytes("TokenWrapper: Insufficient supply"));
      pbmTokenWrapper.mintBatch(alice, ids2, amounts2, "");
    }

    function testBurn() public {
      address alice = address(1);
      uint[] memory ids = new uint[](2);
      ids[0] = 0;
      ids[1] = 1;
      uint[] memory amounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 2;
      pbmTokenWrapper.mintBatch(alice, ids, amounts, "");

      vm.prank(alice);
      pbmTokenWrapper.setApprovalForAll(address(this), true);
      pbmTokenWrapper.burn(alice, 0, 1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 0), 0);
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 2);

      //increase totalSupply so error message below is correct
      pbmTokenWrapper.mint(address(2), 1, 1, "");

      vm.expectRevert(bytes("ERC1155: burn amount exceeds balance"));
      pbmTokenWrapper.burn(alice, 1, 3);
    }

    function testTransferFrom() public {
      address alice = address(1);
      address bob = address(2);
      uint[] memory ids = new uint[](2);
      ids[0] = 0;
      ids[1] = 1;
      uint[] memory amounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 2;
      pbmTokenWrapper.mintBatch(alice, ids, amounts, "");

      vm.expectRevert(bytes("ERC1155: caller is not token owner or approved"));
      pbmTokenWrapper.safeTransferFrom(alice, bob, 0, 1, "");

      vm.prank(alice);
      pbmTokenWrapper.setApprovalForAll(address(this), true);
      pbmTokenWrapper.safeTransferFrom(alice, bob, 0, 1, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 0), 0);
      assertEq(pbmTokenWrapper.balanceOf(bob, 0), 1);
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 2);
      assertEq(pbmTokenWrapper.balanceOf(bob, 1), 0);

      vm.expectRevert(bytes("ERC1155: insufficient balance for transfer"));
      pbmTokenWrapper.safeTransferFrom(alice, bob, 1, 3, "");

      pbmLogic.setTransferable(false);
      vm.expectRevert(bytes("TokenWrapper: Token is not transferable"));
      pbmTokenWrapper.safeTransferFrom(alice, bob, 1, 2, "");
      
      pbmLogic.setTransferable(true);
      pbmTokenWrapper.safeTransferFrom(alice, bob, 1, 2, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);
      assertEq(pbmTokenWrapper.balanceOf(bob, 1), 2);
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
      pbmLogic.setTransferable(false);
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
      pbmLogic.setTransferable(false);
      assertEq(pbmLogic.isAddressWhitelisted(bob), true);
      underlyingToken.mint(address(pbmTokenWrapper), 100000000);

      // When
      uint[] memory transferIDs = new uint[](2);
      transferIDs[0] = 0;
      transferIDs[1] = 1;
      uint[] memory transferAmounts = new uint[](2);
      transferAmounts[0] = 1;
      transferAmounts[1] = 1;
      vm.prank(alice);
      pbmTokenWrapper.setApprovalForAll(address(this), true);
      pbmTokenWrapper.safeBatchTransferFrom(alice, bob, transferIDs, transferAmounts, "");
      
      // Then
      assertEq(pbmTokenWrapper.balanceOf(alice, 0), 0);
      assertEq(pbmTokenWrapper.balanceOf(bob, 0), 0); // Bob's balance should be 0 since token is burnt
      assertEq(underlyingToken.balanceOf(bob), 3);
      
      // Tear Down
      pbmLogic.removeFromWhitelist(bob);

    }

    function testBatchTransferFrom() public {
        address alice = address(1);
        address bob = address(2);
        assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);
        uint[] memory mintIDs = new uint[](2);
        mintIDs[0] = 0;
        mintIDs[1] = 1;
        uint[] memory mintAmounts = new uint[](2);
        mintAmounts[0] = 1;
        mintAmounts[1] = 1;
        pbmTokenWrapper.mintBatch(alice, mintIDs, mintAmounts, "");
        assertEq(pbmTokenWrapper.balanceOf(alice, 0), 1);
        assertEq(pbmTokenWrapper.balanceOf(alice, 1), 1);
        uint[] memory ids = new uint[](2);
        ids[0] = 0;
        ids[1] = 1;
        uint[] memory amounts = new uint[](2);
        amounts[0] = 1;
        amounts[1] = 0;
        
        vm.expectRevert(bytes("ERC1155: caller is not token owner or approved"));
        pbmTokenWrapper.safeBatchTransferFrom(alice, bob, ids, amounts, "");
        
        vm.prank(alice);
        pbmTokenWrapper.setApprovalForAll(address(this), true);
        pbmTokenWrapper.safeBatchTransferFrom(alice, bob, ids, amounts, "");

        assertEq(pbmTokenWrapper.balanceOf(bob, 0), 1);
        assertEq(pbmTokenWrapper.balanceOf(bob, 1), 0);
        assertEq(pbmTokenWrapper.balanceOf(alice, 0), 0);
        assertEq(pbmTokenWrapper.balanceOf(alice, 1), 1);

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
