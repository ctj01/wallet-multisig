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
    bytes32 public constant SIGNER_ROLE = keccak256("SIGNER_ROLE");

    modifier onlySigner() {
        require(hasRole(SIGNER_ROLE, msg.sender), "MultiSigWallet: only signer can call this function");
        _;
    }
    constructor(address[] memory _signers, uint256 _requiredSignatures, address _governanceToken) {
        require(_signers.length >= _requiredSignatures, "MultiSigWallet: signers length must be greater than or equal to requiredSignatures");
        signers = _signers;
        requiredSignatures = _requiredSignatures;
        governanceToken = IERC20(_governanceToken);
        for (uint256 i = 0; i < _signers.length; i++) {
            _grantRole(SIGNER_ROLE, _signers[i]);
        }
    }
  
    function removeSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(SIGNER_ROLE, _signer), "MultiSigWallet: signer does not exist");
        revokeRole(SIGNER_ROLE, _signer);
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == _signer) {
                signers[i] = signers[signers.length - 1];
                signers.pop();
                break;
            }
        }
    }

    function notEnoughBalance(address signer) private view {
        require(IERC20(governanceToken).balanceOf(signer) >= 1e9, "MultiSigWallet: signer does not have enough governance token");
    }
    function addSigner(address _signer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        notEnoughBalance(_signer);
        require(!hasRole(SIGNER_ROLE, _signer), "MultiSigWallet: signer already exists");
        signers.push(_signer);
        _grantRole(SIGNER_ROLE, _signer);
    }

    function changeRequiredSignatures(uint256 _requiredSignatures) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_requiredSignatures <= signers.length, "MultiSigWallet: requiredSignatures must be less than or equal to signers length");
        requiredSignatures = _requiredSignatures;
    }

    function submitTransaction(address destination, uint256 value, bytes memory data) external returns (uint256 transactionId) {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount++;
        emit TransactionCreated(destination, value, transactionId);
    }

    function confirmTransaction(uint256 transactionId) external {
        require(hasRole(SIGNER_ROLE, msg.sender), "MultiSigWallet: only signer can confirm transaction");
        require(transactions[transactionId].destination != address(0), "MultiSigWallet: transaction does not exist");
        require(!confirmations[transactionId][msg.sender], "MultiSigWallet: signer already confirmed transaction");
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
    }

    function executeTransaction(uint256 transactionId) external onlySigner {
        require(transactions[transactionId].destination != address(0), "MultiSigWallet: transaction does not exist");
        require(!transactions[transactionId].executed, "MultiSigWallet: transaction already executed");
        uint256 count = 0;
        for (uint256 i = 0; i < signers.length; i++) {
            if (confirmations[transactionId][signers[i]]) {
                count++;
            }
        }
        require(count >= requiredSignatures, "MultiSigWallet: not enough confirmations");
        Transaction storage transaction = transactions[transactionId];
        transaction.executed = true;
        (bool success, ) = transaction.destination.call{value: transaction.value}(transaction.data);
        require(success, "MultiSigWallet: transaction execution failed");
        emit Execution(transactionId);
    }
    
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
