// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


//0xA2F78ab2355fe2f984D808B5CeE7FD0A93D5270E -- USDC DATAFEED
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
}

contract TokenShop {
    address public immutable tokenUsdcAddress;
    AggregatorV3Interface internal priceFeed;
    IERC20 public minter;
    uint256 public tokenPrice = 100; //1 token = 1.00 usd, with 2 decimal places
    address public owner;
    uint256 public constant FEE_PERCENTAGE = 1; //1% fee

     constructor(address tokenAddress) {

        tokenUsdcAddress = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
        minter = IERC20(tokenAddress);
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
        //Sent amountUSDC, how many usd I have
        uint256 usdcUsd = uint256(getChainlinkDataFeedLatestAnswer());       //with 6 decimal places
        uint256 amountUSD = amountUSDC * usdcUsd / 10**6; //USDC = 6 decimal places
        uint256 amountToken = amountUSD / tokenPrice / 10**(6/2);  //6 decimal places from USDC/USD / 2 decimal places from token 
        return amountToken;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
 
    function withdraw() external onlyOwner {
        uint256 balance = IERC20(tokenUsdcAddress).balanceOf(address(this));
        IERC20(tokenUsdcAddress).transfer(owner, balance);
    }

    function buyToken(uint256 amountUSDC) external payable {
        uint256 fee = amountUSDC * FEE_PERCENTAGE / 100;
        uint256 amountToken = tokenAmount(amountUSDC - fee);
        minter.mint(address(this), amountToken);
        minter.approve(address(this), amountToken);
        minter.transferFrom(address(this), msg.sender, amountToken);     
    }
}