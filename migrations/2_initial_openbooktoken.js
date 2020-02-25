const TOKEN = artifacts.require("./OpenBookToken.sol");
const Dividend = artifacts.require("./Dividend.sol");
const Ballot = artifacts.require("./Ballot.sol");

require('openzeppelin-test-helpers/configure')({ web3 });
const { singletons } = require('openzeppelin-test-helpers');

const CERTIFICATE_SIGNER = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const controller = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const documentURI = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit,sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'; // SHA-256 of documentURI
const docProposal = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit'
const documentHash = '0x1c81c608a616183cc4a38c09ecc944eb77eaff465dd87aae0290177f2b70b6f8'; // SHA-256 of documentURI + '0x';
const ballotOfficialName = 'openBookBallot'


module.exports = async function (deployer, network, accounts) {

    if (network === 'development')  {
        // In a test environment an ERC777 token requires deploying an ERC1820 registry
        await singletons.ERC1820Registry(accounts[0]);
    }

    await deployer.deploy(TOKEN, 'OpenBook', 'OBK', 1, [controller], CERTIFICATE_SIGNER);

    const token = await TOKEN.deployed();
    console.log("Token address:", token.address);

    await deployer.deploy(Dividend, token.address, CERTIFICATE_SIGNER);
    const dividend = await Dividend.deployed();
    console.log("Dividend Contract address:", dividend.address);

    await deployer.deploy(Ballot, ballotOfficialName, docProposal, documentURI, documentHash, token.address);
    const ballot = await Dividend.deployed();
    console.log("Ballot Contract address:", ballot.address);
};
