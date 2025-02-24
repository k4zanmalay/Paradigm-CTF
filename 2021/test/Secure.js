const { ethers } = require("hardhat");
const { expect } = require("chai");

const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const parseEther = ethers.utils.parseEther;

describe("Secure", () => {
    before( async () => {
        [master, player] = await ethers.getSigners();
        WANT = parseEther("50");

        Module = await ethers.getContractFactory("TokenModule");
        module = await Module.deploy();

        Wallet = await ethers.getContractFactory("Wallet");
        wallet = await Wallet.deploy();
        await wallet.allowModule(module.address);
        
        weth = await ethers.getContractAt("src/secure/WETH.sol:WETH9", WETH);
        await weth.deposit({value: WANT});
        await weth.approve(wallet.address, ethers.constants.MaxUint256);
        
        data = Module.interface.encodeFunctionData("deposit", [WETH, master.address, WANT]);
        await wallet.execModule(module.address, data);
    });

    it("Exploits", async () => {
        await weth.connect(player).deposit({value: WANT});
    });

    after(async () => {
        /** SUCCESS CONDITIONS */
        expect(
            await weth.balanceOf(player.address)
        ).to.be.equal(WANT);        
    });
});


