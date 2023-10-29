require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: {
      version: "0.8.20",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200  // A lower number will optimize more for size rather than performance.
        }
      }
    },
    networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    polygonMumbai: {
      url: `https://polygon-mumbai.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,  
      accounts: [process.env.ACCOUNT_PRIVATE_KEY],  
      chainId: 80001,  
    },
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY_SEPOLIA}`,  
      accounts: [process.env.ACCOUNT_PRIVATE_KEY],  
      chainId: 11155111,  
    },
  },
};

