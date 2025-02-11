/**
 *Submitted for verification at BscScan.com on 2022-05-21
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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


// File contracts/libraries/Math.sol



pragma solidity >=0.8.0;

// a library for performing various math operations

library Math {
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


// File @vvs-finance/vvs-swap-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IVVSPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File @vvs-finance/vvs-swap-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IVVSFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @vvs-finance/vvs-swap-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IVVSRouter01 {
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
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File @vvs-finance/vvs-swap-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

interface IVVSRouter02 is IVVSRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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
}


// File contracts/BOMBZap.sol


pragma solidity >=0.8.0;







interface IWBNB is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}


contract BOMBZap is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* ========== CONSTANT VARIABLES ========== */

    address public immutable WBNB;
    IVVSRouter02 public immutable ROUTER;
    IVVSFactory public immutable FACTORY;
    uint256 public lastFetchedPairIndex;
    /* ========== STATE VARIABLES ========== */

    mapping(address => bool) public liquidityPools;

    mapping(address => uint256) public tokens;
    address[] public tokenList;

    mapping(address => uint256) public intermediateTokens;
    address[] public intermediateTokenList;

    mapping(address => mapping(address => address[])) public presetPaths;

    /* ========== EVENT ========== */
    event ZapIn(address indexed to, uint256 amount, uint256 outputAmount);
    event ZapInToken(address indexed from, address indexed to, uint256 amount, uint256 outputAmount);
    event ZapOut(address indexed from, address indexed to, uint256 amount, uint256 outputAmount);
    event SwapExactTokensForTokens(address[] paths, uint256[] amounts);
    event FetchLiquidityPoolsFromFactory(uint256 startFromPairIndex, uint256 endAtPairIndex);

    event AddLiquidityPool(address indexed liquidityPool, bool isFromFactory);
    event AddToken(address indexed token, bool isFromFactory);
    event AddIntermediateToken(address indexed intermediateToken);

    event RemoveLiquidityPool(address indexed liquidityPool);
    event RemoveToken(address indexed token);
    event RemoveIntermediateToken(address indexed intermediateToken);

    event SetPresetPath(address indexed fromToken, address indexed toToken, address[] paths, bool isAutoGenerated);
    event RemovePresetPath(address indexed fromToken, address indexed toToken);

    /* ========== INITIALIZER ========== */

    constructor(address _wbnb, address _router, address _factory) {
        WBNB = _wbnb;
        ROUTER = IVVSRouter02(_router);
        FACTORY = IVVSFactory(_factory);
        _addToken(_wbnb, false);
        _addIntermediateToken(_wbnb);
    }

    receive() external payable {}

    /* ========== External Functions ========== */

    /// @notice swap ERC20 Token to ERC20 Token or LP
    function zapInToken(
        address _fromToken,
        uint256 _inputAmount,
        address _toTokenOrLp,
        uint256 _outputAmountMin
    ) external nonReentrant returns (uint256) {
        require(isToken(_fromToken), "VVSZap:zapInToken: given fromToken is not token");
        require(isToken(_toTokenOrLp) || isLP(_toTokenOrLp), "VVSZap:zapInToken: given toTokenOrLp is not token or LP");
        require(_inputAmount > 0, "VVSZap:zapInToken: given amount should > 0");
        IERC20(_fromToken).safeTransferFrom(msg.sender, address(this), _inputAmount);
        uint256 outputAmount = _zapInFromToken(_fromToken, _inputAmount, _toTokenOrLp, msg.sender);
        require(outputAmount >= _outputAmountMin, "VVSZap:zapInToken: output amount less than expected");
        emit ZapInToken(_fromToken, _toTokenOrLp, _inputAmount, outputAmount);
        return outputAmount;
    }

    /// @notice swap BNB to ERC20 Token or LP, BNB will wrap into WBNB before the rest of action
    /// @param _outputAmountMin: minimum amount expected to received , can estimate by
    /// @return outputAmount: amount of target Token or LP which user will received
    /// @dev estimateZapInToLpSwapPaths if output is LP
    /// @dev estimateZapTokenToTokenAmountsOut if output is token
    function zapIn(address _toTokenOrLp, uint256 _outputAmountMin) external payable nonReentrant returns (uint256) {
        require(msg.value > 0, "VVSZap:zapIn: given amount should > 0");
        IWBNB(WBNB).deposit{value: msg.value}();
        require(isToken(_toTokenOrLp) || isLP(_toTokenOrLp), "VVSZap:zapIn: given toTokenOrLp is not token or LP");
        uint256 outputAmount = _zapInFromToken(WBNB, msg.value, _toTokenOrLp, msg.sender);
        require(outputAmount >= _outputAmountMin, "VVSZap:zapIn: output amount less than expected");
        emit ZapIn(_toTokenOrLp, msg.value, outputAmount);
        return outputAmount;
    }

    /// @notice break LP into token , and swap to target Token or stake as another LP
    function zapOut(
        address _fromLp,
        uint256 _inputAmount,
        address _toTokenOrLp,
        uint256 _outputAmountMin
    ) external payable nonReentrant returns (uint256) {
        require(isLP(_fromLp), "VVSZap:zapOut: should zap out from LP Address");
        require(_fromLp != _toTokenOrLp, "VVSZap:zapOut: input = output");
        require(_inputAmount > 0, "VVSZap:zapOut: given amount should > 0");
        IERC20(_fromLp).safeTransferFrom(msg.sender, address(this), _inputAmount);
        _approveTokenIfNeeded(_fromLp);
        uint256 outputAmount;
        if (isLP(_toTokenOrLp)) {
            uint256 removedAmount = _removeLiquidityToToken(_fromLp, _inputAmount, WBNB, address(this));
            outputAmount = _zapInFromToken(WBNB, removedAmount, _toTokenOrLp, msg.sender);
        } else if (isToken(_toTokenOrLp)) {
            outputAmount = _removeLiquidityToToken(_fromLp, _inputAmount, _toTokenOrLp, msg.sender);
        } else if (_toTokenOrLp == address(0)) {
            // handle native BNB
            outputAmount = _removeLiquidityToToken(_fromLp, _inputAmount, WBNB, address(this));
            IWBNB(WBNB).withdraw(outputAmount);
            (bool sent, ) = payable(msg.sender).call{value: outputAmount}("");
            require(sent, "Failed to send Ether");
        } else {
            revert("VVSZap:zapOut: should zap out to Token or LP Address");
        }

        require(outputAmount >= _outputAmountMin, "VVSZap:zapIn: output amount less than expected");
        emit ZapOut(_fromLp, _toTokenOrLp, _inputAmount, outputAmount);
        return outputAmount;
    }

    /* ========== View Functions ========== */

    function getLiquidityPoolAddress(address _tokenA, address _tokenB) public view returns (address) {
        return FACTORY.getPair(_tokenA, _tokenB);
    }

    function isLiquidityPoolExistInFactory(address _tokenA, address _tokenB) public view returns (bool) {
        return getLiquidityPoolAddress(_tokenA, _tokenB) != address(0);
    }

    function isLP(address _address) public view returns (bool) {
        return liquidityPools[_address] == true;
    }

    function isToken(address _address) public view returns (bool) {
        return !(tokens[_address] == 0);
    }

    function getToken(uint256 i) public view returns (address) {
        return tokenList[i];
    }

    function getTokenListLength() public view returns (uint256) {
        return tokenList.length;
    }

    function getIntermediateToken(uint256 _i) public view returns (address) {
        return intermediateTokenList[_i];
    }

    function getIntermediateTokenListLength() public view returns (uint256) {
        return intermediateTokenList.length;
    }

    /// @notice For complicated / special target , can preset path for swapping for gas saving
    function getPresetPath(address _tokenA, address _tokenB) public view returns (address[] memory) {
        return presetPaths[_tokenA][_tokenB];
    }

    /// @notice For estimate zapIn (Token -> Token) path, including preset path & auto calculated path
    /// if preset path exist , preset path will be taken instead of auto calculated path
    function getPathForTokenToToken(address _fromToken, address _toToken) external view returns (address[] memory) {
        return _getPathForTokenToToken(_fromToken, _toToken);
    }

    /// @notice For checking zapIn (Token -> Token) AUTO-CALCULATED path , in order to allow estimate output amount
    /// fromToken -> IntermediateToken (if any) -> toToken
    function getAutoCalculatedPathWithIntermediateTokenForTokenToToken(address _fromToken, address _toToken)
        external
        view
        returns (address[] memory)
    {
        return _autoCalculatedPathWithIntermediateTokenForTokenToToken(_fromToken, _toToken);
    }

    /// @notice  For estimate zapIn path , in order to allow estimate output amount
    /// fromToken -> IntermediateToken (if any) -> token 0 & token 1 in LP -> LP
    function getSuitableIntermediateTokenForTokenToLP(address _fromToken, address _toLP)
        external
        view
        returns (address)
    {
        return _getSuitableIntermediateToken(_fromToken, _toLP);
    }

    /* ========== Update Functions ========== */

    /// @notice Open for public to call if when this contract's token & LP is outdated from factory
    /// only missing token and LP will be fetched according to lastFetchedPairIndex
    /// automatically fetch from last fetched index and with interval as 8
    function fetchLiquidityPoolsFromFactory() public {
        if (lastFetchedPairIndex < FACTORY.allPairsLength() - 1) {
            fetchLiquidityPoolsFromFactoryWithIndex(lastFetchedPairIndex, 8);
        }
    }

    /// @param _startFromPairIndex FACTORY.allPairs(i) 's index
    /// @param _interval number of LP going to be fetched starting from _startFromPairIndex
    function fetchLiquidityPoolsFromFactoryWithIndex(uint256 _startFromPairIndex, uint256 _interval) public {
        uint256 factoryPairLength = FACTORY.allPairsLength();
        require(
            _startFromPairIndex < factoryPairLength,
            "VVSZap:fetchLiquidityPoolsFromFactoryWithIndex: _startFromPairIndex should < factoryPairLength"
        );
        uint256 endAtPairIndex = _startFromPairIndex + _interval;
        if (endAtPairIndex > factoryPairLength) {
            endAtPairIndex = factoryPairLength;
        }
        for (uint256 i = _startFromPairIndex; i < endAtPairIndex; i++) {
            _addLiquidityPool(FACTORY.allPairs(i), true);
        }
        emit FetchLiquidityPoolsFromFactory(_startFromPairIndex, endAtPairIndex - 1);
        if (lastFetchedPairIndex < endAtPairIndex - 1) {
            lastFetchedPairIndex = endAtPairIndex - 1;
        }
    }

    /* ========== Private Functions ========== */

    function _removeLiquidityToToken(
        address _lp,
        uint256 _amount,
        address _toToken,
        address _receiver
    ) private returns (uint256) {
        require(isLP(_lp), "VVSZap:_removeLiquidityToToken: _lp is Non LP Address");
        IVVSPair pair = IVVSPair(_lp);
        address token0 = pair.token0();
        address token1 = pair.token1();
        (uint256 token0Amount, uint256 token1Amount) = ROUTER.removeLiquidity(
            token0,
            token1,
            _amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        uint256 outputAmount = (
            (token0 == _toToken) ? token0Amount : _swapTokenToToken(token0, token0Amount, _toToken, address(this))
        ) + ((token1 == _toToken) ? token1Amount : _swapTokenToToken(token1, token1Amount, _toToken, address(this)));
        IERC20(_toToken).safeTransfer(_receiver, outputAmount);
        return outputAmount;
    }

    function _zapInFromToken(
        address _from,
        uint256 _amount,
        address _to,
        address _receiver
    ) private returns (uint256) {
        _approveTokenIfNeeded(_from);
        if (isLP(_to)) {
            return _swapTokenToLP(_from, _amount, _to, _receiver);
        } else {
            return _swapTokenToToken(_from, _amount, _to, _receiver);
        }
    }

    function _approveTokenIfNeeded(address token) private {
        if (IERC20(token).allowance(address(this), address(ROUTER)) == 0) {
            IERC20(token).safeApprove(address(ROUTER), type(uint256).max);
        }
    }

    function _swapTokenToLP(
        address _fromToken,
        uint256 _fromTokenAmount,
        address _lp,
        address _receiver
    ) private returns (uint256) {
        require(isLP(_lp), "VVSZap:_swapTokenToLP: _lp is Non LP Address");
        (address token0, uint256 token0Amount, address token1, uint256 token1Amount) = _swapTokenToTokenPairForLP(
            _fromToken,
            _fromTokenAmount,
            _lp
        );
        _approveTokenIfNeeded(token0);
        _approveTokenIfNeeded(token1);
        return _addLiquidityAndReturnRemainingToUser(token0, token1, token0Amount, token1Amount, _receiver);
    }

    function _addLiquidityAndReturnRemainingToUser(
        address token0,
        address token1,
        uint256 token0Amount,
        uint256 token1Amount,
        address _receiver
    ) private returns (uint256) {
        (uint256 amountA, uint256 amountB, uint256 liquidity) = ROUTER.addLiquidity(
            token0,
            token1,
            token0Amount,
            token1Amount,
            0,
            0,
            _receiver,
            block.timestamp
        );
        if (token0Amount - amountA > 0) {
            IERC20(token0).transfer(_receiver, token0Amount - amountA);
        }
        if (token1Amount - amountB > 0) {
            IERC20(token1).transfer(_receiver, token1Amount - amountB);
        }
        return liquidity;
    }

    function _swapTokenToTokenPairForLP(
        address _fromToken,
        uint256 _fromTokenAmount,
        address _lp
    )
        private
        returns (
            address,
            uint256,
            address,
            uint256
        )
    {
        IVVSPair pair = IVVSPair(_lp);
        address token0 = pair.token0();
        address token1 = pair.token1();
        uint256 token0Amount;
        uint256 token1Amount;
        if (_fromToken == token0) {
            token0Amount = _fromTokenAmount / 2;
            token1Amount = _swapTokenToToken(_fromToken, _fromTokenAmount - token0Amount, token1, address(this));
        } else if (_fromToken == token1) {
            token1Amount = _fromTokenAmount / 2;
            token0Amount = _swapTokenToToken(_fromToken, _fromTokenAmount - token1Amount, token0, address(this));
        } else {
            address intermediateToken = _getSuitableIntermediateToken(_fromToken, _lp);
            uint256 intermediateTokenAmount = _fromToken == intermediateToken
                ? _fromTokenAmount
                : _swapTokenToToken(_fromToken, _fromTokenAmount, intermediateToken, address(this));
            uint256 intermediateTokenAmountForToken0 = intermediateTokenAmount / 2;
            uint256 intermediateTokenAmountForToken1 = intermediateTokenAmount - intermediateTokenAmountForToken0;
            token0Amount = token0 == intermediateToken
                ? intermediateTokenAmountForToken0
                : _swapTokenToToken(intermediateToken, intermediateTokenAmountForToken0, token0, address(this));
            token1Amount = token1 == intermediateToken
                ? intermediateTokenAmountForToken1
                : _swapTokenToToken(intermediateToken, intermediateTokenAmountForToken1, token1, address(this));
        }
        return (token0, token0Amount, token1, token1Amount);
    }

    function _swapTokenToToken(
        address _fromToken,
        uint256 _fromAmount,
        address _toToken,
        address _receiver
    ) private returns (uint256) {
        address[] memory path = _getPathForTokenToToken(_fromToken, _toToken);
        _approveTokenIfNeeded(_fromToken);
        uint256[] memory amounts = ROUTER.swapExactTokensForTokens(_fromAmount, 0, path, _receiver, block.timestamp);
        require(amounts[amounts.length - 1] > 0, "VVSZap:_swapTokenToToken: output amounts invalid - 0 amoount");
        emit SwapExactTokensForTokens(path, amounts);
        return amounts[amounts.length - 1];
    }

    function _getPathForTokenToToken(address _fromToken, address _toToken) private view returns (address[] memory) {
        address[] memory path;
        require(_fromToken != _toToken, "VVSZap:_swapTokenToToken: Not Allow fromToken == toToken");
        if (isLiquidityPoolExistInFactory(_fromToken, _toToken)) {
            path = new address[](2);
            path[0] = _fromToken;
            path[1] = _toToken;
        } else {
            path = getPresetPath(_fromToken, _toToken);
            if (path.length == 0) {
                path = _autoCalculatedPathWithIntermediateTokenForTokenToToken(_fromToken, _toToken);
            }
        }
        require(path.length > 0, "VVSZap:_getPathForTokenToToken: Does not support this route");
        return path;
    }

    function _getSuitableIntermediateToken(address _fromToken, address _toLp) private view returns (address) {
        IVVSPair pair = IVVSPair(_toLp);
        address token0 = pair.token0();
        address token1 = pair.token1();
        // IntermediateToken is not necessary, returns _fromToken
        if (_fromToken == token0 || _fromToken == token1) {
            return _fromToken;
        }
        if (intermediateTokens[token0] > 0) {
            if (
                intermediateTokens[token1] > 0 &&
                !isLiquidityPoolExistInFactory(_fromToken, token0) &&
                isLiquidityPoolExistInFactory(_fromToken, token1)
            ) {
                // when both token0 & token1 can be intermediateToken, do comparison
                return token1;
            }
            return token0;
        }
        if (intermediateTokens[token1] > 0) {
            return token1;
        }
        if (
            intermediateTokens[_fromToken] > 0 &&
            isLiquidityPoolExistInFactory(_fromToken, token0) &&
            isLiquidityPoolExistInFactory(_fromToken, token1)
        ) {
            return _fromToken;
        }
        address bestIntermediateToken;
        for (uint256 i = 0; i < intermediateTokenList.length; i++) {
            address intermediateToken = intermediateTokenList[i];
            if (
                isLiquidityPoolExistInFactory(intermediateToken, token0) &&
                isLiquidityPoolExistInFactory(intermediateToken, token1)
            ) {
                if (isLiquidityPoolExistInFactory(_fromToken, intermediateToken)) {
                    return intermediateToken;
                }
                if (intermediateToken != address(0)) {
                    bestIntermediateToken = intermediateToken;
                }
            }
        }
        if (bestIntermediateToken != address(0)) {
            return bestIntermediateToken;
        }
        revert("VVSZap:_getSuitableIntermediateToken: Does not support this route");
    }

    function _autoCalculatedPathWithIntermediateTokenForTokenToToken(address _fromToken, address _toToken)
        private
        view
        returns (address[] memory)
    {
        address[] memory path;
        for (uint256 i = 0; i < intermediateTokenList.length; i++) {
            address intermediateToken = intermediateTokenList[i];
            if (
                _fromToken != intermediateToken &&
                _toToken != intermediateToken &&
                isLiquidityPoolExistInFactory(_fromToken, intermediateToken) &&
                isLiquidityPoolExistInFactory(intermediateToken, _toToken)
            ) {
                path = new address[](3);
                path[0] = _fromToken;
                path[1] = intermediateToken;
                path[2] = _toToken;
                break;
            }
        }
        return path;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function addToken(address _tokenAddress) external onlyOwner {
        require(tokens[_tokenAddress] == 0, "VVSZap:addToken: _tokenAddress is already in token list");
        _addToken(_tokenAddress, false);
    }

    function _addToken(address _tokenAddress, bool _isFromFactory) private {
        require(_tokenAddress != address(0), "Zap:_addToken: _tokenAddress should not be zero");
        require(isLP(_tokenAddress) == false, "VVSZap:_addToken: _tokenAddress is LP");
        tokenList.push(_tokenAddress);
        tokens[_tokenAddress] = tokenList.length;
        emit AddToken(_tokenAddress, _isFromFactory);
    }

    function removeToken(address _tokenAddress) external onlyOwner {
        uint256 tokenListIndex = tokens[_tokenAddress] - 1;
        delete tokens[_tokenAddress];
        if (tokenListIndex != tokenList.length - 1) {
            address lastTokenInList = tokenList[tokenList.length - 1];
            tokenList[tokenListIndex] = lastTokenInList;
            tokens[lastTokenInList] = tokenListIndex + 1;
        }
        tokenList.pop();
        emit RemoveToken(_tokenAddress);
    }

    function addIntermediateToken(address _tokenAddress) public onlyOwner {
        require(
            intermediateTokens[_tokenAddress] == 0,
            "VVSZap:addIntermediateToken: _tokenAddress is already in token list"
        );
        _addIntermediateToken(_tokenAddress);
    }

    function _addIntermediateToken(address _tokenAddress) private {
        require(_tokenAddress != address(0), "Zap:_addIntermediateToken: _tokenAddress should not be zero");
        require(isLP(_tokenAddress) == false, "VVSZap:_addIntermediateToken: _tokenAddress is LP");
        intermediateTokenList.push(_tokenAddress);
        intermediateTokens[_tokenAddress] = intermediateTokenList.length;
        emit AddIntermediateToken(_tokenAddress);
    }

    function removeIntermediateToken(address _intermediateTokenAddress) external onlyOwner {
        uint256 intermediateTokenListIndex = intermediateTokens[_intermediateTokenAddress] - 1;
        delete intermediateTokens[_intermediateTokenAddress];
        if (intermediateTokenListIndex != intermediateTokenList.length - 1) {
            address lastIntermediateTokenInList = intermediateTokenList[intermediateTokenList.length - 1];
            intermediateTokenList[intermediateTokenListIndex] = lastIntermediateTokenInList;
            intermediateTokens[lastIntermediateTokenInList] = intermediateTokenListIndex + 1;
        }
        intermediateTokenList.pop();
        emit RemoveIntermediateToken(_intermediateTokenAddress);
    }

    function setPresetPath(
        address _tokenA,
        address _tokenB,
        address[] memory _path
    ) external onlyOwner {
        _setPresetPath(_tokenA, _tokenB, _path, false);
    }

    function setPresetPathByAutoCalculation(address _tokenA, address _tokenB) external onlyOwner {
        _setPresetPath(
            _tokenA,
            _tokenB,
            _autoCalculatedPathWithIntermediateTokenForTokenToToken(_tokenA, _tokenB),
            true
        );
    }

    function removePresetPath(address tokenA, address tokenB) external onlyOwner {
        delete presetPaths[tokenA][tokenB];
        emit RemovePresetPath(tokenA, tokenB);
    }

    function _setPresetPath(
        address _tokenA,
        address _tokenB,
        address[] memory _path,
        bool _isAutoGenerated
    ) private {
        presetPaths[_tokenA][_tokenB] = _path;
        emit SetPresetPath(_tokenA, _tokenB, _path, _isAutoGenerated);
    }

    function addLiquidityPool(address _lpAddress) external onlyOwner {
        _addLiquidityPool(_lpAddress, false);
    }

    function removeLiquidityPool(address _lpAddress) external onlyOwner {
        liquidityPools[_lpAddress] = false;
        emit RemoveLiquidityPool(_lpAddress);
    }

    function _addLiquidityPool(address _lpAddress, bool _isFromFactory) private {
        require(_lpAddress != address(0), "Zap:_addLiquidityPool: _lpAddress should not be zero");
        if (!liquidityPools[_lpAddress]) {
            IVVSPair pair = IVVSPair(_lpAddress);
            address token0 = pair.token0();
            address token1 = pair.token1();
            if (!isToken(token0)) {
                _addToken(token0, true);
            }
            if (!isToken(token1)) {
                _addToken(token1, true);
            }
            liquidityPools[_lpAddress] = true;
            emit AddLiquidityPool(_lpAddress, _isFromFactory);
        }
    }

    /* ========== RESTRICTED FUNCTIONS FOR MISDEPOSIT ========== */

    function withdrawBalance(address _token, uint256 _amount) public payable onlyOwner {
        if (_token == address(0)) {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                if (_amount == 0) {
                    (bool sent, ) = payable(msg.sender).call{value: balance}("");
                    require(sent, "Failed to send Ether");
                } else {
                    (bool sent, ) = payable(msg.sender).call{value: _amount}("");
                    require(sent, "Failed to send Ether");
                }
            }
        } else {
            uint256 balance = IERC20(_token).balanceOf(address(this));

            if (_amount == 0) {
                _amount = balance;
            }
            IERC20(_token).transfer(owner(), _amount);
        }
    }
}