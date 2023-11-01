// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./OmniToken.sol";

contract LoyaltyProgram is Ownable, EIP712 {

    using SafeERC20 for OmniToken; 
    using SafeMath for uint256;

    mapping(string => address) public loyalIdToUser;
    OmniToken public omniToken;
    uint256 public tokenRatio;
    string public commerceName;
    string public commercePrefix;
    string[] public usersLoyaltyIds;
    uint256 public constant PRODUCT_RATIO = 80;
    uint256 public constant COMMERCE_RATIO = 20;
    bytes32 public constant APPROVAL_TYPEHASH = keccak256("Approval(address owner,address spender,uint256 value)");
    bytes32 public constant TRANSFER_TYPEHASH = keccak256("Transfer(address from,address to,uint256 amount)");
    bytes32 public constant REDEEM_TYPEHASH = keccak256("Redeem(string productSku,address from,address toProductOwner,address toUserOwner,uint256 amount)");

    event Registered(address indexed user, string loyal_ID, uint256 timestamp); 
    event RewardsSent(address indexed from, address indexed to, uint256 amount, uint256 timestamp); 
    event UserTokenTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp); 
    event GaslessApproval(address indexed owner, address indexed spender, uint256 value, uint256 timestamp); 
    event RedeemProduct(string productSku, address indexed from, address _toProductOwner, address indexed _toUserOwner, uint256 amount, uint256 timestamp); 
    event Withdrawal(address indexed from, address indexed to, uint256 amount, uint256 timestamp); 
    event SetTokenRatio(address indexed from, uint256 ratio, uint256 timestamp); 

    constructor(address _omniTokenAddress, address _owner, string memory _commerceName, string memory _commercePrefix)  EIP712("OmniWallet3", "1") {
        omniToken = OmniToken(_omniTokenAddress);
        commerceName = _commerceName;
        commercePrefix = _commercePrefix;
        tokenRatio = 1;
        transferOwnership(_owner); 
    }

    function register(string memory _loyalId, address _userAddress) public onlyOwner returns (bool){
        require(loyalIdToUser[_loyalId] == address(0), "LIDF"); //Loyal Id found
        loyalIdToUser[_loyalId] = _userAddress;
        usersLoyaltyIds.push(_loyalId); 
        emit Registered(_userAddress, _loyalId, block.timestamp);

        return true;
    }

    function getUserAddress(string memory _loyalId) public view returns (address) {
        require(loyalIdToUser[_loyalId] != address(0), "LIDNF"); //Loyal Id not found
        return loyalIdToUser[_loyalId];
    }

    function setTokenRatio(uint256 _newRatio) public onlyOwner {
        tokenRatio = _newRatio;
        emit SetTokenRatio(address(this), _newRatio, block.timestamp);
    }

    function sendRewards(string memory _loyalId, uint256 _purchaseValue) public onlyOwner returns (bool) {
        address recipient = getUserAddress(_loyalId);
        uint256 rewardTokens = _purchaseValue * tokenRatio * 10**18;
        require(omniToken.balanceOf(address(this)) >= rewardTokens, "NT"); //Not enough tokens in contract
        omniToken.safeTransfer(recipient, rewardTokens);
        emit RewardsSent(address(this), recipient, rewardTokens, block.timestamp);
        return true;
    }

    function adminTransferTokensToUser(string memory _loyalId, uint256 _amount) public onlyOwner {
        address recipient = getUserAddress(_loyalId);
        require(omniToken.balanceOf(address(this)) >= _amount, "NT"); //Not enough tokens in contract
        omniToken.safeTransfer(recipient, _amount);
        emit UserTokenTransfer(address(this), recipient, _amount, block.timestamp);
    }

    //gasless
    function redeemProduct(
        string memory _productSku,
        address _from,
        address _toProductCommerceAddress,
        address _toUserCommerceAddress,
        uint256 _amount,
        bytes memory _signature
    ) public onlyOwner returns (bool){

        bytes32 structHash = keccak256(abi.encode(REDEEM_TYPEHASH, keccak256(abi.encodePacked(_productSku)),_from, _toProductCommerceAddress, _toUserCommerceAddress, _amount));
        bytes32 digest = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(digest, _signature);
        require(signer == _from, "IS");

        uint256 weiAmount = _amount.mul(10**18);

        if (_toProductCommerceAddress == _toUserCommerceAddress) {
            omniToken.safeTransferFrom(_from, _toProductCommerceAddress, weiAmount);
        } else {
            uint256 productAmount = weiAmount.mul(PRODUCT_RATIO).div(100); // Calculate % for product owner
            uint256 userAmount = weiAmount.mul(COMMERCE_RATIO).div(100);    // Calculate % for user owner
            omniToken.safeTransferFrom(_from, _toProductCommerceAddress, productAmount);
            omniToken.safeTransferFrom(_from, _toUserCommerceAddress, userAmount);
        }

        emit RedeemProduct(_productSku, _from, _toProductCommerceAddress, _toUserCommerceAddress, weiAmount, block.timestamp); 
        return true;
    }

    //gasless
    function gaslessApprove(
        address _owner,
        address _spender,
        uint256 _value,
        bytes memory _signature
    ) public onlyOwner returns (bool){

        bytes32 structHash = keccak256(abi.encode(APPROVAL_TYPEHASH, _owner, _spender, _value));
        bytes32 digest = _hashTypedDataV4(structHash);
        
        address signer = ECDSA.recover(digest, _signature);
        require(signer == _owner, "IS");
        
        uint256 weiValue = _value.mul(10**18);
        bool success = omniToken.approveFor(_owner, _spender, weiValue);
        require(success, "AF");
        
        emit GaslessApproval(_owner, _spender, weiValue, block.timestamp);
        return success;
    }

    //gasless
    function userTransferTokensToUser(
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _signature
    ) public onlyOwner returns (bool){

        bytes32 structHash = keccak256(abi.encode(TRANSFER_TYPEHASH, _from, _to, _amount));
        bytes32 digest = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(digest, _signature);
        require(signer == _from, "IS");

        uint256 weiAmount = _amount.mul(10**18);
        omniToken.safeTransferFrom(_from, _to, weiAmount);
        emit UserTokenTransfer(_from, _to, weiAmount, block.timestamp);
        return true;
    }

    function withdrawal(address _to, uint256 _amount) public onlyOwner returns(bool){
        require(omniToken.balanceOf(address(this)) >= _amount, "NT"); //Not enough tokens in contract
        omniToken.safeTransfer(_to, _amount);
        emit Withdrawal(address(this), _to, _amount, block.timestamp);
        return true;
    }
 
    function getUsersCount() public view returns (uint256) {
        return usersLoyaltyIds.length;
    }
}
