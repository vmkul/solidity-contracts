import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Voter is Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    
    struct Proposal {
        string name;
        uint voteCount;
    }

    IERC20 TokenContract;
    Counters.Counter private _proposalIds;
    EnumerableSet.AddressSet participants;
    EnumerableSet.AddressSet voters;
    Proposal winningProposal;
    bool votingActive = true;
    uint totalVotes;
    
    mapping(uint => Proposal) proposals;

    constructor(address _ERC20Token) {
        TokenContract = IERC20(_ERC20Token);
    }
    
    modifier activeVoting() {
        require(votingActive, "Voting has concluded!");
        _;
    }
    
    function createProposal(string calldata _name) public activeVoting returns (bool) {
        uint256 newProposalId = _proposalIds.current();
        _proposalIds.increment();
        
        proposals[newProposalId] = Proposal(_name, 0);

        return true;
    }
    
    function viewProposals() public view returns (Proposal[] memory) {
        uint proposalCount = _proposalIds.current();
        Proposal[] memory res = new Proposal[](proposalCount);
        
        for (uint i = 0; i < proposalCount; i++) {
            res[i] = proposals[i];
        }
        
        return res;
    }
    
    function viewWinningProposals() public view returns (Proposal memory) {
        require(!votingActive, "Voting is still active!");
        return winningProposal;
    }

    function viewParticipants() public view returns (address[] memory) {
        uint participantCount = participants.length();
        address[] memory res = new address[](participantCount);
        
        for (uint i = 0; i < participantCount; i++) {
            res[i] = participants.at(i);
        }
        
        return res;
    }

    function registerForVoting() public activeVoting returns (bool) {
        require(TokenContract.balanceOf(msg.sender) >= 10 ** 18, "You don't have enough ERC-20 to be able to participate!");
        return participants.add(msg.sender);
    }
    
    function vote(uint proposalId) public activeVoting returns (bool) {
        Proposal storage proposal = proposals[proposalId];
        
        require(participants.contains(msg.sender), "You have not registered for voting!");
        require(!voters.contains(msg.sender), "You have already voted!");
        
        voters.add(msg.sender);
        uint senderBalance = TokenContract.balanceOf(msg.sender);

        proposal.voteCount += senderBalance;
        totalVotes += senderBalance;
        
        return true;
    }
    
    function concludeVoting() public onlyOwner returns (bool) {
        require(votingActive, "Voting has concluded!");
        
        votingActive = false;
        uint proposalCount = _proposalIds.current();
        uint winningThreshold = (totalVotes * 70) / 100;
        
        for (uint i = 0; i < proposalCount; i++) {
            if (proposals[i].voteCount >= winningThreshold) {
                winningProposal = proposals[i];
                return true;
            }        
        }
        
        return false;
    }
}
