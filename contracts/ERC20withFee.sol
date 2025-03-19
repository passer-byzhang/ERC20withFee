// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IUniswapV2Pair.sol";
// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract ERC20withFee is ERC20Upgradeable, OwnableUpgradeable {
    uint256 constant FEE_SELL = 40; //4%
    uint256 constant FEE_BUY = 20; //2%
    uint256 constant MIN_TRANSFER_AMOUNT = 10;
    address public feeReceiver;

    event Initialized(
        string name,
        string symbol,
        address feeReceiver,
        address owner,
        uint256 minTransferAmount
    );
    event TransferWithFee(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 feeAmount,
        bool isSell
    );
    event FeeReceiverChanged(
        address indexed previousReceiver,
        address indexed newReceiver
    );
    event PairChanged(
        address indexed previousPair,
        address indexed newPair
    );

    error UnderMinTransferAmount(uint256 amount, uint256 minTransferAmount);
    IUniswapV2Pair public pair;
    function initialize(
        string memory name,
        string memory symbol,
        address _feeReceiver,
        address _pair,
        address owner
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init(owner);
        feeReceiver = _feeReceiver;
        pair = IUniswapV2Pair(_pair);
        require(pair.token0() == address(this) || pair.token1() == address(this), "Invalid pair");
        emit Initialized(
            name,
            symbol,
            feeReceiver,
            owner,
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
        uint256 fee = 0;
        bool isSell = false;
        if(msg.sender==address(pair)){
            fee = FEE_BUY;
        }else if(to==address(pair)){
            fee = FEE_SELL;
            isSell = true;
        }

        uint256 feeAmount = (amount * fee) / 1000;
        super._transfer(owner, feeReceiver, feeAmount);
        uint256 transferAmount = amount - feeAmount;
        super._transfer(owner, to, transferAmount);
        if(fee>0){
            emit TransferWithFee(owner, to, amount, feeAmount, isSell);
        }
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
        uint256 fee = 0;
        bool isSell = false;
        if(msg.sender==address(pair)){
            fee = FEE_BUY;
        }else if(to==address(pair)){
            fee = FEE_SELL;
            isSell = true;
        }
        uint256 feeAmount = (amount * fee) / 1000;
        super._transfer(from, feeReceiver, feeAmount);
        uint256 transferAmount = amount - feeAmount;
        super._transfer(from, to, transferAmount);
        if(fee>0){
            emit TransferWithFee(from, to, amount, feeAmount, isSell);
        }
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

    function setPair(address _pair) external onlyOwner {
        require(_pair != address(0), "Pair cannot be the zero address");
        address previousPair = address(pair);
        pair = IUniswapV2Pair(_pair);
        require(pair.token0() == address(this) || pair.token1() == address(this), "Invalid pair");
        emit PairChanged(previousPair, _pair);
    }

}
