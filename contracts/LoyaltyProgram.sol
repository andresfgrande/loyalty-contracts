// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./OmniToken.sol";

contract LoyaltyProgram is Ownable {

    mapping(string => address) public loyalIdToUser;
    OmniToken public omniToken;
    uint256 public tokenRatio;
    mapping(address => uint256) public nonces;

    event Registered(address indexed user, string loyal_ID);
    event RewardsSent(address indexed to, uint256 amount);
    event TokenRatioUpdated(uint256 newRatio);
    event TokenTransfer(address indexed from, address indexed to, uint256 amount);

    constructor(address _omniTokenAddress, address _owner) {
        omniToken = OmniToken(_omniTokenAddress);
        transferOwnership(_owner); 
    }

    function register(string memory _loyalId, address _userAddress ) public onlyOwner {
        require(loyalIdToUser[_loyalId] == address(0), "Loyal ID already registered");
        loyalIdToUser[_loyalId] = _userAddress;
        emit Registered(_userAddress, _loyalId);
    }

    function getUserAddress(string memory _loyalId) public view returns (address) {
        require(loyalIdToUser[_loyalId] != address(0), "Loyal ID not registered");
        return loyalIdToUser[_loyalId];
    }

    function setTokenRatio(uint256 _newRatio) public onlyOwner {
        tokenRatio = _newRatio;
        emit TokenRatioUpdated(newRatio);
    }

    function sendRewards(string memory _loyalId, uint256 _purchaseValue) public onlyOwner {
        address recipient = getUserAddress(_loyalId);
        uint256 rewardTokens = _purchaseValue * tokenRatio;
        require(omniToken.balanceOf(address(this)) >= rewardTokens, "Not enough tokens to send rewards");
        omniToken.transfer(recipient, rewardTokens);
        emit RewardsSent(recipient, rewardTokens);
    }

    function depositTokens(uint256 _amount) public onlyOwner {
        require(omniToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
    }

    function adminTransferTokensToUser() public onlyOwner{
        //TODO
    }

    //Gasless
    function userTransferTokensToUser() public onlyOwner{
        //TODO
    }

    //Gasless
    function purchaseProduct(){
        //TODO
    }

    function getPurchases(){
        //TODO
    }

    

    /*function transferWithSignature(
        address from,
        address to,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) public {
        require(nonce == nonces[from], "Invalid nonce");
        
        bytes32 hash = keccak256(abi.encodePacked(from, to, amount, nonce, address(this)));
        bytes32 prefixedHash = hash.toEthSignedMessageHash();

        require(from == prefixedHash.recover(signature), "Invalid signature");
        nonces[from]++;

        require(omniToken.transferFrom(from, to, amount), "Transfer failed");
        emit TokenTransfer(from, to, amount);
    }*/
}


    //Gasless functions

    //function purchaseProduct()


