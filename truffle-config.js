const HDWalletProvider = require('truffle-hdwallet-provider');

const testnetConf = require('./private_file/ropsten-testnet.js');
/*
module.exports = {
    infuraKey: 'xxxxxx_infula.io's "PROJECT ID"_xxxxxx',
    privateKey: 'xxxxxx_your_eth_address_private_key_xxxxxx',
};
 */

module.exports = {
    networks: {
        contracts_build_directory: './build/contracts',
        ropsten: {
            provider: () => new HDWalletProvider(testnetConf.privateKey, `https://ropsten.infura.io/v3/${testnetConf.infuraKey}`),
            network_id: 3,
            gas: 5500000,
            confirmations: 2,
            timeoutBlocks: 200,
            skipDryRun: true,
        },

        private: {
            host: '127.0.0.1',
            port: 8545,
            network_id: 1547092157,
            from: '0x083Cd205ee174D0d0D259c0225be4218EAdcE556', // truffle develop
            gas: 5651873,
        },
    },

    mocha: {},

    compilers: {
        solc: {
            version: '0.4.24',
        },
    },
};
