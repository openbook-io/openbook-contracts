pragma solidity 0.5.16;

import "./CheckPointToken/ICheckPointToken.sol";
import "./Certificate/CertificateController.sol";
import "./libs/Ownable.sol";
import "./libs/SafeMath.sol";

contract Dividend is CertificateController, Ownable {
    using SafeMath for uint256;

    ICheckPointToken token;

    mapping(uint => uint) balances;

    constructor(ICheckPointToken _token) public {
        token = _token;
    }

    function () payable external {
        balances[block.number] = msg.value;
    }

    function start() external onlyOwner {

    }

    function stop() external onlyOwner {

    }

    function claim(uint256 value, bytes calldata data) external {

    }

    function _getClaimAmount() internal returns(uint){
        return 0;
    }
}
