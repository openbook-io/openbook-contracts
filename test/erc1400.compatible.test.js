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

contract('ERC1400 Compatible', function () {

    ///////////////////////////////////////////////////////
    //   Parameters Testing
    ///////////////////////////////////////////////////////
    describe('parameters', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });
        describe('name', function () {
            it('returns the name of the token', async function () {
                const name = await this.token.name();

                assert.equal(name, 'OpenBookToken');
            });
        });

        describe('symbol', function () {
            it('returns the symbol of the token', async function () {
                const symbol = await this.token.symbol();

                assert.equal(symbol, 'OBT');
            });
        });

        describe('granularity', function () {
            it('returns the granularity of the token', async function () {
                const granularity = await this.token.granularity();

                assert.equal(granularity, '1');
            });
        });
    });

    ///////////////////////////////////////////////////////
    //  AUTHORIZE OPERATOR
    ///////////////////////////////////////////////////////
    describe('authorizeOperator', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });
        it('authorizes operator', async function () {
            await this.token.authorizeOperator(operator, {from: tokenHolder});
            assert.isTrue(await this.token.isOperatorFor(operator, tokenHolder));
        });
    });

    ///////////////////////////////////////////////////////
    //  SET CONTROLLERS
    ///////////////////////////////////////////////////////
    describe('setControllers', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });
        describe('when the caller is the contract owner', function () {
            it('sets the operators as controllers', async function () {
                const controllers1 = await this.token.controllers();
                assert.equal(controllers1.length, 1);
                assert.equal(controllers1[0], controller);
                assert.isTrue(await this.token.isOperatorFor(controller, unknown));
                assert.isTrue(!(await this.token.isOperatorFor(controller_alternative1, unknown)));
                assert.isTrue(!(await this.token.isOperatorFor(controller_alternative2, unknown)));
                await this.token.setControllers([controller_alternative1, controller_alternative2], {from: owner});
                const controllers2 = await this.token.controllers();
                assert.equal(controllers2.length, 2);
                assert.equal(controllers2[0], controller_alternative1);
                assert.equal(controllers2[1], controller_alternative2);
                assert.isTrue(!(await this.token.isOperatorFor(controller, unknown)));
                assert.isTrue(await this.token.isOperatorFor(controller_alternative1, unknown));
                assert.isTrue(await this.token.isOperatorFor(controller_alternative2, unknown));
                await this.token.renounceControl({from: owner});
                assert.isTrue(!(await this.token.isOperatorFor(controller_alternative1, unknown)));
                assert.isTrue(!(await this.token.isOperatorFor(controller_alternative1, unknown)));
                assert.isTrue(!(await this.token.isOperatorFor(controller_alternative2, unknown)));
            });
        });
        describe('when the caller is not the contract owner', function () {
            it('reverts', async function () {
                await shouldFail.reverting(this.token.setControllers([controller_alternative1, controller_alternative2], {from: unknown}));
            });
        });
    });

    ///////////////////////////////////////////////////////
    //  CONTROLLERS
    ///////////////////////////////////////////////////////
    describe('controllers', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });
        describe('when the token is controllable', function () {
            it('returns the list of controllers', async function () {
                const controllers = await this.token.controllers();

                assert.equal(controllers.length, 1);
                assert.equal(controllers[0], controller);
            });
        });
    });

    ///////////////////////////////////////////////////////
    //  SET CERTIFICATE SIGNERS
    ///////////////////////////////////////////////////////
    describe('setCertificateSigner', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });
        describe('when the caller is the contract owner', function () {
            it('sets the operators as certificate signers', async function () {
                assert.isTrue(await this.token.certificateSigners(CERTIFICATE_SIGNER));
                assert.isTrue(!(await this.token.certificateSigners(CERTIFICATE_SIGNER_ALTERNATIVE1)));
                assert.isTrue(!(await this.token.certificateSigners(CERTIFICATE_SIGNER_ALTERNATIVE2)));
                await this.token.setCertificateSigner(CERTIFICATE_SIGNER, false, {from: owner});
                await this.token.setCertificateSigner(CERTIFICATE_SIGNER_ALTERNATIVE1, false, {from: owner});
                await this.token.setCertificateSigner(CERTIFICATE_SIGNER_ALTERNATIVE2, true, {from: owner});
                assert.isTrue(!(await this.token.certificateSigners(CERTIFICATE_SIGNER)));
                assert.isTrue(!(await this.token.certificateSigners(CERTIFICATE_SIGNER_ALTERNATIVE1)));
                assert.isTrue(await this.token.certificateSigners(CERTIFICATE_SIGNER_ALTERNATIVE2));
            });
        });
        describe('when the caller is not the contract owner', function () {
            it('reverts', async function () {
                await shouldFail.reverting(this.token.setCertificateSigner(CERTIFICATE_SIGNER, false, {from: unknown}));
                await shouldFail.reverting(this.token.setCertificateSigner(CERTIFICATE_SIGNER_ALTERNATIVE1, true, {from: unknown}));
            });
        });
    });

    ///////////////////////////////////////////////////////
    //  AUTHORIZE OPERATOR
    ///////////////////////////////////////////////////////
    describe('authorizeOperator', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });
        it('authorizes the operator', async function () {
            assert.isTrue(!(await this.token.isOperatorFor(operator, tokenHolder)));
            await this.token.authorizeOperator( operator, {from: tokenHolder});
            assert.isTrue(await this.token.isOperatorFor(operator, tokenHolder));
        });
        it('emits an authorized event', async function () {
            const {logs} = await this.token.authorizeOperator(operator, {from: tokenHolder});

            assert.equal(logs.length, 1);
            assert.equal(logs[0].event, 'AuthorizedOperator');
            assert.equal(logs[0].args.operator, operator);
            assert.equal(logs[0].args.tokenHolder, tokenHolder);
        });
    });


    ///////////////////////////////////////////////////////
    //  REVOKE OPERATOR
    ///////////////////////////////////////////////////////
    describe('revokeOperator', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });
        describe('when operator is not controller', function () {
            it('revokes the operator', async function () {
                await this.token.authorizeOperator(operator, {from: tokenHolder});
                assert.isTrue(await this.token.isOperatorFor(operator, tokenHolder));
                await this.token.revokeOperator(operator, {from: tokenHolder});
                assert.isTrue(!(await this.token.isOperatorFor(operator, tokenHolder)));
            });
            it('emits a revoked event', async function () {
                await this.token.authorizeOperator(operator, {from: tokenHolder});
                const {logs} = await this.token.revokeOperator(operator, {from: tokenHolder});

                assert.equal(logs.length, 1);
                assert.equal(logs[0].event, 'RevokedOperator');
                assert.equal(logs[0].args.operator, operator);
                assert.equal(logs[0].args.tokenHolder, tokenHolder);
            });
        });
    });


    ///////////////////////////////////////////////////////
    //  SET/GET DOCUMENT
    ///////////////////////////////////////////////////////
    describe('set/getDocument', function () {
        const documentURI = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit,sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'; // SHA-256 of documentURI
        const documentHash = '0x1c81c608a616183cc4a38c09ecc944eb77eaff465dd87aae0290177f2b70b6f8'; // SHA-256 of documentURI + '0x'

        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });

        describe('setDocument', function () {
            describe('when sender is the contract owner', function () {
                it('attaches the document to the token', async function () {
                    await this.token.setDocument(documentName, documentURI, documentHash, {from: owner});
                    const doc = await this.token.getDocument(documentName);
                    assert.equal(documentURI, doc[0]);
                    assert.equal(documentHash, doc[1]);
                });
                it('emits a documemnt event', async function () {
                    const {logs} = await this.token.setDocument(documentName, documentURI, documentHash, {from: owner});

                    assert.equal(logs.length, 1);
                    assert.equal(logs[0].event, 'Document');
                    assert.equal(logs[0].args.name, documentName);
                    assert.equal(logs[0].args.uri, documentURI);
                    assert.equal(logs[0].args.documentHash, documentHash);
                });
            });
            describe('when sender is not the contract owner', function () {
                it('reverts', async function () {
                    await shouldFail.reverting(this.token.setDocument(documentName, documentURI, documentHash, {from: unknown}));
                });
            });
        });
        describe('getDocument', function () {
            describe('when document exists', function () {
                it('returns the document', async function () {
                    await this.token.setDocument(documentName, documentURI, documentHash, {from: owner});
                    const doc = await this.token.getDocument(documentName);
                    assert.equal(documentURI, doc[0]);
                    assert.equal(documentHash, doc[1]);
                });
            });
            describe('when document does not exist', function () {
                it('reverts', async function () {
                    await shouldFail.reverting(this.token.getDocument(documentName));
                });
            });
        });
    });

    ///////////////////////////////////////////////////////
    //  ISSUE
    ///////////////////////////////////////////////////////
    describe('issue', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
        });

        describe('when sender is the issuer', function () {
            describe('when token is issuable', function () {
                it('issues the requested amount', async function () {
                    await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: owner});

                    await assertTotalSupply(this.token, issuanceAmount);
                    await assertBalance(this.token, tokenHolder, issuanceAmount);
                });
                it('issues twice the requested amount', async function () {
                    await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: owner});
                    await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: owner});

                    await assertTotalSupply(this.token, 2 * issuanceAmount);
                    await assertBalance(this.token, tokenHolder,  2 * issuanceAmount);
                });
                it('emits a issued event', async function () {
                    const {logs} = await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: owner});

                    assert.equal(logs.length, 3);

                    assert.equal(logs[0].event, 'Checked');
                    assert.equal(logs[0].args.sender, owner);

                    assert.equal(logs[1].event, 'Issued');
                    assert.equal(logs[1].args.operator, owner);
                    assert.equal(logs[1].args.to, tokenHolder);
                    assert.equal(logs[1].args.value, issuanceAmount);
                    assert.equal(logs[1].args.data, VALID_CERTIFICATE);
                    assert.equal(logs[1].args.operatorData, null);

                    assert.equal(logs[2].event, 'Transfer');
                    assert.equal(logs[2].args.from, ZERO_ADDRESS);
                    assert.equal(logs[2].args.to, tokenHolder);
                    assert.equal(logs[2].args.value, issuanceAmount);
                });
            });
            describe('when token is not issuable', function () {
                it('reverts', async function () {
                    assert.isTrue(await this.token.isIssuable());
                    await this.token.renounceIssuance({from: owner});
                    assert.isTrue(!(await this.token.isIssuable()));
                    await shouldFail.reverting(this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: owner}));
                });
            });
        });
        describe('when sender is not the issuer', function () {
            it('reverts', async function () {
                await shouldFail.reverting(this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: unknown}));
            });
        });
    });

    ///////////////////////////////////////////////////////
    //  REDEEM
    ///////////////////////////////////////////////////////
    describe('redeem', function () {
        const redeemAmount = 300;

        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
            await this.token.issue(controller, issuanceAmount, VALID_CERTIFICATE, {from: owner});
        });

        describe('when the redeemer has enough balance', function () {
            it('redeems the requested amount', async function () {
                await this.token.redeem(redeemAmount, VALID_CERTIFICATE, {from: controller});

                await assertTotalSupply(this.token, issuanceAmount - redeemAmount);
                await assertBalance(this.token, controller, issuanceAmount - redeemAmount);
            });
            it('emits a redeemed event', async function () {
                const {logs} = await this.token.redeem(redeemAmount, VALID_CERTIFICATE, {from: controller});

                assert.equal(logs.length, 3);

                assertBurnEvent(logs, controller, controller, redeemAmount, VALID_CERTIFICATE, null);
            });
        });
    });

    ///////////////////////////////////////////////////////
    //  REDEEM FROM
    ///////////////////////////////////////////////////////
    describe('redeemFrom', function () {
        const redeemAmount = 300;

        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
            await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: owner});
        });

        describe('when the sender is an operator', function () {
            describe('when the redeemer has enough balance', function () {
                it('redeems the requested amount', async function () {
                    await this.token.authorizeOperator(controller, {from: tokenHolder});
                    await this.token.redeemFrom(tokenHolder, redeemAmount, ZERO_BYTE, VALID_CERTIFICATE, {from: controller});

                    await assertTotalSupply(this.token, issuanceAmount - redeemAmount);
                    await assertBalance(this.token, tokenHolder, issuanceAmount - redeemAmount);
                });
                it('emits a redeemFrom', async function () {
                    await this.token.authorizeOperator(controller, {from: tokenHolder});
                    const {logs} = await this.token.redeemFrom(tokenHolder, redeemAmount, ZERO_BYTE, VALID_CERTIFICATE, {from: controller});

                    assert.equal(logs.length, 3);
                    assertBurnEvent(logs, controller, tokenHolder, redeemAmount, null, VALID_CERTIFICATE);
                });
            });
            describe('when the redeemer does not have enough balance', function () {
                it('reverts', async function () {
                    it('redeems the requested amount', async function () {
                        await this.token.authorizeOperator(controller, {from: tokenHolder});

                        await shouldFail.reverting(this.token.redeemFrom(tokenHolder, issuanceAmount + 1, ZERO_BYTE, VALID_CERTIFICATE, {from: controller}));
                    });
                });
            });
        });
        describe('when the sender is a global operator', function () {
            it('redeems the requested amount', async function () {
                await this.token.authorizeOperator(controller, {from: tokenHolder});
                await this.token.redeemFrom(tokenHolder, redeemAmount, ZERO_BYTE, VALID_CERTIFICATE, {from: controller});

                await assertTotalSupply(this.token, issuanceAmount - redeemAmount);
                await assertBalance(this.token, tokenHolder, issuanceAmount - redeemAmount);
            });
        });
        describe('when the sender is not an operator', function () {
            it('reverts', async function () {
                await shouldFail.reverting(this.token.redeemFrom(tokenHolder, redeemAmount, ZERO_BYTE, VALID_CERTIFICATE, {from: operator}));
            });
        });
    });

    ///////////////////////////////////////////////////////
    //  TRANSFERWITHDATA
    ///////////////////////////////////////////////////////
    describe('transferWithData', function () {
        const transferAmount = 300;

        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);

            await this.token.issue(controller, issuanceAmount, VALID_CERTIFICATE, {from: owner});
        });

        describe('when the sender has enough balance', function () {
            it('transfers the requested amount', async function () {
                await assertBalance(this.token, controller, issuanceAmount);
                await assertBalance(this.token, recipient, 0);
                await this.token.transferWithData(recipient, transferAmount, VALID_CERTIFICATE, {from: controller});
                await this.token.transferWithData(recipient, 0, VALID_CERTIFICATE, {from: controller});

                await assertBalance(this.token, controller, issuanceAmount - transferAmount);
                await assertBalance(this.token, recipient,  transferAmount);
            });
            it('emits a transferWithData event', async function () {
                const {logs} = await this.token.transferWithData(recipient, transferAmount, VALID_CERTIFICATE, {from: controller});

                assert.equal(logs.length, 3);

                assertTransferEvent(logs, controller, controller, recipient, transferAmount, VALID_CERTIFICATE, null);
            });
        });
        describe('when the sender does not have enough balance', function () {
            it('reverts', async function () {
                await shouldFail.reverting(this.token.transferWithData(recipient, transferAmount + issuanceAmount, VALID_CERTIFICATE, {from: controller}));
            });
        });
    });


    ///////////////////////////////////////////////////////
    //  TRANSFERFROMWITHDATA
    ///////////////////////////////////////////////////////
    describe('transferFromWithData', function () {
        const transferAmount = 300;

        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
            await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, { from: owner });
            await this.token.setCertificateSigner(operator, true, {from: owner});
        });

        describe('when the sender is an operator', function () {
            describe('when the sender has enough balance', function () {
                it('transfers the requested amount (when sender is specified)', async function () {
                    await assertBalance(this.token, tokenHolder, issuanceAmount);
                    await assertBalance(this.token, recipient,  0);
                    await this.token.authorizeOperator(operator, {from: tokenHolder});
                    await this.token.transferFromWithData(tokenHolder, recipient, transferAmount, ZERO_BYTE, VALID_CERTIFICATE, {from: operator});

                    await assertBalance(this.token, tokenHolder, issuanceAmount - transferAmount);
                    await assertBalance(this.token, recipient,  transferAmount);
                });
            });
        });
    });
})
