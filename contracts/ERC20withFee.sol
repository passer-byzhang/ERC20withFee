// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ERC20withFee is ERC20Upgradeable, OwnableUpgradeable {

    uint256 constant fee = 100;//10%
    address public feeReceiver;
    uint256 public minTransferAmount;

    event TransferWithFee(address indexed from, address indexed to, uint256 amount, uint256 feeAmount);
    event FeeReceiverChanged(address indexed previousReceiver, address indexed newReceiver);

    error UnderMinTransferAmount(uint256 amount,uint256 minTransferAmount);

    function initialize(string memory name, string memory symbol, address _feeReceiver,address owner) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(owner);
        feeReceiver = _feeReceiver;
        minTransferAmount = 10;
    }
    
    function _transfer(address from, address to, uint256 amount) internal override {
        if (amount < minTransferAmount) {
            revert UnderMinTransferAmount(amount,minTransferAmount);
        }
        uint256 feeAmount = amount * fee / 1000;
        uint256 transferAmount = amount - feeAmount;
        super._transfer(from, to, transferAmount);
        emit TransferWithFee(from, to, amount, feeAmount);
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(_feeReceiver != address(0), "Fee receiver cannot be the zero address");
        address previousReceiver = feeReceiver;
        feeReceiver = _feeReceiver;
        emit FeeReceiverChanged(previousReceiver, _feeReceiver);
    }
}
