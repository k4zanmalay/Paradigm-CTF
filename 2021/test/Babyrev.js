const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("Babyrev", () => {
    before( async () => {
        [master, player] = await ethers.getSigners();

        Challenge = await ethers.getContractFactory("src/babyrev/private/Challenge.sol:Challenge");
        challenge = await Challenge.deploy();
        
    });

    it("Exploits", async () => {
        await challenge.solve(ethers.BigNumber.from("0x1ca71c40cb573a1f120ec468c36dde2923591766033254683cab7d34575a9d61"));
    });

    after(async () => {
        /** SUCCESS CONDITIONS */
        expect(
            await challenge.solved()
        ).to.equal(true);        
    });
});




