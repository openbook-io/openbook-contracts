let totalSupply;
let balance;
const ZERO_ADDRESS                      = '0x0000000000000000000000000000000000000000';

export const assertTransferEvent = (
  _logs,
  _operator,
  _from,
  _to,
  _amount,
  _data,
  _operatorData
) => {
  let i = 0;
  if (_logs.length === 3) {
    assert.equal(_logs[0].event, 'Checked');
    assert.equal(_logs[0].args.sender, _operator);
    i = 1;
  }

  assert.equal(_logs[i].event, 'TransferWithData');
  assert.equal(_logs[i].args.operator, _operator);
  assert.equal(_logs[i].args.from, _from);
  assert.equal(_logs[i].args.to, _to);
  assert.equal(_logs[i].args.value, _amount);
  assert.equal(_logs[i].args.data, _data);
  assert.equal(_logs[i].args.operatorData, _operatorData);

  i++;

  assert.equal(_logs[i].event, 'Transfer');
  assert.equal(_logs[i].args.from, _from);
  assert.equal(_logs[i].args.to, _to);
  assert.equal(_logs[i].args.value, _amount);
};

export const assertBurnEvent = (
  _logs,
  _operator,
  _from,
  _amount,
  _data,
  _operatorData
) => {
  let i = 0;
  if (_logs.length === 3) {
    assert.equal(_logs[0].event, 'Checked');
    assert.equal(_logs[0].args.sender, _operator);
    i = 1;
  }

  assert.equal(_logs[i].event, 'Redeemed');
  assert.equal(_logs[i].args.operator, _operator);
  assert.equal(_logs[i].args.from, _from);
  assert.equal(_logs[i].args.value, _amount);
  assert.equal(_logs[i].args.data, _data);
  assert.equal(_logs[i].args.operatorData, _operatorData);

  i++;

  assert.equal(_logs[i].event, 'Transfer');
  assert.equal(_logs[i].args.from, _from);
  assert.equal(_logs[i].args.to, ZERO_ADDRESS);
  assert.equal(_logs[i].args.value, _amount);
};

export const assertBalance = async (
  _contract,
  _tokenHolder,
  _amount
) => {
  balance = await _contract.balanceOf(_tokenHolder);
  assert.equal(balance, _amount);
};

export const assertTotalSupply = async (_contract, _amount) => {
  totalSupply = await _contract.totalSupply();
  assert.equal(totalSupply, _amount);
};
