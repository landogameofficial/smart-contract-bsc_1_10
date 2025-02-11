/**
 *Submitted for verification at BscScan.com on 2022-12-23
*/

/*
https://t.me/BlueyInuBSC
*/
// This is the original Fan Token token of Bluey Inu (https://blueyinu.com/)
//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface BlueyInuIERC20 {
    function decimals() external view returns (uint);
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BlueyInuFANTOKEN {
    
    address public owner;
    
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    uint public totalSupply;
    string public name;
    string public symbol;
    uint public decimals;
    uint public sellingTaxEcosystem;
    uint public sellingTaxMarketing;
    uint public sellingTaxTotal;
    address public fundEcosystem;
    address public fundMarketing;
    bool public transfersAllowed;
    
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isReceiverTaxed;
    mapping(address => bool) private _isWhitelisted;

    BlueyInuIERC20 customtoken;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    modifier isOwner() {
        require(msg.sender == owner, "Only owner can do this!");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        name = 'Bluey Inu';
        symbol = 'BLUEY';
        decimals = 18;
        totalSupply = 1000000000 * 10 ** decimals;
        balances[owner] = totalSupply;
        transfersAllowed = true;
        sellingTaxEcosystem = 0;
        sellingTaxMarketing = 0;
        sellingTaxTotal = sellingTaxEcosystem + sellingTaxMarketing;
        
        emit Transfer(address(0), owner, totalSupply);
        
        _isExcludedFromFee[owner] = true;
        _isWhitelisted[owner] = true;
        _isReceiverTaxed[0xE213a73b8Bd76EDd9d65A1D89465E8624860dD1b] = true; // mainnet router
        fundEcosystem = owner;
        fundMarketing = owner;
    }
    
    function balanceOf(address _owner) public view returns(uint) {
        return balances[_owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        if (!_isWhitelisted[msg.sender]) {
            require(transfersAllowed, 'Transfers are not allowed!');
        }
        require(balances[msg.sender] >= value, 'Balance too low!');
        
        balances[msg.sender] -= value;

        uint toreceive = value;

        if (_isReceiverTaxed[to] && sellingTaxTotal > 0 && !_isExcludedFromFee[msg.sender]) {

            if (sellingTaxMarketing > 0) {
                uint tomarketing = value * sellingTaxMarketing / 100;
                balances[fundMarketing] += tomarketing;
                emit Transfer(msg.sender, fundMarketing, tomarketing);
                toreceive -= tomarketing;
            }

            if (sellingTaxEcosystem > 0) {
                uint toecosystem = value * sellingTaxEcosystem / 100;
                balances[fundEcosystem] += toecosystem;
                emit Transfer(msg.sender, fundEcosystem, toecosystem);
                toreceive -= toecosystem;
            }

        }
        
        balances[to] += toreceive;
        emit Transfer(msg.sender, to, toreceive);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        if (!_isWhitelisted[from]) {
            require(transfersAllowed, 'Transfers are not allowed!');
        }
        require(balances[from] >= value, 'Balance too low!');
        require(allowed[from][msg.sender] >= value, 'Allowance too low!');
        
        balances[from] -= value;
        allowed[from][msg.sender] -=value;

        uint toreceive = value;

        if (_isReceiverTaxed[to] && sellingTaxTotal > 0 && !_isExcludedFromFee[from]) {

            if (sellingTaxMarketing > 0) {
                uint tomarketing = value * sellingTaxMarketing / 100;
                balances[fundMarketing] += tomarketing;
                emit Transfer(from, fundMarketing, tomarketing);
                toreceive -= tomarketing;
            }

            if (sellingTaxEcosystem > 0) {
                uint toecosystem = value * sellingTaxEcosystem / 100;
                balances[fundEcosystem] += toecosystem;
                emit Transfer(from, fundEcosystem, toecosystem);
                toreceive -= toecosystem;
            }

        }
        
        balances[to] += toreceive;
        emit Transfer(from, to, toreceive);
        return true;
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function allowance(address _owner, address _spender) public view returns (uint) {
        return allowed[_owner][_spender];
    }
    
    function burn(uint amount) public {
        require(amount <= balances[msg.sender]);

        totalSupply -= amount;
        balances[msg.sender] -= amount;
        
        emit Transfer(msg.sender, address(0), amount);
    }

    function burnFrom(address from, uint amount) public {
        require(amount <= balances[from], 'More than the balance!');
        require(amount <= allowed[from][msg.sender], 'More than allowed!');

        totalSupply -= amount;
        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        
        emit Transfer(from, address(0), amount);
    }

    function isWhitelisted(address account) public view returns(bool) {
        return _isWhitelisted[account];
    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isReceiverTaxed(address account) public view returns(bool) {
        return _isReceiverTaxed[account];
    }

    function addToWhitelist(address account) public isOwner {
        _isWhitelisted[account] = true;
    }
    
    function removeFromWhitelist(address account) public isOwner {
        _isWhitelisted[account] = false;
    }
    
    function excludeFromFee(address account) public isOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public isOwner {
        _isExcludedFromFee[account] = false;
    }

    function receiverTaxed(address account) public isOwner {
        _isReceiverTaxed[account] = true;
    }
    
    function receiverNotTaxed(address account) public isOwner {
        _isReceiverTaxed[account] = false;
    }

    function setFundEcosystem(address _newAddress) public isOwner {
        fundEcosystem = _newAddress;
    }

    function setFundMarketing(address _newAddress) public isOwner {
        fundMarketing = _newAddress;
    }

    function setEcosystemTax(uint _newTax) public isOwner {
        sellingTaxEcosystem = _newTax;
    }

    function setMarketingTax(uint _newTax) public isOwner {
        sellingTaxMarketing = _newTax;
    }

    function withdrawCustomToken(address _address) public isOwner {
        customtoken = BlueyInuIERC20(_address);
        require(customtoken.balanceOf(address(this)) > 0, "There is nothing to withdraw!");
        
        bool sent = customtoken.transfer(owner, customtoken.balanceOf(address(this)));
        require(sent, "We failed to send tokens");
    }
    
}