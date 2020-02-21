pragma solidity 0.5.16;

import "./CheckPointToken/ICheckPointToken.sol";
import "./Certificate/CertificateController.sol";
import "./libs/Ownable.sol";
import "./libs/SafeMath.sol";

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

    ICheckPointToken token;

    mapping(uint => Deposit) deposits; // depositCount => Deposit
    mapping(address => Claim) claims; // address => Claim

    uint public totalDepositCount;
    uint public claimableCount;
    bool claimable;

    modifier isClaimable() {
        require(claimable, "Action Blocked - Not Claimable");
        _;
    }

    event Deposited(address indexed operator, uint amount);
    event Claimed(address indexed operator, uint amount);

    constructor(ICheckPointToken _token) public {
        token = _token;
        claimable = false;
    }

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

    function start() external onlyOwner {
        claimableCount = totalDepositCount;
        claimable = true;
    }

    function stop() external onlyOwner {
        claimable = false;
    }

    function claim(bytes calldata data) external isClaimable returns(uint) {
        return _claim(msg.sender);
    }

    function getClaimAmount(address _operator) internal returns(uint) {
        return _getClaimAmount(_operator);
    }

    /**************************** INTERNAL FUNCTIONS *************************************/

    function _claim (address _operator) internal returns(uint) {
        uint claimAmount = _getClaimAmount(_operator);

        require(claimAmount > 0, "Action Blocked - Already Claimed");
        require(address(this).balance >= claimAmount, "Action Blocked - Insufficient Balance");

        address(this).transfer(claimAmount);

        _setClaimLog(_operator);

        emit Claimed(_operator, claimAmount);

        return claimAmount;
    }

    function _getClaimAmount(address _operator) internal returns(uint) {
        uint claimAmount;
        uint claimedCount = claims[_operator].claimedCount;

        if(claimedCount >= claimableCount) {
            return 0;
        }

        for (uint i = claimedCount; i < claimableCount; i++){
            claimAmount.add(_getClaimAmountAt(_operator, i + 1));
        }

        return claimAmount;
    }

    function _getClaimAmountAt(address _operator, uint _count) internal returns(uint) {

        uint totalSupplyAt;
        uint balanceAt;

        totalSupplyAt = token.totalSupplyAt(deposits[_count].blockNumber);
        balanceAt = token.balanceAt(_operator, deposits[_count].blockNumber);

        return deposits[_count].depositedAmount.mul(balanceAt.div(totalSupplyAt));
    }

    function _setClaimLog(address _operator) internal returns(bool) {

        uint claimedCount = claims[_operator].claimedCount;
        uint claimAmountAt;

        for (uint i = claimedCount; i <= claimableCount; i++) {
            claimAmountAt = _getClaimAmountAt(_operator, i + 1);
            deposits[i].claimedAmount.add(claimAmountAt);
            claims[_operator].claimedAmount.add(claimAmountAt);
        }

        claims[_operator].claimedCount = claimableCount;

        return true;
    }
}
