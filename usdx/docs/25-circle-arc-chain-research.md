# Circle Arc Chain Research & Integration Guide

## Overview

This document contains research findings and integration requirements for adding Circle's Arc chain as a spoke chain to the USDX Protocol. Arc is Circle's new blockchain network.

## Research Status

**Date**: January 2025  
**Status**: ✅ **UPDATED** - Key information gathered from Arc documentation

## What We Know About Arc Chain

### Basic Information
- **Name**: Arc (Circle's new blockchain network)
- **Type**: EVM-compatible Layer-1 blockchain
- **Status**: Testnet available, mainnet status TBD
- **Developer**: Circle
- **Documentation**: https://docs.arc.network

### Verified Information ✅
- ✅ **EVM-Compatible**: Arc is an EVM-compatible blockchain
- ✅ **Bridge Kit Support**: Circle Bridge Kit **DOES support** Arc chain
- ❌ **LayerZero Support**: LayerZero **DOES NOT** support Arc chain (as of January 2025)
- ✅ **CCTP Support**: Arc supports CCTP (Cross-Chain Transfer Protocol) - contract addresses documented
- ✅ **USDC Support**: USDC is available on Arc via CCTP
- ✅ **Testnet Available**: Arc testnet is operational

### Network Details

#### Testnet ✅ VERIFIED
- **Chain ID**: `5042002` ✅ **VERIFIED**
- **Network Name**: Arc Testnet
- **Currency**: USDC (native gas token) ✅ **VERIFIED**
- **Currency Symbol**: USDC
- **Currency Decimals**: 6 (USDC standard)
- **RPC Endpoints**:
  - Primary: `https://rpc.testnet.arc.network`
  - Alternative: `https://rpc.blockdaemon.testnet.arc.network`
  - Alternative: `https://rpc.drpc.testnet.arc.network`
  - Alternative: `https://rpc.quicknode.testnet.arc.network`
- **WebSocket**: `wss://rpc.testnet.arc.network`
- **Block Explorer**: `https://testnet.arcscan.app`
- **Faucet**: `https://faucet.circle.com`

#### Mainnet
- **Status**: TBD - Check Arc documentation for mainnet launch
- **RPC Endpoints**: TBD
- **Block Explorer**: TBD
- **Chain ID**: TBD

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

### 3. Bridge Kit Support ✅

#### Verified Information
- ✅ **Bridge Kit Support**: Circle Bridge Kit **DOES support** Arc chain
- ✅ **Bridge Kit Chain Identifier**: TBD - Check Bridge Kit SDK documentation for exact identifier (likely "arc" or "arc-testnet")
- ✅ **Adapter Support**: `@circle-fin/adapter-viem-v2` should support Arc (verify in SDK)

#### Verification Steps
1. ✅ Check Bridge Kit SDK documentation for supported chains - **CONFIRMED: Arc is supported**
2. [ ] Review Bridge Kit SDK source code to find exact chain identifier
3. [ ] Test Bridge Kit initialization with Arc chain
4. [ ] Verify adapter compatibility with Arc testnet

### 4. LayerZero Support ❌

#### Critical Finding
- ❌ **LayerZero Support**: LayerZero **DOES NOT** support Arc chain (as of January 2025)
- ⚠️ **Impact**: USDX cross-chain transfers via LayerZero will **NOT** work on Arc
- 🔄 **Alternative**: Need to use alternative cross-chain solution for USDX transfers to/from Arc

#### Implications for USDX Protocol
Since LayerZero is not supported on Arc:
1. **USDXShareOFT** (LayerZero-based) cannot be used for Arc
2. **Cross-chain USDX transfers** to/from Arc will need alternative mechanism
3. **Options to consider**:
   - Use Bridge Kit for USDC transfers (already supported)
   - Wait for LayerZero to add Arc support
   - Use alternative cross-chain protocol (if available)
   - Implement Arc-specific cross-chain solution

#### Verification Steps
1. ✅ Check LayerZero documentation - **CONFIRMED: Arc not supported**
2. [ ] Monitor LayerZero updates for Arc support
3. [ ] Evaluate alternative cross-chain solutions for Arc

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

#### Answered ✅
1. ✅ **Does Bridge Kit support Arc?** - **YES** - Bridge Kit supports Arc
2. ✅ **Does LayerZero support Arc?** - **NO** - LayerZero does not support Arc (as of January 2025)
3. ✅ **Does Arc support CCTP?** - **YES** - CCTP contract addresses are documented
4. ✅ **Is Arc testnet available?** - **YES** - Testnet is operational

#### Still Need Answers ⏳
1. ✅ **What is Arc's chain ID?** - **ANSWERED**: `5042002` (Arc Testnet)
   - ✅ Verified from Arc documentation (`/arc/references/connect-to-arc`)

2. **What is Arc's CCTP domain ID?**
   - Check Circle's CCTP documentation for Arc domain ID
   - Verify in contract addresses page
   - **Status**: CCTP contracts exist on Arc, domain ID needs verification

3. **What are the CCTP contract addresses on Arc?**
   - Check `/arc/references/contract-addresses` page
   - Contract addresses are documented (found addresses: `0x89B50855Aa3bE2F677cD6303Cec089B5F319D72a`, etc.)
   - **Action**: Extract and verify TokenMessenger and MessageTransmitter addresses

4. **What is Bridge Kit's chain identifier for Arc?**
   - Check Bridge Kit SDK documentation or source code
   - Likely "arc", "arc-testnet", or "arc-test"
   - **Action**: Test with Bridge Kit SDK or check SDK source

5. **Is Arc mainnet available?**
   - Check Arc documentation for mainnet status
   - Currently only testnet confirmed (chain ID 5042002)

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

### Arc Documentation
- **Main Docs**: https://docs.arc.network
- **Welcome Page**: https://docs.arc.network/arc/concepts/welcome-to-arc
- **Connect to Arc**: https://docs.arc.network/arc/references/connect-to-arc
- **Contract Addresses**: https://docs.arc.network/arc/references/contract-addresses
- **Deploy on Arc**: https://docs.arc.network/arc/tutorials/deploy-on-arc

### Other Resources
- **ChainList**: https://chainlist.org (may list Arc if it's public)
- **Circle GitHub**: https://github.com/circlefin (may have updates)
- **Arc Testnet Explorer**: https://testnet.arcscan.app
- **Arc Faucet**: https://faucet.circle.com

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
**Status**: ✅ Research updated with Arc documentation findings

## Key Findings Summary

### ✅ Confirmed
- Bridge Kit supports Arc
- CCTP is supported on Arc
- Testnet is available
- EVM-compatible blockchain

### ❌ Limitations
- LayerZero does NOT support Arc
- This impacts USDX cross-chain transfers

### ⏳ Still Needed
- ✅ Chain ID - **FOUND**: `5042002` (Arc Testnet)
- CCTP domain ID - Check Circle CCTP docs
- CCTP contract addresses - Extract from `/arc/references/contract-addresses`
- Bridge Kit chain identifier - Verify with Bridge Kit SDK
- Mainnet status - TBD
