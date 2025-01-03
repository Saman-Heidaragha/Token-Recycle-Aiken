# Token Recycler Contract (Aiken Version)

## Overview

The Token Recycler contract is written in Aiken. It allows users to send tokens to the contract. The contract then calculates a reward based on the amount of tokens sent and returns the tokens to the user.

## Use Case

This contract is useful when you want to incentivize users to recycle certain tokens. For example, if you want to encourage users to recycle specific tokens, this contract can provide rewards for doing so. The reward is three times the value of the tokens sent.

## How It Works

1. **Send Tokens**: A user sends tokens to the contract.
2. **Calculate Reward**: The contract calculates a reward based on the value of the tokens sent. The reward is three times the value of the tokens.
3. **Return Tokens**: The contract sends the tokens back to the user along with the calculated reward.

## Steps to Interact with the Contract

### 1. Prepare the Tokens

### 2. Send Tokens to the Contract

When you send tokens to the contract, it captures the details of the transaction. The contract expects the following details:

- **SenderPKH**: The public key hash of the sender.
- **TokenValue**: The value of the tokens being sent.
- **PolicyId**: The policy ID of the token.

### 3. Contract Processing

Upon receiving the tokens, the contract performs several checks and calculations:

- **Check for Tokens**: It verifies that the input contains the required tokens.
- **Calculate Reward**: It calculates the reward, which is three times the quantity of tokens.
- **Validate Transaction**: It ensures the transaction includes the expected output, which is the reward calculated and sent back to the sender.

### 4. Receive Tokens

If all checks pass, the contract sends back the tokens to the sender's address along with the calculated reward.

## Detailed Explanation of Key Components

### Key Components

- **SenderPKH**: This is the public key hash of the sender.
- **RewardToken**: This includes the policy ID, asset name, and quantity of the token.
- **RecycleDatum**: This holds the following details:
  - `receiverPKH`: The public key hash of the receiver.
  - `tokenValue`: The value of the tokens.
  - `policyId`: The currency symbol (policy ID) of the token.

### Helper Functions

- **get_sender_pkh**: Extracts the sender's public key hash from an address.
- **rewardX**: Calculates the reward value by multiplying the quantity by three.
- **has_token**: Checks if a value contains at least one token of a specified policy and name.

### Validator Function

- **vRecycle**: This is the core function that validates the transaction:
  - It checks if the input contains the required token.
  - It ensures the output includes the new datum with the reward value.
  - It validates that the output address matches the sender's public key hash.

### Main Validator

- **recycle_validator**: This function validates the transaction by calling `vRecycle` with the sender's public key hash, datum, and script context.


