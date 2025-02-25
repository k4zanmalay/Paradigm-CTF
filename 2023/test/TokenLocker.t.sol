// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "forge-std/Test.sol";

contract Exploit is Test {
    address private immutable TARGET = 0x7f5C649856F900d15C83741f45AE46f5C6858234;
    IERC721 private immutable UNI_V3 = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address player = address(0xBaDa55);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");
    }

    function isSolved() public view returns (bool) {
        return UNI_V3.balanceOf(TARGET) == 0;
    }

    function testTokenLockerExploit() public {
        vm.startPrank(player);
        require(isSolved(), "NOT SOLVED");
    }
}




