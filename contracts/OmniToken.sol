// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OmniToken is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("OmniToken", "OMW") {
        _mint(msg.sender, 500000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

/*
deploy token
deploy loyalty program factory pasando como parametro la dirección del token
cambio de owner del token:  loyalty program factory nuevo owner (habra 1 factory)
deploy de Loyalty program mediante el factory (Habra N loyalty programs) 
*/

