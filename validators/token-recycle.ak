use aiken/collection/list.{any, at}
use aiken/crypto.{Blake2b_224, Hash, VerificationKeyHash}
use cardano/address.{Address, Script, VerificationKey}
use cardano/assets.{AssetName, PolicyId, Value, from_asset, quantity_of}
use cardano/transaction.{
  Output, OutputReference, Transaction, Datum, InlineDatum,
}

pub type SenderPKH =
  Hash<Blake2b_224, VerificationKeyHash>

pub type RewardToken {
  pi: PolicyId,
  an: AssetName,
  qty: Int,
}

pub type RecycleDatum {
  receiverPKH: SenderPKH,
  tokenValue: RewardToken,
  policyId: PolicyId,
}

fn get_sender_pkh(address: Address) -> SenderPKH {
  let Address { payment_credential, .. } = address
  when payment_credential is {
    VerificationKey(vkey_hash) -> vkey_hash
    Script(_) -> fail @"script credential"
  }
}

fn rewardX(policy: PolicyId, cs: AssetName, qty: Int) -> Value {
  if qty >= 1 {
    from_asset(policy, cs, qty * 3)
  } else {
    fail @"not enough tokens"
  }
}

// Test for RewardX Function
test test_rewardX() {
  let policy = "00010203040506070809000102030405060708090001020304050607"
  let asset_name = "746f6b656e"
  // hex for "token"
  let qty = 2

  let expected = from_asset(policy, asset_name, 6)
  let result = rewardX(policy, asset_name, qty)

  result == expected
}

fn has_token(policy_id: PolicyId, token_name: AssetName, val: Value) -> Bool {
  quantity_of(val, policy_id, token_name) >= 1
}

test test_has_token() {
  let policy = "#00010203040506070809000102030405060708090001020304050607"
  let asset_name = "746f6b656e"
  // hex for "token"
  // Value that includes the token
  let val = from_asset(policy, asset_name, 5)

  let result = has_token(policy, asset_name, val)

  result == True
}

test test_has_token_none() {
  let policy = "#00010203040506070809000102030405060708090001020304050607"
  let asset_name = "746f6b656e"
  // hex for "token"
  // Value with zero quantity
  let val = from_asset(policy, asset_name, 0)

  let result = has_token(policy, asset_name, val)

  result == False
}

fn check_incoming_tx(
  tx: Transaction,
  policy_id: PolicyId,
  token_name: AssetName,
) -> Bool {
  let result =
    any(
      tx.outputs,
      fn(output: Output) -> Bool {
        has_token(policy_id, token_name, output.value)
      },
    )
  result
}

fn vRecycle(senderPKH: SenderPKH, datum: RecycleDatum, tx: Transaction) -> Bool {
  let Transaction { inputs, outputs, .. } = tx
  let has_required_token =
    check_incoming_tx(tx, datum.tokenValue.pi, datum.tokenValue.an)

  if !has_required_token {
    fail
  } else {
    // Ensure the transaction outputs include the new datum with the reward
    let expected_address =
      Address {
        payment_credential: VerificationKey(senderPKH),
        stake_credential: None,
      }
    let expected_value =
      rewardX(datum.policyId, datum.tokenValue.an, datum.tokenValue.qty)

    let has_output =
      any(
        outputs,
        fn(output: Output) -> Bool {
          output.address == expected_address && quantity_of(
            output.value,
            datum.tokenValue.pi,
            datum.tokenValue.an,
          ) >= datum.tokenValue.qty * 3
        },
      )

    if !has_output {
      fail
    } else {
      True
    }
  }
}

validator recycle_policy(utxo_ref: OutputReference) {
  spend(
    datum_opt: Option<RecycleDatum>,
    _redeemer: Void,
    _utxo_ref,
    tx: Transaction,
  ) {
    expect Some(datum) = datum_opt
    expect Some(inp) = at(tx.inputs, 0)
    let sender_pkh = get_sender_pkh(inp.output.address)
    vRecycle(sender_pkh, datum, tx)
  }

  else(_) {
    fail @"unsupported purpose"
  }
}

test test_vRecycle_success() {
  let sender = "#abcdef0123456789abcdef0123456789abcdef0123456789abcdef01"
  // Fake PKH
  let asset_name = "746f6b656e"
  // "token"
  let policy = "#00010203040506070809000102030405060708090001020304050607"

  let datum =
    RecycleDatum {
      receiverPKH: sender,
      tokenValue: RewardToken { pi: policy, an: asset_name, qty: 2 },
      policyId: policy,
    }

  let expected_output =
    Output {
      address: Address {
        payment_credential: VerificationKey(sender),
        stake_credential: None,
      },
      value: from_asset(policy, asset_name, 6),
      // 2 * 3
      datum: InlineDatum(datum),
      reference_script: None,
    }

  let tx = Transaction { ..placeholder, outputs: [expected_output] }

  vRecycle(sender, datum, tx) == True
}
