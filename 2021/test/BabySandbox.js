const { ethers } = require("hardhat");
const { expect } = require("chai");

const parseEther = ethers.utils.parseEther;

describe("Sandbox", () => {
    before( async () => {
        [master, player] = await ethers.getSigners();

        Sandbox = await ethers.getContractFactory("BabySandbox");
        sandbox = await Sandbox.deploy({value: parseEther("1")});
    });

    it("Exploits", async () => {
        Trigger = await ethers.getContractFactory("Trigger");
        trigger = await Trigger.deploy();
        Destroyer = await ethers.getContractFactory("Destroyer");
        destroyer = await Destroyer.deploy(trigger.address);
        
        await sandbox.run(destroyer.address);
    });

    after(async () => {
        /** SUCCESS CONDITIONS */
        expect(
            await ethers.provider.getBalance(sandbox.address)
        ).to.equal(0);        
    });
});



