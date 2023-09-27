require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.19",
    networks: {
    localhost: {
      url: "http://127.0.0.1:8545"  
    },
    swisstronikTestnet: {
      url: "https://json-rpc.testnet.swisstronik.com",  
      accounts: [process.env.PRIVATE_KEY],  
      chainId: 1291,  
    },
 
  },
};

