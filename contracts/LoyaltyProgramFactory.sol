// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./OmniToken.sol";  
import "./LoyaltyProgram.sol";  

contract LoyaltyProgramFactory is Ownable {
    OmniToken public omniToken;
    address[] public commerceAddresses;

    struct Commerce {
        string name;
        address loyaltyProgramAddress;
    }

    // Mapping from loyalty address to its commerce details
    mapping(address => Commerce) public commerceDetailsByAddress;

    event LoyaltyProgramCreated(address indexed loyaltyProgram, address indexed commerceAddress, string commerceName);

    constructor(address _omniTokenAddress) {
        omniToken = OmniToken(_omniTokenAddress);
    }

    //Create new loyalty program and store the address in array and in a mapping 
    function createLoyaltyProgram(address commerceAddress, string memory commerceName) public onlyOwner returns (LoyaltyProgram) {
        require(commerceDetailsByAddress[commerceAddress].loyaltyProgramAddress == address(0), "LoyaltyProgram already exists for this commerce address");

        LoyaltyProgram loyaltyProgram = new LoyaltyProgram(address(omniToken), commerceAddress, commerceName);

        Commerce memory newCommerce = Commerce({
            name: commerceName,
            loyaltyProgramAddress: address(loyaltyProgram)
        });

        commerceDetailsByAddress[commerceAddress] = newCommerce;
        commerceAddresses.push(commerceAddress);  // Push the commerce address to the array

        emit LoyaltyProgramCreated(address(loyaltyProgram), commerceAddress, commerceName);
        return loyaltyProgram;
    }

    // Envia tokens a LoyaltyProgram con la address del contrato
    function fundLoyaltyProgram(address _loyaltyProgramAddress, uint256 _amount) public onlyOwner {
        require(omniToken.balanceOf(address(this)) >= _amount, "Not enough tokens in factory");
        omniToken.transfer(_loyaltyProgramAddress, _amount);
    }

    // Mint new tokens (en este caso se guardan en este contrato, se podria enviar diectamente a otros contratos)
    function mintTokens(uint256 _amount) public onlyOwner {
        omniToken.mint(address(this), _amount);
    }

     // Mint new tokens (en este caso se guardan en este contrato, se podria enviar diectamente a otros contratos)
    function mintTokensToAddress(uint256 _amount, address _loyaltyProgramAddress) public onlyOwner {
        omniToken.mint(_loyaltyProgramAddress, _amount);
    }

    // Function to get the count of registered commerce addresses
    function getCommerceCount() public view returns (uint256) {
        return commerceAddresses.length;
    }

    function getCommerceByAddress(address _commerceAddress) public view returns (string memory name, address loyaltyProgramAddress) {
        Commerce memory commerce = commerceDetailsByAddress[_commerceAddress];
        return (commerce.name, commerce.loyaltyProgramAddress);
    }

}
