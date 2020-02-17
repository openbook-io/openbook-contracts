pragma solidity 0.5.16;

import "./ERC1400ERC20.sol";
import "./CheckPointToken/ICheckPointToken.sol";

contract CheckPointToken is ICheckPointToken, ERC1400ERC20  {

    /// @dev Checkpoint is the fundamental unit for our internal accounting
    /// (who owns what, and at what moment in time)
    struct Checkpoint {
        uint256 blockNumber;
        uint256 value;
    }

    /// @dev This mapping contains checkpoints for every address:
    mapping (address => Checkpoint[]) public tokenBalances;

    /// @dev This is a one dimensional Checkpoint mapping of the overall token supply:
    Checkpoint[] public tokensTotal;

    /**
     * [CheckpointToken CONSTRUCTOR]
     * @dev Initialize CheckpointToken.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param granularity Granularity of the token.
     * @param controllers Array of initial controllers.
     * @param certificateSigner Address of the off-chain service which signs the
     * conditional ownership certificates required for token transfers, issuance,
     * redemption (Cf. CertificateController.sol).
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 granularity,
        address[] memory controllers,
        address certificateSigner
    )
    public
    ERC1400ERC20(name, symbol, granularity, controllers, certificateSigner)
    {}

    /**************************** EXTERNAL FUNCTIONS *************************************/

    /**
     * @dev total number of tokens in existence at the given block
     * @param blockNumber The block number we want to query for the total supply
     * @return A uint256 specifying the total number of tokens at a given block
     */
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256) {
        return _balanceAtBlock(tokensTotal, blockNumber);
    }


    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @param blockNumber The block number we want to query for the balance.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceAt(address owner, uint256 blockNumber) external view returns (uint256) {
        return _balanceAtBlock(tokenBalances[owner], blockNumber);
    }

    /**************************** INTERNAL FUNCTIONS *************************************/

    function _balanceAtBlock(Checkpoint[] storage checkpoints, uint256 blockNumber) internal view returns (
        uint256 balance
    ) {
        uint256 currentBlockNumber;
        (currentBlockNumber, balance) = _getCheckpoint(checkpoints, blockNumber);
    }

    function _setCheckpoint(Checkpoint[] storage checkpoints, uint256 newValue) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length.sub(1)].blockNumber < block.number)) {
            checkpoints.push(Checkpoint(block.number, newValue));
        } else {
            checkpoints[checkpoints.length.sub(1)] = Checkpoint(block.number, newValue);
        }
    }

    function _getCheckpoint(Checkpoint[] storage checkpoints, uint256 blockNumber) internal view returns (
        uint256 blockNumber_, uint256 value
    ) {
        if (checkpoints.length == 0) {
            return (0, 0);
        }

        // Shortcut for the actual value
        if (blockNumber >= checkpoints[checkpoints.length.sub(1)].blockNumber) {
            return (checkpoints[checkpoints.length.sub(1)].blockNumber, checkpoints[checkpoints.length.sub(1)].value);
        }

        if (blockNumber < checkpoints[0].blockNumber) {
            return (0, 0);
        }

        // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length.sub(1);
        while (max > min) {
            uint256 mid = (max.add(min.add(1))).div(2);
            if (checkpoints[mid].blockNumber <= blockNumber) {
                min = mid;
            } else {
                max = mid.sub(1);
            }
        }

        return (checkpoints[min].blockNumber, checkpoints[min].value);
    }

    /****************************** OVERRIDES ERC777 METHODS ************************************/

    /**
     * [OVERRIDES ERC777 METHOD]
     * @dev Perform the issuance of tokens.
     * @param operator Address which triggered the issuance.
     * @param to Token recipient.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance, and intended for the recipient (to).
     * @param operatorData Information attached to the issuance by the operator (if any).
     */
    function _issue(
        address operator,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    )
    internal nonReentrant
    {
        uint256 blackHoleBalance = _balances[address(0)];
        uint256 totalSupplyNow = _totalSupply;

        _setCheckpoint(tokenBalances[address(0)], blackHoleBalance.add(value));
        _setCheckpoint(tokensTotal, totalSupplyNow.add(value));

        ERC777._issue(operator, to, value, data, operatorData);

        emit Transfer(address(0), to, value); // ERC20 backwards compatibility
    }

    /**
     * [OVERRIDES ERC777 METHOD]
     * @dev Perform the transfer of tokens.
     * @param operator The address performing the transfer.
     * @param from Token holder.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer.
     * @param operatorData Information attached to the transfer by the operator (if any).
     * @param preventLocking 'true' if you want this function to throw when tokens are sent to a contract not
     * implementing 'erc777tokenHolder'.
     * ERC777 native transfer functions MUST set this parameter to 'true', and backwards compatible ERC20 transfer
     * functions SHOULD set this parameter to 'false'.
     */
    function _transferWithData(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData,
        bool preventLocking
    )
    internal
    {
        uint256 fromBalance = _balances[from];
        uint256 toBalance = _balances[to];

        _setCheckpoint(tokenBalances[from], fromBalance.sub(value));
        _setCheckpoint(tokenBalances[to], toBalance.add(value));

        ERC777._transferWithData(operator, from, to, value, data, operatorData, preventLocking);

        emit Transfer(from, to, value);
    }
}
