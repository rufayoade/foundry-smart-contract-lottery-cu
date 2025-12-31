# Load environment variables
export $(shell sed 's/=.*//' .env)

.PHONY: all test deploy build install

build:; forge build

test:; forge test

install:; forge install Cyfrin/foundry-devops@0.2.2 && \
	forge install smartcontractkit/chainlink-brownie-contracts@1.1.1 && \
	forge install foundry-rs/forge-std@v1.8.2 && \
	forge install transmissions11/solmate@v6

deploy-sepolia:
	@echo "Using RPC URL: $(SEPOLIA_RPC_URL)"
	@echo "Private key set: $(if $(PRIVATE_KEY),YES,NO)"
	@echo "Etherscan key set: $(if $(ETHERSCAN_API_KEY),YES,NO)"
	forge script Script/DeployRaffle.s.sol:DeployRaffle --rpc-url $(b4b322d22b7943d594dd076df3943fa8) \
	--private-key $(0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80) --broadcast --verify --etherscan-api-key $(C65PPSXP7AYTXQ97SE77ZCC45SYM3Q6V3V) -vvvv


deploy-anvil: