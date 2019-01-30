# 暗号通貨の仕組みを使った投票システムを実装


## 概要

スマートコントラクトを使った投票システムを実装する

## 要点

- 投票者がETHアドレスを持たなくても投票できるようにする。
- 匿名投票にはなるが、無制限な投票ではなく、あらかじめ投票するためのチケットを配布する。
- 投票チケットには、投票者が特定できる文字列（投票キー）が記載され、投票時に用いる。
- 投票時には投票キーを使用する。投票キーは一度だけ使用できる。
- 投票の状況は常に閲覧可能。
- 投票には開始と終了の日時を設定できる。

## このDappsによって実現できること

ブロックチェーンに情報が記録されるため、記録の改ざんなどの心配がない

## 課題

- 投票者のGASをどうするか？


## 仕様

### キャンペーン作成

_campaignData

```
function createCampaign(string _campaignData, uint _optionNumber, uint _voteStartAt, uint _voteEndAt) public returns (bool);
```

![キャンペーン作成](./sequence-diagram/create-campaign.svg)


### 投票者に追加

```
function addVoter(bytes32 _campaignId, bytes32[] _voterHashList)
```

![投票者に追加](./sequence-diagram/add-voter.svg)

### 投票

```
function vote(bytes32 _campaignId, bytes32 _voterHash, uint _optionNumber) public acceptingPolling(_campaignId) returns (bool);
```

![投票](./sequence-diagram/vote.svg)

### 投票結果参照

```
function getResult(bytes32 _campaignId) public view afterVoteEnd(_campaignId) returns (uint[]);
```

![投票結果参照](./sequence-diagram/get-result.svg)

## 実装

実装はGitHubにて公開する。

https://github.com/PLUSPLUS-JP/crypto-vote


