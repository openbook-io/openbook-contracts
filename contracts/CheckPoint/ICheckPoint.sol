pragma solidity 0.5.16;

interface ICheckPoint {
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
    function balanceAt(address owner, uint256 blockNumber) external view returns (uint256);
}
