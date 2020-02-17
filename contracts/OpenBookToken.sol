pragma solidity 0.5.16;

import "./libs/MinterRole.sol";
import "./libs/DateTime.sol";
import "./CheckPointToken.sol";

contract OpenBookToken is CheckPointToken, MinterRole, DateTime {

    uint public maximumTotalSupply = 100000000;
    uint8 public issuableRate = 10;
    uint16 _lastYearIssuedAt;
    uint16 _currentYearIssuedAt;

    mapping (uint16 => uint) public yearTotalSupplies;
    mapping (address => bool) _whitelisted;

    /**
    * @dev Modifier to verify if token is issuable.
    */
    modifier issuableToken() {
        require(_isIssuable, "A8, Transfer Blocked - Token restriction");
        _;
    }

    event Whitelisted(address indexed who, bool authorized);

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

    /**************************  EXTERNAL FUNCTIONS ***************************/

    function isWhitelisted(address who) external view returns(bool) {
        return _whitelisted[who];
    }

    /**
     * @dev Set whitelisted status for a tokenHolder.
     * @param tokenHolder Address to add/remove from whitelist.
     * @param authorized 'true' if tokenHolder shall be added to whitelist, 'false' if not.
     */
    function setWhitelisted(address tokenHolder, bool authorized) external onlyOwner {
        _setWhitelisted(tokenHolder, authorized);
    }

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
        uint16 currentYear = getYear(now);

        if(_currentYearIssuedAt < currentYear) {
            _lastYearIssuedAt = _currentYearIssuedAt;
        }

        // calculate totalSupply to be able to issue this year
        uint limitedTotalSupply = yearTotalSupplies[_lastYearIssuedAt].mul(issuableRate + 100) / 100;

        // totalSupply equals or less than maximumTotalSupply
        require(maximumTotalSupply >= _totalSupply.add(value), "A8, Transfer Blocked - Max TotalSupply Limited");

        // available totalSupply (this year) equals or less than totalSupply + 10 percent (last year)
        require(limitedTotalSupply == 0 || limitedTotalSupply >= _totalSupply.add(value),
            "A8, Transfer Blocked - Year TotalSupply Limited");

        // issue Tokens internally
        _issue(msg.sender, tokenHolder, value, data, "");

        // save TotalSupply to the mapping data according to year
        yearTotalSupplies[currentYear] = _totalSupply;

        // save current year issued
        _currentYearIssuedAt = currentYear;
    }

    /**************************  INTERNAL FUNCTIONS ***************************/

    /**
     * [INTERNAL]
     * @dev Set whitelisted status for a tokenHolder.
     * @param tokenHolder Address to add/remove from whitelist.
     * @param authorized 'true' if tokenHolder shall be added to whitelist, 'false' if not.
     */
    function _setWhitelisted(address tokenHolder, bool authorized) internal {
        require(tokenHolder != address(0), "Action Blocked - Not a valid address");
        if(_whitelisted[tokenHolder] != authorized) {
            _whitelisted[tokenHolder] = authorized;

            emit Whitelisted(tokenHolder, authorized);
        }
    }

    /************************* OVERRIDES ERC777 METHODS *****************************/

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

        require(_whitelisted[to], "A3: Transfer Blocked - Recipient not whitelisted");

        ERC777._transferWithData(operator, from, to, value, data, operatorData, preventLocking);
    }
}
