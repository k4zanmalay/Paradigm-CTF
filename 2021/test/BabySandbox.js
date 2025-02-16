const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Sandbox", () => {
    before( async () => {
        [master, player] = await ethers.getSigners();

        Sandbox = await ethers.getContractFactory("BabySandbox");
        sandbox = await Sandbox.deploy();
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
            await ethers.provider.getCode(sandbox.address)
        ).to.equal("0x");        
    });
});



