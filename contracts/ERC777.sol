pragma solidity 0.5.16;

import "./libs/Ownable.sol";
import "./libs/ReentrancyGuard.sol";
import "./libs/SafeMath.sol";
import "./ERC1820/ERC1820Client.sol";
import "./Certificate/CertificateController.sol";
import "./ERC777/IERC777.sol";
import "./ERC777/IERC777TokensRecipient.sol";
import "./ERC777/IERC777TokensSender.sol";

/**
 * @title ERC777
 * @dev ERC777 logic
 */
contract ERC777 is IERC777, Ownable, ERC1820Client, CertificateController, ReentrancyGuard {
    using SafeMath for uint256;

    string internal _name;
    string internal _symbol;
    uint256 internal _granularity;
    uint256 internal _totalSupply;

    // Indicate whether the token can still be controlled by operators or not anymore.
    bool internal _isControllable;

    // Mapping from tokenHolder to balance.
    mapping(address => uint256) internal _balances;

    /******************** Mappings related to operator **************************/
    // Mapping from (operator, tokenHolder) to authorized status. [TOKEN-HOLDER-SPECIFIC]
    mapping(address => mapping(address => bool)) internal _authorizedOperator;

    // Array of controllers. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
    address[] internal _controllers;

    // Mapping from operator to controller status. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
    mapping(address => bool) internal _isController;
    /****************************************************************************/

    /**
     * [ERC777 CONSTRUCTOR]
     * @dev Initialize ERC777 and CertificateController parameters + register
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
    CertificateController(certificateSigner)
    {
        _name = name;
        _symbol = symbol;
        _totalSupply = 0;
        require(granularity >= 1, "Constructor Blocked - Token granularity can not be lower than 1");
        _granularity = granularity;

        _setControllers(controllers);

        setInterfaceImplementation("ERC777Token", address(this));
    }

    /********************** ERC777 EXTERNAL FUNCTIONS ***************************/

    /**
     * [ERC777 INTERFACE (1/13)]
     * @dev Get the name of the token, e.g., "MyToken".
     * @return Name of the token.
     */
    function name() external view returns(string memory) {
        return _name;
    }

    /**
     * [ERC777 INTERFACE (2/13)]
     * @dev Get the symbol of the token, e.g., "MYT".
     * @return Symbol of the token.
     */
    function symbol() external view returns(string memory) {
        return _symbol;
    }

    /**
     * [ERC777 INTERFACE (3/13)]
     * @dev Get the total number of issued tokens.
     * @return Total supply of tokens currently in circulation.
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * [ERC777 INTERFACE (4/13)]
     * @dev Get the balance of the account with address 'tokenHolder'.
     * @param tokenHolder Address for which the balance is returned.
     * @return Amount of token held by 'tokenHolder' in the token contract.
     */
    function balanceOf(address tokenHolder) external view returns (uint256) {
        return _balances[tokenHolder];
    }

    /**
     * [ERC777 INTERFACE (5/13)]
     * @dev Get the smallest part of the token that’s not divisible.
     * @return The smallest non-divisible part of the token.
     */
    function granularity() external view returns(uint256) {
        return _granularity;
    }

    /**
     * [ERC777 INTERFACE (6/13)]
     * @dev Get the list of controllers as defined by the token contract.
     * @return List of addresses of all the controllers.
     */
    function controllers() external view returns (address[] memory) {
        return _controllers;
    }

    /**
     * [ERC777 INTERFACE (7/13)]
     * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
     * and redeem tokens on its behalf.
     * @param operator Address to set as an operator for 'msg.sender'.
     */
    function authorizeOperator(address operator) external {
        _authorizedOperator[operator][msg.sender] = true;
        emit AuthorizedOperator(operator, msg.sender);
    }

    /**
     * [ERC777 INTERFACE (8/13)]
     * @dev Remove the right of the operator address to be an operator for 'msg.sender'
     * and to transfer and redeem tokens on its behalf.
     * @param operator Address to rescind as an operator for 'msg.sender'.
     */
    function revokeOperator(address operator) external {
        _authorizedOperator[operator][msg.sender] = false;
        emit RevokedOperator(operator, msg.sender);
    }

    /**
     * [ERC777 INTERFACE (9/13)]
     * @dev Indicate whether the operator address is an operator of the tokenHolder address.
     * @param operator Address which may be an operator of tokenHolder.
     * @param tokenHolder Address of a token holder which may have the operator address as an operator.
     * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool) {
        return _isOperatorFor(operator, tokenHolder);
    }

    /**
     * [ERC777 INTERFACE (10/13)]
     * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function transferWithData(address to, uint256 value, bytes calldata data)
    external
    isValidCertificate(data, 0x2535f762)
    {
        _transferWithData(msg.sender, msg.sender, to, value, data, "", true);
    }

    /**
     * [ERC777 INTERFACE (11/13)]
     * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
     * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, and intended for the token holder ('from').
     * @param operatorData Information attached to the transfer by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData)
    external
    isValidCertificate(operatorData, 0x868d5383)
    {
        address _from = (from == address(0)) ? msg.sender : from;
        require(_isOperatorFor(msg.sender, _from), "A7: Transfer Blocked - Identity restriction");
        _transferWithData(msg.sender, _from, to, value, data, operatorData, true);
    }

    /**
     * [ERC777 INTERFACE (12/13)]
     * @dev Redeem the amount of tokens from the address 'msg.sender'.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function redeem(uint256 value, bytes calldata data)
    external
    isValidCertificate(data, 0xe77c646d)
    {
        _redeem(msg.sender, msg.sender, value, data, "");
    }

    /**
     * [ERC777 INTERFACE (13/13)]
     * @dev Redeem the amount of tokens on behalf of the address from.
     * @param from Token holder whose tokens will be redeemed (or address(0) to set from to msg.sender).
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData)
    external
    isValidCertificate(operatorData, 0xffa90f7f)
    {
        address _from = (from == address(0)) ? msg.sender : from;
        require(_isOperatorFor(msg.sender, _from), "A7: Transfer Blocked - Identity restriction");
        _redeem(msg.sender, _from, value, data, operatorData);
    }

    /********************** ERC777 INTERNAL FUNCTIONS ***************************/

    /**
     * [INTERNAL]
     * @dev Check if 'value' is multiple of the granularity.
     * @param value The quantity that want's to be checked.
     * @return 'true' if 'value' is a multiple of the granularity.
     */
    function _isMultiple(uint256 value) internal view returns(bool) {
        return(value.div(_granularity).mul(_granularity) == value);
    }

    /**
     * [INTERNAL]
     * @dev Check whether an address is a regular address or not.
     * @param addr Address of the contract that has to be checked.
     * @return 'true' if 'addr' is a regular address (not a contract).
     */
    function _isRegularAddress(address addr) internal view returns(bool) {
        if (addr == address(0)) { return false; }
        uint size;
        assembly { size := extcodesize(addr) } // solhint-disable-line no-inline-assembly
        return size == 0;
    }

    /**
     * [INTERNAL]
     * @dev Indicate whether the operator address is an operator of the tokenHolder address.
     * @param operator Address which may be an operator of 'tokenHolder'.
     * @param tokenHolder Address of a token holder which may have the 'operator' address as an operator.
     * @return 'true' if 'operator' is an operator of 'tokenHolder' and 'false' otherwise.
     */
    function _isOperatorFor(address operator, address tokenHolder) internal view returns (bool) {
        return (operator == tokenHolder
            || _authorizedOperator[operator][tokenHolder]
            || (_isControllable && _isController[operator])
        );
    }

    /**
     * [INTERNAL]
     * @dev Perform the transfer of tokens.
     * @param operator The address performing the transfer.
     * @param from Token holder.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer.
     * @param operatorData Information attached to the transfer by the operator (if any)..
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
    nonReentrant
    {
        require(_isMultiple(value), "A9: Transfer Blocked - Token granularity");
        require(to != address(0), "A6: Transfer Blocked - Receiver not eligible");
        require(_balances[from] >= value, "A4: Transfer Blocked - Sender balance insufficient");

        _callSender(operator, from, to, value, data, operatorData);

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);

        _callRecipient(operator, from, to, value, data, operatorData, preventLocking);

        emit TransferWithData(operator, from, to, value, data, operatorData);
    }

    /**
     * [INTERNAL]
     * @dev Perform the token redemption.
     * @param operator The address performing the redemption.
     * @param from Token holder whose tokens will be redeemed.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption, by the operator (if any).
     */
    function _redeem(
        address operator,
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    )
    internal
    nonReentrant
    {
        require(_isMultiple(value), "A9: Transfer Blocked - Token granularity");
        require(from != address(0), "A5: Transfer Blocked - Sender not eligible");
        require(_balances[from] >= value, "A4: Transfer Blocked - Sender balance insufficient");

        _callSender(operator, from, address(0), value, data, operatorData);

        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);

        emit Redeemed(operator, from, value, data, operatorData);
    }

    /**
     * [INTERNAL]
     * @dev Check for 'ERC777TokensSender' hook on the sender and call it.
     * May throw according to 'preventLocking'.
     * @param operator Address which triggered the balance decrease (through transfer or redemption).
     * @param from Token holder.
     * @param to Token recipient for a transfer and 0x for a redemption.
     * @param value Number of tokens the token holder balance is decreased by.
     * @param data Extra information.
     * @param operatorData Extra information, attached by the operator (if any).
     */
    function _callSender(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    )
    internal
    {
        address senderImplementation;
        senderImplementation = interfaceAddr(from, "ERC777TokensSender");

        if (senderImplementation != address(0)) {
            IERC777TokensSender(senderImplementation).tokensToTransfer(operator, from, to, value, data, operatorData);
        }
    }

    /**
     * [INTERNAL]
     * @dev Check for 'ERC777TokensRecipient' hook on the recipient and call it.
     * May throw according to 'preventLocking'.
     * @param operator Address which triggered the balance increase (through transfer or issuance).
     * @param from Token holder for a transfer and 0x for an issuance.
     * @param to Token recipient.
     * @param value Number of tokens the recipient balance is increased by.
     * @param data Extra information, intended for the token holder ('from').
     * @param operatorData Extra information attached by the operator (if any).
     * @param preventLocking 'true' if you want this function to throw when tokens are sent to a contract not
     * implementing 'ERC777TokensRecipient'.
     * ERC777 native transfer functions MUST set this parameter to 'true', and backwards compatible ERC20 transfer
     * functions SHOULD set this parameter to 'false'.
     */
    function _callRecipient(
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
        address recipientImplementation;
            recipientImplementation = interfaceAddr(to, "ERC777TokensRecipient");

        if (recipientImplementation != address(0)) {
            IERC777TokensRecipient(recipientImplementation).tokensReceived(operator, from, to, value, data, operatorData);
        } else if (preventLocking) {
            require(_isRegularAddress(to), "A6: Transfer Blocked - Receiver not eligible");
        }
    }

    /**
     * [INTERNAL]
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
        require(_isMultiple(value), "A9: Transfer Blocked - Token granularity");
        require(to != address(0), "A6: Transfer Blocked - Receiver not eligible");

        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);

        _callRecipient(operator, address(0), to, value, data, operatorData, true);

        emit Issued(operator, to, value, data, operatorData);
    }

    /********************** ERC777 OPTIONAL FUNCTIONS ***************************/

    /**
     * [NOT MANDATORY FOR ERC777 STANDARD]
     * @dev Set list of token controllers.
     * @param operators Controller addresses.
     */
    function _setControllers(address[] memory operators) internal {
        for (uint i = 0; i<_controllers.length; i++){
            _isController[_controllers[i]] = false;
        }
        for (uint j = 0; j<operators.length; j++){
            _isController[operators[j]] = true;
        }
        _controllers = operators;
    }
}
