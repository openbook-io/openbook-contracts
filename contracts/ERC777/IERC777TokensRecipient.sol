pragma solidity 0.5.16;

/**
 * @title IERC777TokensRecipient
 * @dev ERC777TokensRecipient interface
 */
interface IERC777TokensRecipient {

    function canReceive(
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (bool);

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

