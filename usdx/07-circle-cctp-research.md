# Circle CCTP Research

## Overview

Circle's Cross-Chain Transfer Protocol (CCTP) is a permissionless on-chain utility that enables developers to build cross-chain applications with native USDC transfers. It uses a burn-and-mint mechanism with attestation verification.

## Key Components

### 1. TokenMessenger Contract
- **Function**: Burns USDC on source chain
- **Location**: Deployed on each supported chain
- **Key Functions**:
  - `depositForBurn(uint256 amount, uint32 destinationDomain, bytes32 mintRecipient, address burnToken)`
  - Emits `DepositForBurn` event

### 2. MessageTransmitter Contract
- **Function**: Transmits messages and verifies attestations
- **Location**: Deployed on each supported chain
- **Key Functions**:
  - `sendMessage(uint32 destinationDomain, bytes32 recipient, bytes calldata messageBody)`
  - `receiveMessage(bytes calldata message, bytes calldata attestation)`
  - `attestationHash(bytes calldata message, bytes32 attester)`

### 3. Attestation Service
- **Function**: Provides cryptographic attestations for burn events
- **Type**: Off-chain service (Circle-operated)
- **API**: REST API endpoint
- **Process**: 
  1. Monitor burn events
  2. Generate attestation
  3. Provide via API

## Supported Chains and Domains

| Chain | Domain ID | TokenMessenger | MessageTransmitter |
|-------|-----------|----------------|-------------------|
| Ethereum | 0 | 0x... | 0x... |
| Avalanche | 1 | 0x... | 0x... |
| Optimism | 2 | 0x... | 0x... |
| Arbitrum | 3 | 0x... | 0x... |
| Base | 6 | 0x... | 0x... |
| Polygon | 7 | 0x... | 0x... |

## Integration Flow

### Step 1: Burn USDC on Source Chain

```solidity
// User calls TokenMessenger
ITokenMessenger tokenMessenger = ITokenMessenger(TOKEN_MESSENGER_ADDRESS);
tokenMessenger.depositForBurn(
    amount,                    // Amount to burn
    destinationDomain,         // Destination chain domain
    mintRecipient,             // Bytes32 address on destination
    USDC_ADDRESS              // Token to burn
);
```

### Step 2: Get Attestation

```javascript
// Poll Circle's Attestation API
const attestation = await fetch(
  `https://iris-api.circle.com/attestations/${messageHash}`
);
```

### Step 3: Mint USDC on Destination Chain

```solidity
// Call MessageTransmitter with attestation
IMessageTransmitter transmitter = IMessageTransmitter(MESSAGE_TRANSMITTER_ADDRESS);
transmitter.receiveMessage(message, attestation);
```

## Message Format

```solidity
struct BurnMessage {
    bytes32 version;           // Version (currently 0x00000001)
    uint32 sourceDomain;       // Source chain domain
    uint32 destinationDomain;  // Destination chain domain
    bytes32 nonce;            // Nonce for replay protection
    bytes32 sender;           // Sender address (bytes32)
    bytes32 mintRecipient;    // Recipient address (bytes32)
    bytes32 amount;           // Amount (bytes32, uint256)
    bytes32 burnToken;        // Token address (bytes32)
}
```

## Attestation Format

- **Type**: ECDSA signature
- **Signer**: Circle's attestation service
- **Format**: Bytes array
- **Verification**: Done on-chain by MessageTransmitter

## Key Considerations for USDX

### 1. Address Format
- CCTP uses `bytes32` for addresses (not `address`)
- Need to convert between formats:
  ```solidity
  bytes32 mintRecipient = bytes32(uint256(uint160(userAddress)));
  ```

### 2. Attestation Timing
- Attestations typically available within seconds
- May take up to a few minutes in edge cases
- Need to handle pending state in UI

### 3. Gas Costs
- Source chain: Burn transaction + message send
- Destination chain: Attestation verification + mint
- Total: ~100k-200k gas per transfer

### 4. Error Handling
- Attestation not available: Retry mechanism
- Invalid attestation: Reject transaction
- Message replay: Prevented by nonce

### 5. Integration Points
- **USDXVault**: Use CCTP for cross-chain USDC deposits
- **User Flow**: User deposits USDC on Chain A, it's moved to Chain B vault via CCTP
- **Redemption**: User can redeem on any chain, USDC moved via CCTP if needed

## SDK and Tools

### Circle CCTP SDK
- **Language**: TypeScript/JavaScript
- **Functions**:
  - `burnToken()`: Burn USDC
  - `getAttestation()`: Poll for attestation
  - `receiveMessage()`: Complete transfer
- **Usage**: Can simplify integration

### Example Integration

```typescript
import { CCTP } from '@circle-fin/cctp-sdk';

const cctp = new CCTP({
  sourceChain: 'ethereum',
  destinationChain: 'polygon',
});

// Burn USDC
const burnTx = await cctp.burnToken({
  amount: '1000000', // 1 USDC (6 decimals)
  recipient: destinationAddress,
});

// Wait for attestation
const attestation = await cctp.getAttestation(burnTx.messageHash);

// Complete on destination
const mintTx = await cctp.receiveMessage({
  message: burnTx.message,
  attestation: attestation,
});
```

## Security Considerations

1. **Attestation Verification**: Done on-chain, secure
2. **Replay Protection**: Nonce prevents replay attacks
3. **Centralization**: Circle operates attestation service (trusted)
4. **Upgradeability**: Contracts may be upgradeable (check)

## Limitations

1. **USDC Only**: Only supports USDC transfers
2. **Circle Dependency**: Relies on Circle's attestation service
3. **Supported Chains**: Limited to Circle-supported chains
4. **Gas Costs**: Can be expensive on some chains

## Resources

- **Documentation**: https://developers.circle.com/stablecoin/docs/cctp-overview
- **API Reference**: https://developers.circle.com/stablecoin/docs/cctp-api-reference
- **SDK**: https://github.com/circlefin/cctp-sdk
- **Contract Addresses**: https://developers.circle.com/stablecoin/docs/cctp-smart-contracts

## Questions to Resolve

1. **Contract Addresses**: Need to verify mainnet addresses for each chain
2. **Upgradeability**: Check if contracts are upgradeable and implications
3. **Rate Limits**: Any rate limits on attestation API?
4. **Fees**: Are there any fees beyond gas costs?
5. **Error Codes**: Understand all possible error conditions

## Integration Checklist

- [ ] Verify contract addresses for all chains
- [ ] Test CCTP integration on testnets
- [ ] Implement address conversion (address <-> bytes32)
- [ ] Implement attestation polling logic
- [ ] Handle error cases
- [ ] Add UI for pending CCTP transfers
- [ ] Test end-to-end flow
- [ ] Optimize gas usage
- [ ] Add monitoring/alerting
