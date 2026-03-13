// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MerkleProof} from "./MerkleProof.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MerkleAirdrop {
    error AlreadyClaimed();
    error InvalidProof();

    event Claimed(address indexed account, uint256 amount);

    IERC20 public immutable token;
    bytes32 public immutable merkleRoot;

    mapping(address => bool) public claimed;

    constructor(address _token, bytes32 _merkleRoot) {
        require(_token != address(0), "invalid token");
        token = IERC20(_token);
        merkleRoot = _merkleRoot;
    }

    /// @notice Claim airdrop tokens
    /// @param account The claiming address
    /// @param amount The amount to claim
    /// @param proof Merkle proof verifying the claim
    function claim(address account, uint256 amount, bytes32[] calldata proof) external {
        if (claimed[account]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert InvalidProof();

        claimed[account] = true;
        require(token.transfer(account, amount), "transfer failed");

        emit Claimed(account, amount);
    }

    /// @notice Check how many tokens remain in the airdrop contract
    function remainingBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
}
