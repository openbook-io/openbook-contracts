pragma solidity 0.5.16;

contract CertificateBase {

    // Address used by off-chain controller service to sign certificate
    mapping(address => bool) internal _certificateSigners;
    mapping(address => uint256) internal _checkCount;
    // signature size is 65 bytes (tightly packed v + r + s), but gets padded to 96 bytes
    uint internal constant SIGNATURE_SIZE = 96;

    event Checked(address sender);

    constructor(address _certificateSigner) public {
        _setCertificateSigner(_certificateSigner, true);
    }

    /**
    * @dev Set signer authorization for operator.
    * @param operator Address to add/remove as a certificate signer.
    * @param authorized 'true' if operator shall be accepted as certificate signer, 'false' if not.
    */
    function _setCertificateSigner(address operator, bool authorized) internal {
        require(operator != address(0), "Action Blocked - Not a valid address");
        _certificateSigners[operator] = authorized;
    }

    function _checkCertificate(bytes memory _data, bytes4 _function) internal view returns(bool) {
        bytes memory sig = _extractBytes(_data, 0, 65);    // signature generated on offchain
        bytes memory expHex = _extractBytes(_data, 65, 4); // expiration timestamp in Hex;
        uint expUnix = _bytesToUint(expHex);               // expiration timestamp in Unix;

        // params data, first 4 bytes is functionId
        bytes memory data = _extractBytes(msg.data, 0, (msg.data.length - SIGNATURE_SIZE));

        require(expUnix > now, 'Certificate Expired');

        bytes32 txHash = _getSignHash(_getPreSignedHash(_function, data, address(this), expUnix, _checkCount[msg.sender]));

        address recovered = _ecrecoverFromSig(txHash, sig);

        return _certificateSigners[recovered];
    }

    function _ecrecoverFromSig(bytes32 hash, bytes memory sig) internal pure returns (address recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return ecrecover(hash, v, r, s);
    }

    function _getPreSignedHash(
        bytes4 _function, bytes memory _data, address _address, uint _expiration, uint _nonce) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_function, _data, _address, _expiration, _nonce));
    }

    function _getSignHash(bytes32 _hash) internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    function _getRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        return ecrecover(hash, v, r, s);
    }

    function getFunctionId(string calldata _function) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(_function));
    }

    function _getStringHash(string memory _str) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_str));
    }

    function _extractBytes(bytes memory _data, uint _pos, uint _length) internal pure returns(bytes memory) {
        bytes memory result = new bytes(_length);
        for(uint i = 0;i< _length; i++) {
            result[i] = _data[_pos + i];
        }
        return result;
    }

    function _bytesToUint(bytes memory _data) internal pure returns(uint256){
        uint256 number;
        for(uint i=0;i<_data.length;i++){
            number = number + uint8(_data[i])*(2**(8*(_data.length-(i+1))));
        }
        return number;
    }
}
