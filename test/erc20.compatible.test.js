const OpenBookToken = artifacts.require('OpenBookToken.sol');
const shouldFail = require('./utils/ShouldFail');

import {
    assertTransferEvent,
    assertBurnEvent,
    assertBalance,
    assertTotalSupply
} from "./utils/methods";

const owner                             = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const unknown                           = '0xFE5bb18b84bf396edFd2Bdbba5372678AF57a977';

const tokenHolder                       = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const recipient                         = '0x076a40A4468d5C957E4F71aDE543a471A2Efd6DA';
const operator                          = '0xEfc12c6C3bDE4764953b7cC3CC2AB8a5c71BEF19';

const controller                        = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const controller_alternative1           = '0x076a40A4468d5C957E4F71aDE543a471A2Efd6DA';
const controller_alternative2           = '0xEfc12c6C3bDE4764953b7cC3CC2AB8a5c71BEF19';

const CERTIFICATE_SIGNER                = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const CERTIFICATE_SIGNER_ALTERNATIVE1   = '0x076a40A4468d5C957E4F71aDE543a471A2Efd6DA';
const CERTIFICATE_SIGNER_ALTERNATIVE2   = '0xEfc12c6C3bDE4764953b7cC3CC2AB8a5c71BEF19';

const ZERO_ADDRESS                      = '0x0000000000000000000000000000000000000000';
const issuanceAmount                    = 1000;

const VALID_CERTIFICATE                 = '0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
const documentName                      = "0x4f70656e426f6f6b546f6b656e00000000000000000000000000000000000000";
const ZERO_BYTE                         = '0x';

let totalSupply;
let balance;

contract('OpenBookToken', function () {

    ///////////////////////////////////////////////////////
    //  ERC20 Compatibility
    ///////////////////////////////////////////////////////
    describe('ERC20 Compatible functions', function () {
        // Decimals
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });
        describe('decimals', function () {
            it('returns the decimals the token', async function () {
                const decimals = await this.token.decimals();
                assert.equal(decimals, 18);
            });
        });

        // APPROVE
        describe('approve', function () {
            const amount = 100;
            describe('when sender approves an operator', function () {
                it('approves the operator', async function () {
                    assert.equal(await this.token.allowance(tokenHolder, operator), 0);

                    await this.token.approve(operator, amount, { from: tokenHolder });

                    assert.equal(await this.token.allowance(tokenHolder, operator), amount);
                });
                it('emits an approval event', async function () {
                    const { logs } = await this.token.approve(operator, amount, { from: tokenHolder });

                    assert.equal(logs.length, 1);
                    assert.equal(logs[0].event, 'Approval');
                    assert.equal(logs[0].args.owner, tokenHolder);
                    assert.equal(logs[0].args.spender, operator);
                    assert.equal(logs[0].args.value, amount);
                });
            });
            describe('when the operator to approve is the zero address', function () {
                it('reverts', async function () {
                    await shouldFail.reverting(this.token.approve(ZERO_ADDRESS, amount, { from: tokenHolder }));
                });
            });
        });

        // TRANSFER
        describe('transfer', function () {
            beforeEach(async function () {
                await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, { from: owner });
            });

            describe('when token has a whitelist', function () {
                beforeEach(async function () {
                    await this.token.setWhitelisted(tokenHolder, true, { from: owner });
                    await this.token.setWhitelisted(recipient, true, { from: owner });
                });

                describe('when the sender and the recipient are whitelisted', function () {
                    beforeEach(async function () {
                        assert.equal(await this.token.whitelisted(tokenHolder), true);
                        assert.equal(await this.token.whitelisted(recipient), true);
                    });
                    describe('when the amount is a multiple of the granularity', function () {
                        describe('when the recipient is not the zero address', function () {
                            describe('when the sender has enough balance', function () {
                                const amount = issuanceAmount;

                                it('transfers the requested amount', async function () {
                                    await this.token.transfer(recipient, amount, { from: tokenHolder });
                                    await assertBalance(this.token, tokenHolder, issuanceAmount - amount);
                                    await assertBalance(this.token, recipient, amount);
                                });

                                it('emits a Transfer event', async function () {
                                    const { logs } = await this.token.transfer(recipient, amount, { from: tokenHolder });

                                    assert.equal(logs.length, 2);

                                    assert.equal(logs[0].event, 'TransferWithData');
                                    assert.equal(logs[0].args.operator, tokenHolder);
                                    assert.equal(logs[0].args.from, tokenHolder);
                                    assert.equal(logs[0].args.to, recipient);
                                    assert.equal(logs[0].args.value, amount);
                                    assert.equal(logs[0].args.data, null);
                                    assert.equal(logs[0].args.operatorData, null);

                                    assert.equal(logs[1].event, 'Transfer');
                                    assert.equal(logs[1].args.from, tokenHolder);
                                    assert.equal(logs[1].args.to, recipient);
                                    assert.equal(logs[1].args.value, amount);
                                });
                            });
                            describe('when the sender does not have enough balance', function () {
                                const amount = issuanceAmount + 1;

                                it('reverts', async function () {
                                    await shouldFail.reverting(this.token.transfer(recipient, amount, { from: tokenHolder }));
                                });
                            });
                        });

                        describe('when the recipient is the zero address', function () {
                            const amount = issuanceAmount;

                            it('reverts', async function () {
                                await shouldFail.reverting(this.token.transfer(ZERO_ADDRESS, amount, { from: tokenHolder }));
                            });
                        });
                    });
                    describe('when the amount is not a multiple of the granularity', function () {
                        it('reverts', async function () {
                            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 2, [], CERTIFICATE_SIGNER);
                            await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, { from: owner });
                            await shouldFail.reverting(this.token.transfer(recipient, 3, { from: tokenHolder }));
                        });
                    });
                });

                describe('when the sender is not whitelisted', function () {
                    const amount = issuanceAmount;

                    beforeEach(async function () {
                        await this.token.setWhitelisted(tokenHolder, false, { from: owner });

                        assert.equal(await this.token.whitelisted(tokenHolder), false);
                        assert.equal(await this.token.whitelisted(recipient), true);
                    });
                    it('reverts', async function () {
                        await shouldFail.reverting(this.token.transfer(recipient, amount, { from: tokenHolder }));
                    });
                });

                describe('when the recipient is not whitelisted', function () {
                    const amount = issuanceAmount;

                    beforeEach(async function () {
                        await this.token.setWhitelisted(recipient, false, { from: owner });

                        assert.equal(await this.token.whitelisted(tokenHolder), true);
                        assert.equal(await this.token.whitelisted(recipient), false);
                    });
                    it('reverts', async function () {
                        await shouldFail.reverting(this.token.transfer(recipient, amount, { from: tokenHolder }));
                    });
                });
            });
        });
    });
})
