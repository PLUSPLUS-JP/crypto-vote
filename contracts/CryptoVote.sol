pragma solidity ^0.5.0;

// ---------------------------------------------
// CryptoVote.sol
// ---------------------------------------------
// Copyright (c) 2018 PLUSPLUS CO.,LTD.
// Released under the MIT license
// https://www.plusplus.jp/
// ---------------------------------------------

contract CryptoVote {
    struct Questionnaire {
        bytes32 id;
        bytes contentsData;
        uint numberOfChoices;
        uint voteStartAt; // Voting start timestamp
        uint voteEndAt; // Voting end timestamp
        mapping(address => bool) votedList; // Voter list
        address organizer;
        uint createdAt;
        bool isExist;
    }

    address public owner;
    mapping(bytes32 => Questionnaire) public QuestionnaireList;
    mapping(bytes32 => uint[]) private ResultList;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner is available.");
        _;
    }

    modifier acceptingVoting(bytes32 _id) {
        require(isExist(_id) == true, NO_DATA);
        uint ts = block.timestamp;
        require(QuestionnaireList[_id].voteStartAt <= ts && ts <= QuestionnaireList[_id].voteEndAt, "Outside the voting period");
        _;
    }

    string private NO_DATA = "Data does not exist";
    string private ALREADY_REGISTERED = "It is already registered";
    string private NO_DELETE_AUTHORITY = "You do not have permission to delete";

    // Events

    event NewQuestionnaire(bytes32 _id, bytes _contentsData, uint _voteStartAt, uint _voteEndAt);
    event Canceled(bytes32 _id);
    event Vote(address indexed _from, bytes32 _id, uint _choice, uint _timestamp);

    constructor() public {
        // The owner address is maintained.
        owner = msg.sender;
    }

    // @title questionnaire existence check
    function isExist(bytes32 _id) public view returns (bool) {
        if (QuestionnaireList[_id].isExist == true) {
            // exist
            return true;
        } else {
            // not exist
            return false;
        }
    }

    // @title Create a questionnaire
    function create(string memory _contents, uint _numberOfChoices, uint _voteStartAt, uint _voteEndAt) public onlyOwner returns (bool) {
        uint ts = block.timestamp;

        // voteStartAt must be the future.
        require(ts < _voteStartAt, "StartAt must be the future.");

        // The order of start and end must be correct.
        require(_voteStartAt < _voteEndAt, "The order of start and end must be correct.");

        // A minimum voting period of 1 minute is required.
        require(_voteEndAt - _voteStartAt >= 1 minutes, "A minimum voting period of 1 minute is required.");

        bytes32 _id = keccak256(abi.encodePacked(_contents));

        require(isExist(_id) == false);

        QuestionnaireList[_id].isExist = true;
        QuestionnaireList[_id].id = _id;
        QuestionnaireList[_id].contentsData = bytes(_contents);
        QuestionnaireList[_id].numberOfChoices = _numberOfChoices;
        QuestionnaireList[_id].voteStartAt = _voteStartAt;
        QuestionnaireList[_id].voteEndAt = _voteEndAt;
        QuestionnaireList[_id].createdAt = ts;

        ResultList[_id].length = _numberOfChoices;

        emit NewQuestionnaire(_id, bytes(_contents), _voteStartAt, _voteEndAt);

        return true;
    }

    // @title cancel questionnaire
    function cancel(bytes32 _id) public onlyOwner returns (bool) {
        QuestionnaireList[_id].isExist = false;
        QuestionnaireList[_id].contentsData = "";
        QuestionnaireList[_id].voteStartAt = 0;
        QuestionnaireList[_id].voteEndAt = 0;
        QuestionnaireList[_id].createdAt = 0;

        ResultList[_id].length = 0;

        emit Canceled(_id);

        return true;
    }

    // @title Determine if the user has voted
    function isVoted(bytes32 _id) public view returns (bool) {
        return QuestionnaireList[_id].votedList[msg.sender];
    }

    // @title vote
    function vote(bytes32 _id, uint _choice) public acceptingVoting(_id) returns (bool) {
        require(isVoted(_id) == false, "You have already voted");

        uint ts = block.timestamp;

        // Mark as voted
        QuestionnaireList[_id].votedList[msg.sender] = true;

        // vote
        ResultList[_id][_choice]++;

        emit Vote(msg.sender, _id, _choice, ts);

        return true;
    }

    // @title Return the result
    function getResult(bytes32 _id) public view returns (uint[] memory) {
        require(isExist(_id) == true);
        return ResultList[_id];
    }

}
