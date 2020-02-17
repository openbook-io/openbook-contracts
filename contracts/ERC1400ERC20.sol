pragma solidity 0.5.16;

import "./ERC20/IERC20.sol";

import "./ERC1400.sol";


/**
 * @title ERC1400ERC20
 * @dev ERC1400 with ERC20 retrocompatibility
 */
contract ERC1400ERC20 is IERC20, ERC1400 {

    // Mapping from (tokenHolder, spender) to allowed value.
    mapping (address => mapping (address => uint256)) internal _allowed;

    // Mapping from (tokenHolder) to whitelisted status.
    mapping (address => bool) internal _whitelisted;

    /**
     * @dev Modifier to verify if sender and recipient are whitelisted.
     */
    modifier areWhitelisted(address sender, address recipient) {
        require(_whitelisted[sender], "A5"); // Transfer Blocked - Sender not eligible
        require(_whitelisted[recipient], "A6"); // Transfer Blocked - Receiver not eligible
        _;
    }

    /**
     * [ERC1400ERC20 CONSTRUCTOR]
     * @dev Initialize ERC71400ERC20 and CertificateController parameters + register
     * the contract implementation in ERC1820Registry.
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
    ERC1400(name, symbol, granularity, controllers, certificateSigner)
    {
        setInterfaceImplementation("ERC20Token", address(this));
    }

    /**
     * [OVERRIDES ERC1400 METHOD]
     * @dev Get the number of decimals of the token.
     * @return The number of decimals of the token. For Backwards compatibility, decimals are forced to 18 in ERC1400Raw.
     */
    function decimals() external pure returns(uint8) {
        return uint8(18);
    }

    /**
     * [NOT MANDATORY FOR ERC1400 STANDARD]
     * @dev Check the value of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the value of tokens still available for the spender.
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * [NOT MANDATORY FOR ERC1400 STANDARD]
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of 'msg.sender'.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean that indicates if the operation was successful.
     */
    function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0), "A5"); // Transfer Blocked - Sender not eligible
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * [NOT MANDATORY FOR ERC1400 STANDARD]
     * @dev Transfer token for a specified address.
     * @param to The address to transfer to.
     * @param value The value to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transfer(address to, uint256 value) external areWhitelisted(msg.sender, to) returns (bool) {
        ERC777._transferWithData(msg.sender, msg.sender, to, value, "", "", false);
        return true;
    }

    /**
     * [NOT MANDATORY FOR ERC1400 STANDARD]
     * @dev Transfer tokens from one address to another.
     * @param from The address which you want to transfer tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(address from, address to, uint256 value) external areWhitelisted(from, to) returns (bool) {
        require( _isOperatorFor(msg.sender, from)
            || (value <= _allowed[from][msg.sender]), "A7"); // Transfer Blocked - Identity restriction

        if(_allowed[from][msg.sender] >= value) {
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        } else {
            _allowed[from][msg.sender] = 0;
        }

        ERC777._transferWithData(msg.sender, from, to, value, "", "", false);
        return true;
    }

    /***************** ERC1400ERC20 OPTIONAL FUNCTIONS ***************************/

    /**
     * [NOT MANDATORY FOR ERC1400ERC20 STANDARD]
     * @dev Get whitelisted status for a tokenHolder.
     * @param tokenHolder Address whom to check the whitelisted status for.
     * @return bool 'true' if tokenHolder is whitelisted, 'false' if not.
     */
    function whitelisted(address tokenHolder) external view returns (bool) {
        return _whitelisted[tokenHolder];
    }

    /**
     * [NOT MANDATORY FOR ERC1400ERC20 STANDARD]
     * @dev Set whitelisted status for a tokenHolder.
     * @param tokenHolder Address to add/remove from whitelist.
     * @param authorized 'true' if tokenHolder shall be added to whitelist, 'false' if not.
     */
    function setWhitelisted(address tokenHolder, bool authorized) external {
        require(_isController[msg.sender]);
        _setWhitelisted(tokenHolder, authorized);
    }

    /**
     * [NOT MANDATORY FOR ERC1400ERC20 STANDARD]
     * @dev Set whitelisted status for a tokenHolder.
     * @param tokenHolder Address to add/remove from whitelist.
     * @param authorized 'true' if tokenHolder shall be added to whitelist, 'false' if not.
     */
    function _setWhitelisted(address tokenHolder, bool authorized) internal {
        require(tokenHolder != address(0)); // Action Blocked - Not a valid address
        _whitelisted[tokenHolder] = authorized;
    }

    /****************************** OVERRIDES ERC777 METHODS *************************************/

    /**
    * [OVERRIDES ERC777 METHOD]
    * @dev Perform the token redemption.
    * @param operator The address performing the redemption.
    * @param from Token holder whose tokens will be redeemed.
    * @param value Number of tokens to redeem.
    * @param data Information attached to the redemption.
    * @param operatorData Information attached to the redemption by the operator (if any).
    */
    function _redeem(address operator, address from, uint256 value, bytes memory data, bytes memory operatorData) internal {
        ERC777._redeem(operator, from, value, data, operatorData);

        emit Transfer(from, address(0), value);  //  ERC20 backwards compatibility
    }
}
