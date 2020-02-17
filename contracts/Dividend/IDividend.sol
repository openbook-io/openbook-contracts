pragma solidity 0.5.16;

interface IDividend {

    function () external payable;

    function claim(uint256 value, bytes calldata data) external;

    function start() external;

    function stop() external;

    event Start();
    event Stop();
    event Deposit(address indexed operator, uint amount);
    event Claimed(address indexed operator, uint amount);
}
