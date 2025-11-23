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

Succesful bridgekit transfer:    
mainnet to polygon   
https://etherscan.io/tx/0x6131f195dd555d28ec4deafee8b5cdd3d904ba24f186cc07d7654860ff72a2ae  
https://polygonscan.com/tx/0xb0498851a42a6e5a5c9ab0508c66d0cc42264555b48ea86cef114cc1ca2374e8   

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

#### Ledger Clear Signing Prize

We are targeting the **Ledger Clear Signing (ERC-7730)** prize at ETHGlobal Buenos Aires 2025.

**PR:** [feat: Implement uniswap v4 router across chains (#1977)](https://github.com/LedgerHQ/clear-signing-erc7730-registry/pull/1977)

**Prize Category:** 📝 Ledger Clear Signing (ERC-7730)

**What We Built:**

We implemented clear signing support for **Uniswap Universal Router** across multiple chains, enabling human-readable transaction signing on Ledger devices:

- ✅ **Uniswap Universal Router Calldata Parsing** - Added parsing support for Universal Router transactions
- ✅ **ABI and Display Formats** - Updated Uniswap UniversalRouter ABI and display formats
- ✅ **Multi-Chain Contract Addresses** - Corrected Uniswap Universal Router contract addresses across chains
- ✅ **Multi-Chain Support** - Clear signing support for Uniswap Universal Router across multiple chains
- ✅ **Human-Readable Transactions** - Users can see exactly what their transaction will do before signing

**Prize Requirements Checklist:**
- ✅ Build Clear Signing experiences using ERC-7730 descriptors - **YES**: Implemented ERC-7730 descriptors for Uniswap Universal Router transactions
- ✅ Implement human-readable transaction signing - **YES**: Clear signing transforms complex transactions into human-readable formats
- ✅ Enable users to see transaction details before signing - **YES**: Users can see exactly what their transaction will do on Ledger devices
