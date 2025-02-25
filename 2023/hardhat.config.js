require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: {
    compilers: [
      {version: "0.8.13",},
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
      },
    },
  },
  mocha: {
    timeout: 20000000000
  },
  skipFiles: ["node_modules"],
};

