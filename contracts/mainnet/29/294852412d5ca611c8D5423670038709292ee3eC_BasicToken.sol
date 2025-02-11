/**
 *Submitted for verification at BscScan.com on 2022-08-17
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

/**
 * @title BasicToken
 */
contract BasicToken {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balances;
    mapping (address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @dev Initializes Constructor
     */
    constructor (uint256 _initialSupply, string memory _tokenName, string memory _tokenSymbol, address _tokenAddress) {
        totalSupply = _initialSupply * 10 ** uint256(decimals);
        balances[_tokenAddress] = totalSupply;
        name = _tokenName;
        symbol = _tokenSymbol;
        emit Transfer(address(0), _tokenAddress, totalSupply);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_from != address(0), "Error: transfer from the zero address");
        require(_to != address(0), "Error: transfer to the zero address");
        require(balances[_from] >= _value, "Error: transfer from the balance is not enough");
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(allowance[_from][msg.sender] >= _value, "Error: transfer amount exceeds allowance");
        _approve(_from, msg.sender, allowance[_from][msg.sender] - _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function _approve(address _from, address _to, uint256 _value) internal {
        require(_from != address(0), "Error: approve from the zero address");
        require(_to != address(0), "Error: approve to the zero address");
        allowance[_from][_to] = _value;
        emit Approval(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        _approve(msg.sender, _spender, _value);
        return true;
    }
}