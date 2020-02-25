const OpenBookToken = artifacts.require('OpenBookToken.sol');
const Ballot = artifacts.require('Ballot.sol');
const shouldFail = require('./utils/ShouldFail');

const owner                             = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const controller                        = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const tokenHolder                       = '0x076a40A4468d5C957E4F71aDE543a471A2Efd6DA';

const CERTIFICATE_SIGNER                = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const VALID_CERTIFICATE                 = '0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';

const documentURI = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit,sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'; // SHA-256 of documentURI
const docProposal = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit'
const documentHash = '0x1c81c608a616183cc4a38c09ecc944eb77eaff465dd87aae0290177f2b70b6f8'; // SHA-256 of documentURI + '0x';
const ballotOfficialName = 'openBookBallot'

const issuanceAmount = '10000'

contract('Ballot', function () {
    ///////////////////////////////////////////////////////
    //   Parameters Testing
    ///////////////////////////////////////////////////////
    describe('parameters', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
            this.ballot = await Ballot.new(ballotOfficialName, docProposal, documentURI, documentHash, this.token.address);
        });
        describe('ballotOfficialAddress', function () {
            it('returns ballotOfficialAddress', async function () {
                    const ballotOfficialAddress = await this.ballot.ballotOfficialAddress();
                    assert.equal(ballotOfficialAddress, owner)
                }
            )
        });
        describe('ballotOfficialName', function () {
            it('returns ballotOfficialName', async function () {
                    const name = await this.ballot.ballotOfficialName();
                    assert.equal(ballotOfficialName, name)
                }
            )
        });
        describe('ballotToken', function () {
            it('returns ballotToken', async function () {
                    const ballotToken = await this.ballot.ballotToken();
                    assert.equal(ballotToken, this.token.address)
                }
            )
        });
    });

    ///////////////////////////////////////////////////////
    //   Voting
    ///////////////////////////////////////////////////////
    describe('voting', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
            this.ballot = await Ballot.new(ballotOfficialName, docProposal, documentURI, documentHash, this.token.address);
            await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: owner});
            await this.token.issue(controller, issuanceAmount, VALID_CERTIFICATE, {from: owner});
        });
        describe('when created ballot', function () {
            it('can start voting', async function () {
                let state = await this.ballot.state();
                assert.equal(state, 0)
                const {logs} = await this.ballot.startVote({from: owner});
                assert.equal(logs.length, 1);
                assert.equal(logs[0].event, 'voteStarted');
                state = await this.ballot.state();
                assert.equal(state, 1)
            })
            it('can do voting', async function () {
                await this.ballot.startVote({from: owner});
                const state = await this.ballot.state();
                assert.equal(state, 1)
                const {logs} =await this.ballot.doVote(true, {from: tokenHolder});
                assert.equal(logs.length, 1);
                assert.equal(logs[0].event, 'voteDone');
                assert.equal(logs[0].args.voter, tokenHolder);
            })
            it('can end voting with success', async function () {
                await this.ballot.startVote({from: owner});
                let state = await this.ballot.state();
                assert.equal(state, 1)
                const {logs} = await this.ballot.endVote({from: owner});
                assert.equal(logs.length, 1);
                assert.equal(logs[0].event, 'voteEnded');
                assert.equal(logs[0].args.finalResult, true);
                state = await this.ballot.state();
                assert.equal(state, 2)
            })
            it('can end voting with success', async function () {
                await this.token.issue(controller, issuanceAmount, VALID_CERTIFICATE, {from: owner});
                await this.ballot.startVote({from: owner});
                await this.ballot.doVote(true, {from: tokenHolder});
                await this.ballot.doVote(false, {from: controller});
                const {logs} = await this.ballot.endVote({from: owner});
                assert.equal(logs.length, 1);
                assert.equal(logs[0].event, 'voteEnded');
                assert.equal(logs[0].args.finalResult, false);
            })
        });
    })
});
