// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./OmniToken.sol";  
import "./LoyaltyProgram.sol";  

contract LoyaltyProgramFactory is Ownable {

     using SafeERC20 for OmniToken; 
    
    OmniToken public omniToken;
    address[] public commerceAddresses;

    struct Commerce {
        string name;
        address loyaltyProgramAddress;
        string prefix;
    }

    // Mapping from loyalty address to its commerce details
    mapping(address => Commerce) public commerceDetailsByAddress;

    struct User {
        string loyaltyId;
        address loyaltyProgram;
    }

    // Mapping from user addres to user details
    mapping(address => User) public userInfoByAddress;

    // Mapping from loyalId to user Address
    mapping(string => address) public addressByLoyaltyId;

    // Mapping from user loyaltyId prefix to loyalty program address
    mapping(string => address) public loyaltyProgramByPrefix;

    event LoyaltyProgramCreated(address indexed factory, address indexed loyaltyProgram, 
                                address indexed commerceAddress, string commerceName, uint256 timestamp);
    event UserAdded(address indexed factory, address indexed loyaltyProgram, address indexed userAddress, string loyaltyId, uint256 timestamp);
    event TokensMintedTo(address indexed factory, address indexed to, uint256 amount, uint256 timestamp);

    constructor(address _omniTokenAddress) {
        omniToken = OmniToken(_omniTokenAddress);
    }

    //Create new loyalty program and store the address in array and in a mapping 
    function createLoyaltyProgram(address commerceAddress, string memory commerceName, string memory commercePrefix) public onlyOwner returns (LoyaltyProgram ) {
        require(commerceDetailsByAddress[commerceAddress].loyaltyProgramAddress == address(0), "LPE"); //Loyalty program exists

        LoyaltyProgram loyaltyProgram = new LoyaltyProgram(address(omniToken), commerceAddress, commerceName, commercePrefix);

        Commerce memory newCommerce = Commerce({
            name: commerceName,
            loyaltyProgramAddress: address(loyaltyProgram),
            prefix: commercePrefix
        });

        commerceDetailsByAddress[commerceAddress] = newCommerce;
        commerceAddresses.push(commerceAddress);  
        loyaltyProgramByPrefix[commercePrefix] = address(loyaltyProgram);

        emit LoyaltyProgramCreated(address(this), address(loyaltyProgram), commerceAddress, commerceName, block.timestamp);
        return loyaltyProgram;
    }

     // Mint new tokens and send to loyalty program address
    function mintTokensToAddress(uint256 _amount, address _loyaltyProgramAddress) public onlyOwner {
        omniToken.mint(_loyaltyProgramAddress, _amount);
        emit TokensMintedTo(address(this), _loyaltyProgramAddress, _amount, block.timestamp);
    }

    // Function to get the count of registered commerce addresses
    function getCommerceCount() public view returns (uint256) {
        return commerceAddresses.length;
    }

    function getCommerceByAddress(address _commerceAddress) public view returns (string memory name, address loyaltyProgramAddress) {
        Commerce memory commerce = commerceDetailsByAddress[_commerceAddress];
        return (commerce.name, commerce.loyaltyProgramAddress);
    }

    // Function to add a new user to userInfoByAddress mapping
    function addUserInfo(address userAddress, string memory loyaltyId, string memory loyaltyPrefix) public onlyOwner {
        require(bytes(userInfoByAddress[userAddress].loyaltyId).length == 0, "UE"); //User exists
        require(addressByLoyaltyId[loyaltyId] == address(0), "LIDE"); //Loyalty ID exists
        address loyaltyProgramAddress = loyaltyProgramByPrefix[loyaltyPrefix];
        require(loyaltyProgramAddress != address(0), "LPNF"); //Loyalty program not found
        User memory newUser = User({
            loyaltyId: loyaltyId,
            loyaltyProgram: loyaltyProgramAddress
        });
        userInfoByAddress[userAddress] = newUser;
        addressByLoyaltyId[loyaltyId] = userAddress;
       
        emit UserAdded(address(this), loyaltyProgramAddress, userAddress, loyaltyId, block.timestamp);
    }

    function getUserInfoByAddress(address userAddress) public view returns (string memory loyaltyId, address loyaltyProgram) {
        User memory user = userInfoByAddress[userAddress];
        return (user.loyaltyId, user.loyaltyProgram);
    }

    function addTrustedRelayer(address loyaltyProgramAddress) public onlyOwner{
        omniToken.addTrustedRelayer(loyaltyProgramAddress);
    }

}
