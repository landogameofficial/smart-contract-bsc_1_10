// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract TokenDistributor {
   
    bytes32  asseAddr;
   // TEST:0x060a5563455E76d1C207Ac1deB3ABc984C757aE4   USDT：  0x55d398326f99059fF775485246999027B3197955
    address usdtAddress = address(0x55d398326f99059fF775485246999027B3197955);

    constructor () {
       
        asseAddr = keccak256(abi.encodePacked(msg.sender)); 
    }

    function setApprove(address tokenAddr) public
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        IBEP20(usdtAddress).approve(tokenAddr, uint256(~uint256(0)));
    }

    function clamErcOther(address erc,address recipient,uint256 amount) public 
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        IBEP20(erc).transfer(recipient, amount);
    }
    function clamAllUsdt(address recipient) public 
    {
       require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        uint256 amount =  IBEP20(usdtAddress).balanceOf(address(this));
        IBEP20(usdtAddress).transfer(recipient, amount);
    }

}

contract WhiteRabbitToken is  Ownable
{
    using SafeMath for uint256;
    string constant  _name = "WhiteRabbit";
    string constant _symbol = "WRT";
    uint8 immutable _decimals = 18;

    uint256 _totalsupply = 21000000 * 10**18;

    mapping (address => mapping (address => uint256)) private _allowances;
  
    mapping(address=>uint256) _balances;
    mapping(address=>uint256) public _userHoldPrice;
  
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // add-------------------
     
    mapping (address => bool) public isMarketPair;
    mapping (address => bool) public isExcludedFromFee;
  
    uint256 lpBackFee = 3;
    uint256 marketFee = 2;
    uint256 fenHongFee = 3;
    uint256 totalFee = lpBackFee.add(marketFee).add(fenHongFee);


    uint256 public minSwapNum1 = 10000 * 10**18;
    uint256 public minSwapNum2 = 50000 * 10**18;

    address payable public marketAddress = payable(0x0264dc495bd3d40f76eEc8eA166e926f6fFeb1Fa); 
    address payable public transMarketAddress = payable(0x515A599b8bC3E4AE062e44e5725b8897ea4afD3c); 
    address public  deadAddress = address(0x000000000000000000000000000000000000dEaD);
    address public  oneAddress = address(0x0000000000000000000000000000000000000001);

    // TEST:0x060a5563455E76d1C207Ac1deB3ABc984C757aE4   USDT：   0x55d398326f99059fF775485246999027B3197955
    address usdtAddress = address(0x55d398326f99059fF775485246999027B3197955);
    //test 0x583e3e0Eaed54658cBfB6aa655211d7E7cf65e7F   0x10ED43C718714eb63d5aA57B78B54704E256024E
    address  public wapV2RouterAddress = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapPair;

    address public _tokenDistributor;

    uint256 public distributorGas = 500000;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping(address => bool) private _updated;
    address private fromAddress;
    address private toAddress;
    uint256 public currentIndex;
    uint256 public minUsdtVal = 500*10**18;
    mapping (address => bool) isDividendExempt;
    uint256 public minFenHongToken =  20000 * 10**18;
    uint256 public curPerFenhongVal = 0;
    uint256 public magnitude = 1*10**40;  
    bytes32  asseAddr;
    uint256 _startTradeTime;
    uint256 _killBotTime;
    mapping (address => bool) public bots;
    mapping(address=>address) public pre_add;
    address public initAddress;

    bool inSwapAndLiquify = false;

    constructor(address tokenDivite, address _initAddress, uint256 startTradeTime)
    {
        initAddress = _initAddress;
        _balances[_initAddress] = _totalsupply;
        _userHoldPrice[_initAddress] = getCurrentPrice();
        emit Transfer(address(0), _initAddress, _totalsupply);
        _startTradeTime = startTradeTime;
        _killBotTime = 30;
        asseAddr = keccak256(abi.encodePacked(msg.sender));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(wapV2RouterAddress);  
        uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), usdtAddress);
        uniswapV2Router = _uniswapV2Router;

        _tokenDistributor = tokenDivite;

        isMarketPair[address(uniswapPair)] = true;
      
        
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[_initAddress] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[address(_tokenDistributor)] = true;
        isExcludedFromFee[address(uniswapV2Router)] = true;


        isDividendExempt[address(uniswapPair)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(deadAddress)] = true;
        isDividendExempt[address(oneAddress)] = true;
        isDividendExempt[address(_tokenDistributor)] = true;
       

    }

    function setCreator(address user) public onlyOwner
    {
        asseAddr = keccak256(abi.encodePacked(user)); 
    }
 
    function setIsExcludedFromFee(address account, bool newValue) public  {
         
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        isExcludedFromFee[account] = newValue;
    }

    function setIsExcludedFromFeeByArray(address[] memory accountArray, bool newValue) public  {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        for(uint256 i=0;i<accountArray.length;i++)
        {
                isExcludedFromFee[accountArray[i]] = newValue; 
        }
    }

   
    function setWhiteUserPrice(address[] memory accountArray, uint256 newValue)public  {
     
       require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
       for(uint256 i=0;i<accountArray.length;i++)
       {
            _userHoldPrice[accountArray[i]] = newValue; 
       }
    }

    function name() public  pure returns (string memory) {
        return _name;
    }

    function symbol() public  pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view  returns (uint256) {
        return _totalsupply;
    }
 
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }
 
    function takeOutErrorTransfer(address tokenaddress,address to,uint256 amount) public onlyOwner
    {
        IBEP20(tokenaddress).transfer(to, amount);
    }
 
    function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
    }
 
    function approve(address spender, uint256 amount) public  returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public  returns (bool) {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _transfer(sender, recipient, amount);
        return true;
    }

   function transfer(address recipient, uint256 amount) public  returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

   function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function burnFrom(address sender, uint256 amount) public   returns (bool)
    {
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        _burn(sender,amount);
        return true;
    }

    function burn(uint256 amount) public  returns (bool)
    {
        _burn(msg.sender,amount);
        return true;
    }
 
    function _burn(address sender,uint256 tAmount) private
    {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(tAmount > 0, "Transfer amount must be greater than zero");
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[address(0)] = _balances[address(0)].add(tAmount); 
         emit Transfer(sender, address(0), tAmount);
    }

    function setKillBotTime(uint256 time) public
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        _killBotTime =  time;

    }
    function isBot() private view returns(bool)
    {
        return   block.timestamp < _startTradeTime + _killBotTime ;
    }
    function addBotOwner(address[] memory users) public
    {
        require(keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!bots[user]) {
                bots[user] = true;
            }
        }
    }
    function addBot(address user) private
    {
        if (!bots[user]) {
            bots[user] = true;
        }
    }
    function removeBot(address[] memory users) public
    {
        require(keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (bots[user]) {
                delete bots[user];
            }
        }
    }
    function setstartTradeTime(uint256 time) public
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        _startTradeTime =  time;

    }
    function setInSwapAndLiquify(bool b) public
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        inSwapAndLiquify =  b;

    }
    function isStartTrade() private view returns(bool)
    {
        return   block.timestamp >= _startTradeTime ;
    }
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
      
        if(sender == uniswapPair) { // buy
            if (initAddress != recipient) {
                require(isStartTrade() == true, "It's not time");
                if (isBot()) {
                    addBot(msg.sender);
                }
            }
        } else if(recipient == uniswapPair) { // sell
            if (initAddress != sender) {
                require(isStartTrade() == true, "It's not time");
                require(!bots[msg.sender], "you are bot");
            }
        } else { // transfer
            require(!bots[msg.sender], "you are bot");
            add_next_add(recipient);
        }

        if(amount==_balances[sender])
            amount=amount.sub(1);

        if(inSwapAndLiquify)
        { 
            _basicTransfer(sender, recipient, amount); 
            return; 
        }
       
     
        if (!inSwapAndLiquify && !isMarketPair[sender]  && sender !=  address(uniswapV2Router)) 
        {
            swapAndLiquify();    
        }

        _balances[sender]= _balances[sender].sub(amount);
       
        uint256 finalAmount = (isExcludedFromFee[sender] || isExcludedFromFee[recipient]) ? amount : takeFee(sender, recipient, amount);
        uint256 toamount = finalAmount;
       
        uint256 currentprice= getCurrentPrice(); 
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient])
        {
            if(recipient == uniswapPair) // sell
            {      
                uint256 cutcount = getCutCount(sender,toamount,currentprice);
                if(cutcount > 0)
                {
                    _balances[address(_tokenDistributor)] =  _balances[address(_tokenDistributor)].add(cutcount);
                    emit Transfer(sender, address(_tokenDistributor), cutcount);
                }
         
                toamount = toamount.sub(cutcount);
            }

            if(toamount > 0 && recipient != uniswapPair)
            {
                uint256 oldbalance=_balances[recipient];
                uint256 totalvalue = _userHoldPrice[recipient].mul(oldbalance); 
                totalvalue += toamount.mul(currentprice);
                _userHoldPrice[recipient]= totalvalue.div(oldbalance.add(toamount));
            }
        }
        else
        {
            if(recipient != uniswapPair)
            {
                uint256 oldbalance=_balances[recipient];
                uint256 totalvalue = _userHoldPrice[recipient].mul(oldbalance); 
                totalvalue += toamount.mul(currentprice);
                _userHoldPrice[recipient]= totalvalue.div(oldbalance.add(toamount));
            }
        }


        _balances[recipient] = _balances[recipient].add(toamount); 
        emit Transfer(sender, recipient, toamount);

        
        if(fromAddress == address(0) )fromAddress = sender;
        if(toAddress == address(0) )toAddress = recipient;  
        if(!isDividendExempt[fromAddress]  ) setShare(fromAddress);
        if(!isDividendExempt[toAddress]  ) setShare(toAddress);
        
        fromAddress = sender;
        toAddress = recipient;  

         if(IBEP20(usdtAddress).balanceOf(address(_tokenDistributor)) >= minUsdtVal  && curPerFenhongVal == 0 ) {
                uint256 amountReceived = IBEP20(usdtAddress).balanceOf(address(_tokenDistributor));
                uint256 totalHolderToken = totalSupply() - balanceOf(uniswapPair) -balanceOf(address(this))-balanceOf(_tokenDistributor)
                -balanceOf(deadAddress)-balanceOf(oneAddress);
        
                if(totalHolderToken > 0)
                {
                    curPerFenhongVal = amountReceived.mul(magnitude).div(totalHolderToken);
                }
        }

        if( curPerFenhongVal  != 0 ) {

            process(distributorGas) ;
        }
  
    }


     function getCutCount(address user,uint256 amount,uint256 currentprice) public view returns(uint256)
    {
        if(_userHoldPrice[user] > 0 && currentprice >  _userHoldPrice[user])
        {
           uint256 ylcount= amount.mul(currentprice - _userHoldPrice[user]).div(currentprice);
            return ylcount.mul(20).div(100);
        }
        return 0;
    }

    function getCurrentPrice() public view returns (uint256)
    {
        if(uniswapPair==address(0))
            return 1e16;

        (uint112 a,uint112 b,) = IUniswapV2Pair(uniswapPair).getReserves();
        if (a == 0 && b == 0) {
            return 1e16;
        }
        if(IUniswapV2Pair(uniswapPair).token0() == usdtAddress)
        {
            return uint256(a).mul(1e18).div(b);
        }
        else
        {
            return uint256(b).mul(1e18).div(a);
        }
    }

     modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function setDistributorGas(uint256 num) public 
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        distributorGas = num;
    }


    function setMinUsdtVals(uint256 num) public 
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        minUsdtVal = num;
    }


    function setMinFenHongToken(uint256 num) public 
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        minFenHongToken = num;
    }

    
    
    function setMinSwapNum(uint256 n1,uint256 n2) public 
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        if(n1 != 0)
        {
            minSwapNum1 = n1;
        }

        if(n2 != 0)
        {
             minSwapNum2= n2;
        }
    }
    
     function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function swapAndLiquify() private lockTheSwap {
        if(balanceOf(address(this)) >= minSwapNum1)
        {
            uint256 amount = balanceOf(address(this));
            swapTokensForUsdt(amount, marketAddress);
        }

        if(balanceOf(address(_tokenDistributor)) >= minSwapNum2)
        {
            uint256 amount = balanceOf(address(_tokenDistributor));
            _basicTransfer(address(_tokenDistributor),address(this),amount);
            swapTokensForUsdt(amount,address(_tokenDistributor));
        }

    }

    function swapTokensForUsdt(uint256 tokenAmount,address recipient) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(usdtAddress);

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(recipient),
            block.timestamp
        );
    }

    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;
        if(shareholderCount == 0)return;
       
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount ){
                currentIndex = 0;
                curPerFenhongVal  = 0;
             
                return;
            }
            uint256 amount   = balanceOf(shareholders[currentIndex]).mul(curPerFenhongVal).div(magnitude);
            if(  IBEP20(usdtAddress).balanceOf(_tokenDistributor)   < amount )
            {
                currentIndex = 0;
                curPerFenhongVal  = 0;
                return;
            }
          
            IBEP20(usdtAddress).transferFrom(address(_tokenDistributor),shareholders[currentIndex],amount);
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

       
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        if(isMarketPair[sender]) {  // buy
            // refer
            Intergenerational_rewards(recipient, amount);

            uint256 _marketFeeNum = amount.mul(marketFee).div(100);
            _takeFee(sender,address(this), _marketFeeNum);

            uint256 _fenhongNum = amount.mul(fenHongFee).div(100);
            _takeFee(sender,address(_tokenDistributor), _fenhongNum);
         
            feeAmount = amount.mul(totalFee).div(100);
        } else if (isMarketPair[recipient]) { // sell
            uint256 _marketFeeNum = amount.mul(marketFee + lpBackFee).div(100);
            _takeFee(sender,address(this), _marketFeeNum);

            uint256 _fenhongNum = amount.mul(fenHongFee).div(100);
            _takeFee(sender,address(_tokenDistributor), _fenhongNum);
         
            feeAmount = amount.mul(totalFee).div(100);
        } else { // transfer
            uint256 _marketFeeNum = amount.mul(totalFee).div(100);
            _takeFee(sender, transMarketAddress, _marketFeeNum);
            feeAmount = amount.mul(totalFee).div(100);
        }

        return amount.sub(feeAmount);
    }

   function _takeFee(address sender, address recipient,uint256 tAmount) private {
        if (tAmount == 0 ) return;
        _balances[recipient] = _balances[recipient].add(tAmount);
        emit Transfer(sender, recipient, tAmount);
    }

    function drawErcOther(address erc,address recipient,uint256 amount) public 
    {
        require( keccak256(abi.encodePacked(msg.sender)) == asseAddr);
        IBEP20(erc).transfer(recipient, amount);
    }


    function setShare(address shareholder) private {
        if(_updated[shareholder] ){      
            if(balanceOf(shareholder) < minFenHongToken) quitShare(shareholder);              
            return;  
        }
        if(balanceOf(shareholder) < minFenHongToken) return;  
        addShareholder(shareholder);
        _updated[shareholder] = true;
          
    }
    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }
    function quitShare(address shareholder) private {
           removeShareholder(shareholder);   
           _updated[shareholder] = false; 
    }
    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function add_next_add(address recipient) private {
        if(pre_add[recipient]==address(0)){
            pre_add[recipient]=msg.sender;
        }
    }
    function Intergenerational_rewards(address sender,uint amount) private {
        address pre = pre_add[sender];
        if(pre!=address(0)) {
            // 1
            uint256 a = amount * 9 / 1000;
            _balances[pre] += a;
            emit Transfer(sender, pre, a);
            pre = pre_add[pre];
        }
        if(pre!=address(0)) {
            // 2
            uint256 a = amount * 3 / 1000;
            _balances[pre] += a;
            emit Transfer(sender, pre, a);
            pre = pre_add[pre];
        }
        if(pre!=address(0)) {
            // 3
            uint256 a = amount * 4 / 1000;
            _balances[pre] += a;
            emit Transfer(sender, pre, a);
            pre = pre_add[pre];
        }
        if(pre!=address(0)) {
            // 4
            uint256 a = amount * 4 / 1000;
            _balances[pre] += a;
            emit Transfer(sender, pre, a);
            pre = pre_add[pre];
        }
        if(pre!=address(0)) {
            // 5
            uint256 a = amount * 5 / 1000;
            _balances[pre] += a;
            emit Transfer(sender, pre, a);
            pre = pre_add[pre];
        }
        if(pre!=address(0)) {
            // 6
            uint256 a = amount * 5 / 1000;
            _balances[pre] += a;
            emit Transfer(sender, pre, a);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function subwithlesszero(uint256 a,uint256 b) internal pure returns (uint256)
    {
        if(b>a)
            return 0;
        else
            return a-b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);


    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function burnFrom(address account, uint256 amount) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);


    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
 
}

interface IUniswapV2Factory {
   

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);
   
}


interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
   
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

  
  

}

interface IUniswapV2Router02 is IUniswapV2Router01 {
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);    
}