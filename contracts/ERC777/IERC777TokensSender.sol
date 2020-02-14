pragma solidity 0.5.16;

/**
 * @title IERC777TokensSender
 * @dev ERC777TokensSender interface
 */
interface IERC777TokensSender {

    function canTransfer(
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns(bool);

    function tokensToTransfer(
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

}
