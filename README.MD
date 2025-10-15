# 🎖️ CompletionBadgeNFT

**CompletionBadgeNFT** is a minimal, import-free ERC-721 smart contract built in Solidity for issuing **NFT completion badges** — perfect for marking achievements, course completions, or verified tasks.

---

## 📜 Contract Details

- **Network:** Ethereum (or compatible EVM chain)
- **Contract Address:** [`0xe3415769e2d7811035B07a697F7f702AaC9BFE26`](https://etherscan.io/address/0xe3415769e2d7811035B07a697F7f702AaC9BFE26)
- **Token Name:** CompletionBadge  
- **Token Symbol:** CBADGE  
- **Standard:** ERC-721 (fully compatible)  
- **License:** MIT  

---

## ⚙️ Key Features

- 🧩 **No Imports or Constructor:** Lightweight and self-contained Solidity code — easy to verify and deploy.  
- 🏅 **Mint Your Own Badge:** Anyone can claim a badge with a single call to `claimBadge()`.  
- 🧑‍💼 **Admin Controls:** The contract owner can mint badges for others and update metadata URI.  
- 🔒 **Ownership Management:** Includes `initialize()` (no arguments) for first-time setup and `transferOwnership()` for later.  
- 🗂️ **Metadata Ready:** Each NFT URI is generated as `baseURI + tokenId + ".json"` for flexible hosting (e.g., IPFS or your API).  

---

## 🧠 Functions Overview

| Function | Access | Description |
|-----------|--------|-------------|
| `initialize()` | Public (once) | Initializes the contract owner (no constructor used). |
| `claimBadge()` | Public | Mints a new NFT badge to the caller. |
| `adminMint(address to)` | Owner only | Mints a badge to any address. |
| `setBaseURI(string newBase)` | Owner only | Updates base URI for metadata. |
| `balanceOf(address)` | Public view | Returns how many badges an address holds. |
| `ownerOf(uint256)` | Public view | Returns current owner of a specific badge. |
| `tokenURI(uint256)` | Public view | Returns full metadata URL for a badge. |
| `burn(uint256)` | Owner/Approved | Burns (destroys) a badge NFT. |

---

## 🧩 How to Interact

### 🪄 Initialize the Contract

After deployment, **call once**:

```solidity
initialize()
