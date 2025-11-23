# ethglobal-argentina-25

## USDX Protocol

**USDX** is a decentralized yield-bearing stablecoin with unified yield generation across multiple chains. USDX uses LayerZero OVault for cross-chain yield vault integration with a hub-and-spoke architecture, enabling users to mint USDX on any supported chain while maintaining a single collateral source and unified yield generation on Ethereum.

USDX integrates **Circle Bridge Kit** to allow users to seamlessly and without fees bridge USDC from any of the spoke chains to the hub chain (Ethereum) to mint USDX, providing a frictionless cross-chain experience.

**Documentation:**
- **[USDX Prospectus](./usdx/docs/USDX-PROSPECTUS.md)** - Executive overview
- **[USDX README](./usdx/README.md)** - Complete project documentation with architecture diagrams
- **[USDX Documentation Index](./usdx/docs/README.md)** - Full documentation index
- **[Flow Diagrams](./usdx/docs/03-flow-diagrams.md)** - Visual flow diagrams for deposit, mint, transfer, and withdrawal processes

### Prize Submissions

#### LayerZero Cross-Chain Implementation Prize

We are targeting the **LayerZero Cross-Chain Implementation** prize at ETHGlobal Buenos Aires 2025.

**Prize Category:** 🌐 LayerZero Cross-Chain Implementation - $20,000 prize pool

**What We Built:**

USDX implements a comprehensive cross-chain stablecoin protocol using **LayerZero OVault** for unified yield generation across multiple chains:

- ✅ **Hub-and-Spoke Architecture** - Ethereum hub with collateral and yield, spoke chains for minting
- ✅ **LayerZero OVault Integration** - Cross-chain yield vault using OVault standard
- ✅ **USDXShareOFTAdapter** - Share OFT adapter on hub chain (lockbox model)
- ✅ **USDXShareOFT** - Share OFT representation on spoke chains
- ✅ **USDXVaultComposerSync** - Cross-chain orchestrator for deposit/redeem operations
- ✅ **USDXToken (OFT)** - USDX token with LayerZero cross-chain transfers
- ✅ **Multi-Chain Support** - Deployed across Ethereum, Polygon, Arbitrum, Optimism, and more

**Prize Requirements Checklist:**
- ✅ Build cross-chain applications using LayerZero protocol - **YES**: USDX uses LayerZero OVault for cross-chain yield vault integration
- ✅ Implement innovative use cases for omnichain infrastructure - **YES**: OVault implementation for unified yield generation across chains
- ✅ Demonstrate seamless cross-chain user experiences - **YES**: Hub-and-spoke architecture enables seamless USDX minting on any chain

#### Circle USDC Bridge Kit & ARC Prize

We are targeting the **Circle USDC Bridge Kit and ARC** prize for cross-chain USDC experience at ETHGlobal Buenos Aires 2025.

**Prize Category:** 💵 Circle USDC Bridge Kit & ARC - Cross-Chain USDC Experience

**What We Built:**

USDX integrates **Circle Bridge Kit** (built on CCTP) to enable seamless, fee-free USDC bridging:

- ✅ **Bridge Kit Integration** - Seamless USDC transfers from spoke chains to hub chain
- ✅ **Fee-Free Bridging** - Users can bridge USDC without fees to mint USDX
- ✅ **Cross-Chain Deposit Flow** - Users deposit USDC from any spoke chain → Ethereum hub
- ✅ **Frontend Integration** - Complete Bridge Kit SDK integration in USDX frontend
- ✅ **Multi-Chain Support** - Supports Ethereum, Base, Arbitrum, Optimism testnets and mainnets
- ✅ **User Experience** - Frictionless cross-chain experience for minting USDX

**Prize Requirements Checklist:**
- ✅ Build cross-chain USDC experiences using Bridge Kit/CCTP - **YES**: Complete Bridge Kit integration for USDC transfers from spoke chains to hub chain
- ✅ Implement seamless user flows for USDC bridging - **YES**: Fee-free, seamless bridging flow integrated into USDX frontend
- ✅ Demonstrate innovative use cases for cross-chain USDC - **YES**: Using bridged USDC to mint yield-bearing stablecoin (USDX) across chains

## Ledger Clear Signing Prize Submission

We submitted an implementation for the **Ledger Clear Signing (ERC-7730)** prize at ETHGlobal Buenos Aires 2025.

### Submission Details

**PR:** [feat: Implement uniswap v4 router across chains (#1977)](https://github.com/LedgerHQ/clear-signing-erc7730-registry/pull/1977)

**Prize Category:** 📝 CLEAR SIGNING (ERC-7730) - $4,000 prize pool ($2,500 for 1st place, $1,500 for 2nd place)

### What We Built

We implemented clear signing support for **Uniswap Universal Router** across multiple chains, enabling human-readable transaction signing on Ledger devices. This allows users to see exactly what their transaction will do before signing, improving security and user experience.

**Key Features:**
- ✅ Added Uniswap Universal Router calldata parsing
- ✅ Updated Uniswap UniversalRouter ABI and display formats
- ✅ Corrected Uniswap Universal Router contract addresses across chains
- ✅ Multi-chain support for Uniswap Universal Router

### About the Ledger Prize

The Ledger Clear Signing prize focuses on building **Clear Signing experiences** using ERC-7730 descriptors. Clear signing transforms complex blockchain transactions into human-readable formats, enabling users to understand exactly what they're signing on their Ledger hardware wallets. This is crucial for security and user trust in DeFi applications.

**Prize Requirements:**
- Build Clear Signing experiences or Device Management Kit integrations
- Implement ERC-7730 descriptors for human-readable transaction signing
- Enable users to see transaction details in a clear, understandable format before signing
