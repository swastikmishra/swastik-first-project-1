// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FriendTech is ERC20 {
    address public owner;

    mapping(address => uint256) private sharePrice;
    mapping(address => uint256) public totalShares;
    mapping(address => uint256) public dividendBalance; // Track dividend balances for each user

    event DividendPaid(address indexed receiver, uint256 amount);

    constructor() ERC20("FriendTech", "FTK") {
        owner = msg.sender;
    }

    function setSharePrice(uint256 price) external {
        require(price > 0, "Price must be greater than zero");
        sharePrice[msg.sender] = price;
    }

    function getSharePrice(address user) public view returns (uint256) {
        return sharePrice[user];
    }

    function setTotalShares(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        totalShares[msg.sender] = amount;
    }

    function getTotalShares(address user) public view returns (uint256) {
        return totalShares[user];
    }
    
    function distributeDividends(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(msg.sender == owner, "Only the owner can distribute dividends");

        for (address shareholder : totalShares) {
            uint256 share = totalShares[shareholder];
            if (share > 0) {
                uint256 dividend = (amount * share) / totalSupply();
                dividendBalance[shareholder] += dividend;
            }
        }
    }

    function claimDividends() external {
        uint256 dividend = dividendBalance[msg.sender];
        require(dividend > 0, "No dividends to claim");

        dividendBalance[msg.sender] = 0;
        payable(msg.sender).transfer(dividend);

        emit DividendPaid(msg.sender, dividend);
    }

    function buyShares(address seller, uint256 amount) external payable {
        require(amount > 0, "Amount must be greater than zero");
        require(totalShares[seller] >= amount, "Seller does not have enough shares");
        require(sharePrice[seller] <= msg.value, "Insufficient payment");

        totalShares[seller] -= amount;
        totalShares[msg.sender] += amount;

        // Calculate the amount of tokens to mint based on the share price
        uint256 tokensToMint = (msg.value * 10**decimals()) / sharePrice[seller];
        _mint(msg.sender, tokensToMint);
    }

    function sellShares(address buyer, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(totalShares[msg.sender] >= amount, "Insufficient shares");

        totalShares[msg.sender] -= amount;
        totalShares[buyer] += amount;

        // Calculate the amount of tokens to burn based on the share price
        uint256 tokensToBurn = (amount * sharePrice[msg.sender]) / 10**decimals();
        _burn(msg.sender, tokensToBurn);
        payable(buyer).transfer(tokensToBurn);
    }

    function transferShares(address to, uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(totalShares[msg.sender] >= amount, "Insufficient shares");

        totalShares[msg.sender] -= amount;
        totalShares[to] += amount;

        // Transfer the corresponding amount of tokens
        _transfer(msg.sender, to, amount);
    }
}