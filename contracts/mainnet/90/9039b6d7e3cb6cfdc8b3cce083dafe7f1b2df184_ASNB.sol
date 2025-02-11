/**
 *Submitted for verification at BscScan.com on 2022-06-25
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-12
*/

pragma solidity ^0.8.6;

// SPDX-License-Identifier: Unlicensed
interface IERC20 {
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address public _owner;

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
}

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
        require(c >= a, "SafeMath: addition overflow");

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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
}

contract ASNB is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal;
    uint256 private _tTotalFee;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;
    uint256 private _decimals;    

    uint256 public _liquidityFee = 0;
    uint256 public _destroyFee = 0;
    address private _destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);

    uint256 public _inviterFee = 1;
    address public inviterAddress = address(0x000000000000000000000000000000000000dEaD);
    mapping(address => address) public inviter;
    mapping(address => uint256) public lastSellTime;

    address public uniswapV2Pair = _destroyAddress;
    
    //交易对
    address public pair;

    //分红钱包
    address public fund1Address = address(0);    

    //质押挖矿
    address public fund2Address = address(0);

    //营销钱包
    address public fund3Address = address(0);
    //NFT
    address public fund4Address = address(0);
//回流  
    address public fund5Address = address(0);
    
    uint256 public _fund1Fee = 2;    
    uint256 public _fund2Fee = 1;
    uint256 public _fund3Fee = 1;
    //nft
    uint256 public _fund4Fee = 2;
    //回流
    uint256 public _fund5Fee = 2;
    //1销毁

    //黑名单
    mapping (address => bool) public isBlackList;

    constructor(address tokenOwner) {
        _name = "ASNB";
        _symbol = "ASNB";
        _decimals = 18;

        _tTotal = 210000000 * 10**_decimals;
        uint256 leftAmount = 1 * 10**_decimals;
        _tTotalFee = _tTotal.sub(leftAmount);
        _rTotal = (MAX - (MAX % _tTotal));

        _rOwned[tokenOwner] = _rTotal;

        //exclude owner and this contract from fee
        _isExcludedFromFee[tokenOwner] = true;
        _isExcludedFromFee[address(this)] = true;

        _owner = msg.sender;
        emit Transfer(address(0), tokenOwner, _tTotal);
    }
    
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }


    //交易方法
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }


    

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function claimTokens() public onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        //判断是否为黑名单

        require(!isBlackList[from], "blacklist users");

        //判断单次最大99%       
        require(amount.div(100).mul(99) < balanceOf(from), "Transfer amount max 99%");


        //判断是否需要手续费
        bool takeFee = true;

       // uint256 _destroyTotal = balanceOf(_destroyAddress);
        // if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || _destroyTotal>= _tTotalFee) {
        //     takeFee = false;
        // }else{
        //     if(from != uniswapV2Pair && to != uniswapV2Pair){
        //         takeFee = false;
        //     }
        // }

        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }else{
            // if(from != uniswapV2Pair && to != uniswapV2Pair){
            //     takeFee = false;
            // }
        }

       
        bool shouldSetInviter = balanceOf(to) == 0 &&
            inviter[to] == address(0) &&
            from != uniswapV2Pair;

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);

        if (shouldSetInviter) {
            inviter[to] = from;
        }
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        uint256 currentRate = _getRate();

      
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

        uint256 rate;
        if (takeFee) {      
            // _takeTransfer(
            //     sender,
            //     uniswapV2Pair,
            //     tAmount.div(100).mul(_liquidityFee),
            //     currentRate
            // );
            if(pair != address(0)){
                if(sender == pair){
                    _takeTransfer(
                        sender,
                        fund4Address,
                        tAmount.div(100).mul(_fund4Fee),
                        currentRate
                    );
                    
                    _takeTransfer(
                        sender,
                        fund5Address,
                        tAmount.div(100).mul(_fund5Fee),
                        currentRate
                    );
        

                }else if(recipient == pair){
                    _takeTransfer(
                        sender,
                        fund1Address,
                        tAmount.div(100).mul(_fund1Fee),
                        currentRate
                    );
                    
                    _takeTransfer(
                        sender,
                        fund2Address,
                        tAmount.div(100).mul(_fund2Fee),
                        currentRate
                    );

                    _takeTransfer(
                        sender,
                        fund3Address,
                        tAmount.div(100).mul(_fund3Fee),
                        currentRate
                    );
                }else{
                    _takeTransfer(
                        sender,
                        fund1Address,
                        tAmount.div(100).mul(_fund1Fee),
                        currentRate
                    );
                    
                    _takeTransfer(
                        sender,
                        fund2Address,
                        tAmount.div(100).mul(_fund2Fee),
                        currentRate
                    );

                    _takeTransfer(
                        sender,
                        fund3Address,
                        tAmount.div(100).mul(_fund3Fee),
                        currentRate
                    );
                }


            }
            else{
                _takeTransfer(
                    sender,
                    fund1Address,
                    tAmount.div(100).mul(_fund1Fee),
                    currentRate
                );
                
                _takeTransfer(
                    sender,
                    fund2Address,
                    tAmount.div(100).mul(_fund2Fee),
                    currentRate
                );

                _takeTransfer(
                    sender,
                    fund3Address,
                    tAmount.div(100).mul(_fund3Fee),
                    currentRate
                );
            }   
          
            _takeInviterFee(sender, tAmount.div(100).mul(_inviterFee));  
            rate = _inviterFee + _fund1Fee + _fund2Fee + _fund3Fee;
        }

       
        uint256 recipientRate = 100 - rate;
        _rOwned[recipient] = _rOwned[recipient].add(
            rAmount.div(100).mul(recipientRate)
        );


        emit Transfer(sender, recipient, tAmount.div(100).mul(recipientRate));
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        emit Transfer(sender, to, tAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _takeInviterFee(
        address sender,
        uint256 tAmount
    ) private {
        // address cur;
        // address reciver;
        // if (sender == uniswapV2Pair) {
        //     cur = recipient;
        // } else {
        //     cur = sender;
        // }
        emit Transfer(sender, inviterAddress, tAmount);
    }

    // function _takeInviterFee(
    //     address sender,
    //     address recipient,
    //     uint256 tAmount,
    //     uint256 currentRate
    // ) private {
    //     address cur;
    //     address reciver;
    //     if (sender == uniswapV2Pair) {
    //         cur = recipient;
    //     } else {
    //         cur = sender;
    //     }
    //     for (int256 i = 0; i < 1; i++) {
    //         uint256 rate;
    //         if (i == 0) {
    //             rate = 1;
    //         }
    //         cur = inviter[cur];
    //         if (cur == address(0)) {
    //             reciver = inviterAddress;
    //         }else{
    //             reciver = cur;
    //         }
    //         uint256 curTAmount = tAmount.div(100).mul(rate);
    //         uint256 curRAmount = curTAmount.mul(currentRate);
    //         _rOwned[reciver] = _rOwned[reciver].add(curRAmount);


    //         emit Transfer(sender, reciver, curTAmount);
    //     }
    // }

    function changeRouter(address router) public onlyOwner {
        uniswapV2Pair = router;
    }

    function getRate()public view returns (uint256){
        uint256 currentRate = _getRate();
        return currentRate;
    }

    //设置分红钱包
    function setFund1feeAddress(address account) public onlyOwner{
        fund1Address = account;
    }

    //设置需要质押的钱包
    function setFund2feeAddress(address account) public onlyOwner{
        fund2Address = account;
    }

    //设置营销钱包
    function setFund3feeAddress(address account) public onlyOwner{
        fund3Address = account;
    }

    function setFund4feeAddress(address account) public onlyOwner{
        fund4Address = account;
    }

    function setFund5feeAddress(address account) public onlyOwner{
        fund5Address = account;
    }



    function setFund1fee(uint256 _fee) public onlyOwner{
        _fund1Fee = _fee;
    }

    function setFund2fee(uint256 _fee) public onlyOwner{
        _fund2Fee = _fee;
    }



    function setFund3fee(uint256 _fee) public onlyOwner{
        _fund3Fee = _fee;
    }


    function setFund4fee(uint256 _fee) public onlyOwner{
        _fund4Fee = _fee;
    }


    function setFund5fee(uint256 _fee) public onlyOwner{
        _fund5Fee = _fee;
    }



    function excludeFromFeeList(address[] memory accounts) public onlyOwner { //添加持币人地址
        require(accounts.length != 0, "no accounts");
        address cur;
        for(uint i = 0; i < accounts.length; i++) {
            cur = accounts[i];
            _isExcludedFromFee[cur] = true;
        }
    }

    //手续费白名单
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    //取消手续费白名单
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setPair(address _pair) public onlyOwner {
        pair = _pair;
    }

    //flag 为true时 加入黑名单   为false时取消黑名单
    function addBlackList(address account, bool flag) external onlyOwner() { //加入黑名单
        isBlackList[account] = flag;
    }

}