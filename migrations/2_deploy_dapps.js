const fs = require('fs');
const CryptoVote = artifacts.require('./CryptoVote.sol');

module.exports = (deployer) => {
    deployer.deploy(CryptoVote).then(() => {
        // Save ABI to file
        fs.mkdirSync('deploy/abi/', { recursive: true });
        fs.writeFileSync('deploy/abi/CryptoVote.json', JSON.stringify(CryptoVote.abi), { flag: 'w' });
    });
};
