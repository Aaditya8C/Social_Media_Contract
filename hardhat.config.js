require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@nomiclabs/hardhat-ethers");

/** @type import('hardhat/config').HardhatUserConfig */

const ALCHEMY_API_KEY = process.env.ALCHEMY_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
module.exports = {
  solidity: "0.8.24",
  networks: {
    sepolia: {
      url: ALCHEMY_API_KEY,
      accounts: [PRIVATE_KEY],
      chainId: 11155111,
    },
    // ganache: {
    //   url: "HTTP://127.0.0.1:7545", // Default Ganache URL
    //   chainId: 5777, // Default chain ID for Ganache
    //   accounts: [PRIVATE_KEY],
    // },
  },
  paths: {
    artifacts: "../client/app/artifacts",
  },
};
