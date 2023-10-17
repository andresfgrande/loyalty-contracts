// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./OmniToken.sol";

contract LoyaltyProgram is Ownable {

    using SafeERC20 for OmniToken; 

    mapping(string => address) public loyalIdToUser;
    OmniToken public omniToken;
    uint256 public tokenRatio;
    //mapping(address => uint256) private nonces;
    string public commerceName;
    string public commercePrefix;
    string[] public usersLoyaltyIds;

    event Registered(address indexed user, string loyal_ID);
    event RewardsSent(address indexed to, uint256 amount);
    event UserTokenTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event GaslessApproval(address indexed owner, address indexed spender, uint256 value, uint256 timestamp);
    event AdminTokenTransfer(address indexed recipient, uint256 amount);

    constructor(address _omniTokenAddress, address _owner, string memory _commerceName, string memory _commercePrefix) {
        omniToken = OmniToken(_omniTokenAddress);
        commerceName = _commerceName;
        commercePrefix = _commercePrefix;
        tokenRatio = 1;
        transferOwnership(_owner); 
    }

    function register(string memory _loyalId, address _userAddress ) public onlyOwner returns (bool){
        require(loyalIdToUser[_loyalId] == address(0), "LIDF"); //Loyal Id found
        loyalIdToUser[_loyalId] = _userAddress;
        usersLoyaltyIds.push(_loyalId); 
        emit Registered(_userAddress, _loyalId);

        return true;
    }

    function getUserAddress(string memory _loyalId) public view returns (address) {
        require(loyalIdToUser[_loyalId] != address(0), "LIDNF"); //Loyal Id not found
        return loyalIdToUser[_loyalId];
    }

    function setTokenRatio(uint256 _newRatio) public onlyOwner {
        tokenRatio = _newRatio;
    }

    function sendRewards(string memory _loyalId, uint256 _purchaseValue) public onlyOwner returns (bool) {
        address recipient = getUserAddress(_loyalId);
        uint256 rewardTokens = _purchaseValue * tokenRatio * 10**18;
        require(omniToken.balanceOf(address(this)) >= rewardTokens, "NT"); //Not enough tokens in contract
        omniToken.safeTransfer(recipient, rewardTokens);
        emit RewardsSent(recipient, rewardTokens);
        return true;
    }

    function adminTransferTokensToUser(string memory _loyalId, uint256 _amount) public onlyOwner {
        address recipient = getUserAddress(_loyalId);
        require(omniToken.balanceOf(address(this)) >= _amount, "NT"); //Not enough tokens in contract
        omniToken.safeTransfer(recipient, _amount);
        emit AdminTokenTransfer(recipient, _amount);
    }

    //gasless
    function purchaseProduct(){
        //TODO
    }

    //gasless
    function gaslessApprove(
        address _owner,
        address _spender,
        uint256 _value,
        bytes memory _signature
    ) public onlyOwner returns (bool){
        bytes32 message = prefixed(keccak256(abi.encodePacked(_owner, _spender, _value)));
        require(recoverSigner(message, _signature) == _owner, "IS"); //Invalid signature
        bool success = omniToken.approveFor(_owner, _spender, _value);
        require(success, "AF");
        return success;
    }

    //gasless
    function userTransferTokensToUser(
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _signature
    ) public onlyOwner returns (bool){
        bytes32 message = prefixed(keccak256(abi.encodePacked(_from, _to, _amount)));
        require(recoverSigner(message, _signature) == _from, "IS"); //Invalid signature
        omniToken.safeTransferFrom(_from, _to, _amount);
        emit UserTokenTransfer(_from, _to, _amount, block.timestamp);
        return true;
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




