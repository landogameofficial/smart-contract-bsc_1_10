/**
 *Submitted for verification at BscScan.com on 2022-09-19
*/

pragma solidity ^0.5.0;

/*


         ____ /\ ____            _ _ B --           - -__ O   -_
        /v y \/\/    \                   --  --___O    _ __--__ -" _
       ____\7 \\_^_^/ \                            _ --        -_M"-_
      /    V/ \/   \ ^/\       __/\ __                          _--,_
     / \^\|/ \()^7_ \ ^|      /">^/",,\                        /"("\"\
    /\^   / \^_() 7_\         |^ / <"<,\                     _/"/"|\ )\>_
    |^    /\ ()_|  7|        / >/ >O-,\"                 _/"_." _/ / / \"\
          ^   \_\            ^" V"O^  V               /""_-" ,/"  /\  \ ) "-,_
               \_\              '  \>              _-"/ ( .-/ \ !   )  \ _\"-_"\_
 ___ ___ ______ \_\ _ _____ ___ ___ \> _ ___   _-"/_-"   / (    |  / \  | \  \_- "-_  __ _ _
       _  _ _-   \_\   --  -   - --  \">   -<_"__" /  _/|   \ \ | /! \  \  -_( _"-<_">-- -
              --  \_`>    _--    _ ___",">-____ _"> ""_" "--"--"-" "-"' "-"  '"  _
                   \__">      C"" -_O   "O-'           '">        __ -  -
         _ __()_ ___"-__"\__ __)    - O         __ - - "      - -
                ()   _">--"> _ .-- "      - """
                        """

 - BOOM token -
 A social experiment on the blockchain.
 https://boomtoken.info
 https://t.me/boomvacuum

 Self-burning cryptocurrency:
 4% of each transaction is burned.

*/

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract BOOM is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant tokenName = "BOOM";
  string constant tokenSymbol = "BOOM";
  uint8  constant tokenDecimals = 2;
  uint256 _totalSupply = 1000000;
  uint256 public basePercent = 100;
  uint256 public denominator = 2500;
  address public tipReceiver = msg.sender;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _issue(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function cut(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 cutValue = roundValue.mul(basePercent).div(denominator);
    return cutValue;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    uint256 tokensToTip = tokensToTransfer.div(100);
    uint256 tokensRemaining = tokensToTransfer.sub(tokensToTip);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[tipReceiver] = _balances[tipReceiver].add(tokensToTip);
    _balances[to] = _balances[to].add(tokensRemaining);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensRemaining);
    emit Transfer(msg.sender, tipReceiver, tokensToTip);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    uint256 tokensToTip = tokensToTransfer.div(100);
    uint256 tokensRemaining = tokensToTransfer.sub(tokensToTip);

    _balances[tipReceiver] = _balances[tipReceiver].add(tokensToTip);
    _balances[to] = _balances[to].add(tokensRemaining);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, tipReceiver, tokensToTip);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
  }

  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _issue(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function destroy(uint256 amount) external {
    _destroy(msg.sender, amount);
  }

  function _destroy(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function destroyFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _destroy(account, amount);
  }
}