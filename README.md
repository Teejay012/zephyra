# 💠 Zephyra Protocol

**Zephyra** is a decentralized stablecoin ecosystem that empowers users to mint a crypto-backed stablecoin (**ZUSD**) using overcollateralized assets (WETH or WBTC), participate in a Chainlink-powered NFT mini-game, and transfer stablecoins across chains via Chainlink CCIP.

Built with **Solidity**, **Foundry**, and **Next.js**, Zephyra integrates **Chainlink VRF**, **Price Feeds**, and **CCIP** to create a composable DeFi and gaming experience.

---

## 🧩 Problem Zephyra Solves

1. **Trustless Stablecoin Minting:** Centralized stablecoins pose custodial and regulatory risks. Zephyra offers an overcollateralized, decentralized alternative: ZUSD.
2. **Cross-Chain Stablecoin Transfers:** Moving stablecoins across chains is fragmented. Zephyra solves this with Chainlink CCIP.
3. **Engaging User Experience:** Many DeFi apps lack gamification. Zephyra adds a chance-based NFT mini-game powered by secure randomness from Chainlink VRF.

---

## 🚀 Features

| Feature | Description |
|--------|-------------|
| 🏦 **ZUSD Minting** | Mint ZUSD by depositing WETH or WBTC as collateral. |
| 🧮 **Health Factor Monitoring** | Real-time risk tracking and liquidation warnings. |
| 🔁 **Cross-Chain Transfers** | Seamlessly move ZUSD across chains using Chainlink CCIP. |
| 🎰 **TryLuck NFT Game** | Win rare NFTs in a provably fair game powered by Chainlink VRF and automatically managed with Chainlink Automation. |
| 🕒 **Automated Game Round Logic** | Chainlink Automation monitors the TryLuck game to end rounds and trigger random winner selection based on time or entry conditions. |
| 💻 **User-Friendly Frontend** | Built with Next.js for seamless wallet interactions and ZUSD vault management. |

---

## 🛠️ Tech Stack

| Layer | Tools |
|------|-------|
| **Smart Contracts** | Solidity, Foundry |
| **Frontend** | React.js (Next.js), Tailwind CSS |
| **Oracle Services** | Chainlink VRF, Automation, Price Feeds, CCIP |
| **Tooling** | Ethers.js, Forge, Cast, Chainlink Functions (planned) |

---


## 🔗 Chainlink Integrations

| Chainlink Feature | Location in Code | Description |
|-------------------|------------------|-------------|
| **Price Feeds** | [`ZephyraVault.sol`](https://github.com/Teejay012/zephyra/blob/main/smart-contract/src/ZephyraVault.sol#L504) | Fetches WETH/USD and WBTC/USD prices to determine collateral value and calculate how much ZUSD can be minted. |
| **VRF (Verifiable Randomness)** | [`ZephyraNFT.sol`](https://github.com/Teejay012/zephyra/blob/main/smart-contract/src/ZephyraNFT.sol#L289) | Requests secure randomness using Chainlink VRF to fairly select NFT winner. |
| **Automation** | [`ZephyraNFT.sol`](https://github.com/Teejay012/zephyra/blob/main/smart-contract/src/ZephyraNFT.sol#L245) | Uses Chainlink Automation (`checkUpkeep` / `performUpkeep`) to detect expired game rounds and automatically trigger winner selection logic. |
| **CCIP (Cross-Chain Transfer)** | [`ZephyraCrossChain.sol`](https://github.com/Teejay012/zephyra/blob/main/smart-contract/src/ZephyraCrossChain.sol), [`ZephyraReceiver.sol`](https://github.com/Teejay012/zephyra/blob/main/smart-contract/src/ZephyraReceiver.sol) | Sends ZUSD from source chain to destination chain and mints/redeems the token via Chainlink CCIP. |

---

## 🔗 Deployment

| Component | Address / URL |
|----------|----------------|
| ZUSD Token (Testnet) | `0x792c6B6Cd8CdC39cA45D19438E8b53674CdB73E5` |
| Vault Contract | `0x4BdD39A36Ec6f8B9904eA2ECf0E06eb09445B926` |
| Zephy NFT | `0x26ACde522bc7c5EbB9A0614E7710f45A063B09ED` |
| CCIP Contract | `0x708ccC43D27eFF4F057DE2A19f6bDC3e1Fa39bE5` |
| Cross-Chain Wrapper | `0xDAAF457596D0dF7861789A70Dc4d7DeB5496b6D9` |
| Frontend URL | [zephyra](https://zephyra-kappa.vercel.app/) |
| Demo Video | [YouTube Demo](https://youtu.be/your-demo-link) |

---

## ⚙️ How to Run Locally

1. **Clone the Repo**

```bash
git clone https://github.com/Teejay012/zephyra.git
cd zephyra
npm install  # or yarn
```

2. **Install Dependencies**

```bash
npm install  # or yarn
```

3. **Run the Frontend**

```bash
npm run dev
```


---

## 📹 Demo Preview







---


## 👥 Team
- TJ (EtherEngineer) — Solidity Architect & Junior Security Researcher


---


## 🏁 Submission Summary

✅ Uses Chainlink Price Feeds for real-time collateral valuation

✅ Uses Chainlink VRF for secure NFT game randomness

✅ Uses Chainlink CCIP for cross-chain stablecoin movement

✅ Uses Chainlink Automation to monitor and manage NFT game rounds without manual intervention

✅ Frontend + Smart Contracts fully built and deployed


---


## 📜 License
MIT License

---


