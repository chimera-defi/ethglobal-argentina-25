# ethglobal-argentina-25

## USDX Protocol

**USDX** is a decentralized yield-bearing stablecoin with unified yield generation across multiple chains. USDX uses LayerZero OVault for cross-chain yield vault integration with a hub-and-spoke architecture, enabling users to mint USDX on any supported chain while maintaining a single collateral source and unified yield generation on Ethereum.

For more information, see the **[USDX Prospectus](./usdx/docs/USDX-PROSPECTUS.md)**.

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
