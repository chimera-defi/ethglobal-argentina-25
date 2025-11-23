# LayerZero SDK Migration Plan

## Overview

This document outlines the plan to migrate from simplified LayerZero implementations to the official LayerZero SDK.

## Current Status

- ✅ Official LayerZero SDK packages installed: `@layerzerolabs/lz-evm-oapp-v2@3.0.147`
- ✅ Official contracts available in `lib/LayerZero-v2/packages/layerzero-v2/evm/`
- ⚠️ Current contracts use simplified implementations
- ⚠️ Need to migrate to official SDK contracts

## Migration Strategy

### Phase 1: Migrate USDXShareOFT to Official OFT

**Current**: Custom `USDXShareOFT` contract
**Target**: Extend official `OFT` contract from SDK

**Changes Required**:
1. Extend `OFT` instead of `ERC20`
2. Use `OApp` pattern for LayerZero integration
3. Update constructor to match SDK pattern
4. Update `send` function to use SDK's `send` method
5. Update `lzReceive` to use SDK's `_lzReceive` pattern

### Phase 2: Migrate USDXShareOFTAdapter to Official OFTAdapter

**Current**: Custom `USDXShareOFTAdapter` contract
**Target**: Extend official `OFTAdapter` contract from SDK

**Changes Required**:
1. Extend `OFTAdapter` instead of custom implementation
2. Override `_debit` and `_credit` for vault share locking/unlocking
3. Update to use SDK's `send` method
4. Update `lzReceive` to use SDK's `_lzReceive` pattern

### Phase 3: Update USDXVaultComposerSync

**Current**: Custom composer implementation
**Target**: Keep custom implementation but update to work with official SDK contracts

**Changes Required**:
1. Update to use official SDK's `SendParam` and `MessagingFee` types
2. Update to use SDK's `send` method from OFTAdapter
3. Update message encoding/decoding to match SDK format

### Phase 4: Update Deployment Scripts

**Changes Required**:
1. Add LayerZero endpoint addresses for all networks
2. Update deployment scripts to use correct endpoint addresses
3. Add configuration for DVNs and executors
4. Add trusted remote setup

### Phase 5: Update Tests

**Changes Required**:
1. Update mocks to match official SDK interfaces
2. Update test expectations for SDK message formats
3. Add integration tests with official SDK patterns

## LayerZero Endpoint Addresses

### Mainnet
- Ethereum: `0x1a44076050125825900e736c501f859c50fE728c`
- Polygon: `0x1a44076050125825900e736c501f859c50fE728c`
- Arbitrum: `0x1a44076050125825900e736c501f859c50fE728c`
- Base: `0x1a44076050125825900e736c501f859c50fE728c`
- Optimism: `0x1a44076050125825900e736c501f859c50fE728c`

### Testnet
- Ethereum Sepolia: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- Polygon Mumbai: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- Arbitrum Sepolia: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- Base Sepolia: `0x6EDCE65403992e310A62460808c4b910D972f10f`
- Optimism Sepolia: `0x6EDCE65403992e310A62460808c4b910D972f10f`

### Forked Mainnet (Local Testing)
- Use `MockLayerZeroEndpoint` for local testing
- Endpoint address: Deploy mock endpoint in deployment script

## Endpoint IDs (EIDs)

- Ethereum Mainnet: `30101`
- Ethereum Sepolia: `40161`
- Polygon Mainnet: `30109`
- Polygon Mumbai: `40109`
- Arbitrum One: `30110`
- Arbitrum Sepolia: `40231`
- Base Mainnet: `30184`
- Base Sepolia: `40245`
- Optimism Mainnet: `30111`
- Optimism Sepolia: `40232`

## Implementation Notes

1. **OApp Pattern**: All contracts must extend `OApp` or use `OAppCore`
2. **Peer Configuration**: Must set peers using `setPeer(uint32 eid, bytes32 peer)`
3. **Message Encoding**: Use SDK's `OFTMsgCodec` for message encoding/decoding
4. **Fee Handling**: Use SDK's `MessagingFee` and `quoteSend` for fee estimation
5. **Compose Messages**: Use SDK's `OFTComposeMsgCodec` for compose messages

## Testing Strategy

1. **Unit Tests**: Update existing tests to use official SDK patterns
2. **Integration Tests**: Test with mock endpoints first
3. **Forked Mainnet Tests**: Test on forked mainnet with mock endpoints
4. **Testnet Tests**: Test on actual testnets with real endpoints

## Rollout Plan

1. ✅ Create migration plan (this document)
2. ⏳ Migrate USDXShareOFT to official OFT
3. ⏳ Migrate USDXShareOFTAdapter to official OFTAdapter
4. ⏳ Update USDXVaultComposerSync
5. ⏳ Update deployment scripts
6. ⏳ Update tests
7. ⏳ Test on forked mainnet
8. ⏳ Deploy to testnet
9. ⏳ Deploy to mainnet

## Risk Mitigation

1. **Backward Compatibility**: Keep old contracts for reference
2. **Gradual Migration**: Migrate one contract at a time
3. **Comprehensive Testing**: Test each migration step thoroughly
4. **Rollback Plan**: Keep ability to rollback to simplified implementations

