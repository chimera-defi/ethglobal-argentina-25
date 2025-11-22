# USDX Open Questions and Clarifications Needed

## Circle Bridge Kit Questions

### ✅ Answered from Documentation Review

1. **SDK Integration** ✅
   - **Package Name**: Need to verify exact name (likely `@circle-fin/bridge-kit` or similar)
   - **TypeScript Support**: Documentation suggests TypeScript support is available
   - **Installation**: Available via npm (see installation docs)
   - **Documentation**: https://developers.circle.com/bridge-kit/tutorials/installation

2. **Quickstart Guides** ✅
   - Base → Ethereum transfer guide available
   - Ethereum → Solana transfer guide available
   - Guides show complete integration flow
   - **Documentation**: https://developers.circle.com/bridge-kit/quickstarts/transfer-usdc-from-base-to-ethereum

### ⏳ Needs Verification (Review Documentation Directly)

1. **API Key and Authentication**
   - ⏳ Do we need a Circle API key for Bridge Kit?
   - ⏳ How to obtain and manage API keys?
   - ⏳ Are there rate limits on Bridge Kit API?
   - **Action**: Review Bridge Kit overview and API reference docs

2. **UI Components**
   - ⏳ Are there React UI components available?
   - ⏳ How customizable are the Bridge Kit React components?
   - ⏳ Can we style them to match our design system?
   - ⏳ Are there accessibility considerations?
   - **Action**: Check if Bridge Kit includes UI components or is SDK-only

3. **Webhooks**
   - ⏳ How to set up webhook endpoints?
   - ⏳ What is the webhook payload format?
   - ⏳ How to secure webhook endpoints?
   - ⏳ What is the retry policy for failed webhooks?
   - **Action**: Review API reference for webhook documentation

4. **Error Handling**
   - ⏳ What are all possible error types?
   - ⏳ How does Bridge Kit handle failed transfers?
   - ⏳ Can transfers be retried?
   - ⏳ What happens if attestation times out?
   - **Action**: Review quickstart guides and error handling documentation

5. **Fees**
   - ⏳ Are there any fees beyond gas costs?
   - ⏳ Who pays for Bridge Kit service (if any)?
   - ⏳ Are there volume-based fee structures?
   - **Action**: Review pricing/fees documentation

6. **Status Tracking**
   - ⏳ How accurate is status tracking?
   - ⏳ Can we query transfer status programmatically?
   - ⏳ What is the typical transfer completion time?
   - **Action**: Review SDK API for status tracking methods

### 📚 Documentation URLs to Review

- **Overview**: https://developers.circle.com/bridge-kit
- **Installation**: https://developers.circle.com/bridge-kit/tutorials/installation
- **Quickstart (Base → Ethereum)**: https://developers.circle.com/bridge-kit/quickstarts/transfer-usdc-from-base-to-ethereum
- **Quickstart (Ethereum → Solana)**: https://developers.circle.com/bridge-kit/quickstarts/transfer-usdc-from-ethereum-to-solana
- **API Reference**: https://developers.circle.com/api-reference (check for Bridge Kit endpoints)

## Circle CCTP Questions (Reference - Bridge Kit handles most of these)

*Note: Bridge Kit abstracts away most CCTP complexity. These questions are for reference/advanced use cases.*

1. **Contract Addresses**
   - Need to verify mainnet contract addresses (Bridge Kit should handle this)
   - Are contracts upgradeable? What are the implications?

2. **Attestation API**
   - Bridge Kit handles attestation polling automatically
   - What happens if attestation is delayed or fails? (Bridge Kit should handle)

3. **Fees**
   - Are there any fees beyond gas costs for CCTP transfers?
   - Who pays for the attestation service?

4. **Error Handling**
   - What are all possible error conditions? (Bridge Kit should provide clear errors)
   - How to handle failed CCTP transfers? (Bridge Kit should handle)

## LayerZero Questions

1. **OApp vs Custom Implementation**
   - Should we use OApp standard or custom implementation?
   - What are the trade-offs?
   - Is OApp required for certain features?

2. **Message Fees**
   - How are fees calculated exactly?
   - Can fees be paid in ZRO token?
   - What are typical fee ranges?

3. **PreCrime**
   - Should we implement PreCrime for additional security?
   - What are the gas costs?
   - Is it worth it for USDX use case?

4. **Message Size Limits**
   - What is the maximum message size?
   - How to optimize payload size?

5. **Reliability**
   - What is the typical message delivery time?
   - What happens if message fails?
   - Can messages be retried?

## Hyperlane Questions

1. **ISM Selection**
   - Which ISM type is best for USDX?
   - Multisig vs Custom ISM?
   - How many validators should we use?

2. **Validator Network**
   - How decentralized is the validator network?
   - What are the security guarantees?
   - Are there any centralization risks?

3. **Message Fees**
   - How are fees calculated?
   - What are typical fee ranges?
   - Can fees be estimated accurately?

4. **Address Format**
   - Confirmation needed on bytes32 address conversion
   - Any edge cases to consider?

## Protocol Design Questions

1. **Yield Distribution**
   - Final decision on yield distribution model?
   - Protocol treasury vs rebasing vs buyback?
   - Can we support multiple models?

2. **Minting Model**
   - Confirm 1:1 minting ratio?
   - Should we add over-collateralization buffer?
   - What happens if USDC depegs?

3. **Cross-Chain Transfer Fees**
   - Finalize fee structure?
   - Who pays fees (user vs protocol)?
   - How to handle fee refunds?

4. **Redemption Model**
   - Confirm cross-chain redemption support?
   - How to handle CCTP delays during redemption?
   - What if user redeems on different chain than deposit?

5. **Bridge Selection**
   - How to choose between LayerZero and Hyperlane?
   - Should users choose or protocol decides?
   - Can we use both simultaneously for redundancy?

6. **Yield Strategy**
   - Confirm Aave as primary strategy?
   - When to add multi-strategy support?
   - How to handle strategy failures?

## Technical Questions

1. **Upgradeability**
   - Confirm UUPS pattern for core contracts?
   - Which contracts should be upgradeable?
   - What is the upgrade process?

2. **Access Control**
   - Who should have admin roles?
   - Multi-sig configuration?
   - How many signers required?

3. **Pause Mechanism**
   - Should pause be per-chain or global?
   - Who can pause?
   - What is the unpause process?

4. **Gas Optimization**
   - Are there specific gas targets?
   - Should we use libraries for common operations?
   - Batch operation support needed?

5. **Testing Strategy**
   - Which testnets to use?
   - Fork testing requirements?
   - Cross-chain testing setup?

## Security Questions

1. **Audit Requirements**
   - Which audit firms to consider?
   - How many audits needed?
   - Timeline for audits?

2. **Bug Bounty**
   - Should we run a bug bounty program?
   - What is the reward structure?
   - When to launch?

3. **Insurance**
   - Should we get protocol insurance?
   - Which providers to consider?
   - Coverage amount?

4. **Key Management**
   - Multi-sig wallet provider?
   - Hardware wallet requirements?
   - Key rotation process?

## Legal/Compliance Questions

1. **Regulatory Status**
   - What is the regulatory status of USDX?
   - Any compliance requirements?
   - Legal review needed?

2. **Jurisdiction**
   - Which jurisdiction for legal entity?
   - Tax implications?
   - KYC/AML requirements?

3. **Terms of Service**
   - Do we need terms of service?
   - User agreements?
   - Privacy policy?

## Operational Questions

1. **Monitoring**
   - Which monitoring tools to use?
   - Alert configuration?
   - Incident response plan?

2. **Documentation**
   - User documentation needed?
   - Developer documentation?
   - API documentation?

3. **Support**
   - Customer support channels?
   - Community management?
   - Documentation site?

4. **Marketing**
   - Marketing strategy?
   - Community building?
   - Partnerships?

## Implementation Priority

1. **MVP Features**
   - What features are essential for MVP?
   - What can be deferred to Phase 2?
   - Minimum viable chains?

2. **Timeline**
   - Are there any hard deadlines?
   - Preferred launch timeline?
   - Testnet duration?

3. **Team**
   - Who is on the development team?
   - External contractors needed?
   - Security audit timeline?

## Next Steps

1. **Research**
   - [ ] Verify CCTP contract addresses
   - [ ] Test CCTP integration on testnets
   - [ ] Test LayerZero integration
   - [ ] Test Hyperlane integration
   - [ ] Research yield strategies

2. **Design Decisions**
   - [ ] Finalize yield distribution model
   - [ ] Finalize fee structure
   - [ ] Finalize bridge selection logic
   - [ ] Finalize upgradeability approach

3. **Legal/Compliance**
   - [ ] Legal review
   - [ ] Compliance check
   - [ ] Terms of service draft

4. **Team Setup**
   - [ ] Confirm team members
   - [ ] Set up development environment
   - [ ] Set up CI/CD pipeline
   - [ ] Set up monitoring

## Notes

- These questions should be resolved before or during implementation
- Some questions may require testing on testnets
- Legal/compliance questions should be addressed early
- Security questions are critical and should be resolved before mainnet
