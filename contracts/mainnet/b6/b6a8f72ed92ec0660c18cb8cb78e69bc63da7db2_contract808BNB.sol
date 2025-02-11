/**
 *Submitted for verification at BscScan.com on 2022-12-17
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor()  {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract contract808BNB is Owned, ReentrancyGuard {
    using SafeMath for uint256;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawReferalsBonus(address indexed user, uint256 amount);
    event WithdrawDeposit(address indexed user, uint256 index, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayedIn(address indexed user, uint256 totalAmount);
    event FeePayedOut(address indexed user, uint256 totalAmount);
    event ReinvestDeposit(address indexed user, uint256 index, uint256 amount);


    uint256 public totalInvested;
    uint256 public totalReInvested;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
        uint256 checkpoint;
    }

    struct Action {
        uint8 types;
        uint256 amount;
        uint256 date;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256[3] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
        Action[] actions;
    }
    
    mapping(address => User) internal users;

    bool public started;
    address payable public commissionWallet;


    uint256[] public REFERRAL_PERCENTS = [100, 20, 10]; // 100 = 10%
    uint256 public INVEST_MIN_AMOUNT = 0.01 ether; // 0.01 bnb
    uint256 public INVEST_MAX_AMOUNT = 10 ether; // 10 bnb
    uint256 public PROJECT_FEE = 150; // 150 = 15%
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;
    uint8 private planCurrent = 0;
    uint256 public totalUsers = 0;
    uint256 public startPoint;
    
    constructor() {
        commissionWallet = payable(msg.sender);
        plans.push(Plan(10, 200)); // 10 days, 200 = 20%
    }

    function startproject() public onlyOwner {
        startPoint = block.timestamp;
        started = true;
    }

    function setCommissionWallet(address newaddr) public onlyOwner {
        commissionWallet = payable(newaddr);
    }

    function sfi(uint256 value) public onlyOwner {
        PROJECT_FEE = value;
    }

    function invest(address referrer) public payable nonReentrant  {
        require(started, "808BNB: not launched");
        
        require(msg.value >= INVEST_MIN_AMOUNT, "808BNB: Deposit value is too small");
        require(msg.value <= INVEST_MAX_AMOUNT, "808BNB: Deposit limit exceeded");
        require(planCurrent < plans.length, "808BNB: Invalid plan");

        if (PROJECT_FEE > 0 ) {
            uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
            uint256 contractBalance = address(this).balance;
            if(fee > contractBalance) {
                fee = contractBalance;
            }
            (bool success, ) = commissionWallet.call{ value: fee }("");
            require(success, "withdrawFromAttackee failed to send");
            emit FeePayedIn(msg.sender, fee);
        }

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(amount);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(planCurrent, msg.value, block.timestamp, block.timestamp));
        user.actions.push(Action(0, msg.value, block.timestamp));

        totalInvested = totalInvested.add(msg.value);
        totalUsers ++;
        emit NewDeposit(msg.sender, planCurrent, msg.value);
    }

    function withdrawreferalsbonus() public nonReentrant {
        User storage user = users[msg.sender];
        uint256 referralBonus = getUserReferralBonus(msg.sender);
        uint256 contractBalance = address(this).balance;

        require(referralBonus > 0, "808BNB: User has no referal payments");
        require(contractBalance > referralBonus , "808BNB: No enought balance. Try later");

        if (referralBonus > 0) {
            user.bonus = 0;
        }
        
        user.withdrawn = user.withdrawn.add(referralBonus);

        (bool success, ) = payable(msg.sender).call{ value: referralBonus }("");
        require(success, "withdrawFromAttackee failed to send");
        user.actions.push(Action(2, referralBonus, block.timestamp));
        emit WithdrawReferalsBonus(msg.sender, referralBonus);
    }

    function withdrawdeposit(uint256 index) public nonReentrant {
        require(started, "808BNB: not launched");
        
        User storage user = users[msg.sender];

        uint256 amount = getUserDepositProfit(msg.sender, index);
        require(amount > 0, "808BNB: No deposit amount");
        
        uint256 finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
        if (finish > block.timestamp)
            user.deposits[index].checkpoint = block.timestamp; 
        else   
            user.deposits[index].checkpoint = finish; 

        user.withdrawn = user.withdrawn.add(amount);

        
        (bool success, ) = payable(msg.sender).call{ value: amount }("");
        require(success, "withdrawFromAttackee failed to send");
        user.actions.push(Action(3, amount, block.timestamp));
        emit WithdrawDeposit(msg.sender, index, amount);

        if (PROJECT_FEE > 0 ) {
            uint256 fee = amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
            uint256 contractBalance = address(this).balance;
            if(fee > contractBalance) {
                fee = contractBalance;
            }
            (bool success1, ) = commissionWallet.call{ value: fee }("");
            require(success1, "withdrawFromAttackee failed to send");
            emit FeePayedIn(msg.sender, fee);
        }
    }

    function reinvestdeposit(uint256 index) public nonReentrant{
        User storage user = users[msg.sender];

        uint256 amount = getUserDepositProfit(msg.sender, index);
        require(amount > 0, "808BNB: No deposit amount");
        
        uint256 finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
        if (finish > block.timestamp)
            user.deposits[index].checkpoint = block.timestamp; 
        else
            user.deposits[index].checkpoint = finish; 

        user.withdrawn = user.withdrawn.add(amount);

        user.actions.push(Action(4, amount, block.timestamp));

        uint8 plan = 0;
        user.deposits.push(Deposit(plan, amount, block.timestamp, block.timestamp));
        user.actions.push(Action(0, amount, block.timestamp));

        totalReInvested = totalReInvested.add(amount);

        emit ReinvestDeposit(msg.sender, index, amount);

        if (PROJECT_FEE > 0 ) {
            uint256 fee = amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
            uint256 contractBalance = address(this).balance;
            if(fee > contractBalance) {
                fee = contractBalance;
            }
            (bool success, ) = commissionWallet.call{ value: fee }("");
            require(success, "withdrawFromAttackee failed to send");
            emit FeePayedIn(msg.sender, fee);
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo() public view returns (uint256 time, uint256 percent) {
        time = plans[0].time;
        percent = plans[0].percent;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
        return users[userAddress].withdrawn;
    }

    function getUserCheckpoint(address userAddress) public view returns (uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns (address) {
        return users[userAddress].referrer;
    }

    function getUserDownlineCount(address userAddress) public view returns (uint256[3] memory referrals) {
        return (users[userAddress].levels);
    }

    function getUserTotalReferrals(address userAddress) public view returns (uint256) {
        return users[userAddress].levels[0] + users[userAddress].levels[1] + users[userAddress].levels[2];
    }

    function getUserReferralBonus(address userAddress) public view returns (uint256) {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns (uint256) {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress) public view returns (uint256) {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
        return amount;
    }

    function getUserDepositsInfo(address userAddress) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
       
        User storage user = users[userAddress];
       
        uint256[] memory index  = new uint256[](user.deposits.length);
        uint256[] memory start  = new uint256[](user.deposits.length);
        uint256[] memory finish = new uint256[](user.deposits.length);
        uint256[] memory checkpoint = new uint256[](user.deposits.length);
        uint256[] memory amount = new uint256[](user.deposits.length);
        uint256[] memory withdrawn = new uint256[](user.deposits.length);
        uint256[] memory profit = new uint256[](user.deposits.length);

        for (uint256 i=0; i< user.deposits.length; i++) {
            index[i]  = i;
            amount[i] = user.deposits[i].amount;
            start[i]  = user.deposits[i].start;
            checkpoint[i] = user.deposits[i].checkpoint;
            finish[i] = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(TIME_STEP));
            uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER); 
            withdrawn[i] = share.mul(checkpoint[i].sub(start[i])).div(TIME_STEP);

            profit[i] = 0;
            if (checkpoint[i] < finish[i]) {
                uint256 from = start[i] > checkpoint[i] ? start[i] : checkpoint[i];
                uint256 to = finish[i] < block.timestamp ? finish[i] : block.timestamp;
                if (from < to) {
                    profit[i] = share.mul(to.sub(from)).div(TIME_STEP);
                }
            }
        }

       
        return
        (
            index,
            start,
            checkpoint,
            finish,
            amount,
            withdrawn,
            profit
        );
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish, uint256 checkpoint, uint256 withdrawn, uint256 profit) {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
        checkpoint = user.deposits[index].checkpoint;
        uint256 share = user.deposits[index].amount.mul(plans[user.deposits[index].plan].percent).div(PERCENTS_DIVIDER);
        withdrawn = share.mul(checkpoint.sub(start)).div(TIME_STEP);
        profit = 0;

        if (checkpoint < finish) {
            uint256 from = user.deposits[index].start > user.deposits[index].checkpoint ? user.deposits[index].start : user.deposits[index].checkpoint;
            uint256 to = finish < block.timestamp ? finish : block.timestamp;
            if (from < to) {
                profit = share.mul(to.sub(from)).div(TIME_STEP);
            }
        }
    }

    function getUserDepositProfit(address userAddress, uint256 index) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 plan = user.deposits[index].plan;
        uint256 percent = plans[plan].percent;
        uint256 amount = user.deposits[index].amount;
        uint256 start = user.deposits[index].start;
        uint256 finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(TIME_STEP));
        uint256 checkpoint = user.deposits[index].checkpoint;
        uint256 profit = 0;

        if (checkpoint < finish) {
            uint256 share = amount.mul(percent).div(PERCENTS_DIVIDER);
            uint256 from = start > checkpoint ? start : checkpoint;
            uint256 to = finish < block.timestamp ? finish : block.timestamp;
            if (from < to) {
                profit = share.mul(to.sub(from)).div(TIME_STEP);
            }
        }
        return profit;
    }

    function umin(uint256 _value) public onlyOwner{
        INVEST_MIN_AMOUNT = _value;
    }
    function umax(uint256 _value) public onlyOwner{
        INVEST_MAX_AMOUNT = _value;
    }

    function getUserActions(address userAddress, uint256 index) public view returns (uint8[] memory, uint256[] memory, uint256[] memory) {
        require(index > 0, "wrong index");
        User storage user = users[userAddress];
        uint256 start;
        uint256 end;
        uint256 cnt = 50;

        start = (index - 1) * cnt;
        if (user.actions.length < (index * cnt)) {
            end = user.actions.length;
        }
        else {
            end = index * cnt;
        }

        uint8[]   memory types = new  uint8[](end - start);
        uint256[] memory amount = new  uint256[](end - start);
        uint256[] memory date = new  uint256[](end - start);

        for (uint256 i = start; i < end; i++) {
            types[i - start] = user.actions[i].types;
            amount[i - start] = user.actions[i].amount;
            date[i - start] = user.actions[i].date;
        }
        return
        (
            types,
            amount,
            date
        );
    }

    function getUserActionLength(address userAddress) public view returns (uint256) {
        return users[userAddress].actions.length;
    }

    function getUsersCount() public view returns (uint256) {
        return totalUsers;
    }

    function getStartPoint() public view returns (uint256) {
        return startPoint;
    }

    function getSiteInfo() public view returns (
        uint256 _totalInvested, 
        uint256 _totalReInvested, 
        uint256 _refPercent,
        uint256 _INVEST_MIN_AMOUNT,
        uint256 _INVEST_MAX_AMOUNT
        ) 
    {
        return (
            totalInvested, 
            totalReInvested, 
            REFERRAL_PERCENTS[0],
            INVEST_MIN_AMOUNT,
            INVEST_MAX_AMOUNT
        );
    }

    function getUserInfo(address userAddress) public view returns (uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
        return (getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}