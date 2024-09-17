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

    function placeBid() external payable {
        require(msg.value > currentHighestBid.amount, "Bid too low");
        require(block.timestamp > currentHighestBid.timestamp + AUCTION_DURATION, "Auction not ended");

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
