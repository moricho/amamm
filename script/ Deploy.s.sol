// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/AuctionManager.sol";
import "../src/AuctionManagedAMMHook.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManagerAddress = vm.envAddress("POOL_MANAGER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        AuctionManager auctionManager = new AuctionManager();
        console.log("AuctionManager deployed to:", address(auctionManager));

        AuctionManagedAMMHook auctionManagedAMMHook =
            new AuctionManagedAMMHook(IPoolManager(poolManagerAddress), auctionManager);
        console.log("AuctionManagedAMMHook deployed to:", address(auctionManagedAMMHook));

        vm.stopBroadcast();
    }
}
