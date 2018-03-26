const Web3 = require('web3');
const TruffleConfig = require('../truffle');

var Migrations = artifacts.require("./HivePreSale.sol");

module.exports = function(deployer, network, addresses) {
	const config = TruffleConfig.networks[network];
	const web3 = new Web3(new Web3.providers.HttpProvider('http://' + config.host + ':' + config.port));
    console.log('>> Unlocking account ' + config.from);
    web3.personal.unlockAccount(config.from, config.password, 36000);
	
  deployer.deploy(Migrations, 333334, config.owner, config.vault, 1523232000, 1524528000, {gas: 4000000});
};
