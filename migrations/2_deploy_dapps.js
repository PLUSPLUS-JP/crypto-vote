const CryptoVote = artifacts.require('./CryptoVote.sol');

module.exports = (deployer) => {
    deployer.deploy(CryptoVote);
};
