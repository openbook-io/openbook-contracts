const OpenBookToken = artifacts.require('OpenBookToken.sol');
const shouldFail = require('./utils/ShouldFail');

import {
    assertTransferEvent,
    assertBalance
} from "./utils/methods";

const owner                             = '0x91620735349a0B25750facc8e3354c9f02B1518B';

const tokenHolder                       = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const recipient                         = '0x076a40A4468d5C957E4F71aDE543a471A2Efd6DA';
const operator                          = '0xEfc12c6C3bDE4764953b7cC3CC2AB8a5c71BEF19';
const controller                        = '0x91620735349a0B25750facc8e3354c9f02B1518B';

const CERTIFICATE_SIGNER                = '0x91620735349a0B25750facc8e3354c9f02B1518B';

const ZERO_ADDRESS                      = '0x0000000000000000000000000000000000000000';
const issuanceAmount                    = 100000;

const VALID_CERTIFICATE                 = '0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';

contract('ERC20 Compatible', function () {

    ///////////////////////////////////////////////////////
    // Decimals
    ///////////////////////////////////////////////////////
    beforeEach(async function () {
        this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
    });
    describe('decimals', function () {
        it('returns the decimals the token', async function () {
            const decimals = await this.token.decimals();
            assert.equal(decimals, 18);
        });
    });


    ///////////////////////////////////////////////////////
    // APPROVE
    ///////////////////////////////////////////////////////
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

    ///////////////////////////////////////////////////////
    // TRANSFER
    ///////////////////////////////////////////////////////
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

                                assertTransferEvent(logs, tokenHolder, tokenHolder, recipient, amount, null, null);
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


    ///////////////////////////////////////////////////////
    // TRANSFER FROM
    ///////////////////////////////////////////////////////
    describe('transferFrom', function () {
        const approvedAmount = 10000;
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
                describe('when the operator is approved', function () {
                    beforeEach(async function () {
                        await this.token.approve(operator, approvedAmount, { from: tokenHolder });
                    });
                    describe('when the amount is a multiple of the granularity', function () {
                        describe('when the recipient is not the zero address', function () {
                            describe('when the sender has enough balance', function () {
                                const amount = 500;

                                it('transfers the requested amount', async function () {
                                    await this.token.transferFrom(tokenHolder, recipient, amount, { from: operator });
                                    await assertBalance(this.token, tokenHolder, issuanceAmount - amount);
                                    await assertBalance(this.token, recipient, amount);

                                    assert.equal(await this.token.allowance(tokenHolder, operator), approvedAmount - amount);
                                });

                                it('emits a sent + a transfer event', async function () {
                                    const { logs } = await this.token.transferFrom(tokenHolder, recipient, amount, { from: operator });

                                    assert.equal(logs.length, 2);

                                    assertTransferEvent(logs, operator, tokenHolder, recipient, amount, null, null);
                                });
                            });
                            describe('when the sender does not have enough balance', function () {
                                const amount = approvedAmount + 1;

                                it('reverts', async function () {
                                    await shouldFail.reverting(this.token.transferFrom(tokenHolder, recipient, amount, { from: operator }));
                                });
                            });
                        });

                        describe('when the recipient is the zero address', function () {
                            const amount = issuanceAmount;

                            it('reverts', async function () {
                                await shouldFail.reverting(this.token.transferFrom(tokenHolder, ZERO_ADDRESS, amount, { from: operator }));
                            });
                        });
                    });
                    describe('when the amount is not a multiple of the granularity', function () {
                        it('reverts', async function () {
                            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 2, [], CERTIFICATE_SIGNER);
                            await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, { from: owner });
                            await shouldFail.reverting(this.token.transferFrom(tokenHolder, recipient, 3, { from: operator }));
                        });
                    });
                });
                describe('when the operator is not approved', function () {
                    const amount = approvedAmount;
                    describe('when the operator is not approved but authorized', function () {
                        it('transfers the requested amount', async function () {
                            await this.token.authorizeOperator(operator, { from: tokenHolder });
                            assert.equal(await this.token.allowance(tokenHolder, operator), 0);

                            await this.token.transferFrom(tokenHolder, recipient, amount, { from: operator });
                            await assertBalance(this.token, tokenHolder, issuanceAmount - amount);
                            await assertBalance(this.token, recipient, amount);
                        });
                    });
                    describe('when the operator is not approved and not authorized', function () {
                        it('reverts', async function () {
                            await shouldFail.reverting(this.token.transferFrom(tokenHolder, recipient, amount, { from: operator }));
                        });
                    });
                });
            });
            describe('when the sender is not whitelisted', function () {
                const amount = approvedAmount;
                beforeEach(async function () {
                    await this.token.setWhitelisted(tokenHolder, false, { from: owner });

                    assert.equal(await this.token.whitelisted(tokenHolder), false);
                    assert.equal(await this.token.whitelisted(recipient), true);
                });
                it('reverts', async function () {
                    await shouldFail.reverting(this.token.transferFrom(tokenHolder, recipient, amount, { from: operator }));
                });
            });
            describe('when the recipient is not whitelisted', function () {
                const amount = approvedAmount;
                beforeEach(async function () {
                    await this.token.setWhitelisted(recipient, false, { from: owner });

                    assert.equal(await this.token.whitelisted(tokenHolder), true);
                    assert.equal(await this.token.whitelisted(recipient), false);
                });
                it('reverts', async function () {
                    await shouldFail.reverting(this.token.transferFrom(tokenHolder, recipient, amount, { from: operator }));
                });
            });
        });
    });
})
