// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract SnowCrashToken is ERC20 {
    constructor() ERC20("AppleCrash Token", "Apple") {
        _mint(msg.sender, 102400000 * 10 ** decimals());
    }
}