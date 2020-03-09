pragma solidity 0.5.16;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}


/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <remco@2π.com>, Eenae <alexey@mixbytes.io>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

/**
 * @title DateTime
 * @dev Date and Time utilities contracts
 */
contract DateTime {
    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint year) public pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }


    function getYear(uint timestamp) public pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            }
            else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
contract IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title IERC777TokensSender
 * @dev ERC777TokensSender interface
 */
interface IERC777TokensSender {

    function canTransfer(
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns(bool);

    function tokensToTransfer(
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

}

/**
 * @title IERC777TokensRecipient
 * @dev ERC777TokensRecipient interface
 */
interface IERC777TokensRecipient {

    function canReceive(
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external view returns (bool);

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint value,
        bytes calldata data,
        bytes calldata operatorData
    ) external;
}

/**
 * @title IERC777 token standard
 * @dev ERC777 interface
 */
interface IERC777 {

    function name() external view returns (string memory); // 1/13
    function symbol() external view returns (string memory); // 2/13
    function totalSupply() external view returns (uint256); // 3/13
    function balanceOf(address owner) external view returns (uint256); // 4/13
    function granularity() external view returns (uint256); // 5/13

    function controllers() external view returns (address[] memory); // 6/13
    function authorizeOperator(address operator) external; // 7/13
    function revokeOperator(address operator) external; // 8/13
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool); // 9/13

    function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
    function transferFromWithData(
        address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

    function redeem(uint256 value, bytes calldata data) external; // 12/13
    function redeemFrom(
        address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13

    event TransferWithData(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data,
        bytes operatorData
    );
    event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
    event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

}

/**
 * @title ERC1400 security token standard
 * @dev Customized for OpenBook Business Logic
 */
interface IERC1400  {

    // Document Management
    function getDocument(bytes32 name) external view returns (string memory, bytes32); // 1/9
    function setDocument(bytes32 name, string calldata uri, bytes32 documentHash) external; // 2/9
    event Document(bytes32 indexed name, string uri, bytes32 documentHash);

    // Controller Operation
    function isControllable() external view returns (bool); // 3/9

    // Token Issuance
    function isIssuable() external view returns (bool); // 4/9
}

interface ICheckPoint {
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256);
    function balanceAt(address owner, uint256 blockNumber) external view returns (uint256);
}


contract ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) public view returns (address);
}

/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

contract CertificateBase {

    // Address used by off-chain controller service to sign certificate
    mapping(address => bool) internal _certificateSigners;
    mapping(address => uint256) internal _checkCount;
    // signature size is 65 bytes (tightly packed v + r + s), but gets padded to 96 bytes
    uint internal constant SIGNATURE_SIZE = 96;
    uint internal constant FUNCTION_ID_SIZE = 4; // 4 bytes

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

    function _checkCertificate(bytes memory _data) internal view returns(bool) {
        bytes memory sig = _extractBytes(_data, 0, 65);    // signature generated on offchain
        bytes memory expHex = _extractBytes(_data, 65, 4); // expiration timestamp in Hex;
        uint expUnix = _bytesToUint(expHex);               // expiration timestamp in Unix;

        // params data, first 4 bytes is functionId
        bytes memory data = _extractBytes(msg.data, 0, (msg.data.length - SIGNATURE_SIZE));
        bytes memory functionId = _extractBytes(msg.data, 0, FUNCTION_ID_SIZE);
        bytes32 txHash = _getSignHash(_getPreSignedHash(functionId, data, address(this), expUnix, _checkCount[msg.sender]));
        address recovered = _ecrecoverFromSig(txHash, sig);

        if(_certificateSigners[recovered]) {
            require(expUnix > now, 'Certificate Expired');
            return true;
        }
        return false;
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
        bytes memory _functionId, bytes memory _data, address _address, uint _expiration, uint _nonce) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(_functionId, _data, _address, _expiration, _nonce));
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

contract CertificateController is CertificateBase {

    /**
     * @dev Modifier to protect methods with certificate control
     */
    modifier isValidCertificate(bytes memory data) {
        require(_certificateSigners[msg.sender]
            || _checkCertificate(data), "Transfer Blocked - Sender lockup period not ended");

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
    isValidCertificate(data)
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
    isValidCertificate(operatorData)
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
    isValidCertificate(data)
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
    isValidCertificate(operatorData)
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

/**
 * @title ERC1400
 * @dev ERC1400 logic
 */
contract ERC1400 is IERC1400, ERC777 {

    struct Doc {
        string docURI;
        bytes32 docHash;
    }

    // Mapping for token URIs.
    mapping(bytes32 => Doc) internal _documents;

    // Indicate whether the token can still be issued by the issuer or not anymore.
    bool internal _isIssuable;

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
    ERC777(name, symbol, granularity, controllers, certificateSigner)
    {
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
        _transferWithData(msg.sender, msg.sender, to, value, "", "", false);
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

        _transferWithData(msg.sender, from, to, value, "", "", false);
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

contract CheckPoint is ICheckPoint, ERC1400ERC20  {

    /// @dev Checkpoint is the fundamental unit for our internal accounting
    /// (who owns what, and at what moment in time)
    struct Checkpoint {
        uint256 blockNumber;
        uint256 value;
    }

    /// @dev This mapping contains checkpoints for every address:
    mapping (address => Checkpoint[]) public tokenBalances;

    /// @dev This is a one dimensional Checkpoint mapping of the overall token supply:
    Checkpoint[] public tokensTotal;

    /**
     * [CheckpointToken CONSTRUCTOR]
     * @dev Initialize Checkpoint.
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
    ERC1400ERC20(name, symbol, granularity, controllers, certificateSigner)
    {}

    /**************************** EXTERNAL FUNCTIONS *************************************/

    /**
     * @dev total number of tokens in existence at the given block
     * @param blockNumber The block number we want to query for the total supply
     * @return A uint256 specifying the total number of tokens at a given block
     */
    function totalSupplyAt(uint256 blockNumber) external view returns (uint256) {
        return _balanceAtBlock(tokensTotal, blockNumber);
    }


    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the the balance of.
     * @param blockNumber The block number we want to query for the balance.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceAt(address owner, uint256 blockNumber) external view returns (uint256) {
        return _balanceAtBlock(tokenBalances[owner], blockNumber);
    }

    /**************************** INTERNAL FUNCTIONS *************************************/

    function _balanceAtBlock(Checkpoint[] storage checkpoints, uint256 blockNumber) internal view returns (
        uint256 balance
    ) {
        uint256 currentBlockNumber;
        (currentBlockNumber, balance) = _getCheckpoint(checkpoints, blockNumber);
    }

    function _setCheckpoint(Checkpoint[] storage checkpoints, uint256 newValue) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length.sub(1)].blockNumber < block.number)) {
            checkpoints.push(Checkpoint(block.number, newValue));
        } else {
            checkpoints[checkpoints.length.sub(1)] = Checkpoint(block.number, newValue);
        }
    }

    function _getCheckpoint(Checkpoint[] storage checkpoints, uint256 blockNumber) internal view returns (
        uint256 blockNumber_, uint256 value
    ) {
        if (checkpoints.length == 0) {
            return (0, 0);
        }

        // Shortcut for the actual value
        if (blockNumber >= checkpoints[checkpoints.length.sub(1)].blockNumber) {
            return (checkpoints[checkpoints.length.sub(1)].blockNumber, checkpoints[checkpoints.length.sub(1)].value);
        }

        if (blockNumber < checkpoints[0].blockNumber) {
            return (0, 0);
        }

        // Binary search of the value in the array
        uint256 min = 0;
        uint256 max = checkpoints.length.sub(1);
        while (max > min) {
            uint256 mid = (max.add(min.add(1))).div(2);
            if (checkpoints[mid].blockNumber <= blockNumber) {
                min = mid;
            } else {
                max = mid.sub(1);
            }
        }

        return (checkpoints[min].blockNumber, checkpoints[min].value);
    }

    /****************************** OVERRIDES ERC777 METHODS ************************************/

    /**
     * [OVERRIDES ERC777 METHOD]
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
    internal
    {
        uint256 toBalance = _balances[to];
        uint256 totalSupplyNow = _totalSupply;

        _setCheckpoint(tokenBalances[to], toBalance.add(value));
        _setCheckpoint(tokensTotal, totalSupplyNow.add(value));

        ERC777._issue(operator, to, value, data, operatorData);

        emit Transfer(address(0), to, value); // ERC20 backwards compatibility
    }

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

        ERC777._transferWithData(operator, from, to, value, data, operatorData, preventLocking);

        emit Transfer(from, to, value);
    }
}


/**
 * @title OpenBookToken
 * @dev OpenBookToken with CheckPointToken
 */
contract OpenBookToken is CheckPoint, MinterRole, DateTime {

    uint public maximumTotalSupply = 100000000;
    uint private initialSupply = 2000000;
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
    {
        _issue(msg.sender, msg.sender, initialSupply, "", "");
        totalSuppliesPerYear[0] = initialSupply;
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
    isValidCertificate(data)
    {
        // totalSupply equals or less than maximumTotalSupply
        require(maximumTotalSupply >= _totalSupply.add(value), "A8, Transfer Blocked - Max TotalSupply Limited");

        // get current year
        uint16 currentYear = getYear(now);
        if(_currentYearIssuedAt < currentYear) {
            _lastYearIssuedAt = _currentYearIssuedAt;
        }

        // calculate totalSupply to be able to issue
        uint limitedTotalSupply = totalSuppliesPerYear[_lastYearIssuedAt].mul(issuableRate + 100) / 100;

        // available totalSupply equals or less than (totalSupply + 10 percent) of last year
        require(limitedTotalSupply >= _totalSupply.add(value),
            "A8, Transfer Blocked - Year TotalSupply Limited");

        // issue tokens
        _issue(msg.sender, tokenHolder, value, data, "");

        // save totalSupply of current year
        totalSuppliesPerYear[currentYear] = _totalSupply;

        // update current year
        _currentYearIssuedAt = currentYear;
    }
}
