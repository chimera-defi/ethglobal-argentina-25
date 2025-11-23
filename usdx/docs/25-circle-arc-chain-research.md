# Circle Arc Chain Research & Integration Guide

## Overview

This document contains research findings and integration requirements for adding Circle's Arc chain as a spoke chain to the USDX Protocol. Arc is Circle's new blockchain network.

## Research Status

**Date**: January 2025  
**Status**: ⚠️ **IN PROGRESS** - Documentation may be limited as Arc is a new chain

## What We Know About Arc Chain

### Basic Information
- **Name**: Arc (Circle's new chain)
- **Type**: Blockchain network (likely EVM-compatible based on Circle's infrastructure)
- **Status**: Newly announced/launched chain
- **Developer**: Circle

### Assumptions (To Be Verified)
Based on Circle's existing infrastructure patterns:
- Arc is likely EVM-compatible (for CCTP/Bridge Kit support)
- Arc likely supports USDC via CCTP
- Arc likely supports Circle Bridge Kit
- Arc likely has LayerZero support (for USDX cross-chain transfers)

## Integration Requirements

### 1. Chain Configuration

#### Required Information
- [ ] **Chain ID**: Numeric chain ID for Arc
- [ ] **Network Name**: Official network name
- [ ] **RPC Endpoints**: 
  - Mainnet RPC URL
  - Testnet RPC URL (if available)
- [ ] **Block Explorer**: Block explorer URL
- [ ] **Native Currency**: Currency symbol and decimals
- [ ] **Chain Type**: EVM-compatible or other

#### Where to Find This Information
1. Circle Developer Documentation: `https://developers.circle.com`
2. Circle Bridge Kit Documentation: `https://developers.circle.com/bridge-kit`
3. Circle CCTP Documentation: `https://developers.circle.com/stablecoin/docs/cctp-overview`
4. Arc Chain Official Documentation (if available)
5. ChainList.org (if Arc is listed)

### 2. CCTP (Cross-Chain Transfer Protocol) Support

#### Required Information
- [ ] **CCTP Domain ID**: Arc's CCTP domain identifier
- [ ] **TokenMessenger Address**: Contract address for burning USDC
- [ ] **MessageTransmitter Address**: Contract address for minting USDC
- [ ] **USDC Contract Address**: Native USDC contract address on Arc
- [ ] **Attestation Service**: Confirmation that Circle's attestation service supports Arc

#### Verification Steps
1. Check Circle's CCTP smart contracts documentation
2. Verify contract addresses on Arc block explorer
3. Test CCTP transfer on testnet (if available)
4. Confirm attestation API supports Arc domain

### 3. Bridge Kit Support

#### Required Information
- [ ] **Bridge Kit Chain Identifier**: String identifier used by Bridge Kit SDK (e.g., "arc", "arc-mainnet")
- [ ] **Bridge Kit Support**: Confirmation that Bridge Kit SDK supports Arc
- [ ] **Adapter Support**: Confirmation that `@circle-fin/adapter-viem-v2` supports Arc

#### Verification Steps
1. Check Bridge Kit SDK documentation for supported chains
2. Review Bridge Kit SDK source code (if available)
3. Test Bridge Kit initialization with Arc chain
4. Verify adapter compatibility

### 4. LayerZero Support (For USDX Cross-Chain)

#### Required Information
- [ ] **LayerZero Endpoint Address**: LayerZero endpoint contract on Arc
- [ ] **LayerZero Chain ID**: Arc's LayerZero endpoint ID (EID)
- [ ] **LayerZero Support**: Confirmation that LayerZero supports Arc

#### Verification Steps
1. Check LayerZero documentation for supported chains
2. Verify LayerZero endpoint contract deployment
3. Test LayerZero message passing to/from Arc

### 5. Network Configuration

#### Frontend Configuration
- [ ] Add Arc to `frontend/src/config/chains.ts`
- [ ] Add Arc to Bridge Kit chain mapping in `frontend/src/lib/bridgeKit.ts`
- [ ] Add Arc to wallet provider chain configurations
- [ ] Update chain selector UI components

#### Backend/Contract Configuration
- [ ] Update deployment scripts (`DeploySpoke.s.sol`, `DeploySpokeOnly.s.sol`)
- [ ] Add Arc chain ID handling in contracts
- [ ] Update LayerZero endpoint ID mappings
- [ ] Update CCTP domain mappings

## Current Project Structure

### Spoke Chain Implementation

The USDX Protocol uses a hub-and-spoke architecture:

1. **Hub Chain**: Ethereum (where USDC collateral is held)
2. **Spoke Chains**: Other chains where USDX can be minted (currently Base Sepolia, Polygon)

#### Key Files for Spoke Chain Integration

1. **Deployment Scripts**:
   - `usdx/contracts/script/DeploySpoke.s.sol` - Main spoke deployment
   - `usdx/contracts/script/DeploySpokeOnly.s.sol` - Spoke-only deployment

2. **Frontend Configuration**:
   - `usdx/frontend/src/config/chains.ts` - Chain definitions
   - `usdx/frontend/src/lib/bridgeKit.ts` - Bridge Kit chain mappings

3. **Contract Configuration**:
   - `usdx/contracts/USDXSpokeMinter.sol` - Spoke minter contract
   - `usdx/contracts/USDXToken.sol` - USDX token contract
   - `usdx/contracts/USDXShareOFT.sol` - Cross-chain share representation

## Integration Pattern

### Step-by-Step Integration Pattern

Based on existing spoke chain implementations:

1. **Chain Configuration**
   ```typescript
   // Add to frontend/src/config/chains.ts
   ARC: {
     id: <CHAIN_ID>,
     name: 'Arc',
     rpcUrl: '<RPC_URL>',
     currency: '<NATIVE_CURRENCY>',
     blockExplorer: '<BLOCK_EXPLORER_URL>',
   }
   ```

2. **Bridge Kit Mapping**
   ```typescript
   // Add to frontend/src/lib/bridgeKit.ts
   <CHAIN_ID>: 'arc' // or 'arc-mainnet'
   ```

3. **Deployment Script Update**
   ```solidity
   // Update DeploySpoke.s.sol
   if (chainId == <ARC_CHAIN_ID>) {
       POSITION_ORACLE = msg.sender;
       LOCAL_EID = <ARC_LAYERZERO_EID>;
   }
   ```

4. **LayerZero Configuration**
   - Update LayerZero endpoint ID mappings
   - Configure cross-chain paths (Hub ↔ Arc)

## Research Checklist

### Documentation Review
- [ ] Circle Developer Documentation
- [ ] Circle Bridge Kit Documentation
- [ ] Circle CCTP Documentation
- [ ] Arc Chain Official Documentation
- [ ] LayerZero Documentation

### Technical Verification
- [ ] Verify Arc chain ID
- [ ] Verify CCTP contract addresses
- [ ] Verify Bridge Kit support
- [ ] Verify LayerZero support
- [ ] Test network connectivity
- [ ] Test USDC transfers via CCTP
- [ ] Test Bridge Kit integration

### Integration Planning
- [ ] Map integration requirements
- [ ] Identify code changes needed
- [ ] Plan testing strategy
- [ ] Document deployment process

## Known Gaps & Questions

### Critical Questions
1. **What is Arc's chain ID?**
   - Need to verify from Circle documentation or Arc chain docs

2. **Does Arc support CCTP?**
   - Need to verify CCTP contract deployment on Arc
   - Need to verify domain ID assignment

3. **Does Bridge Kit support Arc?**
   - Need to check Bridge Kit SDK for Arc support
   - May need to wait for Bridge Kit update if not yet supported

4. **Does LayerZero support Arc?**
   - Need to verify LayerZero endpoint deployment
   - Need to verify endpoint ID (EID)

5. **Is Arc mainnet or testnet?**
   - Need to determine if testnet is available for testing

### Documentation Gaps
- Arc chain may be too new for comprehensive documentation
- May need to contact Circle support for specific details
- May need to check Circle's GitHub repositories for updates

## Resources

### Circle Documentation
- **Main Docs**: https://developers.circle.com
- **Bridge Kit**: https://developers.circle.com/bridge-kit
- **CCTP**: https://developers.circle.com/stablecoin/docs/cctp-overview
- **CCTP Contracts**: https://developers.circle.com/stablecoin/docs/cctp-smart-contracts

### LayerZero Documentation
- **Main Docs**: https://layerzero.gitbook.io/docs
- **Supported Chains**: https://layerzero.gitbook.io/docs/technical-reference/mainnet/mainnet-addresses

### Other Resources
- **ChainList**: https://chainlist.org (may list Arc if it's public)
- **Circle GitHub**: https://github.com/circlefin (may have updates)

## Next Steps

1. **Complete Research**: Gather all required information about Arc chain
2. **Verify Support**: Confirm CCTP, Bridge Kit, and LayerZero support
3. **Create Implementation Plan**: Document exact code changes needed
4. **Test Integration**: Test on testnet (if available) before mainnet
5. **Documentation**: Update project documentation with Arc chain details

## Notes

- Arc is a new chain, so documentation may be limited
- May need to wait for Circle to publish full documentation
- Integration may require updates to Bridge Kit SDK or LayerZero
- Consider testing on testnet first (if available)

---

**Last Updated**: January 2025  
**Status**: Research in progress - awaiting Circle documentation updates
