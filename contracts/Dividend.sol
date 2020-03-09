pragma solidity 0.5.16;

import "./CheckPoint/ICheckPoint.sol";
import "./Certificate/CertificateController.sol";
import "./libs/Ownable.sol";
import "./libs/SafeMath.sol";

/**
 * @title Dividend
 * @dev Dividend with CertificateController
 */
contract Dividend is CertificateController, Ownable {
    using SafeMath for uint256;

    struct Deposit {
        address operator;
        uint blockNumber;
        uint depositedAmount;
        uint claimedAmount;
    }

    struct Claim {
        uint claimedCount;
        uint claimedAmount;
    }

    ICheckPoint public token;

    mapping(uint => Deposit) public deposits; // depositCount => Deposit
    mapping(address => Claim) public claims; // address => Claim

    uint public totalDepositCount;
    uint public claimableCount;
    bool public claimable;

    modifier isClaimable() {
        require(claimable, "Action Blocked - Not Claimable");
        _;
    }

    event Deposited(address indexed operator, uint256 amount);
    event Claimed(address indexed operator, uint256 amount);

    /**
    * [Dividend CONSTRUCTOR]
    * @dev Initialize Dividend.
    * @param _token CheckPoint.
    * @param _certificateSigner Address of the off-chain service which signs the
    * conditional ownership certificates required for token transfers, issuance,
    * redemption (Cf. CertificateController.sol).
    */
    constructor(
        ICheckPoint _token,
        address _certificateSigner
    )
    public
    CertificateController(_certificateSigner)
    {
        token = _token;
        claimable = false;
    }

    /**
    * payable function to deposit
    */
    function () payable external {
        deposits[totalDepositCount] = Deposit({
            operator: msg.sender,
            blockNumber: block.number,
            depositedAmount: msg.value,
            claimedAmount: 0
        });

        totalDepositCount ++;

        emit Deposited(msg.sender, msg.value);
    }

    /**************************** PUBLIC FUNCTIONS *************************************/

    /**
    * @dev start claim
    */
    function start() external onlyOwner {
        _setClaimableCount(totalDepositCount);
        claimable = true;
    }

    /**
    * @dev stop claim
    */
    function stop() external onlyOwner {
        claimable = false;
    }

    /**
    * @dev claim divided
    * @param data Information attached to the claim, by the claimer. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
    * @return claimAmount uint
    */
    function claim(bytes calldata data)
    external
    isClaimable
    isValidCertificate(data)
    payable
    returns (uint256)
    {
        return _claim(msg.sender);
    }

    /**************************** OPTIONAL FUNCTIONS *************************************/

    /**
    * @dev get claim amount
    * @dev _operator Address
    * @return claimAmount uint256
    */
    function getClaimAmount(address _operator) external view returns(uint256) {
        return _getClaimAmount(_operator);
    }

    /**
    * @dev get claim amount at count
    * @dev _operator Address
    * @dev _count uint256
    * @return claimAmount uint256
    */
    function getClaimAmountAt(address _operator, uint256 _count) external view returns(uint256) {

        return _getClaimAmountAt(_operator, _count);
    }

    /**
    * @dev set claimable count
    * @param _count uint256
    * @return true
    */
    function setClaimableCount(uint256 _count) external onlyOwner returns(bool) {
        return _setClaimableCount(_count);
    }

    /**************************** INTERNAL FUNCTIONS *************************************/

    /**
    * [INTERNAL]
    * @dev set claimable count
    * @dev _count uint256
    * @return true
    */
    function _setClaimableCount(uint256 _count) internal returns(bool) {
        require(totalDepositCount >= _count && _count > claimableCount, "Action Blocked - Invalid Count");
        claimableCount = _count;
        return true;
    }

    /**
    * [INTERNAL]
    * @dev claim
    * @param _operator address
    * @return claimAmount uint256
    */
    function _claim (address payable _operator) internal returns(uint256) {
        require(_operator != address(0), "Transfer Blocked - Operator not eligible");

        uint256 totalClaimAmount;
        uint256 claimedCount = claims[_operator].claimedCount;
        uint256 claimAmountAt;

        require(claimedCount < claimableCount, "Action Blocked - Already Claimed");

        for (uint i = claimedCount; i < claimableCount; i++){
            claimAmountAt = _getClaimAmountAt(_operator, i);
            deposits[i].claimedAmount = deposits[i].claimedAmount.add(claimAmountAt);
            claims[_operator].claimedAmount = claims[_operator].claimedAmount.add(claimAmountAt);
            totalClaimAmount = totalClaimAmount.add(claimAmountAt);
        }

        require(totalClaimAmount > 0, "Action Blocked - Insufficient balance");

        claims[_operator].claimedCount = claimableCount;

        _operator.transfer(totalClaimAmount);

        emit Claimed(_operator, totalClaimAmount);

        return totalClaimAmount;
    }

    /**
    * [INTERNAL]
    * @dev get claim amount
    * @dev _operator Address
    * @return claimAmount uint256
    */
    function _getClaimAmount(address _operator) internal view returns(uint256) {
        uint256 claimAmount;
        uint256 claimedCount = claims[_operator].claimedCount;

        if(claimableCount <= claimedCount) {
            return 0;
        }

        for (uint i = claimedCount; i < claimableCount; i++){
            claimAmount = claimAmount.add(_getClaimAmountAt(_operator, i));
        }

        return claimAmount;
    }

    /**
    * [INTERNAL]
    * @dev get claim amount at count
    * @dev _operator Address
    * @dev _count uint256
    * @return claimAmount uint256
    */
    function _getClaimAmountAt(address _operator, uint256 _count) internal view returns(uint256) {

        uint256 totalSupplyAt;
        uint256 balanceAt;

        totalSupplyAt = token.totalSupplyAt(deposits[_count].blockNumber);

        balanceAt = token.balanceAt(_operator, deposits[_count].blockNumber);

        return deposits[_count].depositedAmount.mul(balanceAt).div(totalSupplyAt);
    }

    /**************************** Certification Controller *************************************/

    /**
    * @dev Add a certificate signer for the token.
    * @param operator Address to set as a certificate signer.
    * @param authorized 'true' if operator shall be accepted as certificate signer, 'false' if not.
    */
    function setCertificateSigner(address operator, bool authorized) external onlyOwner {
        _setCertificateSigner(operator, authorized);
    }
}
