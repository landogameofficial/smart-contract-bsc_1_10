/**
 *Submitted for verification at BscScan.com on 2022-08-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.9;


// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

// 
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// 
contract LobbyFomo is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Round data
    struct AuctionRound {
        uint256 hmineInRound;
        uint256 sharesInRound;
    }

    struct User {
        uint256 hmineJackpot; // Fomo
        uint256 daiJackpot; // Fomo
    }
    uint256 public hminePerRound = 30e18;
    uint256 public hmineInLobby;
    mapping(address => User) users;
    mapping(uint256 => AuctionRound) auctionRounds;
    mapping(address => mapping(uint256 => uint256)) userSharesInLobby; // Track users share in each lobby round

    uint256 daiJackpot; // Tracks current DAI jackpot
    uint256 public nextRoundJackpot; // Tracks current DAI jackpot in next Round
    uint256 hmineJackpot; // Tracks current HMINE jackpot

    uint256 daiReward; // Tracks the DAI reward that was previously won from jackpot but not claimed yet.
    uint256 hmineReward; // Tracks the HMINE reward that was previously won from jackpot but not claimed yet.
    uint256 public fomoDeposit = 5e17; // 1 HMINE
    uint256 public timeIncrement = 1 minutes; //
    uint256 public fomoRoundInit = 30 minutes; //
    bool contractPaused = false;
    uint256 public lobbyStartTime = 1659117600;
    uint256 public fomoCountDown;

    address public bankroll; // 0x25be1fcF5F51c418a0C30357a4e8371dB9cf9369
    address public fomoKing; // 0x25be1fcF5F51c418a0C30357a4e8371dB9cf9369
    address public hmineToken; // 0xBC7A48dE21b14Ce7fccCe8b35c04B82e4c81578B
    address public daiToken; // 0x1af3f329e8be154074d8769d1ffa4ee058b1dbc3
    address management; // 0x2165fa4a32B9c228cD55713f77d2e977297D03e8

    event JoinLobby(address indexed _user, uint256 _round, uint256 _daiAmount);
    event JoinFomo(
        address indexed _user,
        uint256 _time,
        uint256 _countDown,
        uint256 _hmineAmount
    );
    event ClaimLobby(address indexed user, uint256 _amount, uint256 _round);
    event ClaimAllLobby(address indexed user, uint256 _amount);
    event ClaimFomoReward(
        address indexed user,
        uint256 _hmine,
        uint256 _dai,
        uint256 _time,
        uint256 _countDown
    );
    event HmineAdded(uint256 _round, uint256 _hmine);
    event DaiAdded(uint256 _time, uint256 _countDown, uint256 _dai);
    event StartGame(uint256 _daiJackpot, uint256 _countDown);

    constructor(
        address _dai,
        address _hmine,
        address _bankroll,
        address _management
    ) {
        hmineToken = _hmine;
        daiToken = _dai;
        bankroll = _bankroll;
        fomoKing = _bankroll;
        management = _management;
    }

    modifier onlyManagement() {
        require(msg.sender == management, "Unauthorized");
        _;
    }

    /*****************************************************************************************************/
    /******************************   Management Components **********************************************/
    /*****************************************************************************************************/

    // Admin updates incremented time for fomo
    function updateTimeIncrement(uint256 _t) external onlyOwner {
        require(_t >= 1 minutes, "Invalid time");
        timeIncrement = _t;
    }

    // Admin updates initialization time for fomo rounds
    function updateFomoTimeInit(uint256 _t) external onlyOwner {
        require(_t >= 1 minutes, "Invalid time");
        fomoRoundInit = _t;
    }

    // Admin updates max fomo value
    function updateFomoDeposit(uint256 _f) external onlyOwner {
        require(_f > 0, "Cannot be zero");
        fomoDeposit = _f;
    }

    // Admin can call this function to start the lobby.
    function startLobby(uint256 _start) external onlyOwner {
        require(
            lobbyStartTime == 0 || lobbyStartTime > block.timestamp,
            "Already started"
        );
        lobbyStartTime = _start;
    }

    // Admin updates bankroll address
    function updateBankrollAddress(address _b) external onlyOwner {
        require(_b != address(0), "Invalid address");
        bankroll = _b;
    }

    // Admin updates bankroll address
    function updateManagement(address _m) external onlyOwner {
        require(_m != address(0), "Invalid address");
        management = _m;
    }

    // Admin updates HMINE address
    function updateHMINE(address _m) external onlyOwner {
        require(_m != address(0), "Invalid address");
        hmineToken = _m;
    }

    function startFomoGame() external onlyManagement {
        // Update jackpots if the previous countdown already ended
        require(block.timestamp >= fomoCountDown, "Game is already in session");
        require(nextRoundJackpot > 0, "No jackpot for next round");

        // Update user reward trackers
        users[fomoKing].daiJackpot += daiJackpot;
        users[fomoKing].hmineJackpot += hmineJackpot;

        // Updates the overall reward trackers
        daiReward += daiJackpot;
        hmineReward += hmineJackpot;

        daiJackpot = nextRoundJackpot;
        nextRoundJackpot = 0;
        hmineJackpot = 0;
        fomoCountDown = block.timestamp + fomoRoundInit;

        emit StartGame(daiJackpot, fomoCountDown);
    }

    // Admin adds DAI to the jackpot.
    // If countdown ended or has not started yet, then add time to the clock.
    function addDaiToJackpot(uint256 _amount)
        external
        onlyManagement
        nonReentrant
    {
        // Count down ended already so we need to start a new round

        nextRoundJackpot += _amount;

        // Admin sends dai to contract
        IERC20(daiToken).safeTransferFrom(msg.sender, address(this), _amount);

        emit DaiAdded(block.timestamp, fomoCountDown, _amount);
    }

    // Admin can use this feature if the current game is a long game and they want to roll over the next jackpot to the current round.
    function rollOverNextJackpot() external onlyManagement {
        require(block.timestamp < fomoCountDown, "Game already ended");
        require(nextRoundJackpot > 0, "No jackpot for next round");

        daiJackpot += nextRoundJackpot;
        nextRoundJackpot = 0;
    }

    // Admin can add HMINE to the lobby for auction in the current round.
    function addHmineToLobby(uint256 _amount)
        external
        onlyManagement
        nonReentrant
    {
        // Count down ended already so we need to start a new round
        require(_amount > 0, "Invalid amount");
        uint256 _round = _getCurrentRound();
        // Admin sends HMINE to contract
        IERC20(hmineToken).safeTransferFrom(msg.sender, address(this), _amount);
        hmineInLobby += _amount;
        emit HmineAdded(_round, _amount);
    }

    // Used only if we want to shutdown lobby and redeploy
    function withdrawHmine(uint256 _amount) external onlyOwner nonReentrant {
        require(_amount > 0, "Invalid amount");
        require(_amount <= hmineInLobby, "Insufficient HMINE");
        IERC20(hmineToken).safeTransfer(msg.sender, _amount);
    }

    // Used only if we want to shutdown lobby and redeploy
    function withdrawDai() external onlyOwner nonReentrant {
        require(nextRoundJackpot > 0, "Invalid amount");
        IERC20(daiToken).safeTransfer(msg.sender, nextRoundJackpot);
        nextRoundJackpot = 0;
    }

    function updateHminePerRound(uint256 _hmine) external onlyOwner {
        require(_hmine > 0, "Invalid amount");

        hminePerRound = _hmine;
    }

    function togglePause(bool _pause) external onlyOwner {
        contractPaused = _pause;
    }

    /*****************************************************************************************************/
    /******************************   Lobby Components ****************************************************/
    /*****************************************************************************************************/

    // Retreives the current lobby round.
    function _getCurrentRound() internal view returns (uint256 _round) {
        if (lobbyStartTime == 0 || lobbyStartTime >= block.timestamp) {
            _round = 1;
        } else {
            uint256 modDays = (block.timestamp - lobbyStartTime) % 1 days;
            _round = (block.timestamp - lobbyStartTime) / 1 days;
            if (modDays > 0) {
                _round += 1;
            }
        }
    }

    // External call to get current round.
    function getRound() external view returns (uint256 _round) {
        _round = _getCurrentRound();
    }

    function getRoundInfo(uint256 _round)
        external
        view
        returns (uint256 _hmine, uint256 _shares)
    {
        if (auctionRounds[_round].hmineInRound > 0) {
            _hmine = auctionRounds[_round].hmineInRound;
        } else {
            _hmine = hminePerRound;
        }

        _shares = auctionRounds[_round].sharesInRound;
    }

    // User auctions DAI for HMINE in the lobby.  DAI added will determine share of HMINE for that round.
    // Each round is 24 hours.
    function joinLobby(address _user, uint256 _amount) external nonReentrant {
        uint256 _round = _getCurrentRound();

        require(
            block.timestamp >= lobbyStartTime && lobbyStartTime != 0,
            "Lobby not started yet"
        );
        require(!contractPaused, "Contract paused");

        // Updates Hmine in the round if it has not be updated yet.
        if (auctionRounds[_round].hmineInRound == 0) {
            require(hmineInLobby >= hminePerRound, "Insufficient HMINE");
            auctionRounds[_round].hmineInRound = hminePerRound;
            hmineInLobby -= hminePerRound;
        }

        auctionRounds[_round].sharesInRound += _amount;
        userSharesInLobby[_user][_round] += _amount;

        nextRoundJackpot += _amount / 2;

        // User sends DAI to contract for FOMO jackpot
        IERC20(daiToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount / 2
        );

        // Admin sends DAI to bankroll
        IERC20(daiToken).safeTransferFrom(msg.sender, bankroll, _amount / 2);

        emit JoinLobby(msg.sender, _round, _amount);
    }

    function userLobbyInfo(address _u, uint256 _round)
        external
        view
        returns (uint256 _userShare, uint256 _earning)
    {
        uint256 _shareInRound = auctionRounds[_round].sharesInRound;
        uint256 _hmineInRound;
        if (auctionRounds[_round].hmineInRound > 0) {
            _hmineInRound = auctionRounds[_round].hmineInRound;
        } else {
            _hmineInRound = hminePerRound;
        }
        _userShare = userSharesInLobby[_u][_round];

        if (_shareInRound == 0 || _hmineInRound == 0 || _userShare == 0) {
            _earning = 0;
        } else {
            _earning = (_userShare * _hmineInRound) / _shareInRound;
        }
    }

    // Claims the HMINE in the lobby auctions
    function claimSingleLobby(uint256 _round) external nonReentrant {
        uint256 _currentRound = _getCurrentRound();
        // If the lobby is still on that round, you can't claim it yet.
        require(_round < _currentRound, "Round not ended yet");
        uint256 _shareInRound = auctionRounds[_round].sharesInRound;
        uint256 _hmineInRound = auctionRounds[_round].hmineInRound;
        uint256 _userShare = userSharesInLobby[msg.sender][_round];
        uint256 _lobbyReward;

        if (_shareInRound != 0 && _hmineInRound != 0 && _userShare != 0) {
            _lobbyReward = (_userShare * _hmineInRound) / _shareInRound;
        }

        // Sets share to zero so user can no longer claim from this lobby.
        userSharesInLobby[msg.sender][_round] = 0;

        // Contract sends HMINE to user.
        IERC20(hmineToken).safeTransfer(msg.sender, _lobbyReward);

        emit ClaimLobby(msg.sender, _lobbyReward, _round);
    }

    function claimAllLobby(uint256[] memory _rounds) external nonReentrant {
        uint256 _currentRound = _getCurrentRound();
        uint256 _lobbyReward;

        for (uint256 _i = 0; _i < _rounds.length; _i++) {
            uint256 _round = _rounds[_i];
            if (
                _round < _currentRound &&
                userSharesInLobby[msg.sender][_round] > 0
            ) {
                _lobbyReward +=
                    (userSharesInLobby[msg.sender][_round] *
                        auctionRounds[_round].hmineInRound) /
                    auctionRounds[_round].sharesInRound;

                // Updates user share for that round so you can't claim anymore
                userSharesInLobby[msg.sender][_round] = 0;
            }
        }

        // Contract sends HMINE to user.
        IERC20(hmineToken).safeTransfer(msg.sender, _lobbyReward);

        emit ClaimAllLobby(msg.sender, _lobbyReward);
    }

    /*****************************************************************************************************/
    /******************************   FOMO Components ****************************************************/
    /*****************************************************************************************************/

    // User deposits 0.1 HMINE to enter the FOMO game.  Adds 1 minute to the clock.
    function enterFomo() external nonReentrant {
        require(fomoCountDown != 0, "Not started yet");
        // Countdown ended
        require(block.timestamp < fomoCountDown, "Count down ended");

        //Updates the jackpot value and count down.
        hmineJackpot += fomoDeposit / 2;
        fomoCountDown += timeIncrement;

        //updates current jackpot candidate
        fomoKing = msg.sender;

        // user sends HMINE to contract
        IERC20(hmineToken).safeTransferFrom(
            msg.sender,
            address(this),
            fomoDeposit / 2
        );

        // Sends half the hmine to bankroll
        IERC20(hmineToken).safeTransferFrom(
            msg.sender,
            bankroll,
            fomoDeposit / 2
        );

        emit JoinFomo(msg.sender, block.timestamp, fomoCountDown, fomoDeposit);
    }

    // Display current jackpots minus the reward.
    function currentJackpot()
        external
        view
        returns (uint256 _daiJackpot, uint256 _hmineJackpot)
    {
        // round already ended but not updated yet.
        if (block.timestamp >= fomoCountDown) {
            _daiJackpot = 0;
            _hmineJackpot = 0;
        } else {
            _daiJackpot = daiJackpot;
            _hmineJackpot = hmineJackpot;
        }
    }

    // Displays the user's reward value for both DAI and HMINE.  If user has no winnings then just show zero.
    function userFomoRewards(address _u)
        external
        view
        returns (uint256 _rewardDai, uint256 _rewardHmine)
    {
        _rewardDai = users[_u].daiJackpot;
        _rewardHmine = users[_u].hmineJackpot;

        if (block.timestamp >= fomoCountDown && fomoKing == _u) {
            _rewardHmine += hmineJackpot;
            _rewardHmine += daiJackpot;
        }
    }

    // User claims the jackpot reward.
    function claimFomoRewards() external nonReentrant {
        uint256 _rewardDai = users[msg.sender].daiJackpot;
        uint256 _rewardHmine = users[msg.sender].hmineJackpot;

        // If previous fomo count down ended and no other round started yet.
        if (block.timestamp >= fomoCountDown && fomoKing == msg.sender) {
            _rewardDai += daiJackpot;
            _rewardHmine += hmineJackpot;

            daiReward += daiJackpot;
            hmineReward += hmineJackpot;

            daiJackpot = 0;
            hmineJackpot = 0;
        }

        // Contract sends HMINE to user.
        IERC20(hmineToken).safeTransfer(msg.sender, _rewardHmine);

        // Contract sends DAI to user.
        IERC20(daiToken).safeTransfer(msg.sender, _rewardDai);

        // Updates the overall reward trackers
        daiReward -= _rewardDai;
        hmineReward -= _rewardHmine;

        // Update user jackpot reward values
        users[msg.sender].daiJackpot = 0;
        users[msg.sender].hmineJackpot = 0;

        emit ClaimFomoReward(
            msg.sender,
            _rewardHmine,
            _rewardDai,
            block.timestamp,
            fomoCountDown
        );
    }
}