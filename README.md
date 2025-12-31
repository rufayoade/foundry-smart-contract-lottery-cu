# Raffle Smart Contract 🎫

A decentralized raffle/lottery smart contract built with Solidity and Foundry, using Chainlink VRF for verifiable randomness and Chainlink Automation for upkeep.

## Features ✨
- **Chainlink VRF v2.5**: Provably fair random winner selection
- **Chainlink Automation**: Automated upkeep and winner picking
- **Multi-player support**: Multiple participants can enter
- **Automatic payout**: Winner receives entire pot automatically
- **Secure**: No owner privileges, fully decentralized

## Test Coverage ✅
- **100% function coverage** (17/17 functions)
- **98.48% line coverage** (65/66 lines)
- **21 comprehensive tests** including unit, integration, and fuzz tests

## Quick Start 🚀

### Prerequisites
- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Git](https://git-scm.com/)

### Installation
make install
make build

### Testing
make test

### Coverage Report
forge coverage

## Project Structure 📁

src/Raffle.sol              # Main contract
test/RaffleTest.t.sol       # Comprehensive test suite
Script/DeployRaffle.s.sol   # Deployment script
Makefile                    # Build automation
.env.example                # Environment template

## Deployment ��

1. Copy .env.example to .env:
   cp .env.example .env

2. Add your keys to .env:
   SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_KEY
   PRIVATE_KEY=your_private_key
   ETHERSCAN_API_KEY=your_etherscan_key

3. Deploy to Sepolia:
   make deploy-sepolia

## Contract Functions 📋

### Player Functions
- enterRaffle() - Enter the raffle with entrance fee
- checkUpkeep() - Check if upkeep is needed
- performUpkeep() - Perform upkeep (Chainlink Automation)

### View Functions
- getPlayers() - Get list of players
- getRecentWinner() - Get most recent winner
- getRaffleState() - Get current raffle state
- getEntranceFee() - Get current entrance fee

## Testing Strategy 🧪

### Unit Tests
- Basic functionality
- State transitions
- Error conditions

### Integration Tests
- VRF integration
- Full raffle lifecycle
- Winner selection and payout

### Fuzz Tests
- Random request ID validation
- Edge case testing

## Security Considerations 🔒
- Uses Chainlink's proven VRF for randomness
- No owner privileges after deployment
- Automatic time-based upkeep
- Funds are escrowed in contract until winner is selected

## License 📄
MIT
