# GamePass Smart Contracts

Smart contracts for GamePass play-to-earn platform. Deploy to Celo. Test locally. Verify on Blockscout.

## What These Contracts Do

GamePassToken: ERC20 token for payments and rewards. Players use PASS tokens to mint Gems. Top players earn PASS rewards.

GamePassSwap: Buy PASS tokens with CELO or cUSD. Exchange rates set by owner. Mints tokens directly to buyers.

GamePassGem: ERC721 NFT contract. Players mint Gems to unlock games. One Gem costs 34 PASS tokens.

GamePassRewards: Tracks scores. Distributes rewards. Leaderboard management. Prize pool distribution.

## Prerequisites

Install Foundry. Get CELO for gas fees. Have a wallet ready.

Foundry installation: https://book.getfoundry.sh/getting-started/installation

## Installation

Clone the repository. Navigate to contracts folder. Install dependencies.

```bash
git clone <repository-url>
cd GamePass/contracts
forge install
```

Build contracts:

```bash
forge build
```

Run tests:

```bash
forge test
```

All tests must pass before deployment.

## Configuration

Create a `.env` file in the contracts directory:

```
PRIVATE_KEY=0xyour_private_key_with_0x_prefix
TREASURY_ADDRESS=your_treasury_address
ETHERSCAN_API_KEY=your_etherscan_api_key
```

Important notes:
- Private key must include 0x prefix
- Treasury address receives initial 500M PASS tokens
- Etherscan API key works for Celo Mainnet and Celo Sepolia

## Get Testnet Tokens

Get testnet tokens before deploying:

- Celo Sepolia Faucet: https://faucet.celo.org/celo-sepolia
- Google Cloud Faucet: https://cloud.google.com/application/web3/faucet/celo/sepolia

You need CELO for gas fees.

## Deployment

### Deploy All Contracts

Deploy everything to Celo Sepolia:

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url celo-sepolia --broadcast --verify
```

This deploys all four contracts. Sets up relationships. Activates claim conditions. Verifies on Blockscout.

### Deploy Token and Swap Only

Deploy latest contracts with cUSD support:

```bash
forge script script/DeployTokenAndSwap.s.sol:DeployTokenAndSwapScript --rpc-url celo-sepolia --broadcast --verify
```

This deploys new token and swap contracts. Includes cUSD payment support.

### Deploy to Mainnet

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url celo --broadcast --verify
```

## Deployed Contracts

Celo Sepolia Testnet:

GamePassToken: (To be deployed)

GamePassSwap: (To be deployed)

GamePassGem: (To be deployed)

GamePassRewards: (To be deployed)

cUSD Token: 0xdE9e4C3ce781b4bA68120d6261cbad65ce0aB00b

View contracts on Blockscout: https://celo-sepolia.blockscout.com/

## Usage

### Buy PASS Tokens with CELO

Send CELO to swap contract. Receive PASS tokens.

Exchange rate: 1 CELO equals 30 PASS tokens.

Minimum purchase: 0.01 CELO.

### Buy PASS Tokens with cUSD

Approve cUSD spending first. Call buyTokensWithCUSD function.

Exchange rate: 0.17 cUSD equals 30 PASS tokens.

Minimum purchase: 0.01 cUSD.

### Mint NFT Gems

Approve 34 PASS tokens. Call claim function on Gem contract.

One Gem unlocks all games.

### Submit Scores

Call submitScore function on rewards contract.

Minimum score: 10 points.

### Claim Rewards

Top players call claimRewards function.

Reward distribution:
- First place: 40 percent of prize pool
- Second place: 25 percent of prize pool
- Third place: 15 percent of prize pool
- Places four through ten: 10 percent split among seven players
- Participation: 10 percent split among all eligible players

### Fund Prize Pool

Owner calls fundPrizePool function.

Mints PASS tokens directly to contract.
