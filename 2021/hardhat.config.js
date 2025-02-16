require("@nomicfoundation/hardhat-chai-matchers");
require("@nomiclabs/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: {
    compilers: [
      {version: "0.4.16",},
      {version: "0.4.24",},
      {version: "0.5.12",},
      {version: "0.6.12",},
      {version: "0.7.0",},
      {version: "0.7.6",},
      {version: "0.8.0",},
    ],
  },
  paths: {
    sources: "./src/",
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      forking: {
        url: "https://rpc.ankr.com/eth",
        //blockNumber: 14390000,
        blockNumber: 11800000
      },
    },
  },
  mocha: {
    timeout: 20000000000
  },
  skipFiles: ["node_modules"],
};

