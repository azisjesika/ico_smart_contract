const Web3 = require('web3');
const TruffleConfig = require('../truffle');

var Migrations = artifacts.require("./HiveSale.sol");

module.exports = function(deployer, network, addresses) {
//	const config = TruffleConfig.networks[network];
//	const web3 = new Web3(new Web3.providers.HttpProvider('http://' + config.host + ':' + config.port));
 //   console.log('>> Unlocking account ' + config.from);
//    web3.personal.unlockAccount(config.from, "123456", 36000);
	
 // deployer.deploy(Migrations, 266400, '0x5472d3D24323bbFbEEEe33cF0C49817AcA1CEC9F', '0x83B102D4D127fe98ed4352A3E269d50b363b4EAc', 1520261466, 1520347866, {gas: 4000000});
};
