pragma solidity >=0.4.21<0.6.0;

// ---------------------------------------------
// CryptoVote.sol
// ---------------------------------------------
// Copyright (c) 2018 PLUSPLUS CO.,LTD.
// Released under the MIT license
// https://www.plusplus.jp/
// ---------------------------------------------

//
// Data identity verification
//
contract CryptoVote {
    // 投票キャンペーン
    struct Campaign {
        //キャンペーンハッシュID（内部生成）
        bytes32 campaignId;
        // Campaignの情報のJSON文字列
        string campaignData;
        // 選択肢の数
        uint optionNumber;
        // 投票開始タイムスタンプ
        // Voting start timestamp
        uint voteStartAt;
        //投票終了タイムスタンプ
        // Voting end timestamp
        uint voteEndAt;
        // 投票者リストを保持する
        mapping(bytes32 => bool) voters;
        // 投票済みリストを保持する
        mapping(bytes32 => bool) votedList;
        // campaign登録者
        address campaignOwner;
        // campaign登録日時
        uint createdAt;
        bool isExist;
    }

    // Owner of Smart Contract
    // スマートコントラクトのオーナー
    address public owner;

    // Keep a list of hashes
    // ハッシュの一覧を保持する
    mapping(bytes32 => Campaign) public CampaignList;

    // 投票結果を保持する
    mapping(bytes32 => uint[]) private RecordList;

    // ***********************************
    // スマートコントラクトのオーナーであること
    // ***********************************
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner is available.");
        _;
    }

    // ***********************************
    // 投票キャンペーンのオーナーであること
    // ***********************************
    modifier onlyCampaignOwner(bytes32 _campaignId) {
        require(isExist(_campaignId) == true, NO_DATA);
        require(msg.sender == CampaignList[_campaignId].campaignOwner, "Only the owner is available.");
        _;
    }

    // ***********************************
    // 投票受付中であること
    // ***********************************
    modifier acceptingPolling(bytes32 _campaignId) {
        require(isExist(_campaignId) == true, NO_DATA);
        uint ts = block.timestamp;
        require(CampaignList[_campaignId].voteStartAt <= ts && ts <= CampaignList[_campaignId].voteEndAt, "Outside the voting period");
        _;
    }

    // ***********************************
    // 投票開始前であること
    // ***********************************
    modifier beforeVoteStart(bytes32 _campaignId) {
        require(isExist(_campaignId) == true, NO_DATA);
        uint ts = block.timestamp;
        require(ts < CampaignList[_campaignId].voteStartAt);
        _;
    }

    // ***********************************
    // 投票終了前であること
    // ***********************************
    modifier beforeVoteEnd(bytes32 _campaignId) {
        require(isExist(_campaignId) == true, NO_DATA);
        uint ts = block.timestamp;
        require(ts < CampaignList[_campaignId].voteEndAt);
        _;
    }

    // ***********************************
    // 投票締め切り後であること
    // ***********************************
    modifier afterVoteEnd(bytes32 _campaignId) {
        require(isExist(_campaignId) == true, NO_DATA);
        uint ts = block.timestamp;
        require(CampaignList[_campaignId].voteEndAt <= ts);
        _;
    }

    string private NO_DATA = "Data does not exist";
    string private ALREADY_REGISTERED = "It is already registered";
    string private NO_DELETE_AUTHORITY = "You do not have permission to delete";

    // Events

    // ***********************************
    // キャンペーン作成
    // ***********************************
    event NewCampaign(address indexed _from, bytes32 _campaignId, string _campaignData, uint _voteStartAt, uint _voteEndAt);

    // ***********************************
    // 投票
    // ***********************************
    event Vote(address indexed _from, bytes32 _campaignId, bytes32 _voterId, uint _optionNumber, uint _timestamp);

    // ***********************************
    // 投票者追加
    // ***********************************
    event AddVoter(address indexed _from, bytes32 _campaignId, uint256 _newVoters);

    // ***********************************
    // コンストラクタ
    // ***********************************
    constructor() public {
        // The owner address is maintained.
        owner = msg.sender;
    }

    // ***********************************
    // Obtain a hash value
    // ハッシュ値を得る
    // ***********************************
    function getKeccak256Hash(string _sha3hash) public pure returns (bytes32) {
        bytes32 keccak256hash = keccak256(abi.encodePacked(_sha3hash));
        return keccak256hash;
    }

    // ***********************************
    // campaign existence check
    // キャンペーン存在チェック
    // ***********************************
    function isExist(bytes32 _campaignId) public view returns (bool) {
        if (CampaignList[_campaignId].isExist == true) {
            // exist
            return true;
        } else {
            // not exist
            return false;
        }
    }

    // ***********************************
    // Whether you are the owner of the campaign
    // あなたがキャンペーンの登録者であるか
    // ***********************************
    function areYouCampaignOwner(bytes32 _campaignId) public view returns (bool) {
        require(isExist(_campaignId) == true, NO_DATA);

        if (msg.sender == CampaignList[_campaignId].campaignOwner) {
            return true;
        } else {
            return false;
        }
    }

    // ***********************************
    // campaign作成
    // ***********************************
    function createCampaign(string _campaignData, uint _optionNumber, uint _voteStartAt, uint _voteEndAt) public onlyOwner returns (bool) {
        uint ts = block.timestamp;

        // voteStartAtが未来日であること
        require(ts < _voteStartAt);

        // voteStartAt < voteEndAt であること
        require(_voteStartAt < _voteEndAt);

        // voteEndAt - voteStartAt が1分以上あること
        require(_voteEndAt - _voteStartAt >= 1 minutes);

        bytes32 _campaignId = getKeccak256Hash(_campaignData);

        // 同じものが存在しないこと
        require(isExist(_campaignId) == false);

        CampaignList[_campaignId].isExist = true;
        CampaignList[_campaignId].campaignId = _campaignId;
        CampaignList[_campaignId].campaignData = _campaignData;
        CampaignList[_campaignId].optionNumber = _optionNumber;
        CampaignList[_campaignId].voteStartAt = _voteStartAt;
        CampaignList[_campaignId].voteEndAt = _voteEndAt;
        CampaignList[_campaignId].campaignOwner = msg.sender;
        CampaignList[_campaignId].createdAt = ts;

        // 投票結果の初期化
        RecordList[_campaignId].length = _optionNumber;

        // 通知
        emit NewCampaign(msg.sender, _campaignId, _campaignData, _voteStartAt, _voteEndAt);

        return true;
    }

    // ***********************************
    // 投票者IDが存在するか
    // ***********************************
    function existVoterId(bytes32 _campaignId, bytes32 _voterHash) public view returns (bool) {
        return CampaignList[_campaignId].voters[_voterHash];
    }

    // ***********************************
    // 投票済みか
    // ***********************************
    function isVoted(bytes32 _campaignId, bytes32 _voterHash) public view returns (bool) {
        return CampaignList[_campaignId].votedList[_voterHash];
    }

    // ***********************************
    // 投票者の追加
    // -----------------------------------
    // 【条件】
    // キャンペーンのオーナーであること
    // 投票期限前であること
    // ***********************************
    function addVoter(bytes32 _campaignId, bytes32[] _voterHashList) public onlyCampaignOwner(_campaignId) beforeVoteEnd(_campaignId) returns (bool) {
        require(_voterHashList.length <= 100);

        uint256 newVoters = 0;

        for (uint i = 0; i < _voterHashList.length; ++i) {
            if (existVoterId(_campaignId, _voterHashList[i])) {
                continue;
            }

            CampaignList[_campaignId].voters[_voterHashList[i]] = true;
            ++newVoters;
        }

        emit AddVoter(msg.sender, _campaignId, newVoters);

        return true;
    }

    // ***********************************
    // 投票
    // -----------------------------------
    // 【条件】
    // 投票期間中であること
    // ***********************************
    function vote(bytes32 _campaignId, bytes32 _voterHash, uint _optionNumber) public acceptingPolling(_campaignId) returns (bool) {
        // 投票権があること
        require(existVoterId(_campaignId, _voterHash) == true, "投票権がありません");

        // 未投票であること
        require(isVoted(_campaignId, _voterHash) == false, "投票済みです");

        uint ts = block.timestamp;

        // 投票済みに変更
        CampaignList[_campaignId].votedList[_voterHash] = true;

        // 一票加算
        RecordList[_campaignId][_optionNumber]++;

        emit Vote(msg.sender, _campaignId, _voterHash, _optionNumber, ts);

        return true;
    }

    // ***********************************
    // 投票結果参照
    // -----------------------------------
    // 【条件】
    // なし
    // ***********************************
    function getResult(bytes32 _campaignId) public view returns (uint[]) {
        return RecordList[_campaignId];
    }

    // ---------------------------------------------
    // Destruction of a contract (only owner)
    // ---------------------------------------------
    function destory(string _delete_me) public onlyOwner {
        // Delete by giving keyword
        require(getKeccak256Hash("delete me") == getKeccak256Hash(_delete_me), "The keywords do not match.");
        selfdestruct(owner);
    }

}
