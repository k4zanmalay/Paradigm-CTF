pragma solidity 0.4.24;

contract UniswapV2RouterLike {
    function swapExactETHForTokens(uint amountOutMin, address[] memory path, address to, uint deadline)
        public
        payable
        returns (uint[] memory amounts);
}
