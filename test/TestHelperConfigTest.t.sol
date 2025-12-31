// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {TestHelperConfig} from "./TestHelperConfig.sol";

contract TestHelperConfigTest is Test {
    TestHelperConfig public helperConfig;
    
    function setUp() public {
        helperConfig = new TestHelperConfig();
    }
    
    function testGetOrCreateAnvilEthConfigReturnsValidConfig() public {
        // Act
        TestHelperConfig.NetworkConfig memory config = 
            helperConfig.getOrCreateAnvilEthConfig();
        
        // Assert
        assertEq(config.entranceFee, 0.01 ether);
        assertEq(config.interval, 30);
        assertTrue(config.vrfCoordinator != address(0));
        assertEq(config.gasLane, 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae);
        assertEq(config.callbackGasLimit, 500000);
        assertEq(config.subscriptionId, 0);
        assertTrue(config.link != address(0));
    }
    
    function testGetOrCreateAnvilEthConfigIsIdempotent() public {
        // First call
        TestHelperConfig.NetworkConfig memory config1 = 
            helperConfig.getOrCreateAnvilEthConfig();
        address vrfCoordinator1 = config1.vrfCoordinator;
        
        // Second call - should return same config
        TestHelperConfig.NetworkConfig memory config2 = 
            helperConfig.getOrCreateAnvilEthConfig();
        address vrfCoordinator2 = config2.vrfCoordinator;
        
        // Should be the same (idempotent)
        assertEq(vrfCoordinator1, vrfCoordinator2);
        assertEq(config1.entranceFee, config2.entranceFee);
        assertEq(config1.interval, config2.interval);
    }
}
