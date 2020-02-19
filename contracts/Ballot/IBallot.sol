pragma solidity 0.5.16;

interface IBallot {
    function getDocument() external view returns (string memory, string memory, bytes32);
    function geResult() external view returns (uint, uint, bool);
    function startVote() external;
    function doVote(bool _choice) external returns (bool voted);
    function endVote() external;
}
