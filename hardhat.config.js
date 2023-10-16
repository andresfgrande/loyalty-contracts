require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config()

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
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
  },
};

