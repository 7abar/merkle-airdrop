# Merkle Airdrop

Gas-efficient ERC-20 token airdrop using **Merkle tree proofs**. Written in Solidity with Foundry tests.

## How Merkle Airdrops Work

Instead of storing every recipient on-chain (expensive), a Merkle airdrop stores only the **root hash** of a Merkle tree. To claim, users submit a proof — a small array of hashes — that the contract verifies against the root.

```
         Root
        /    \
     H(0,1)  H(2,3)
     /   \   /   \
   L0   L1  L2   L3
  (alice)(bob)(carol)(dave)
```

Each leaf: `keccak256(keccak256(abi.encode(address, amount)))`  
Double-hashing prevents second preimage attacks.

**Gas savings:** O(log N) proof verification vs O(N) on-chain list.

## Setup

```bash
git clone https://github.com/7abar/merkle-airdrop
cd merkle-airdrop
forge install foundry-rs/forge-std
```

## Run Tests

```bash
forge test
forge test -vvv
```

## Generate the Merkle Tree (TypeScript)

```typescript
import { keccak256, encodePacked, encodeAbiParameters, parseAbiParameters } from "viem";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

// Airdrop list: [address, amount]
const airdropList = [
  ["0xAlice...", "100000000000000000000"],
  ["0xBob...",   "200000000000000000000"],
  ["0xCarol...", "300000000000000000000"],
  ["0xDave...",  "400000000000000000000"],
];

const tree = StandardMerkleTree.of(airdropList, ["address", "uint256"]);

console.log("Merkle Root:", tree.root);

// Get proof for alice (index 0)
const aliceProof = tree.getProof(0);
console.log("Alice proof:", aliceProof);

// Save full tree
import fs from "fs";
fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));
```

Install:
```bash
npm install @openzeppelin/merkle-tree viem
```

## Deploy

```bash
export AIRDROP_TOKEN=0xYourTokenAddress
export MERKLE_ROOT=0xYourMerkleRoot
export PRIVATE_KEY=0xYourPrivateKey

# Fund the contract after deployment!
forge script script/Deploy.s.sol --rpc-url base_sepolia --broadcast --private-key $PRIVATE_KEY
```

## Claim Tokens (Cast)

```bash
# Replace with actual proof values
cast send $AIRDROP_CONTRACT \
  "claim(address,uint256,bytes32[])" \
  0xAliceAddress 100000000000000000000 \
  "[0xproof1,0xproof2,...]" \
  --private-key $ALICE_KEY --rpc-url base_sepolia
```

## Frontend Integration (Viem)

```typescript
import { createWalletClient, http } from "viem";
import { base } from "viem/chains";

const airdropAbi = [
  {
    name: "claim",
    type: "function",
    inputs: [
      { name: "account", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "proof", type: "bytes32[]" },
    ],
    outputs: [],
    stateMutability: "nonpayable",
  },
] as const;

// Claim
const hash = await walletClient.writeContract({
  address: AIRDROP_CONTRACT,
  abi: airdropAbi,
  functionName: "claim",
  args: [userAddress, amount, proof],
});
```

## Security Notes

- Double-hashed leaves prevent second preimage attacks
- `claimed` mapping prevents double-claiming
- Proof verification is fully on-chain — trustless
- Custom errors save gas vs `require` strings

## License

MIT
