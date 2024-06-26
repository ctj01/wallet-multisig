// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


//0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E -- USDC DATAFEED
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
interface TokenInterface {
    function mint(address to, uint256 amount) external; 
}

contract TokenShop {
    AggregatorV3Interface internal priceFeed;
    TokenInterface public minter;
    uint256 public tokenPrice = 100; //1 token = 1.00 usd, with 2 decimal places
    address public owner;

     constructor(address tokenAddress) {
        minter = TokenInterface(tokenAddress);
        /**
        * Network: Sepolia
        * Aggregator: USDC/USD
        * Address: 0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E
        * Decimals: 6
        */
        priceFeed = AggregatorV3Interface(0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E);
        owner = msg.sender;
    }
      /**
    * Returns the latest answer
    */
    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price;
    }
    function tokenAmount(uint256 amountUSDC) public view returns (uint256) {
        //Sent amountETH, how many usd I have
        uint256 usdcUsd = uint256(getChainlinkDataFeedLatestAnswer());       //with 8 decimal places
        uint256 amountUSD = amountUSDC * usdcUsd / 10**6; //USDC = 6 decimal places
        uint256 amountToken = amountUSD / tokenPrice / 10**(8/2);  //8 decimal places from USDC/USD / 2 decimal places from token 
        return amountToken;
    } 
}