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
      vm.expectRevert(bytes("Token is not transferable"));
      pbmTokenWrapper.safeTransferFrom(alice, bob, 2, 2, "");
      
      pbmLogic.setTransferable(true);
      pbmTokenWrapper.safeTransferFrom(alice, bob, 2, 2, "");
      assertEq(pbmTokenWrapper.balanceOf(alice, 2), 0);
      assertEq(pbmTokenWrapper.balanceOf(bob, 2), 2);
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

      vm.expectRevert(bytes("ERC1155: caller is not token owner or approved"));
      pbmTokenWrapper.safeTransferFrom(alice, bob, 1, 1, "");
      
      uint[] memory transferIDs = new uint[](2);
      ids[0] = 1;
      ids[1] = 2;
      uint[] memory transferAmounts = new uint[](2);
      amounts[0] = 1;
      amounts[1] = 1;
      vm.prank(alice);
      pbmTokenWrapper.setApprovalForAll(address(this), true);
      // vm.expectEmit();
      // pbmTokenWrapper.safeBatchTransferFrom(alice, bob, transferIDs, transferAmounts, "");
      // assertEq(pbmTokenWrapper.balanceOf(alice, 1), 0);
      // assertEq(pbmTokenWrapper.balanceOf(bob, 1), 1);
      // assertEq(pbmTokenWrapper.balanceOf(alice, 2), 1);
      // assertEq(pbmTokenWrapper.balanceOf(bob, 2), 1);
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
