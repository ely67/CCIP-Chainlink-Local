// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Import necessary contracts and interfaces
import { Test, console } from "forge-std/Test.sol";
import { CCIPLocalSimulator, IRouterClient, WETH9, LinkToken, BurnMintERC677Helper } from "@chainlink/local/src/ccip/CCIPLocalSimulator.sol";
import { CrossChainNameServiceLookup } from "../src/CrossChainNameServiceLookup.sol";
import { CrossChainNameServiceReceiver } from "../src/CrossChainNameServiceReceiver.sol";
import { CrossChainNameServiceRegister } from "../src/CrossChainNameServiceRegister.sol";

// Main test contract for Cross-Chain Name Service
contract CrossChainNameService is Test{
    // Declare state variables
    CCIPLocalSimulator public ccipLocalSimulator;
    CrossChainNameServiceLookup public lookupRegister;
    CrossChainNameServiceLookup public lookupReceiver;
    CrossChainNameServiceReceiver public receiver;
    CrossChainNameServiceRegister public register;
    uint64 selectChainselector;

    // Setup function to initialize the test environment
    function setUp() public {
        // Create a new instance of CCIPLocalSimulator
        ccipLocalSimulator = new CCIPLocalSimulator();

        (
            uint64 chainSelector,
            IRouterClient sourceRouter,
            IRouterClient destinationRouter,
            WETH9 wrappedNative,
            LinkToken linkToken,
            BurnMintERC677Helper ccipBnM,
            BurnMintERC677Helper ccipLnM
        ) = ccipLocalSimulator.configuration();

        // Deploy necessary contracts
        lookupRegister = new CrossChainNameServiceLookup();
        lookupReceiver = new CrossChainNameServiceLookup();
        receiver = new CrossChainNameServiceReceiver(address(sourceRouter), address(lookupReceiver), chainSelector);
        register = new CrossChainNameServiceRegister(address(sourceRouter), address(lookupRegister));

        // Set up cross-chain name service addresses
        lookupRegister.setCrossChainNameServiceAddress(address(register));
        lookupReceiver.setCrossChainNameServiceAddress(address(receiver));

        // Enable chain for cross-chain communication
        uint256 gasLimit = 200000;
        register.enableChain(selectChainselector, address(receiver), gasLimit);

        // Request LINK tokens for fees
        uint256 linkForFees = 5 ether;
        ccipLocalSimulator.requestLinkFromFaucet(address(register), linkForFees);
        selectChainselector = chainSelector;
    }

    // Test function for Cross-Chain Name Service
    function testCrossChainNameService() public {
       
        vm.prank(address(register));
        address alice = makeAddr("Alice");
        string memory name = "alice.ccns";

        lookupRegister.register(name, address(alice));

        address registeredAddress = lookupRegister.lookup(name);
        assert(registeredAddress == alice);
    }
}