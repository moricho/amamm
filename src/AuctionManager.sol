// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract AuctionManager {
    struct Bid {
        address bidder;
        uint256 amount;
        uint256 timestamp;
    }

    Bid public currentHighestBid;
    uint256 public constant AUCTION_DURATION = 1 days;

    /// @notice Thrown when a new bid is not higher than the current highest bid
    /// @param bidAmount The amount of the new bid that was too low
    /// @param currentHighestAmount The current highest bid amount
    error BidTooLow(uint256 bidAmount, uint256 currentHighestAmount);

    /// @notice Thrown when a bid is placed before the current auction has ended
    /// @param currentAuctionEndTime The timestamp when the current auction will end
    /// @param currentTime The current block timestamp
    error AuctionNotEnded(uint256 currentAuctionEndTime, uint256 currentTime);

    function placeBid() external payable {
        // Ensure the new bid is higher than the current highest bid
        // This maintains the ascending price nature of the auction
        // and prevents users from placing bids that cannot win
        if (msg.value <= currentHighestBid.amount) {
            revert BidTooLow(msg.value, currentHighestBid.amount);
        }

        // Check if the current auction has ended
        if (block.timestamp <= currentHighestBid.timestamp + AUCTION_DURATION) {
            revert AuctionNotEnded(currentHighestBid.timestamp + AUCTION_DURATION, block.timestamp);
        }

        // Refund previous highest bidder
        if (currentHighestBid.bidder != address(0)) {
            payable(currentHighestBid.bidder).transfer(currentHighestBid.amount);
        }

        currentHighestBid = Bid(msg.sender, msg.value, block.timestamp);
    }

    function getCurrentManager() public view returns (address) {
        return currentHighestBid.bidder;
    }
}
