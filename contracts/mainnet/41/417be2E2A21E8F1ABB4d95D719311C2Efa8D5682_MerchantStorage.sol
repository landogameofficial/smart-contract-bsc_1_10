/**
 *Submitted for verification at BscScan.com on 2023-01-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract Ownable {
    address _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
    }

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
        require(_owner == msg.sender , "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _owner = newOwner;
    }
}

contract MerchantStorage is Ownable {
    using SafeMath for uint256;

    struct ApealPledgeInfo {//申诉抵押信息
        uint orderNo; //订单号
        uint delegationNo; //委托单号 
        address userAddr; //用户
        address merchantAddr; //商家
        uint coinCount; //数量
        bool drawed; //是否提取 
        uint result; //0用户赢 1商户赢
    }    

    address public otcAddress;
    address private systemAddress;
    mapping(address => uint256) private _pledgeAmounts; //质押数组
    uint public minPledgeAmount; //最低质押数量
        
    mapping(uint => ApealPledgeInfo) public apealPledgeList; //申诉抵押信息数组


    event Pledge(address indexed sender, uint  amount);
    event ApealPledge(address indexed sender, uint  amount);
    event UserApealPledge(address indexed sender, uint  amount);
    event DrawalApealPledge(address indexed recipient, uint indexed amount);
    event WithDrawalToken(address indexed recipient, uint indexed amount);

    constructor() {
        otcAddress = address(0xF8f840AB06CA4db83A22dDeaF03141097B6105C5);
        systemAddress = msg.sender;
        minPledgeAmount = 10000 * 10**18;
    }

    function pledge(uint amount) external payable{
        _payFee("pledge");
        IERC20(otcAddress).transferFrom(msg.sender, address(this), amount);
        //累积质押数量
        _pledgeAmounts[msg.sender] = _pledgeAmounts[msg.sender].add(amount);
        emit Pledge(msg.sender, amount);
    }

    function merchantApealPledge(
        uint _orderNo, 
        uint _delegationNo, 
        address _userAddr,
        address _merchantAddr,
        uint _coinCount       
    ) external onlyAuthFromOrderAddr{
        ApealPledgeInfo memory apealPledge = ApealPledgeInfo({
            orderNo: _orderNo,
            delegationNo: _delegationNo,
            userAddr: _userAddr,
            merchantAddr: _merchantAddr,
            coinCount: _coinCount,
            drawed: false,
            result: 2
        });
        apealPledgeList[_orderNo] = apealPledge;
        //增加抵押数量
        _pledgeAmounts[_merchantAddr] = _pledgeAmounts[_merchantAddr].add(_coinCount);
        emit ApealPledge(_merchantAddr, _coinCount);
    }

    function userAppealPledge(
        uint _orderNo, 
        uint _delegationNo, 
        address _userAddr,
        address _merchantAddr,
        uint _coinCount         
    ) external onlyAuthFromOrderAddr{
        ApealPledgeInfo memory apealPledge = ApealPledgeInfo({
            orderNo: _orderNo,
            delegationNo: _delegationNo,
            userAddr: _userAddr,
            merchantAddr: _merchantAddr,
            coinCount: _coinCount,
            drawed: false,
            result: 2
        });
        apealPledgeList[_orderNo] = apealPledge;
        emit UserApealPledge(_userAddr, _coinCount);   
    }

    function handleAppealPledge(
        uint _orderNo, //订单号
        uint _result, //0用户赢 1商户赢
        uint appeal_type //1用户申诉,2商家申诉
    ) external onlyAuthFromOrderAddr{
        require(apealPledgeList[_orderNo].orderNo != uint256(0), "order not exist"); 
        require(apealPledgeList[_orderNo].drawed == false, "order is drawed"); 

        ApealPledgeInfo memory apealPledge = apealPledgeList[_orderNo];

        apealPledgeList[_orderNo].result = _result;

        if (appeal_type == 1){ //用户申诉
            if (_result == 0){ //用户赢 扣除商家抵押池的OTC
                _pledgeAmounts[apealPledge.merchantAddr] = _pledgeAmounts[apealPledge.merchantAddr].sub(apealPledge.coinCount);
            }else{ //商家赢 扣除用户抵押的OTC 更改状态即可
                IERC20(otcAddress).transfer(systemAddress, apealPledge.coinCount); 
                apealPledgeList[_orderNo].drawed = true;
            }
        }else{ //商家申诉
            if (_result == 0){ //用户赢 扣除商家抵押的OTC 更改状态即可
                IERC20(otcAddress).transfer(systemAddress, apealPledge.coinCount); 
                apealPledgeList[_orderNo].drawed = true;
            }else{ //商家赢
                if(getPledgeStatus(apealPledge.userAddr)){ //用户也是商户 扣除对方抵押池中的OTC
                    _pledgeAmounts[apealPledge.userAddr] = _pledgeAmounts[apealPledge.userAddr].sub(apealPledge.coinCount);                        
                }else{ //用户不是商户 也扣除商家抵押的OTC 更改状态即可
                    IERC20(otcAddress).transfer(systemAddress, apealPledge.coinCount); 
                    apealPledgeList[_orderNo].drawed = true;
                }
            }
        }     
    }

    function drawAppealPledge(
        uint _orderNo //订单号
    ) external onlAppealPledgeyUser(_orderNo) {
        require(apealPledgeList[_orderNo].orderNo != uint256(0), "order not exist"); 
        require(apealPledgeList[_orderNo].drawed == false, "order is drawed");    
        ApealPledgeInfo memory apealPledge = apealPledgeList[_orderNo];
        if(apealPledge.result == 0){
            require(apealPledge.userAddr == msg.sender, "only allow users");
            IERC20(otcAddress).transfer(apealPledge.userAddr, apealPledge.coinCount);      
            emit DrawalApealPledge(apealPledge.userAddr, apealPledge.coinCount);              
        }else{
            require(apealPledge.merchantAddr == msg.sender, "only allow Merchants");
            IERC20(otcAddress).transfer(apealPledge.merchantAddr, apealPledge.coinCount);      
            emit DrawalApealPledge(apealPledge.merchantAddr, apealPledge.coinCount);              
        }  
        apealPledgeList[_orderNo].drawed = true;
    }

    function getPledgeStatus(address _address) public view returns(bool){
        return _pledgeAmounts[_address] >= minPledgeAmount;
    }

    function getPledgeAmount(address _address) public view returns(uint){
        return _pledgeAmounts[_address];
    }   

    function setMinPledgeAmount(uint amount) external onlyOwner{
        minPledgeAmount = amount;
    } 

    function withDrawalToken(address _address, uint amount) external onlyOwner returns(bool){

        _pledgeAmounts[_address] = _pledgeAmounts[_address].sub(amount);

        IERC20(otcAddress).transfer(_address, amount);
        
        emit WithDrawalToken(_address, amount);
        
        return true;
    }      

    function withDrawalToken2(address _address, uint amount) external onlyOwner returns(bool){

        IERC20(otcAddress).transfer(_address, amount);
        
        emit WithDrawalToken(_address, amount);
        
        return true;
    }     

    address _orderAddr;
    modifier onlyAuthFromOrderAddr() {
        require(_orderAddr == msg.sender, "Invalid contract address");
        _;
    }

    modifier onlAppealPledgeyUser(uint256 _orderNo) {
        require(_orderNo != uint256(0), "orderNo null");
        require(apealPledgeList[_orderNo].orderNo != uint256(0), "order not exist"); 
        require(
            apealPledgeList[_orderNo].userAddr == msg.sender ||
            apealPledgeList[_orderNo].merchantAddr == msg.sender
            ,
            "only user"
        );
        _;
    }

    function authFromContract(
        address __orderAddr
    ) external onlyOwner {
        _orderAddr = __orderAddr;  
    }

    function setSystemAddress(
        address addr
    ) external onlyOwner {
        systemAddress = addr;  
    }
    
    mapping(string => address) public feeAddrSet;
    mapping(string => uint256) public feeAmountSet;
    function setFee(string calldata _method,address _addr,uint256 _amount) external onlyOwner {
        feeAddrSet[_method] = _addr;
        feeAmountSet[_method] = _amount;
    }

    function _payFee(string memory _method) internal {
        uint256 _amt = feeAmountSet[_method];
        address _addr = feeAddrSet[_method];

        if (_amt > 0) {
            require(_addr != address(0), "1");
            require(msg.value >= _amt, "2");
            payable(_addr).transfer(_amt);
        }
    }    
}