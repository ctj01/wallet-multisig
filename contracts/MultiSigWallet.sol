// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
}

contract MultiSigWallet is AccessControl {
    address[] public signers;
    uint256 public requiredSignatures;
    uint256 public transactionCount;
    IERC20 public governanceToken;
    
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;

    event Deposit(address indexed sender, uint256 value);
    event TransactionCreated(address indexed destination, uint256 value, uint256 transactionId);
    event Confirmation(address indexed sender, uint256 transactionId);
    event Execution(uint256 transactionId);
}
