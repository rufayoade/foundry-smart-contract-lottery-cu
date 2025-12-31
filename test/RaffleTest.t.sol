// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {Raffle} from "src/Raffle.sol";
import {VRFCoordinatorV2_5Mock} from
    "@chainlink/contracts/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {console2} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";


contract RaffleTest is Test {
    // Events (same as in Raffle contract)
    event RaffleEntered(address indexed player);
    event WinnerPicked(address indexed winner);

    Raffle public raffle;
    VRFCoordinatorV2_5Mock public vrfCoordinatorMock;

    uint256 public entranceFee;
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

    function setUp() public {
        // 1. Deploy VRF mock
        vrfCoordinatorMock = new VRFCoordinatorV2_5Mock(
            0.25 ether, // MOCK_BASE_FEE
            1e9,        // MOCK_GAS_PRICE_LINK
            4e15        // MOCK_WEI_PER_UNIT_LINK
        );

        // 2. Create a subscription on THIS mock
        uint256 subId = vrfCoordinatorMock.createSubscription();
        console2.log("CREATED SUBSCRIPTION (uint256):", subId);
        console2.log("TRUNCATED TO uint64:", uint64(subId));

        // 3. Deploy raffle with that subscription ID
        raffle = new Raffle(
            0.01 ether, // entranceFee
            30,         // interval
            address(vrfCoordinatorMock), // vrfCoordinator
            0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae, // gasLane
            subId,      // subscriptionId (uint256 in your Raffle now)
            500000      // callbackGasLimit
        );

        // 4. Add raffle as a consumer to THAT same subscription
        console2.log("Adding consumer with subscription ID:", subId);
        vrfCoordinatorMock.addConsumer(subId, address(raffle));

        // 5. Fund the subscription with ETH (for VRF payments)
        // The mock needs subscription balance to charge for VRF requests
        vrfCoordinatorMock.fundSubscription(subId, 1000 ether);

        entranceFee = 0.01 ether;
    }

    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    /************************************************************/
    /*                       ENTER RAFFLE                       */
    /************************************************************/

    function testRaffleRevertsWhenYouDontPayEnough() public {
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.prank(PLAYER);

        vm.expectRevert(Raffle.Raffle_SendMoreToEnterRaffle.selector);
        raffle.enterRaffle(); // No value sent
    }

    function testRaffleRecordsPlayersWhenTheyEnter() public {
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.prank(PLAYER);

        raffle.enterRaffle{value: entranceFee}();

        address playerRecorded = raffle.getPlayer(0);
        assert(playerRecorded == PLAYER);
    }

    function testEnteringRaffleEmitsEvent() public {
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.prank(PLAYER);

        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);

        raffle.enterRaffle{value: entranceFee}();
    }
 
    function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        // DEBUG: Check what subscription ID Raffle actually has
         uint256 subIdFromRaffle = raffle.getSubscriptionId();
         console2.log("SUB ID FROM RAFFLE:", subIdFromRaffle);

        // 1. First player enters
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // 2. Move time & block forward past interval
        vm.warp(block.timestamp + 31);
        vm.roll(block.number + 31);

        // 3. performUpkeep moves state to CALCULATING and triggers VRF request
        raffle.performUpkeep("");

        // 4. Second player should NOT be able to enter while CALCULATING
        address player2 = makeAddr("player2");
        vm.deal(player2, STARTING_PLAYER_BALANCE);

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(player2);
        raffle.enterRaffle{value: entranceFee}();
    }

    /************************************************************/
    /*                    CHECK UPKEEP TESTS                    */
    /************************************************************/

    function testCheckUpkeepReturnsFalseWhenNoBalance() public view {
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseWhenNoPlayers() public {
        // Give contract ETH but no players
        vm.deal(address(raffle), 1 ether);
        vm.warp(block.timestamp + 31);
        
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsFalseWhenNoTimePassed() public {
        // Player enters but time hasn't passed
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
    }

    function testCheckUpkeepReturnsTrueWhenAllConditionsMet() public {
        // All conditions: balance, players, time passed, is open
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        vm.warp(block.timestamp + 31);
        
        (bool upkeepNeeded,) = raffle.checkUpkeep("");
        assertTrue(upkeepNeeded);
    }

    function testPerformUpkeepRevertsWhenNotNeeded() public {
        vm.expectRevert(abi.encodeWithSelector(Raffle.Raffle_UpkeepNotNeeded.selector, 0, 0, 0));
        raffle.performUpkeep("");
    }

     /************************************************************/
    /*                    CHECK UPKEEP TESTS                    */
    /************************************************************/
        
    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
         // Arrange: Player enters but time interval (30s) hasn't passed
         vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
         vm.prank(PLAYER);
         raffle.enterRaffle{value: entranceFee}();

         // Act
         (bool upkeepNeeded,) = raffle.checkUpkeep("");

         // Assert
         assert(!upkeepNeeded);

    }
    
    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
       // Arrange: ALL conditions met - balance + players + time passed + OPEN
       vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
       vm.prank(PLAYER);
       raffle.enterRaffle{value: entranceFee}(); // ✅ Players + balance

       vm.warp(block.timestamp + 31); // ✅ Time passed (30s interval)

       // Act
       (bool upkeepNeeded,) = raffle.checkUpkeep("");

       // Assert
       assert(upkeepNeeded);
    }
    function testPerformUpkeepWorksCorrectly() public {
        // Arrange: All conditions met
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        vm.warp(block.timestamp + 31); // Time passed (interval is 30)
        vm.roll(block.number + 1);     // New block
        
        // Act
        raffle.performUpkeep("");
        
        // Assert: State changed to CALCULATING
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }


    function testPerformUpkeepUpdatesLastRequestId() public {
        // Arrange
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        vm.warp(block.timestamp + 31);
        vm.roll(block.number + 1);
        
        // Act
        uint256 startingRequestId = raffle.getLastRequestId();
        raffle.performUpkeep("");
        uint256 newRequestId = raffle.getLastRequestId();
        
        // Assert
        assert(newRequestId > startingRequestId);
    }

    function testFulfillRandomWordsDirectCall() public {
        // Arrange: Multiple players enter
        address player1 = makeAddr("player1");
        address player2 = makeAddr("player2");
        address player3 = makeAddr("player3");
        
        // All players enter
        vm.deal(player1, STARTING_PLAYER_BALANCE);
        vm.prank(player1);
        raffle.enterRaffle{value: entranceFee}();
        
        vm.deal(player2, STARTING_PLAYER_BALANCE);
        vm.prank(player2);
        raffle.enterRaffle{value: entranceFee}();
        
        vm.deal(player3, STARTING_PLAYER_BALANCE);
        vm.prank(player3);
        raffle.enterRaffle{value: entranceFee}();
        
        // Move time forward and perform upkeep
        vm.warp(block.timestamp + 31);
        vm.roll(block.number + 1);
        raffle.performUpkeep("");
        
        // Contract should be in CALCULATING state
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
        
        // Get request ID
        uint256 requestId = raffle.getLastRequestId();
        
        // Record balances before
        uint256 contractBalanceBefore = address(raffle).balance;
        uint256 player1BalanceBefore = player1.balance;
        uint256 player2BalanceBefore = player2.balance;
        uint256 player3BalanceBefore = player3.balance;
        
        // Act: Simulate VRF callback with specific random number
        // We'll use random number that picks player2 (index 1)
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 1; // This modulo 3 = 1 (player2)
        
        // We need to call rawFulfillRandomWords which is called by the coordinator
        // First, become the VRF coordinator
        vm.prank(address(vrfCoordinatorMock));
        
        // Call the internal function
        raffle.rawFulfillRandomWords(requestId, randomWords);
        
        // Assert
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getRecentWinner() == player2); // player2 should win
        assert(address(raffle).balance == 0); // All money sent to winner
        
        // Check winner got all the money
        assert(player2.balance == player2BalanceBefore + contractBalanceBefore);
        
        // Check other players didn't get money
        assert(player1.balance == player1BalanceBefore);
        assert(player3.balance == player3BalanceBefore);
        
        // Players list should be reset
        assert(raffle.getPlayerCount() == 0);
    }

    function testAllGettersWorkCorrectly() public {
        // Test all getter functions
        assert(raffle.getEntranceFee() == 0.01 ether);
        assert(raffle.getInterval() == 30);
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
        assert(raffle.getLastTimeStamp() <= block.timestamp);
        assert(raffle.getPlayerCount() == 0);
        
        // Test subscription ID getter
        uint256 subId = raffle.getSubscriptionId();
        assert(subId > 0);
        
        // Test callback gas limit
        assert(raffle.getCallbackGasLimit() == 500000);
        
        // Test key hash
        bytes32 keyHash = raffle.getKeyHash();
        assert(keyHash == 0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae);
        
        // Test getPlayers returns empty array initially
        address payable[] memory players = raffle.getPlayers();
        assert(players.length == 0);
        
        // Test getLastRequestId is initially 0
        assert(raffle.getLastRequestId() == 0);
        
        // Test getRecentWinner is initially address(0)
        assert(raffle.getRecentWinner() == address(0));
        
        // Test getPlayer with invalid index reverts
        vm.expectRevert();
        raffle.getPlayer(0); // Should revert when no players
    }

    modifier raffleEntered() {
        // Arrange since we need it over and over
        vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        
        vm.warp(block.timestamp + 31);
        vm.roll(block.number + 1);
        _;
    }

    // What if we need to get data from emitted events in our tests?
    function testPerformUpkeepUpdatesRaffleStateAndEmitsRequestId() public raffleEntered {
        
        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Assert
        Raffle.RaffleState raffleState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(raffleState) == 1);
    }
    
    /************************************************************/
    /*                    FULFILL RANDOM WORDS                  */
    /************************************************************/
    function testFulfillRandomWordsCanOnlyBeCalledAfterPerformUpkeep(uint256 randomRequestId) public raffleEntered {
        // Arrange / Act / Assert
        // Should revert since we haven't performed upkeep
        vm.expectRevert(VRFCoordinatorV2_5Mock.InvalidRequest.selector);
        VRFCoordinatorV2_5Mock(address(vrfCoordinatorMock)).fulfillRandomWords(randomRequestId, address(raffle));
    }

    function testFulfillRandomWordsPicksAWinnerResetsAndSendMoney() public raffleEntered {
        // Arrange
        uint256 additionalEntrants = 3; // 4 total
        uint256 startingIndex = 1;
        address expectedWinner = address(1);

        for (uint256 i = startingIndex; i < startingIndex + additionalEntrants; i++) {
            address newPlayer = address(uint160(i));
            hoax(newPlayer, 1 ether);
            raffle.enterRaffle{value: entranceFee}();
        }
        uint256 startingTimeStamp = raffle.getLastTimeStamp();
        uint256 winnerStartingBalance = expectedWinner.balance;

        // Act
        vm.recordLogs();
        raffle.performUpkeep("");
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        // Pretend to be Chainlink VRF
    VRFCoordinatorV2_5Mock(address(vrfCoordinatorMock)).fulfillRandomWords(uint256(requestId), address(raffle));

    // Assert
    address recentWinner = raffle.getRecentWinner();
    Raffle.RaffleState raffleState = raffle.getRaffleState();
    uint256 winnerBalance = recentWinner.balance;
    uint256 endingTimeStamp = raffle.getLastTimeStamp();
    uint256 prize = entranceFee * (additionalEntrants + 1);

    assert(recentWinner == expectedWinner);
    assert(uint256(raffleState) == 0);
    assert(winnerBalance == winnerStartingBalance + prize);
    assert(endingTimeStamp > startingTimeStamp);  
    }
}

