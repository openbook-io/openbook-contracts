pragma solidity 0.5.16;

import "./libs/MinterRole.sol";
import "./libs/DateTime.sol";
import "./CheckPoint.sol";

/**
 * @title OpenBookToken
 * @dev OpenBookToken with CheckPointToken
 */
contract OpenBookToken is CheckPoint, MinterRole, DateTime {

    uint public maximumTotalSupply = 100000000;
    uint8 public issuableRate = 10;
    uint16 _lastYearIssuedAt;
    uint16 _currentYearIssuedAt;

    mapping (uint16 => uint) public totalSuppliesPerYear;

    /**
    * @dev Modifier to verify if token is issuable.
    */
    modifier issuableToken() {
        require(_isIssuable, "A8, Transfer Blocked - Token restriction");
        _;
    }


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
    CheckPoint(name, symbol, granularity, controllers, certificateSigner)
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
        uint16 currentYear = getYear(now);

        if(_currentYearIssuedAt < currentYear) {
            _lastYearIssuedAt = _currentYearIssuedAt;
        }

        // calculate totalSupply to be able to issue
        uint limitedTotalSupply = totalSuppliesPerYear[_lastYearIssuedAt].mul(issuableRate + 100) / 100;

        // totalSupply equals or less than maximumTotalSupply
        require(maximumTotalSupply >= _totalSupply.add(value), "A8, Transfer Blocked - Max TotalSupply Limited");

        // available totalSupply equals or less than (totalSupply + 10 percent) of last year
        require(limitedTotalSupply == 0 || limitedTotalSupply >= _totalSupply.add(value),
            "A8, Transfer Blocked - Year TotalSupply Limited");

        // issue tokens
        _issue(msg.sender, tokenHolder, value, data, "");

        // save totalSupply of current year
        totalSuppliesPerYear[currentYear] = _totalSupply;

        // update current year
        _currentYearIssuedAt = currentYear;
    }
}
