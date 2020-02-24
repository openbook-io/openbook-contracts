const OpenBookToken = artifacts.require('OpenBookToken.sol');
const DividendContract = artifacts.require('Dividend.sol');
const shouldFail = require('./utils/ShouldFail');

const owner                             = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const controller                        = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const tokenHolder                       = '0x076a40A4468d5C957E4F71aDE543a471A2Efd6DA';


const CERTIFICATE_SIGNER                = '0x91620735349a0B25750facc8e3354c9f02B1518B';
const ZERO_ADDRESS                      = '0x0000000000000000000000000000000000000000';

const VALID_CERTIFICATE                 = '0x000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';
const documentName                      = "0x4f70656e426f6f6b546f6b656e00000000000000000000000000000000000000";
const ZERO_BYTE                         = '0x';

const depositAmount                     = web3.utils.toWei('10', 'ether');
const halfOfDepositAmount               = web3.utils.toWei('5', 'ether');

contract('Dividend Strategy', function () {
    ///////////////////////////////////////////////////////
    //   Parameters Testing
    ///////////////////////////////////////////////////////
    describe('parameters', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
            this.dividend = await DividendContract.new(this.token.address, CERTIFICATE_SIGNER);
        });
        describe('claimable', function () {

            it('returns false', async function () {
                    const claimable = await this.dividend.claimable();
                    assert.isTrue(!claimable)
                }
            )
        });
        describe('token', function () {
            beforeEach(async function () {
                this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
                this.dividend = await DividendContract.new(this.token.address, CERTIFICATE_SIGNER);
            });
            it('returns token address', async function () {
                const tokenAddress = await this.dividend.token();
                assert.equal(tokenAddress, this.token.address)
            });
        });
    });

    ///////////////////////////////////////////////////////
    //   Deposit
    ///////////////////////////////////////////////////////
    describe('deposit', function () {
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);
            this.dividend = await DividendContract.new(this.token.address, CERTIFICATE_SIGNER);
        });
        it('can send eth to dividend', async function () {
           await web3.eth.sendTransaction({
               from: controller,
               to: this.dividend.address,
               value: depositAmount,
               gas: 6000000,
               gasPrice: 10
           });
            const balance = await web3.eth.getBalance(this.dividend.address);
            assert.equal(depositAmount, balance)
        });
        it('can get totalDepositCount', async function () {
            await web3.eth.sendTransaction({
                from: controller,
                to: this.dividend.address,
                value: depositAmount,
                gas: 6000000,
                gasPrice: 10
            });

            const totalDepositCount = await this.dividend.totalDepositCount();
            assert.equal(totalDepositCount, 1);
        });
    });

    ///////////////////////////////////////////////////////
    //  Get ClaimAmount
    ///////////////////////////////////////////////////////
    describe('Get ClaimAmount', function () {
        const issuanceAmount = 5;
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);

            await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: owner});
            await this.token.issue(controller, issuanceAmount, VALID_CERTIFICATE, {from: owner});

            this.dividend = await DividendContract.new(this.token.address, CERTIFICATE_SIGNER);

            await web3.eth.sendTransaction({
                from: controller,
                to: this.dividend.address,
                value: depositAmount,
                gas: 6000000,
                gasPrice: 10
            });
        });

        it('can get claimableCount', async function () {
            await this.dividend.start({from: owner});
            const count = await this.dividend.claimableCount();
            assert.equal(count, 1);
        });

        it('can get claimableAmount at count', async function () {
           await this.dividend.start({from: owner});
           const amount = await this.dividend.getClaimAmountAt(tokenHolder, 0);
           assert.equal(amount, halfOfDepositAmount);
        });

        it('can get claimableAmount', async function () {
            await this.dividend.start({from: owner});
            const amount1 = await this.dividend.getClaimAmount(tokenHolder);
            assert.equal(amount1, halfOfDepositAmount);
            const amount2 = await this.dividend.getClaimAmount(controller);
            assert.equal(amount2, halfOfDepositAmount);
        });
    });

    ///////////////////////////////////////////////////////
    //  Claim
    ///////////////////////////////////////////////////////
    describe('Claim', function () {
        const issuanceAmount = 5;
        beforeEach(async function () {
            this.token = await OpenBookToken.new('OpenBookToken', 'OBT', 1, [controller], CERTIFICATE_SIGNER);

            await this.token.issue(tokenHolder, issuanceAmount, VALID_CERTIFICATE, {from: owner});
            await this.token.issue(controller, issuanceAmount, VALID_CERTIFICATE, {from: owner});

            this.dividend = await DividendContract.new(this.token.address, CERTIFICATE_SIGNER);

            await web3.eth.sendTransaction({
                from: controller,
                to: this.dividend.address,
                value: depositAmount,
                gas: 6000000,
                gasPrice: 10
            });
        });

        it('can claim', async function () {
            const beforeBalance = await web3.eth.getBalance(this.dividend.address);
            await this.dividend.start({from: owner});
            await this.dividend.claim(VALID_CERTIFICATE, {from: controller});
            const afterBalance = await web3.eth.getBalance(this.dividend.address);
            assert.equal(beforeBalance, depositAmount);
            assert.equal(afterBalance, halfOfDepositAmount);
        });
    });
});
