// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./OmniToken.sol";

contract LoyaltyProgram is Ownable {

    mapping(string => address) public loyalIdToUser;
    OmniToken public omniToken;
    uint256 public tokenRatio;
    //mapping(address => uint256) private nonces;
    string public commerceName;
    string public commercePrefix;
    string[] public usersLoyaltyIds;

    event Registered(address indexed user, string loyal_ID);
    event RewardsSent(address indexed to, uint256 amount);
    event TokenRatioUpdated(uint256 newRatio);
    event UserTokenTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event GaslessApproval(address indexed owner, address indexed spender, uint256 value, uint256 timestamp);

    constructor(address _omniTokenAddress, address _owner, string memory _commerceName, string memory _commercePrefix) {
        omniToken = OmniToken(_omniTokenAddress);
        commerceName = _commerceName;
        commercePrefix = _commercePrefix;
        transferOwnership(_owner); 
    }

    function register(string memory _loyalId, address _userAddress ) public onlyOwner {
        require(loyalIdToUser[_loyalId] == address(0), "Loyal ID already registered");
        loyalIdToUser[_loyalId] = _userAddress;
        usersLoyaltyIds.push(_loyalId); 
        emit Registered(_userAddress, _loyalId);
    }

    function getUserAddress(string memory _loyalId) public view returns (address) {
        require(loyalIdToUser[_loyalId] != address(0), "Loyal ID not registered");
        return loyalIdToUser[_loyalId];
    }

    function setTokenRatio(uint256 _newRatio) public onlyOwner {
        tokenRatio = _newRatio;
        emit TokenRatioUpdated(_newRatio);
    }

    function sendRewards(string memory _loyalId, uint256 _purchaseValue) public onlyOwner {
        address recipient = getUserAddress(_loyalId);
        uint256 rewardTokens = _purchaseValue * tokenRatio;
        require(omniToken.balanceOf(address(this)) >= rewardTokens, "Not enough tokens to send rewards");
        omniToken.transfer(recipient, rewardTokens);
        emit RewardsSent(recipient, rewardTokens);
    }

    function adminTransferTokensToUser() public onlyOwner{
        //TODO
    }

    //gasless
    function gaslessApprove(
        address _owner,
        address _spender,
        uint256 _value,
        bytes memory _signature
    ) public onlyOwner {
        bytes32 message = prefixed(keccak256(abi.encodePacked(_owner, _spender, _value)));
        require(recoverSigner(message, _signature) == _owner, "Invalid signature");

        require(omniToken.approveFor(_owner, _spender, _value), "Approval failed");
    }

    //gasless
    function userTransferTokensToUser(
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _signature
    ) public onlyOwner {
        bytes32 message = prefixed(keccak256(abi.encodePacked(_from, _to, _amount)));
        require(recoverSigner(message, _signature) == _from, "Invalid signature");

        require(omniToken.transferFrom(_from, _to, _amount), "Token transfer failed");
        emit UserTokenTransfer(_from, _to, _amount, block.timestamp);
    }

    function prefixed(bytes32 hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        return ECDSA.recover(message, sig);
    }
    
     function getUsersCount() public view returns (uint256) {
        return usersLoyaltyIds.length;
    }
}




