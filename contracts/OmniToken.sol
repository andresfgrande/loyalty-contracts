// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OmniToken is ERC20, ERC20Burnable, Ownable {

    mapping(address => bool) public trustedRelayers;

    constructor() ERC20("OmniToken", "OMWTT") {
        _mint(msg.sender, 500000 * 10 ** decimals());
    }

    function addTrustedRelayer(address relayer) external onlyOwner {
        trustedRelayers[relayer] = true;
    }

    function removeTrustedRelayer(address relayer) external onlyOwner {
        trustedRelayers[relayer] = false;
    }

    function approveFor(address owner, address spender, uint256 value) external returns (bool) {
        require(trustedRelayers[msg.sender], "NTR"); //Not a trusted relayer
        _approve(owner, spender, value);
        return true;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function isTrustedRelayer(address loyaltyProgramAddress) public view returns(bool){
        return trustedRelayers[loyaltyProgramAddress];
    }
}
