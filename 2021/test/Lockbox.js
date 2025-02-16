const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Lockbox", () => {
    before( async () => {
        [master, player] = await ethers.getSigners();

        Entrypoint = await ethers.getContractFactory("Entrypoint");
        entrypoint = await Entrypoint.deploy();
    });

    it("Exploits", async () => {
        Cracker = await ethers.getContractFactory("Cracker");
        cracker = await Cracker.deploy(entrypoint.address);
        
        //0x7E5F4552091A69125d5DfCb7b8C2659029395Bdf 
        //private key for this address is 0x...01 
        
        privateKey = "0x" + "01".padStart(64, "0")
        signingKey = new ethers.utils.SigningKey(privateKey);
        messageHash = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("stage1")); 
        signature = await signingKey.signDigest(messageHash);
        const {v, r, s} = ethers.utils.splitSignature(signature);
        await cracker.attack(v, r, s);
    });

    after(async () => {
        /** SUCCESS CONDITIONS */
        expect(
            await entrypoint.solved()
        ).to.be.true;        
    });
});



