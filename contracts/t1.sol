// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';


contract TestToken1 is ERC20 {
    address public admin;
    constructor() ERC20('Test Token 1', 'TS1') {
        _mint(msg.sender, 100000000 * 10 ** 18);
        admin = msg.sender;
    }
    
    function mint(address to, uint amount) external {
        require(msg.sender == admin, 'only admin');
        _mint(to, amount);
    }
    
    function burn(uint amount) external {
        _burn(msg.sender, amount);
    }
}