/**
 *Submitted for verification at BscScan.com on 2022-09-01
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-22
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier: UNLICENCED
/*
    GroBat Token
    10% tax - 3% reflection in BUSD 2% LP 5% marketing wallet!  NO DEV FEES
    45% initial burn
    5% team tokens locked initially
    contract dev: @CryptoBatmanBSC
    marketing partners: @Leoxgroza  
    https://t.me/Grobatbsc
    https://www.grobattoken.com - live at launch

*/
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

interface IpresaleAirdrop {
    function airdropPresale(address recipient, uint256 amount) external;
}

contract ManualDividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;
    mapping(address => bool) adminAccounts;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
   
    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    
    IBEP20 public rewardtoken = IBEP20(BUSD);
    mapping (address => uint256) totaldividendsOfToken;
    IDEXRouter router;

    address[] public shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;
    mapping (address => mapping (address => Share)) public rewardshares;

    uint256 public totalShares;
    //uint256 public totalDividends;
    uint256 public totalDistributed;
    //uint256 public dividendsPerShare;
    mapping (address => uint256) public dividendsPerShareRewardToken;
    mapping (address => uint256) public totaldividendsrewardtoken;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 1 hours;
    uint256 public minDistribution = 1 * (10 ** 18);

    uint256 public currentIndex;

    bool initialized = false; // unneccesary as all booleans are initialiased to false;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyAdmin() {
        require(adminAccounts[msg.sender]); _;
    }

    constructor (address _router) {
        router = _router != address(0)
            ? IDEXRouter(_router)
            : IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
            //: IDEXRouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); //Testnet
        adminAccounts[msg.sender] = true;
        rewardtoken = IBEP20(_token);
    }

    function distributeToken(address[] calldata holders) external onlyAdmin {
        for(uint i = 0; i < holders.length; i++){
            if(shares[holders[i]].amount > 10000){ 
                distributeDividendInToken(holders[i]);
            }
        }
    }

    function getshareholders()external view returns(uint256 shareholderamount){
        return shareholders.length;
    }
    

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyAdmin {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }
    
    function setRewardToken(IBEP20 newrewardToken) external onlyAdmin{
        rewardtoken = newrewardToken;
    }
    
    function addAdmin(address adminAddress) public onlyAdmin{
        adminAccounts[adminAddress] = true;
    }
    
    
    function removeAdmin(address adminAddress) public onlyAdmin{
        adminAccounts[adminAddress] = false;
    }
    
    
    function setInitialShare(address shareholder, uint256 amount) external onlyAdmin {
        addShareholder(shareholder);
        totalShares += amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    
    function setShareMultiple(address[] calldata addresses, uint256[] calldata amounts) external onlyAdmin
    {
        require(addresses.length == amounts.length, "must have the same length");
        for (uint i = 0; i < addresses.length; i++){
            setShareInternal(addresses[i], amounts[i]*(10**18));
        }
    }
    
    function setShareInternal(address shareholder, uint256 amount) internal {
        
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares += (shares[shareholder].amount) + (amount);
        shares[shareholder].amount = amount;
        rewardshares[WBNB][shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function setShare(address shareholder, uint256 amount) external override onlyAdmin {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
        
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares -= (shares[shareholder].amount);
        shares[shareholder].amount = amount;
        totalShares += (amount);
        rewardshares[WBNB][shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override {

        totaldividendsOfToken[WBNB] = totaldividendsOfToken[WBNB] + msg.value;
        dividendsPerShareRewardToken[WBNB] = dividendsPerShareRewardToken[WBNB] + (dividendsPerShareAccuracyFactor * (msg.value) / (totalShares));
    }

    function process(uint256 gas) external override {
        // this shouldnt be called from outside
    }
    
    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
                && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            rewardshares[WBNB][shareholder].totalRealised  += (amount);
            rewardshares[WBNB][shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }
    
    function distributeDividendInToken(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed += amount;
            shareholderClaims[shareholder] = block.timestamp;
            rewardshares[WBNB][shareholder].totalRealised  += (amount);
            rewardshares[WBNB][shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            address[] memory path = new address[](2);
            path[0] = address(WBNB);
            path[1] = address(rewardtoken);
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
                0,
                path,
                shareholder,
                block.timestamp
            );
        }
    }
    
    function claimDividend() external {
        distributeDividendInToken(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = rewardshares[WBNB][shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }

        return shareholderTotalDividends - (shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShareRewardToken[WBNB] / dividendsPerShareAccuracyFactor;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract GroBat is IBEP20, Auth {
    using SafeMath for uint256;

    address WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Gro Bat";
    string constant _symbol = "GRBT";
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 1 * 10**15* (10 ** _decimals); //1 tril
    uint256 public _maxTxAmount = _totalSupply / 50; // 2%
    uint256 public _maxHoldAmount = _totalSupply / 50; // 2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;
    mapping (address => bool) isMaxHoldExempt;


    /* @dev   
        all fees are set wwith 2 decimal places added, please remember this when setting fees.
    */

    uint256 public liquidityFee = 200;
    uint256 reflectionFee = 300;
    uint256 public marketingFee = 500;
    uint256 public developmentfee = 0;
    uint256 charityorBurn = 0;
    uint256 public rewardtokenFee = 0;
    uint256 public sellpremium = 100;
    uint256 public totalFee = 1000;
    uint256 public feeDenominator = 10000;

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address public devFeeReciever;
    address public presaleAddress;
    address public charityFeeReciever;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;
    mapping (address => bool) public pairs;
    address public presaleContract;

    bool public canTrade = false;
    uint256 public launchedAt;


    ManualDividendDistributor public distributor;
    uint256 distributorGas = 500000;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 10000; // 0.01%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (
    ) Auth(msg.sender) {
        router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E); //Mainnet
        //router = IDEXRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); //Testnet
        pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
        pairs[pair] = true;
        _allowances[address(this)][address(router)] = _totalSupply;
        isMaxHoldExempt[pair] = true;
        isMaxHoldExempt[DEAD] = true;

        distributor = new ManualDividendDistributor(address(router));
        distributor.addAdmin(address(msg.sender));

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;
        authorizations[msg.sender] = true;
        
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = msg.sender;
        devFeeReciever = msg.sender;
        owner = msg.sender;
        isMaxHoldExempt[owner] = true;
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender];} 
    function rewardtoken()external view returns(address) {return address(distributor.rewardtoken());}
    function getrewardDistributionTime()external view returns(uint256){return distributor.minPeriod();}
    function getRewardDistributionMinAmount() external view returns(uint256){return distributor.minDistribution();}
    
    function getEstimatedgroForBnb(uint bnbAmount) public view returns (uint[] memory) {
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);
        return router.getAmountsOut(bnbAmount, path);
    }
    
    function getEstimatedBnbForgro(uint groAmount) public view returns (uint[] memory) {
            address[] memory path = new address[](2);
            path[1] = router.WETH();
            path[0] = address(this);
        return router.getAmountsOut(groAmount, path);
    }
    
    function buyTokens(uint amountOutMin)public payable {
        address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(this);
            uint deadline = block.timestamp + 100;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: msg.value }(amountOutMin, path, address(msg.sender), deadline);
    }

    function sellTokens(uint amountOutMin)public payable {
        address[] memory path = new address[](2);
            path[1] = router.WETH();
            path[0] = address(this);
            uint deadline = block.timestamp + 100;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountOutMin,0, path, address(this), deadline);
    }


    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function setDistributor(ManualDividendDistributor dist)external authorized {
        distributor = dist;
    }

    function setSwapThresholdDivisor(uint divisor)external authorized {
        require(divisor >= 100, "grotoken: max sell percent is 1%");
        swapThreshold = _totalSupply / divisor;
    }
    
    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }

    function setRewardToken(IBEP20 newrewardToken) external authorized{
        distributor.setRewardToken(newrewardToken);
    }
    
    function revertRewardToken() external authorized {
        distributor.setRewardToken(IBEP20(address(this)));
    }
    
    function setPresaleContract(address ctrct) external authorized {
        presaleContract = ctrct;
        isDividendExempt[presaleContract] = true;
        isFeeExempt[presaleContract] = true;
        isTxLimitExempt[presaleContract] = true;
    }
    
    function airdropPresale(address recipient, uint256 amount) external authorized {
        _balances[msg.sender] = _balances[msg.sender].sub(amount , "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        try distributor.setShare(recipient, _balances[recipient]) {} catch {}
        emit Transfer(msg.sender, recipient, amount);
    }
    
    function airdropPresaleInternal(address recipient, uint256 amount) internal {
        require(_balances[msg.sender] >= amount);
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        try distributor.setInitialShare(recipient, amount) {} catch {}
        emit Transfer(msg.sender, recipient, amount);
    }
    
    function setmaxholdpercentage(uint256 percentage) external authorized {
        require(percentage >= 1); // cant change percentage below 0, so everyone can hold the percentage
        _maxHoldAmount = _totalSupply * percentage / 100; // percentage based on amount
    }
    
    function airdropArray(address[] calldata newholders, uint256[] calldata amounts) external authorized{
        uint256 iterator = 0;
        require(newholders.length == amounts.length, "must be the same length");
        while(iterator < newholders.length){
            airdropPresaleInternal(newholders[iterator], amounts[iterator] * 10**_decimals);
            iterator += 1;
        }
    }
    
    function allowtrading()external authorized {
        canTrade = true;
    }
    
    function setSellPremium(uint256 premium)external authorized {
        require(premium >=0 && premium + totalFee <= 4500);
        require(premium <= sellpremium || premium <= 400); // premium can only go down after launch or max 4% above the total buy tax.
        sellpremium = premium;
    }
    
    function addNewPair(address newPair)external authorized{
        pairs[newPair] = true;
        isMaxHoldExempt[newPair] = true;
        isDividendExempt[newPair] = true;
    }
    
    function removePair(address pairToRemove)external authorized{
        pairs[pairToRemove] = false;
        isMaxHoldExempt[pairToRemove] = false;
    }
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != uint256(_totalSupply)){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(!canTrade){
            require(sender == owner || sender == presaleContract); // only owner allowed to trade or add liquidity
        }
        if(sender != owner && recipient != owner){
            if(!pairs[recipient] && !isMaxHoldExempt[recipient]){
                require (balanceOf(recipient) + amount <= _maxHoldAmount, "cant hold more than max hold dude, sorry");
            }
        }
        
        

        if(shouldSwapBack()){ swapBack(); }
        
        checkTxLimit(sender, recipient, amount);
        
        if(!launched() && pairs[recipient]){ require(_balances[sender] > 0); launch(); }
        
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = 0;
        
        if(!shouldTakeFee(sender) || !shouldTakeFee(recipient)){
            amountReceived = amount;
        }else{
            amountReceived = takeFee(sender, amount);
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if(!isDividendExempt[sender]){ try distributor.setShare(sender, _balances[sender]) {} catch {} }
        if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, _balances[recipient]) {} catch {} }

        emit Transfer(sender, recipient, amountReceived);
        return true;

    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function checkTxLimit(address sender, address reciever, uint256 amount) internal view {
        if(sender != owner && reciever != owner){
            require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
        }
    }

    function shouldTakeFee(address endpt) internal view returns (bool) {
        return !isFeeExempt[endpt];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }
    
    // returns any mis-sent tokens to the marketing wallet
    function claimtokensback(IBEP20 tokenAddress) external authorized {
        payable(devFeeReciever).transfer(address(this).balance);
        tokenAddress.transfer(marketingFeeReceiver, tokenAddress.balanceOf(address(this)));
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function launch() internal {
        launchedAt = block.timestamp;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        require(holder != address(this) && !pairs[holder]);
        isDividendExempt[holder] = exempt;
        if(exempt){
            distributor.setShare(holder, 0);
        }else{
            distributor.setShare(holder, _balances[holder]);
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee,  uint256 _reflectionFee, uint256 _marketingFee, uint256 _devFee,uint256 _charityFee,uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        developmentfee = _devFee;
        charityorBurn = _charityFee;
        totalFee = _liquidityFee.add(_reflectionFee).add(_marketingFee).add(developmentfee).add(charityorBurn);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/4); // cant be over 25% of total.
    }
    
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2); // leave some tokens for liquidity addition
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify); // swap everything bar the liquidity tokens. we need to add a pair

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountBNBLiquidity = amountBNB.mul(dynamicLiquidityFee).div(totalBNBFee).div(2);
        
        if(reflectionFee > 0){
            uint256 amountBNBReflection = amountBNB.mul(reflectionFee).div(totalBNBFee);
            try distributor.deposit{value: amountBNBReflection}() {} catch {}
        }
        
        uint256 amountBNBMarketing = amountBNB.mul(marketingFee).div(totalBNBFee);

        if(developmentfee > 0){
            uint256 amountBNBDev = amountBNB.mul(developmentfee).div(totalBNBFee);
            payable(devFeeReciever).transfer(amountBNBDev);
        }
        

        payable(marketingFeeReceiver).transfer(amountBNBMarketing);
        
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address devWallet) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReciever = devWallet;
    }
    
    function setCharityWallet(address charityWallet)external authorized{
        charityFeeReciever = charityWallet;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    
     function shouldSwapBack() internal view returns (bool) {
        return !pairs[msg.sender]
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized {
        // minperiod is sent in in seconds, _mindistribution is sent in as a number * 10**18, i.e wei value.
        require(_minPeriod >= 1 hours && _minPeriod <= 1 days, "can not set the period to any thing less than an hour or more than 7 days");
        require(_minDistribution <= 2 * 10 ** 18 && _minDistribution > 0, "can not set the distribution to anything more than 2 bnb and it must be greater than 0");
        
        distributor.setDistributionCriteria(_minPeriod, _minDistribution);
    }

    function setDistributorSettings(uint256 gas) external authorized {
        require(gas < 750000);
        distributorGas = gas;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }


    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
    event BuybackMultiplierActive(uint256 duration);
    
}