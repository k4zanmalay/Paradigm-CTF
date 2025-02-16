pragma solidity 0.8.0;

import "../src/hello/Hello.sol";
import "forge-std/Test.sol";

contract Exploit is Test {
    Hello hello;
    address player = address(0xBaDa55);

    function setUp() external {
        hello = new Hello();
    }

    function isSolved() public view returns (bool) {
        return hello.solved();
    }

    function testHelloExploit() public {
        vm.prank(player);
        hello.solve(); 
        require(isSolved(), "NOT SOLVED");
    }
}


