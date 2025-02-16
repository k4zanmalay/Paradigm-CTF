const { ethers } = require("hardhat");
const { expect } = require("chai");

const ROUTER = "0xf164fC0Ec4E93095b804a4795bBe1e041497b92a";
const WETH = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const TOKENS = [
    "0x6B175474E89094C44Da98b954EedeAC495271d0F",
    "0x0000000000085d4780B73119b644AE5ecd22b376",
    "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    "0xdAC17F958D2ee523a2206206994597C13D831ec7"
];

const parseEther = ethers.utils.parseEther;

let tokens = [];
let amounts = [];

describe("Swap", () => {
    before( async () => {
        [master, player] = await ethers.getSigners();

        Swap = await ethers.getContractFactory("StableSwap");
        swap = await Swap.deploy();
        router = await ethers.getContractAt("UniswapV2RouterLike", ROUTER);
        for(let i=0; i<TOKENS.length; i++) {
            await swap.addCollateral(TOKENS[i]);
            path = [WETH, TOKENS[i]];
            router.swapExactETHForTokens(0, path, master.address, 2**32 - 1, {value: parseEther("100")});

            tokens[i] = await ethers.getContractAt("src/swap/ERC20.sol:ERC20Like", TOKENS[i]);
            await tokens[i].approve(swap.address, ethers.constants.MaxUint256);
            amounts[i] = await tokens[i].balanceOf(master.address);
        }

        
        await swap.mint(amounts);
        value = await swap.totalValue();
    });

    it("Exploits", async () => {
        Swapper = await ethers.getContractFactory("Swapper");
        swapper = await Swapper.deploy();
        await swapper.attack(swap.address, {value: parseEther("400")});  
    });

    after(async () => {
        /** SUCCESS CONDITIONS */
        expect(
            await swap.totalValue()
        ).to.be.lt(value.div(100));        
    });
});

