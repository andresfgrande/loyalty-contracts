// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "./OmniToken.sol";

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

struct Approval {
    address owner;
    address spender;
    uint256 value;
}

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
    bytes32 private domainSeparator;
    bytes32 public constant APPROVAL_TYPEHASH = keccak256("Approval(address owner,address spender,uint256 value)");

    event Registered(address indexed user, string loyal_ID, uint256 timestamp); 
    event RewardsSent(address indexed from, address indexed to, uint256 amount, uint256 timestamp); 
    event UserTokenTransfer(address indexed from, address indexed to, uint256 amount, uint256 timestamp); 
    event GaslessApproval(address indexed owner, address indexed spender, uint256 value, uint256 timestamp); 
    event RedeemProduct(address indexed from, address _toProductOwner, address indexed _toUserOwner, uint256 amount, uint256 timestamp); 

    constructor(address _omniTokenAddress, address _owner, string memory _commerceName, string memory _commercePrefix)  EIP712("OmniWallet3", "1") {
        omniToken = OmniToken(_omniTokenAddress);
        commerceName = _commerceName;
        commercePrefix = _commercePrefix;
        tokenRatio = 1;
        transferOwnership(_owner); 
        domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("OmniWallet3")),
                keccak256(bytes("1")),
                uint256(11155111),
                address(this)
            )
        );
    }

    function register(string memory _loyalId, address _userAddress ) public onlyOwner returns (bool){
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
        address _from,
        address _toProductCommerceAddress,
        address _toUserCommerceAddress,
        uint256 _amount,
        bytes memory _signature
    ) public onlyOwner returns (bool){
        bytes32 message = prefixed(keccak256(abi.encodePacked(_from, _toProductCommerceAddress, _toUserCommerceAddress, _amount)));
        require(recoverSigner(message, _signature) == _from, "IS"); //Invalid signature

        if (_toProductCommerceAddress == _toUserCommerceAddress) {
            omniToken.safeTransferFrom(_from, _toProductCommerceAddress, _amount);
        } else {
            uint256 productAmount = _amount.mul(PRODUCT_RATIO).div(100); // Calculate % for product owner
            uint256 userAmount = _amount.mul(COMMERCE_RATIO).div(100);    // Calculate % for user owner
            omniToken.safeTransferFrom(_from, _toProductCommerceAddress, productAmount);
            omniToken.safeTransferFrom(_from, _toUserCommerceAddress, userAmount);
        }

        emit RedeemProduct(_from, _toProductCommerceAddress, _toUserCommerceAddress, _amount, block.timestamp); 
        return true;
    }

    function gaslessApproveTyped(
        address _owner,
        address _spender,
        uint256 _value,
        bytes memory _signature
    ) public onlyOwner returns (bool){
        // Create the EIP712 hash of your data
        bytes32 structHash = keccak256(abi.encode(APPROVAL_TYPEHASH, _owner, _spender, _value));
        bytes32 digest = _hashTypedDataV4(structHash);
        
        // Recover the signer from the signature
        address signer = ECDSA.recover(digest, _signature);
        require(signer == _owner, "IS");
        
        // Now proceed with your approval logic
        bool success = omniToken.approveFor(_owner, _spender, _value);
        require(success, "AF");
        
        emit GaslessApproval(_owner, _spender, _value, block.timestamp);
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




