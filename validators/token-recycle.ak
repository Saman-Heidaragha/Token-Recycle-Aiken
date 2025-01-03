use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction.{OutputReference, ScriptContext, Transaction, Input, Output}
use aiken/transaction/value.{PolicyId, AssetName, Value, quantity_of, from_asset}
use aiken/transaction/credential.{VerificationKey, Address, VerificationKeyCredential, ScriptCredential, from_verification_key}
use aiken/list.{any, at}
use aiken/bytearray
use aiken/builtin.{blake2b_256, serialise_data}
use aiken/math/rational.{zero}

type SenderPKH = Hash<Blake2b_224, VerificationKey>
type TokenValue = Value

type RewardToken {
    pi: PolicyId,
    an: AssetName,
    qty: Int,
}

type RecycleDatum {
    receiverPKH: SenderPKH,
    tokenValue: RewardToken,
    policyId: PolicyId,
}

fn get_sender_pkh(address: Address) -> SenderPKH {
    let Address { payment_credential, .. } = address
    when payment_credential is {
        VerificationKeyCredential(vkey) -> vkey
        ScriptCredential(_) -> error
    }
}

fn rewardX(policy: PolicyId, cs: AssetName, qty: Int) -> Value {
    if qty >= 1 {
        from_asset(policy, cs, qty * 3)
    } else {
        error
    }
}

fn has_token(policy_id: PolicyId, token_name: AssetName, val: Value) -> Bool {
    quantity_of(val, policy_id, token_name) >= 1
}

fn vRecycle(
    senderPKH: SenderPKH,
    datum: RecycleDatum,
    scriptContext: ScriptContext
) -> Bool {
    let Transaction { inputs, outputs, .. } = scriptContext.transaction

    let has_required_token = any(inputs, fn(input: Input) -> Bool {
        has_token(datum.policyId, datum.tokenValue.an, input.output.value)
    })

    if !has_required_token {
        error
    } else {
        // Ensure the transaction outputs include the new datum with the reward
        let expected_address = Address {
            payment_credential: VerificationKeyCredential(senderPKH),
            stake_credential: None
        }
        let expected_value = rewardX(datum.policyId, datum.tokenValue.an, datum.tokenValue.qty)

        let has_output = any(outputs, fn(output: Output) -> Bool {
            output.address == expected_address && output.value == expected_value
        })

        if !has_output {
            error
        } else {
            True
        }
    }
}

validator {
    fn recycle_validator(datum: RecycleDatum, _redeemer: Void, ctx: ScriptContext) -> Bool {
        let input_option = at(ctx.transaction.inputs, 0)
        let sender_pkh = when input_option is {
            Some(input) -> {
                let address = input.output.address
                get_sender_pkh(address)
            }
            None -> error
        }
        vRecycle(sender_pkh, datum, ctx)
    }
}
