pragma solidity 0.5.16;

import "./CheckPoint/ICheckPoint.sol";
import "./Ballot/IBallot.sol";
import "./libs/SafeMath.sol";

/**
 * @title Ballot
 * @dev Implements voting process
 */
contract Ballot is IBallot {
    using SafeMath for uint256;

    struct Doc {
        string docURI;
        string docProposal;
        bytes32 docHASH;
    }

    struct vote{
        address voterAddress;
        uint weight;
        bool choice;
    }

    struct voter {
        bool voted;
    }

    uint private countWeight = 0;
    uint private totalWeight = 0;
    bool private finalResult = false;
    uint public totalVote = 0;

    address public ballotOfficialAddress;
    string public ballotOfficialName;

    uint public ballotBlockNumber;
    Doc private ballotOfficialDoc;
    ICheckPoint public ballotToken;

    mapping(uint => vote) private votes;
    mapping(address => voter) public voterRegister;

    enum State { Created, Voting, Ended }
    State public state;

    modifier condition(bool _condition) {
        require(_condition);
        _;
    }

    modifier onlyOfficial() {
        require(msg.sender ==ballotOfficialAddress);
        _;
    }

    modifier inState(State _state) {
        require(state == _state);
        _;
    }

    event voteStarted();
    event voteEnded(bool finalResult);
    event voteDone(address voter);

    /**
    * [Ballot CONSTRUCTOR]
    * @dev creates a new ballot contract
    * @param _ballotOfficialName string Official Name
    * @param _docProposal string Proposal
    * @param _docURI string Doc URI
    * @param _docHASH byte32 byte32
    * @param _token ICheckPoint OpenBook Token
    */
    constructor(
        string memory _ballotOfficialName,
        string memory _docProposal,
        string memory _docURI,
        bytes32 _docHASH,
        ICheckPoint _token
    )
    public
    {
        ballotOfficialAddress = msg.sender;
        ballotOfficialName = _ballotOfficialName;

        ballotOfficialDoc.docURI = _docURI;
        ballotOfficialDoc.docProposal = _docProposal;
        ballotOfficialDoc.docHASH = _docHASH;

        ballotToken = _token;
        state = State.Created;
    }

    /**
     * @dev Access document
     * @return Requested document + document hash.
     */
    function getDocument() external view returns (string memory, string memory, bytes32) {
        require(bytes(ballotOfficialDoc.docURI).length != 0, "Action Blocked - Empty document");
        return (
            ballotOfficialDoc.docURI,
            ballotOfficialDoc.docProposal,
            ballotOfficialDoc.docHASH
        );
    }

    /**
     * @dev Access vote result
     * @return Requested countWeight + totalWeight + finalResult.
     */
    function geResult() external view returns (uint, uint, bool) {
        return (countWeight, totalWeight, finalResult);
    }

    /**
    * @dev declare voting starts now
    */
    function startVote()
    external
    inState(State.Created)
    onlyOfficial
    {
        state = State.Voting;
        ballotBlockNumber = block.number;
        emit voteStarted();
    }

    /**
    * @dev voters vote by indicating their choice (true/false)
    * @param _choice Bool for vote result
    * @return voted
    */
    function doVote(bool _choice) external
    inState(State.Voting)
    returns (bool voted)
    {
        bool found = false;
        uint balanceAt = ballotToken.balanceAt(msg.sender, ballotBlockNumber);

        if(balanceAt > 0
        && !voterRegister[msg.sender].voted){
            voterRegister[msg.sender].voted = true;
            vote memory v;
            v.voterAddress = msg.sender;
            v.choice = _choice;
            v.weight = balanceAt;
            if (_choice){
                countWeight = countWeight.add(balanceAt);
            }
            votes[totalVote] = v;
            totalWeight = totalWeight.add(balanceAt);
            totalVote++;
            found = true;
        }
        emit voteDone(msg.sender);
        return found;
    }

    /**
    * @dev end votes
    */
    function endVote()
    external
    inState(State.Voting)
    onlyOfficial
    {
        state = State.Ended;
        finalResult = countWeight >= totalWeight.sub(countWeight);
        emit voteEnded(finalResult);
    }
}
