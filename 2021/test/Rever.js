const { ethers } = require("hardhat");
const { expect } = require("chai");

const generateRandomString = (length) => {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
  return Array.from({ length }, () => chars.charAt(Math.floor(Math.random() * chars.length))).join('');
}

const checker = async(contractInstance, signer) => {
  const testcases = {
    "": true,
    "a": true,
    "ab": false,
    "aba": true,
    "paradigm": false,
    "tattarrattat": true,
  };

  // Generate additional dynamic test cases
  for (let i = 0; i < 10; i++) {
    if (i % 2 === 0) {
      if (Math.random() > 0.5) {
        const str = generateRandomString(63);
        testcases[str + generateRandomString(1) + str.split('').reverse().join('')] = true;
      } else {
        const str = generateRandomString(64);
        testcases[str + str.split('').reverse().join('')] = true;
      }
    } else {
      testcases[generateRandomString(128)] = false;
    }
  }

  for (const [input, expected] of Object.entries(testcases)) {
    const result = await contractInstance["test(string)"](input);
    if (result !== expected) {
      console.error(`Test failed for input "${input}": expected ${expected}, got ${result}`);
      return false;
    }
  }
  
  return true;
}

describe("Rever", () => {
    before( async () => {
        [master, player] = await ethers.getSigners();

        Setup = await ethers.getContractFactory("Setup");
        setup = await Setup.deploy();
        challengeAddress = await setup.challenge();
        challenge = await ethers.getContractAt("Challenge", challengeAddress);
    });

    it("Solved", async () => {
        bytecode = "0x3436471c5b81473603033560f81c823560f81c1481831016156025575b47820191506004565b80821434534734f3f3344753341482805b56046050910182475b5725601516108381141cf86035821cf8603503033647815b1c473634";
        challenge.connect(player).deploy(bytecode);    
        fwd = await challenge.fwd();
        rev = await challenge.rev();
        
        tx = {to: fwd, value: 1};
        await player.sendTransaction(tx);
        tx.to = rev;
        await player.sendTransaction(tx);

        // Run the checker function
        isCorrect = await checker(setup, player);
        expect(isCorrect).to.be.true; 
    });
});

