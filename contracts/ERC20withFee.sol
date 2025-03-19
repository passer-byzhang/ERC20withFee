// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ERC20withFee is ERC20Upgradeable, OwnableUpgradeable {
    uint256 constant FEE = 100; //10%
    uint256 constant MIN_TRANSFER_AMOUNT = 10;
    address public feeReceiver;

    event Initialized(
        string name,
        string symbol,
        address feeReceiver,
        address owner,
        uint256 fee,
        uint256 minTransferAmount
    );
    event TransferWithFee(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 feeAmount
    );
    event FeeReceiverChanged(
        address indexed previousReceiver,
        address indexed newReceiver
    );

    error UnderMinTransferAmount(uint256 amount, uint256 minTransferAmount);

    function initialize(
        string memory name,
        string memory symbol,
        address _feeReceiver,
        address owner
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(owner);
        feeReceiver = _feeReceiver;
        emit Initialized(
            name,
            symbol,
            feeReceiver,
            owner,
            FEE,
            MIN_TRANSFER_AMOUNT
        );
    }

    function transfer(
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (amount < MIN_TRANSFER_AMOUNT) {
            revert UnderMinTransferAmount(amount, MIN_TRANSFER_AMOUNT);
        }
        address owner = _msgSender();
        
        uint256 feeAmount = (amount * FEE) / 1000;
        super._transfer(owner, feeReceiver, feeAmount);
        uint256 transferAmount = amount - feeAmount;
        super._transfer(owner, to, transferAmount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (amount < MIN_TRANSFER_AMOUNT) {
            revert UnderMinTransferAmount(amount, MIN_TRANSFER_AMOUNT);
        }
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);

        uint256 feeAmount = (amount * FEE) / 1000;
        super._transfer(from, feeReceiver, feeAmount);
        uint256 transferAmount = amount - feeAmount;
        super._transfer(from, to, transferAmount);

        return true;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        require(
            _feeReceiver != address(0),
            "Fee receiver cannot be the zero address"
        );
        address previousReceiver = feeReceiver;
        feeReceiver = _feeReceiver;
        emit FeeReceiverChanged(previousReceiver, _feeReceiver);
    }
}
