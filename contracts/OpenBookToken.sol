pragma solidity 0.5.16;

import "./libs/MinterRole.sol";
import "./CheckPointToken.sol";

contract OpenBookToken is CheckPointToken, MinterRole {
    /**
     * [OpenBookToken CONSTRUCTOR]
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
    CheckPointToken(name, symbol, granularity, controllers, certificateSigner)
    {}

    /**
     * @dev Issue tokens.
     * @param tokenHolder Address for which we want to issue tokens.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance, by the issuer. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function issue(address tokenHolder, uint256 value, bytes calldata data)
    external
    onlyMinter
    issuableToken
    isValidCertificate(data, 0xbb3acde9)
    {
        _issue(msg.sender, tokenHolder, value, data, "");
    }
}
