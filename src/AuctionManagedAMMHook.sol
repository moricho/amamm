// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {BaseHook} from "v4-periphery/src/base/hooks/BaseHook.sol";
import {IPoolManager} from "v4-core/interfaces/IPoolManager.sol";
import {Hooks} from "v4-core/libraries/Hooks.sol";
import {PoolId, PoolIdLibrary} from "v4-core/types/PoolId.sol";
import {PoolKey} from "v4-core/types/PoolKey.sol";
import {StateLibrary} from "v4-core/libraries/StateLibrary.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "v4-core/types/BeforeSwapDelta.sol";
import {LPFeeLibrary} from "v4-core/libraries/LPFeeLibrary.sol";
import {BalanceDelta} from "v4-core/types/BalanceDelta.sol";

import {AuctionManager} from "./AuctionManager.sol";

contract AuctionManagedAMMHook is BaseHook {
    using StateLibrary for IPoolManager;
    using PoolIdLibrary for PoolKey;
    using LPFeeLibrary for uint24;

    AuctionManager public auctionManager;
    // Manager fees to be distributed to LPs
    mapping(address => uint256) public managerFees;
    // Keeping track of the moving average gas price
    uint128 public movingAverageGasPrice;
    // How many times has the moving average been updated?
    // Needed as the denominator to update it the next time based on the moving average formula
    uint104 public movingAverageGasPriceCount;
    // The last time we distributed fees
    uint256 public lastDistributionTimestamp;

    // The default base fees we will charge
    uint24 public constant BASE_FEE = 3000; // 0.3%
    // How often we distribute fees to LPs
    uint256 public constant DISTRIBUTION_INTERVAL = 1 days;

    error MustUseDynamicFee();

    constructor(IPoolManager _poolManager, AuctionManager _auctionManager) BaseHook(_poolManager) {
        auctionManager = _auctionManager;

        updateMovingAverage();
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeInitialize(address, PoolKey calldata key, uint160, bytes calldata)
        external
        pure
        override
        returns (bytes4)
    {
        if (!key.fee.isDynamicFee()) revert MustUseDynamicFee();
        return this.beforeInitialize.selector;
    }

    function beforeSwap(address sender, PoolKey calldata key, IPoolManager.SwapParams calldata, bytes calldata)
        external
        override
        returns (bytes4, BeforeSwapDelta, uint24)
    {
        address currentManager = auctionManager.getCurrentManager();

        if (sender == currentManager) {
            // Manager trades without fees
            poolManager.updateDynamicLPFee(key, 0);
            return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
        }

        uint24 fee = calculateDynamicFee();
        managerFees[currentManager] += fee;

        // Update the LP fee to reflect the new fee
        poolManager.updateDynamicLPFee(key, fee);
        return (this.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(address, PoolKey calldata, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        override
        returns (bytes4, int128)
    {
        // Update our moving average gas price
        updateMovingAverage();

        // Distribute fees if it's time
        if (block.timestamp >= lastDistributionTimestamp + DISTRIBUTION_INTERVAL) {
            distributeFees();
            lastDistributionTimestamp = block.timestamp;
        }

        return (this.afterSwap.selector, 0);
    }

    function calculateDynamicFee() internal view returns (uint24) {
        uint128 gasPrice = uint128(tx.gasprice);

        // if gasPrice > movingAverageGasPrice * 1.1, then half the fees
        if (gasPrice > (movingAverageGasPrice * 11) / 10) {
            return BASE_FEE / 2;
        }

        // if gasPrice < movingAverageGasPrice * 0.9, then double the fees
        if (gasPrice < (movingAverageGasPrice * 9) / 10) {
            return BASE_FEE * 2;
        }

        // default fee
        return BASE_FEE;
    }

    // Distribute fees to LPs
    function distributeFees() internal {
        address currentManager = auctionManager.getCurrentManager();
        // uint256 feesToDistribute = managerFees[currentManager];
        managerFees[currentManager] = 0;

        // TODO: Distribute fees to LPs
        // This would involve interacting with the Uniswap v4 pool to properly allocate fees
    }

    // Update our moving average gas price
    function updateMovingAverage() internal {
        uint128 gasPrice = uint128(tx.gasprice);

        // New Average = ((Old Average * # of Txns Tracked) + Current Gas Price) / (# of Txns Tracked + 1)
        movingAverageGasPrice =
            ((movingAverageGasPrice * movingAverageGasPriceCount) + gasPrice) / (movingAverageGasPriceCount + 1);

        movingAverageGasPriceCount++;
    }
}
