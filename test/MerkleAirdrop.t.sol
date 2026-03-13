// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {MerkleProof} from "../src/MerkleProof.sol";

// Simple ERC20 mock
contract MockERC20 {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "insufficient");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract MerkleAirdropTest is Test {
    MockERC20 token;
    MerkleAirdrop airdrop;

    // 4 airdrop recipients
    address alice   = address(0xA11CE);
    address bob     = address(0xB0B);
    address carol   = address(0xCA601);
    address dave    = address(0xDA7E);

    uint256 aliceAmt  = 100e18;
    uint256 bobAmt    = 200e18;
    uint256 carolAmt  = 300e18;
    uint256 daveAmt   = 400e18;

    // Merkle tree storage
    bytes32[4] leaves;
    bytes32[2] level1;
    bytes32 root;

    // Proofs for each leaf
    bytes32[] aliceProof;
    bytes32[] bobProof;
    bytes32[] carolProof;
    bytes32[] daveProof;

    function _leaf(address account, uint256 amount) internal pure returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
    }

    function _hashPair(bytes32 a, bytes32 b) internal pure returns (bytes32) {
        return a < b
            ? keccak256(abi.encodePacked(a, b))
            : keccak256(abi.encodePacked(b, a));
    }

    function setUp() public {
        token = new MockERC20();

        // Build 4-leaf Merkle tree
        // Leaves
        leaves[0] = _leaf(alice, aliceAmt);
        leaves[1] = _leaf(bob, bobAmt);
        leaves[2] = _leaf(carol, carolAmt);
        leaves[3] = _leaf(dave, daveAmt);

        // Level 1
        level1[0] = _hashPair(leaves[0], leaves[1]);
        level1[1] = _hashPair(leaves[2], leaves[3]);

        // Root
        root = _hashPair(level1[0], level1[1]);

        // Build proofs
        // Alice proof: [leaves[1], level1[1]]
        aliceProof.push(leaves[1]);
        aliceProof.push(level1[1]);

        // Bob proof: [leaves[0], level1[1]]
        bobProof.push(leaves[0]);
        bobProof.push(level1[1]);

        // Carol proof: [leaves[3], level1[0]]
        carolProof.push(leaves[3]);
        carolProof.push(level1[0]);

        // Dave proof: [leaves[2], level1[0]]
        daveProof.push(leaves[2]);
        daveProof.push(level1[0]);

        // Deploy airdrop
        airdrop = new MerkleAirdrop(address(token), root);

        // Fund airdrop contract
        token.mint(address(airdrop), aliceAmt + bobAmt + carolAmt + daveAmt);
    }

    function test_ClaimSuccess() public {
        uint256 before = token.balanceOf(alice);

        vm.prank(alice);
        airdrop.claim(alice, aliceAmt, aliceProof);

        assertEq(token.balanceOf(alice), before + aliceAmt);
        assertTrue(airdrop.claimed(alice));
    }

    function test_CannotClaimTwice() public {
        vm.prank(alice);
        airdrop.claim(alice, aliceAmt, aliceProof);

        vm.prank(alice);
        vm.expectRevert(MerkleAirdrop.AlreadyClaimed.selector);
        airdrop.claim(alice, aliceAmt, aliceProof);
    }

    function test_InvalidProofReverts() public {
        // Use bob's proof for alice
        vm.prank(alice);
        vm.expectRevert(MerkleAirdrop.InvalidProof.selector);
        airdrop.claim(alice, aliceAmt, bobProof);
    }

    function test_FullMerkleTree() public {
        // All 4 can claim
        vm.prank(alice);
        airdrop.claim(alice, aliceAmt, aliceProof);

        vm.prank(bob);
        airdrop.claim(bob, bobAmt, bobProof);

        vm.prank(carol);
        airdrop.claim(carol, carolAmt, carolProof);

        vm.prank(dave);
        airdrop.claim(dave, daveAmt, daveProof);

        assertEq(token.balanceOf(alice), aliceAmt);
        assertEq(token.balanceOf(bob), bobAmt);
        assertEq(token.balanceOf(carol), carolAmt);
        assertEq(token.balanceOf(dave), daveAmt);
        assertEq(airdrop.remainingBalance(), 0);
    }

    function test_WrongAmountReverts() public {
        vm.prank(alice);
        vm.expectRevert(MerkleAirdrop.InvalidProof.selector);
        airdrop.claim(alice, aliceAmt + 1, aliceProof);
    }
}
