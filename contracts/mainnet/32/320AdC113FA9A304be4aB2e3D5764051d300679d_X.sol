/**
 *Submitted for verification at BscScan.com on 2022-12-06
*/

/**
 *Submitted for verification at BscScan.com on 2022-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// ----------------------------------------------- Context ---------------------------------------------------
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// ----------------------------------------------- Ownable ---------------------------------------------------
contract Ownable is Context {
    address _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// ----------------------------------------------- Pausable ---------------------------------------------------
contract Pausable is Ownable {
	event Pause();
	event Unpause();
	bool public paused = false;  
	modifier whenNotPaused() {
		require(!paused);
		_;
	}  
	modifier whenPaused() {
		require(paused);
		_;
	}  
	function pause() onlyOwner whenNotPaused public {
		paused = true;
		emit Pause();
	}	
	function unpause() onlyOwner whenPaused public {
		paused = false;
		emit Unpause();
	}
}

// ----------------------------------------------- IBEP20 ---------------------------------------------------
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

// ----------------------------------------------- SafeMath ---------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');
        return c;
    }
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }
    function sub( uint256 a, uint256 b, string memory errorMessage ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }    
}

// ----------------------------------------------- Address ---------------------------------------------------
library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), 'Address: call to non-contract');
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// ----------------------------------------------- BEP20 ---------------------------------------------------
abstract contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowances;

    uint256 _totalSupply;

    string _name;
    string _symbol;
    uint8 _decimals;
    
    function getOwner() external override view returns (address) {
        return owner();
    }
   
    function name() public override view returns (string memory) {
        return _name;
    }

    function decimals() public override view returns (uint8) {
        return _decimals;
    }
   
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero')
        );
        return true;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
	
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// ----------------------------------------------- PancakeSwap ---------------------------------------------------
interface IPancakeSwapV2Router01 {
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
interface IPancakeSwapV2Router02 is IPancakeSwapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;   
}
interface IPancakeSwapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// ---------------------------------------------------------------------------------------------------------------
// ----------------------------------------------- X ---------------------------------------------------------
// ---------------------------------------------------------------------------------------------------------------
contract X is BEP20, Pausable { 
	using SafeMath for uint256; 
	using SafeBEP20 for IBEP20;
	
	uint256 public immutable MAX_SYPPLY; 
	uint256 MAX_INT = 2**256 - 1;
    
	uint256 public maxTransferAmount;
	uint256 public maxTaxFreeTransferAmount;		
	uint256 public taxPercent;  
		         
    mapping (address => bool) public taxExcludedList;
	mapping (address => bool) public operatorsList;
	mapping (address => bool) public exchangesList;	
	mapping (address => bool) public blackList;	
    			
	IPancakeSwapV2Router02 public immutable pancakeSwapV2Router;
	address public immutable pancakeSwapV2Pair;

	uint256 public lpUnlockTimestamp;
	bool inSwapAndLiquify;
	bool lockingLiquidity;
    bool public swapAndLiquifyEnabled;
	uint256 public addToLiquidityAmount;

	modifier onlyOperator() {
        require(operatorsList[_msgSender()], 'X: caller is not the operator');
        _;
    }

	modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

	modifier lockLiquidity {
        lockingLiquidity = true;
        _;
        lockingLiquidity = false;
    }

	event Taxed(address from, address to, uint256 value);
	event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
	event Liquify(address from, uint256 tokenAmount, uint256 ethAmount);
	event LpLocked(uint256 lockTime, uint256 unlockTime);
	
	constructor(){
	    _name = 'X';
        _symbol = 'X';
        _decimals = 18;
		MAX_SYPPLY = 10000000000000000 * 1e18;

		pancakeSwapV2Router = IPancakeSwapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
		pancakeSwapV2Pair = IPancakeSwapV2Factory(pancakeSwapV2Router.factory())
            .createPair(address(this), pancakeSwapV2Router.WETH());
		exchangesList[pancakeSwapV2Pair] = true;

		swapAndLiquifyEnabled = true;				
		addToLiquidityAmount = 3 * 1e18;
		maxTaxFreeTransferAmount = 3 * 1e18;
		maxTransferAmount = 1000000 * 1e18;	
		taxPercent = 100; // 1%	
        
		taxExcludedList[address(this)] = true; 
		
		_owner = _msgSender();
		taxExcludedList[_owner] = true;
   	}

	function addLockedLiquidity(uint256 tokenAmount, uint256 bnbAmount) public payable lockLiquidity onlyOperator {
        uint256 currentBalance = balanceOf(address(this));				
		if ( tokenAmount > currentBalance ) {
			mintTo(address(this), tokenAmount.sub(currentBalance));
		}
		require(bnbAmount <= address(this).balance, 'X: not enough BNB');
        
        addLiquidity(tokenAmount, bnbAmount);
		emit Liquify(_msgSender(), tokenAmount, bnbAmount);
    }

	function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);

        // add the liquidity		
        pancakeSwapV2Router.addLiquidityETH{ value: bnbAmount }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );				
    }

	function swapAndLiquify(uint256 amount) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half); // <- this breaks the BNB -> swap when swap + liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to pancakeSwap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

	function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the pancakeSwap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeSwapV2Router.WETH();

        _approve(address(this), address(pancakeSwapV2Router), tokenAmount);

        // make the swap
        pancakeSwapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
		require(!blackList[sender] && !blackList[recipient], 'X: transfer from/to blacklisted address');		
        require(sender != address(0), 'X: transfer from the zero address');
        require(recipient != address(0), 'X: transfer to the zero address');
		if ( paused ) {
		    require(operatorsList[sender], "X: sender not whitelist to transfer when paused");
		}
		
		bool takeTax = false; 	
		
		// tax and max transfer check
		if ( 
        	!inSwapAndLiquify && // if not adding liquidity auto now       	
            !lockingLiquidity && // if not adding liquidity manual now
            sender != address(pancakeSwapV2Router) && // router -> pair is removing liquidity which shouldn't have max
            exchangesList[recipient] && // sells only by detecting transfer to market maker pair
            !taxExcludedList[sender] && // no max for those excluded
			!operatorsList[sender]
        ) {
            require(amount <= maxTransferAmount, "X: sell transfer amount exceeds the max allowed");
			if (
				taxPercent != 0 &&
				amount > maxTaxFreeTransferAmount							
			) {
				takeTax = true;
			}
        }
		
		// auto add to liquidity
        if (
			swapAndLiquifyEnabled && // if enabled
			balanceOfToken() >= addToLiquidityAmount && // if balance more than min add to liquidity
            !inSwapAndLiquify && // if not adding liquidity auto now  
            !lockingLiquidity && // if not adding liquidity manual now
            sender != pancakeSwapV2Pair &&
			sender != address(pancakeSwapV2Router) && // router -> pair is removing liquidity 
			sender != address(this) &&
			!exchangesList[sender] && // sells only by detecting transfer to market maker pair
            !taxExcludedList[sender] && // if sender not excluded from tax 
			!operatorsList[sender] &&  // if not operator 
            recipient != address(this)
        ) {
            swapAndLiquify(addToLiquidityAmount); // add liquidity
        }

        _balances[sender] = _balances[sender].sub(amount, 'X: transfer amount exceeds balance');
        
		// tax
		uint256 taxAmount;			
		if ( takeTax ) { 
            taxAmount = amount.mul(taxPercent).div(10000);
			amount = amount.sub(taxAmount);
			_balances[address(this)] = _balances[address(this)].add(taxAmount);
			emit Taxed(sender, recipient, taxAmount);
			emit Transfer(sender, address(this), taxAmount);		
        }
		
		_balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

	function balanceOfToken() public view returns (uint256) {
        return balanceOf(address(this));
    }

	function balanceOfBnb() public view returns (uint256) {
        return address(this).balance;
    }

	function balanceOfLp() public view returns (uint256) {
        return IBEP20(pancakeSwapV2Pair).balanceOf(address(this));
    }

	function balanceOfBep20(address token) public view returns (uint256) {
        return IBEP20(token).balanceOf(address(this));
    }
	
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, 'X: transfer amount exceeds allowance') );
        return true;
    }

	function lockLpTokens(uint256 unlockTimestamp) external onlyOwner {
		require(lpUnlockTimestamp <= block.timestamp, 'X: already locked');
		lpUnlockTimestamp = block.timestamp;
		emit LpLocked(block.timestamp, unlockTimestamp);	
	}

	function toggleOperatorsList(address account) external onlyOwner returns (bool) {
		operatorsList[account] = !operatorsList[account];	
		return operatorsList[account];
	}
   		    
	// set tax: 100 = 1%, 50 = 0,5%, 350 = 3,5%, 1000 = 10% (MAX), 0 for no tax
    function setTaxPercent(uint256 newTaxPercent) external onlyOwner {
		require(newTaxPercent <= 1200, 'X: tax can`t be more than 12%');
		taxPercent = newTaxPercent;	
	}
	
    function setMaxTransferAmount(uint256 newMaxTransferAmount) external onlyOwner {
		maxTransferAmount = newMaxTransferAmount;	
	}

	function toggleExchangesList(address account) external onlyOwner returns (bool) {
		require(account != pancakeSwapV2Pair, 'X: pancakeSwapV2Pair can`t be removed from list');
		exchangesList[account] = !exchangesList[account];	
		return exchangesList[account];
	}

	function toggleBlackList(address account) external onlyOwner returns (bool) {
		blackList[account] = !blackList[account];	
		return blackList[account];
	}

	function toggleSwapAndLiquifyEnabled() external onlyOwner returns (bool) {
		swapAndLiquifyEnabled = !swapAndLiquifyEnabled;
		return swapAndLiquifyEnabled;	
	}

	function toggleTaxExcluded(address account) external onlyOwner returns (bool) {
		taxExcludedList[account] = !taxExcludedList[account];	
		return taxExcludedList[account];
	}
	
	function setAddToLiquidityAmount(uint256 newAddToLiquidityAmount) external onlyOwner {
		addToLiquidityAmount = newAddToLiquidityAmount;	
	}
	
	function setMaxTaxFreeTransferAmount(uint256 newMaxTaxFreeTransferAmount) external onlyOwner {
		maxTaxFreeTransferAmount = newMaxTaxFreeTransferAmount;	
	}
	
	// drop to list of recipients with different amounts for each	
   	function migrateAccounts(address[] memory recipients, uint256[] memory amounts) public onlyOperator returns (uint256 amountTotal) {
        uint8 cnt = uint8(recipients.length);
        require(cnt > 0 && cnt <= 255, 'X: number or recipients must be more then 0 and not much than 255');
        require(amounts.length == recipients.length, 'X: number or recipients must be equal to number of amounts');
        for ( uint i = 0; i < cnt; i++ ){
			require(amounts[i] != 0, 'X: you can`t drop 0');
            amountTotal = amountTotal.add(amounts[i]);
			mintTo(recipients[i], amounts[i]);
        }        
        return amountTotal;
    }

	function availableTokensToMint() public view returns (uint256) {
   	    return MAX_SYPPLY.sub(_totalSupply); 
    }
   	 	   	
   	function mint(uint256 amount) public onlyOperator {
		require(_totalSupply.add(amount) <= MAX_SYPPLY, 'X: exceed max supply');
        _mint(_msgSender(), amount);        
    }
    
    function mintTo(address recipient, uint256 amount) public onlyOperator {
        require(_totalSupply.add(amount) <= MAX_SYPPLY, 'X: exceed max supply');
        _mint(recipient, amount);        
    }

    function claimBalance(address to) external onlyOperator {
        payable(to).transfer(address(this).balance);
    }

    function claimToken(address token, uint256 amount, address to) external onlyOperator {
        IBEP20(token).transfer(to, amount);
    }

	function recoverTokens(address token, uint256 amount) external onlyOperator {
        if (token == pancakeSwapV2Pair) {
			require(lpUnlockTimestamp <= block.timestamp, 'X: can`t withdraw LP tokens before unlock time');			
		}				
		IBEP20(token).safeTransfer(_msgSender(), amount);        
    }

	function recoverBnb(uint256 amount) external onlyOperator {		
		require(amount <= balanceOfBnb(), 'X: transfer amount exceeds BNB balance');
        (bool sent,) = _msgSender().call{ value: amount }("");
        require(sent, 'X: failed');       
    }
        
	//to recieve BNB from pancakeSwapV2Router when swaping
    receive() external payable {}
   	
}