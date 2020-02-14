pragma solidity 0.5.16;

import "./CertificateBase.sol";

contract CertificateController is CertificateBase {

    /**
     * @dev Modifier to protect methods with certificate control
     */
    modifier isValidCertificate(bytes memory data, bytes4 _functionId) {
        require(_certificateSigners[msg.sender]
            || _checkCertificate(data, _functionId), "Transfer Blocked - Sender lockup period not ended");

        _checkCount[msg.sender] += 1; // Increment sender check count

        emit Checked(msg.sender);
        _;
    }

    constructor(address _certificateSigner) public CertificateBase(_certificateSigner) {}

    /**
     * @dev Get number of transations already sent to this contract by the sender
     * @param sender Address whom to check the counter of.
     * @return uint256 Number of transaction already sent to this contract.
     */
    function checkCount(address sender) external view returns (uint256) {
        return _checkCount[sender];
    }

    /**
     * @dev Get certificate signer authorization for an operator.
     * @param operator Address whom to check the certificate signer authorization for.
     * @return bool 'true' if operator is authorized as certificate signer, 'false' if not.
     */
    function certificateSigners(address operator) external view returns (bool) {
        return _certificateSigners[operator];
    }
}
