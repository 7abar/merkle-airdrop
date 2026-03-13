// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract DeployMerkleAirdrop is Script {
    function run() external {
        address token = vm.envAddress("AIRDROP_TOKEN");
        bytes32 merkleRoot = vm.envBytes32("MERKLE_ROOT");

        vm.startBroadcast();
        MerkleAirdrop airdrop = new MerkleAirdrop(token, merkleRoot);
        console.log("MerkleAirdrop deployed:", address(airdrop));
        console.log("Token:", token);
        console.logBytes32(merkleRoot);
        vm.stopBroadcast();
    }
}
