pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

// import "./verifier.sol";
// import "./onlyOwner.sol";

contract AnonumousVoting {

    uint256 public amount = 100;    
    uint256 public upperParticipateNum = 10;
    uint256 public lowerParicipateNum = 5;
    bool public isClosed;

    bytes[] public encryptedVotes;
    bytes32[] public hashedVotes; // can be integrated encrypted with hash.

    bytes[] public encryptedRights;
    bytes32[] public hashedRights; // TODO: make struct

    mapping(bytes32 => uint[]) public voteIndexies;

    mapping(bytes32 => bool) public voteNullifier; // hash(ownerAddress, votedAmount) => bool
    mapping(bytes32 => bool) public rightNullifier;

    event UpdateRight(address indexed participant, uint256 rightIndex);
    event UpdateVotedNum(address indexed participant, uint256 voteIndex);

    function register(bytes memory encryptedRight) public {
        require(!isClosed, "The voting is closed.");
        bytes32 hashedRight = sha256(abi.encodePacked(msg.sender, amount));        

        updateRight(hashedRight, encryptedRight);
    }

    

    // Constraints(        
    //     private sk, 
    //     private candidatePk, 
    //     private currVotingRightNum, 
    //     private nextVotedNum, 
    //     private nextVotingRightNum,
    //     public prevHashedVotingRight, 
    //     public currHashedVotingRight, 
    //     public currHashedVotes,
    // ) {
    //     pk = computePublicKeyfromSecret(sk)
    //     currHashedVotingRight == sha256(pk, currVotingRightNum)  // pk or address?        
    //     currVotingRightNum == nextVotedNum + nextVotingRightNum
    //     nextHashedVotes == sha256(candidatePk, nextVotedNum)
    //     nextHashedVotingRight == sha256(pk, nextVotingRightNum)
    //     return 1
    // }

    function anonymousVote(
        uint[2] memory a,
        uint[2] memory a_p,
        uint[2][2] memory b,
        uint[2] memory b_p,
        uint[2] memory c,
        uint[2] memory c_p,
        uint[2] memory h,
        uint[2] memory k,
        uint[7] memory input,
        bytes memory encryptedVote, // Need encrypted by receiver?
        bytes memory encryptedRight 
    ) public {        
        // require(verifyTx(a, a_p, b, b_p, c, c_p, h, k, input), "Invalid zk proof");

        bytes32 currHashedVotingRight = sha256(abi.encodePacked(input[0], input[1])); // TODO: need calcNoteHash 
        require(!rightNullifier[currHashedVotingRight], "The right does not exist.");

        bytes32 nextHashedVotes = sha256(abi.encodePacked(input[2], input[3]));
        updateVotedNum(nextHashedVotes, encryptedVote);

        bytes32 nextHashedRight = sha256(abi.encodePacked(input[4], input[5]));
        updateRight(nextHashedRight, encryptedRight);

    }    
    
    function closeVoting() public { // onlyowner or threshold right num
        isClosed = true;
    }


    function reveal() public returns (bytes[] memory) {
        require(isClosed, "Need to be closed voting.");

        uint[] memory indexies = voteIndexies[sha256(abi.encodePacked(msg.sender))];
        bytes[] memory result = new bytes[](indexies.length);

        for (uint i; i < indexies.length; i++) {
            result[i] = encryptedVotes[indexies[i]];
        }

        return result;
    }

    function getVotesLength() public view returns (uint256) {
        return hashedVotes.length;
    }

    function getRightsLength() public view returns (uint256) {
        return hashedRights.length;
    }

    function updateRight(bytes32 right, bytes memory encryptedRight) internal {
        hashedRights.push(right);
        encryptedRights.push(encryptedRight);

        emit UpdateRight(msg.sender, hashedRights.length - 1);
    }

    function updateVotedNum(bytes32 vote, bytes memory encryptedVote) internal {
        hashedVotes.push(vote);
        encryptedVotes.push(encryptedVote);

        emit UpdateVotedNum(msg.sender, hashedVotes.length - 1);
    }

}
