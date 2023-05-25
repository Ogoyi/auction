// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AuctionPlatform {
    using SafeMath for uint256;

    struct Auction {
        address payable seller;
        string image;
        string brand;
        string color;
        string durability;
        uint256 price;
        uint256 endTime;
        address highestBidder;
        uint256 highestBid;
        bool ended;
    }

    uint256 internal auctionCount = 0;
    address internal cUsdTokenAddress = 0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;

    mapping(uint256 => Auction) internal auctions;

    function createAuction(
        string memory _image,
        string memory _brand,
        string memory _color,
        string memory _durability,
        uint256 _price,
        uint256 _duration
    ) public {
        Auction storage newAuction = auctions[auctionCount];

        newAuction.seller = payable(msg.sender);
        newAuction.image = _image;
        newAuction.brand = _brand;
        newAuction.color = _color;
        newAuction.durability = _durability;
        newAuction.price = _price;
        newAuction.endTime = block.timestamp.add(_duration);
        newAuction.ended = false;

        auctionCount++;
    }

    function getAuction(uint256 _index)
        public
        view
        returns (
            address payable,
            string memory,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            address,
            uint256,
            bool
        )
    {
        Auction storage auction = auctions[_index];
        return (
            auction.seller,
            auction.image,
            auction.brand,
            auction.color,
            auction.durability,
            auction.price,
            auction.endTime,
            auction.highestBidder,
            auction.highestBid,
            auction.ended
        );
    }

    function placeBid(uint256 _index) public payable {
        Auction storage auction = auctions[_index];
        require(!auction.ended, "Auction has ended");
        require(block.timestamp < auction.endTime, "Auction has ended");
        require(msg.value > auction.highestBid, "Bid amount too low");

        if (auction.highestBid > 0) {
            // Refund the previous highest bidder
            require(
                IERC20Token(cUsdTokenAddress).transfer(
                    auction.highestBidder,
                    auction.highestBid
                ),
                "Transfer failed."
            );
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
    }

    function endAuction(uint256 _index) public {
        Auction storage auction = auctions[_index];
        require(!auction.ended, "Auction has already ended");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet");

        auction.ended = true;

        if (auction.highestBid > 0) {
            // Transfer the highest bid amount to the seller
            require(
                IERC20Token(cUsdTokenAddress).transfer(
                    auction.seller,
                    auction.highestBid
                ),
                "Transfer failed."
            );
        }
    }

    function getAuctionCount() public view returns (uint256) {
        return auctionCount;
    }
}