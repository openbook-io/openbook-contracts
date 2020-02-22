const TOKEN = artifacts.require("./OpenBookToken.sol");

require('openzeppelin-test-helpers/configure')({ web3 });
const { singletons } = require('openzeppelin-test-helpers');

const CERTIFICATE_SIGNER = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const controller = '0x91620735349a0B25750facc8e3354c9f02B1518B';


module.exports = async function (deployer, network, accounts) {

    if (network === 'development')  {
        // In a test environment an ERC777 token requires deploying an ERC1820 registry
        await singletons.ERC1820Registry(accounts[0]);
    }

    await deployer.deploy(TOKEN, 'OpenBook', 'OBK', 1, [controller], CERTIFICATE_SIGNER);

    const token = await TOKEN.deployed();
    console.log("Token address:", token.address);
};
