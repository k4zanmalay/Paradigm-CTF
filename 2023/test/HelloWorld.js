const { ethers } = require("hardhat");
const { expect } = require("chai");

const parseEther = ethers.utils.parseEther;

describe("HelloWorld", () => {
    before( async () => {
        HW = await ethers.getContractFactory("HelloWorld");
        hw = await HW.deploy();
    });

    it("Exploits", async () => {
        Boom = await ethers.getContractFactory("Boom");
        boom = await Boom.deploy({value: parseEther("13.38")});
    });

    after(async () => {
        /** SUCCESS CONDITIONS */
        expect(
            await hw.isSolved()
        ).to.be.true;        
    });
});


