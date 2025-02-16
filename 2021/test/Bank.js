const { ethers } = require("hardhat");
const { expect } = require("chai");

const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const parseEther = ethers.utils.parseEther;

describe("Bank", () => {
    before( async () => {
        [master, player] = await ethers.getSigners();
        amount = parseEther("50");

        WETHABI = [
            "function deposit() payable",
            "function approve(address,uint256) returns(bool)",
            "function balanceOf(address) view returns(uint256)",           
        ];

        Bank = await ethers.getContractFactory("Bank");
        bank = await Bank.deploy();
        
        weth = await ethers.getContractAt(WETHABI, WETH);
        await weth.deposit({value: amount});
        await weth.approve(bank.address, ethers.constants.MaxUint256);
        
        await bank.depositToken(0, WETH, amount);
        bal = await weth.balanceOf(bank.address);
    });

    it("Exploits", async () => {
        Banker = await ethers.getContractFactory("Banker");
        banker = await Banker.deploy();
        await banker.attack(bank.address);
    });

    after(async () => {
        /** SUCCESS CONDITIONS */
        expect(
            await weth.balanceOf(bank.address)
        ).to.equal(0);        
    });
});



