pragma solidity 0.5.16;

import "./libs/MinterRole.sol";
import "./ERC1400/IERC1400.sol";

/**
 * @title ERC1400
 * @dev ERC1400 logic
 */
contract ERC1400 is IERC1400, MinterRole {

    struct Doc {
        string docURI;
        bytes32 docHash;
    }

    // Mapping for token URIs.
    mapping(bytes32 => Doc) internal _documents;

    // Indicate whether the token can still be issued by the issuer or not anymore.
    bool internal _isIssuable;

    /**
     * @dev Modifier to verify if token is issuable.
     */
    modifier issuableToken() {
        require(_isIssuable, "A8, Transfer Blocked - Token restriction");
        _;
    }

    /**
     * [ERC1400 CONSTRUCTOR]
     * @dev Initialize ERC1400 + register
     * the contract implementation in ERC820Registry.
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
    ERC1410(name, symbol, granularity, controllers, certificateSigner)
    {
        setInterfaceImplementation("ERC1400Token", address(this));
        _isControllable = true;
        _isIssuable = true;
    }

    /********************** ERC1400 EXTERNAL FUNCTIONS **************************/

    /**
     * [ERC1400 INTERFACE (1/9)]
     * @dev Access a document associated with the token.
     * @param name Short name (represented as a bytes32) associated to the document.
     * @return Requested document + document hash.
     */
    function getDocument(bytes32 name) external view returns (string memory, bytes32) {
        require(bytes(_documents[name].docURI).length != 0, "Action Blocked - Empty document");
        return (
        _documents[name].docURI,
        _documents[name].docHash
        );
    }

    /**
     * [ERC1400 INTERFACE (2/9)]
     * @dev Associate a document with the token.
     * @param name Short name (represented as a bytes32) associated to the document.
     * @param uri Document content.
     * @param documentHash Hash of the document [optional parameter].
     */
    function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external onlyOwner {
        _documents[name] = Doc({
            docURI: uri,
            docHash: documentHash
            });
        emit Document(name, uri, documentHash);
    }

    /**
     * [ERC1400 INTERFACE (3/9)]
     * @dev Know if the token can be controlled by operators.
     * If a token returns 'false' for 'isControllable()'' then it MUST always return 'false' in the future.
     * @return bool 'true' if the token can still be controlled by operators, 'false' if it can't anymore.
     */
    function isControllable() external view returns (bool) {
        return _isControllable;
    }

    /**
     * [ERC1400 INTERFACE (4/9)]
     * @dev Know if new tokens can be issued in the future.
     * @return bool 'true' if tokens can still be issued by the issuer, 'false' if they can't anymore.
     */
    function isIssuable() external view returns (bool) {
        return _isIssuable;
    }

    /********************** ERC1400 OPTIONAL FUNCTIONS **************************/

    /**
     * [NOT MANDATORY FOR ERC1400 STANDARD]
     * @dev Definitely renounce the possibility to control tokens on behalf of tokenHolders.
     * Once set to false, '_isControllable' can never be set to 'true' again.
     */
    function renounceControl() external onlyOwner {
        _isControllable = false;
    }

    /**
     * [NOT MANDATORY FOR ERC1400 STANDARD]
     * @dev Definitely renounce the possibility to issue new tokens.
     * Once set to false, '_isIssuable' can never be set to 'true' again.
     */
    function renounceIssuance() external onlyOwner {
        _isIssuable = false;
    }

    /**
     * [NOT MANDATORY FOR ERC1400 STANDARD]
     * @dev Set list of token controllers.
     * @param operators Controller addresses.
     */
    function setControllers(address[] calldata operators) external onlyOwner {
        _setControllers(operators);
    }

    /**
    * @dev Add a certificate signer for the token.
    * @param operator Address to set as a certificate signer.
    * @param authorized 'true' if operator shall be accepted as certificate signer, 'false' if not.
    */
    function setCertificateSigner(address operator, bool authorized) external onlyOwner {
        _setCertificateSigner(operator, authorized);
    }
}
