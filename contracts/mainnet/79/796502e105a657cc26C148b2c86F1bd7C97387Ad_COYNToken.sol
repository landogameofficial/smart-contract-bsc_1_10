/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Sample token contract
//
// Symbol        : COYN
// Name          : CONSTANCY SOFTWARE FACTORY CRYPTOCURRENCY
// Total supply  : 100000000000000000000000000
// Decimals      : 18
// Owner Account : 0xcd8Cc200e709b9F23aF0befBd646dC513ad7EcC6
//
// Enjoy.
//
// (c) by Matias Devin - Constancy 2021. MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Lib: Safe Math
// ----------------------------------------------------------------------------
contract SafeMath {

    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


/**
ERC Token Standard #20 Interface
https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
*/
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


/**
en:
Contract function to receive approval and execute function in one call
Borrowed from MiniMeToken

es:
Función de contrato para recibir aprobación y ejecutar la función en una llamada
Tomado prestado de MiniMeToken
*/
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

/**
en:
ERC20 Token, with the addition of symbol, name and decimals and assisted token transfers

es:
Token ERC20, con la adición de símbolo, nombre y decimales y transferencias de tokens asistidas
*/
contract COYNToken is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "COYN";
        name = "CONSTANCY SOFTWARE FACTORY CRYPTOCURRENCY";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0xcd8Cc200e709b9F23aF0befBd646dC513ad7EcC6] = _totalSupply;
        emit Transfer(address(0), 0xcd8Cc200e709b9F23aF0befBd646dC513ad7EcC6, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply / Suministro total
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // Obtenga el saldo del token para la cuenta tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // en:
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // es:
    //Transferir el saldo de la cuenta del propietario del token a la cuenta
    // - La cuenta del propietario debe tener saldo suficiente para transferir
    // - Se permiten transferencias de valor 0
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // en:
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // es:
    // El propietario del token puede aprobar que el gastador transfiera tokens de (...)
    // de la cuenta del propietario del token
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recomienda que no haya comprobaciones para el ataque de doble gasto de aprobación
    // ya que esto debería implementarse en las interfaces de usuario
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // es:
    // Transferir tokens de la cuenta de origen a la cuenta de destino
    //
    // La cuenta de llamada ya debe tener suficientes tokens aprobar (...) - d
    // para gastos de la cuenta de remitente y
    // - De la cuenta debe tener saldo suficiente para transferir
    // - El gastador debe tener una asignación suficiente para transferir
    // - Se permiten transferencias de valor 0
    // Transfer tokens from the from account to the to account
    // en:
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // en:
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // es:
    // El propietario del token puede aprobar que el gastador transfiera tokens de (...)
    // de la cuenta del propietario del token. La función de contrato de gastador
    // Luego se ejecuta ReceiveApproval (...)
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH / No aceptes ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }
}