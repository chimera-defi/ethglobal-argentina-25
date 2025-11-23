# Migration Guide: Simplified OVault → LayerZero Official SDK

## Executive Summary

**Current State:** We have a working, simplified OVault implementation  
**Target State:** LayerZero's official OApp SDK with production-grade OFT/OVault  
**Effort:** ~2-3 weeks of development + testing  
**Benefits:** Production-ready, battle-tested, better security, official support

---

## What We Have (Simplified)

### Current Architecture

```
USDXVaultComposerSync.sol (Simplified)
├─ Manual LayerZero message handling
├─ Basic send/receive logic
├─ Custom payload encoding
└─ Minimal error handling

USDXShareOFTAdapter.sol (Simplified)
├─ Basic ERC20 wrapper
├─ Simple lock/unlock mechanism
├─ Manual LayerZero integration
└─ Custom sendTo() implementation

USDXShareOFT.sol (Simplified)
├─ Basic OFT token on spoke
├─ Simple mint/burn
└─ Manual LayerZero receive
```

### What's Missing from Official SDK

1. ❌ **OApp Base Contracts** - No inherited OApp functionality
2. ❌ **Proper OFTAdapter** - Custom implementation vs official pattern
3. ❌ **DVN Support** - No Decentralized Verifier Network integration
4. ❌ **Executor Options** - Basic gas handling only
5. ❌ **Rate Limiting** - No built-in protection
6. ❌ **Pausable** - No emergency pause mechanism
7. ❌ **Message Library** - No versioning or upgradability
8. ❌ **Proper Error Recovery** - Limited retry/recovery logic
9. ❌ **Gas Estimation** - Manual gas calculations
10. ❌ **Security Features** - Minimal access control patterns

---

## LayerZero Official SDK Architecture

### Official OApp SDK Structure

```solidity
// From @layerzerolabs/oapp-evm

OApp.sol (Base Contract)
├─ Inherits from OAppCore
├─ _lzSend() - Standardized sending
├─ _lzReceive() - Standardized receiving
├─ setPeer() - Peer management
├─ quote() - Gas estimation
└─ Proper event emissions

OFTAdapter.sol (Official)
├─ Inherits from OFT + OAppCore
├─ Lock-based model (like our adapter)
├─ Proper credit accounting
├─ Built-in rate limiting
├─ composeMsgSender() support
└─ Standardized message format

OFT.sol (Official)
├─ Burn/mint model on spokes
├─ Proper ERC20 implementation
├─ Credit/debit accounting
├─ Rate limiting built-in
└─ Compose message support
```

### Key Official SDK Features

#### 1. OApp Base (vs Our Custom Implementation)

**Official OApp:**
```solidity
abstract contract OApp is OAppSender, OAppReceiver, OAppCore {
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    ) internal virtual returns (MessagingReceipt memory);
    
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual;
}
```

**Our Current (Simplified):**
```solidity
// Direct endpoint calls, no OApp base
lzEndpoint.send{value: msg.value}(params, msg.sender);
```

#### 2. OFTAdapter Pattern

**Official OFTAdapter:**
```solidity
abstract contract OFTAdapter is OFT {
    IERC20 internal immutable innerToken;
    
    function _debit(
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        // Lock tokens
        innerToken.safeTransferFrom(msg.sender, address(this), _amountLD);
        return (_amountLD, _amountLD);
    }
    
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 _srcEid
    ) internal virtual override returns (uint256 amountReceivedLD) {
        // Unlock tokens
        innerToken.safeTransfer(_to, _amountLD);
        return _amountLD;
    }
}
```

**Our Current (Simplified):**
```solidity
// Manual lock/unlock with separate balance tracking
function lockShares(uint256 shares) external {
    IERC20(address(vault)).transferFrom(msg.sender, address(this), shares);
    lockedShares[msg.sender] += shares;
    _mint(msg.sender, shares);
}
```

#### 3. Compose Messages (Advanced)

**Official SDK supports compose messages** - allows contracts to receive messages and execute logic:

```solidity
function _lzCompose(
    address _from,
    bytes32 _guid,
    bytes calldata _message,
    address _executor,
    bytes calldata _extraData
) internal virtual {
    // Execute logic after receiving cross-chain message
}
```

**Our Current:** No compose message support

---

## Migration Plan

### Phase 1: Add Official SDK Dependencies (1-2 days)

#### 1.1 Install LayerZero OApp SDK

```bash
cd contracts
forge install LayerZero-Labs/LayerZero-v2 --no-commit
```

#### 1.2 Update `foundry.toml`

```toml
[dependencies]
"@layerzerolabs/lz-evm-protocol-v2" = "LayerZero-v2/packages/layerzero-v2/evm/protocol"
"@layerzerolabs/oapp-evm" = "LayerZero-v2/packages/layerzero-v2/evm/oapp"
```

#### 1.3 Create Remappings

```
@layerzerolabs/=lib/LayerZero-v2/packages/layerzero-v2/evm/
```

---

### Phase 2: Migrate OFTAdapter (3-5 days)

#### 2.1 Create `USDXShareOFTAdapterV2.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OFTAdapter} from "@layerzerolabs/oapp-evm/contracts/oft/OFTAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title USDXShareOFTAdapterV2
 * @notice Official LayerZero OFTAdapter for USDX vault shares
 * @dev Uses LayerZero's battle-tested OFTAdapter pattern
 */
contract USDXShareOFTAdapterV2 is OFTAdapter {
    constructor(
        address _token,           // Vault share token (ERC-4626)
        address _lzEndpoint,      // LayerZero endpoint
        address _owner            // Owner address
    ) OFTAdapter(_token, _lzEndpoint, _owner) {}
    
    /**
     * @dev Override to add custom logic before sending
     */
    function _debit(
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    ) internal virtual override returns (uint256 amountSentLD, uint256 amountReceivedLD) {
        // Official SDK handles the lock automatically
        return super._debit(_amountLD, _minAmountLD, _dstEid);
    }
    
    /**
     * @dev Override to add custom logic after receiving
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 _srcEid
    ) internal virtual override returns (uint256 amountReceivedLD) {
        // Official SDK handles the unlock automatically
        return super._credit(_to, _amountLD, _srcEid);
    }
}
```

**Changes from our simplified version:**
- ✅ Inherits from official `OFTAdapter`
- ✅ No manual lock/unlock tracking
- ✅ Built-in rate limiting
- ✅ Proper gas estimation via `quoteSend()`
- ✅ DVN support
- ✅ Message retry support

---

### Phase 3: Migrate OFT (Spoke) (2-3 days)

#### 3.1 Create `USDXShareOFTV2.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OFT} from "@layerzerolabs/oapp-evm/contracts/oft/OFT.sol";

/**
 * @title USDXShareOFTV2
 * @notice Official LayerZero OFT for USDX vault shares on spoke chains
 */
contract USDXShareOFTV2 is OFT {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _owner
    ) OFT(_name, _symbol, _lzEndpoint, _owner) {}
    
    /**
     * @dev Override to add custom minting logic
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 _srcEid
    ) internal virtual override returns (uint256 amountReceivedLD) {
        // Official SDK handles minting automatically
        return super._credit(_to, _amountLD, _srcEid);
    }
}
```

**Changes:**
- ✅ Inherits from official `OFT`
- ✅ No manual mint/burn in lzReceive
- ✅ Built-in credit/debit accounting
- ✅ Proper decimals handling

---

### Phase 4: Migrate Vault Composer (3-4 days)

#### 4.1 Create `USDXVaultComposerV2.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {OApp, MessagingFee, MessagingReceipt, Origin} from "@layerzerolabs/oapp-evm/contracts/oapp/OApp.sol";
import {OAppOptionsType3} from "@layerzerolabs/oapp-evm/contracts/oapp/libs/OAppOptionsType3.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {USDXYearnVaultWrapper} from "./USDXYearnVaultWrapper.sol";
import {USDXShareOFTAdapterV2} from "./USDXShareOFTAdapterV2.sol";

/**
 * @title USDXVaultComposerV2
 * @notice Official LayerZero OApp for orchestrating cross-chain vault operations
 * @dev Uses LayerZero V2 OApp SDK for production-grade reliability
 */
contract USDXVaultComposerV2 is OApp, ReentrancyGuard, OAppOptionsType3 {
    using OptionsBuilder for bytes;
    
    USDXYearnVaultWrapper public immutable vault;
    USDXShareOFTAdapterV2 public immutable shareOFT;
    IERC20 public immutable asset;
    
    struct DepositParams {
        uint256 assets;
        uint32 dstEid;
        address receiver;
    }
    
    constructor(
        address _vault,
        address _shareOFT,
        address _asset,
        address _lzEndpoint,
        address _owner
    ) OApp(_lzEndpoint, _owner) {
        vault = USDXYearnVaultWrapper(_vault);
        shareOFT = USDXShareOFTAdapterV2(_shareOFT);
        asset = IERC20(_asset);
    }
    
    /**
     * @notice Deposit assets and send shares cross-chain (Official SDK way)
     */
    function deposit(
        DepositParams calldata params,
        bytes calldata options
    ) external payable nonReentrant returns (MessagingReceipt memory receipt) {
        if (params.assets == 0) revert ZeroAmount();
        
        // 1. Transfer assets from user
        asset.transferFrom(msg.sender, address(this), params.assets);
        
        // 2. Approve and deposit to vault
        asset.approve(address(vault), params.assets);
        uint256 shares = vault.deposit(params.assets, address(this));
        
        // 3. Approve shares to OFTAdapter
        vault.approve(address(shareOFT), shares);
        
        // 4. Use official SDK's send() method
        bytes memory payload = abi.encode(params.receiver, shares);
        
        // Official SDK handles gas estimation, DVN, executors
        receipt = _lzSend(
            params.dstEid,
            payload,
            options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
        
        emit DepositInitiated(receipt.guid, msg.sender, params.assets, params.dstEid);
    }
    
    /**
     * @dev Official SDK receive handler
     */
    function _lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) internal virtual override {
        // Handle receives (for redeem flow)
        (address receiver, uint256 shares) = abi.decode(_message, (address, uint256));
        
        // Process redemption
        _processRedemption(receiver, shares, _origin.srcEid);
        
        emit RedemptionReceived(_guid, receiver, shares);
    }
    
    /**
     * @notice Quote the fee for a cross-chain deposit (Official SDK)
     */
    function quoteSend(
        DepositParams calldata params,
        bytes calldata options
    ) external view returns (MessagingFee memory fee) {
        bytes memory payload = abi.encode(params.receiver, params.assets);
        return _quote(params.dstEid, payload, options, false);
    }
    
    function _processRedemption(address receiver, uint256 shares, uint32 srcEid) internal {
        // Redeem shares for assets
        uint256 assets = vault.redeem(shares, receiver, address(this));
        emit RedemptionCompleted(receiver, shares, assets);
    }
}
```

**Major Improvements:**
- ✅ Inherits from official `OApp`
- ✅ Uses `_lzSend()` and `_lzReceive()` (standardized)
- ✅ Proper `MessagingReceipt` with GUID tracking
- ✅ Built-in `quoteSend()` for gas estimation
- ✅ DVN and executor support
- ✅ Options handling via `OAppOptionsType3`
- ✅ Proper error recovery

---

### Phase 5: Testing & Migration (5-7 days)

#### 5.1 Update Tests

Create `IntegrationE2E_OfficialSDK.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {USDXVaultComposerV2} from "../../contracts/USDXVaultComposerV2.sol";
import {USDXShareOFTAdapterV2} from "../../contracts/USDXShareOFTAdapterV2.sol";
import {USDXShareOFTV2} from "../../contracts/USDXShareOFTV2.sol";
// ... imports

contract IntegrationE2EOfficialSDKTest is Test {
    function testOfficialSDKDepositFlow() public {
        // Test using official SDK's send/receive
        
        // 1. User deposits via composer
        USDXVaultComposerV2.DepositParams memory params = 
            USDXVaultComposerV2.DepositParams({
                assets: 1000e6,
                dstEid: POLYGON_EID,
                receiver: alice
            });
        
        // 2. Quote gas first (official SDK)
        MessagingFee memory fee = composer.quoteSend(params, "");
        
        // 3. Execute deposit
        vm.prank(alice);
        MessagingReceipt memory receipt = composer.deposit{value: fee.nativeFee}(
            params,
            ""
        );
        
        // 4. Verify GUID tracking
        assertGt(uint256(receipt.guid), 0);
        
        // 5. Simulate LayerZero delivery (official endpoint mock)
        // ... endpoint simulation
        
        // 6. Verify shares received on spoke
        assertEq(shareOFTSpoke.balanceOf(alice), 1000e6);
    }
}
```

#### 5.2 Migration Checklist

- [ ] Install LayerZero V2 SDK
- [ ] Create V2 contracts (Adapter, OFT, Composer)
- [ ] Write comprehensive tests
- [ ] Deploy V2 to testnets
- [ ] Run parallel testing (V1 vs V2)
- [ ] Verify gas costs (V2 should be comparable)
- [ ] Test edge cases (rate limiting, pausing)
- [ ] Test DVN configurations
- [ ] Document V2 architecture
- [ ] Create migration scripts for existing deployments

---

## Comparison: Simplified vs Official SDK

| Feature | Our Simplified | Official SDK | Impact |
|---------|---------------|--------------|---------|
| **Base Architecture** | Custom | OApp inheritance | Better standardization |
| **OFT Pattern** | Custom lock/unlock | Official OFTAdapter | Battle-tested security |
| **Gas Estimation** | Manual calculation | `quoteSend()` | Accurate quotes |
| **DVN Support** | None | Built-in | Better security |
| **Rate Limiting** | None | Built-in | DoS protection |
| **Pausable** | Manual | Built-in | Emergency control |
| **Message Retry** | Manual | Built-in | Better reliability |
| **Compose Messages** | None | Built-in | Advanced patterns |
| **Event Standards** | Custom | Standardized | Better indexing |
| **Upgrade Path** | None | Message library | Future-proof |
| **Gas Costs** | ~200k gas | ~180-200k gas | Similar/better |
| **Code Complexity** | ~500 LOC | ~300 LOC | Simpler |
| **Audit Status** | None | Audited by LZ | Production-ready |

---

## Benefits of Migration

### Security
✅ **Audited by LayerZero Labs** - Official contracts are battle-tested  
✅ **Rate limiting** - Built-in protection against spam  
✅ **Pausable** - Emergency pause mechanism  
✅ **Better error handling** - Proper retry logic

### Developer Experience
✅ **Standardized patterns** - Easier for other devs to understand  
✅ **Better documentation** - Official LayerZero docs apply  
✅ **Tooling support** - Official SDK has deployment tools  
✅ **Gas estimation** - Built-in `quoteSend()`

### Features
✅ **DVN configuration** - Flexible security model  
✅ **Executor options** - Gas optimization  
✅ **Compose messages** - Advanced cross-chain patterns  
✅ **Message libraries** - Upgradability

### Maintenance
✅ **Official support** - LayerZero team maintains SDK  
✅ **Bug fixes** - Automatic via SDK updates  
✅ **New features** - Benefit from SDK improvements

---

## Costs & Risks

### Development Time
- **Phase 1 (Dependencies):** 1-2 days
- **Phase 2 (OFTAdapter):** 3-5 days
- **Phase 3 (OFT):** 2-3 days
- **Phase 4 (Composer):** 3-4 days
- **Phase 5 (Testing):** 5-7 days
- **Total:** ~15-20 days (3-4 weeks)

### Migration Risks
⚠️ **Breaking changes** - New contract interfaces  
⚠️ **Gas cost changes** - May differ from simplified version  
⚠️ **Learning curve** - Team needs to learn official SDK  
⚠️ **Testing burden** - Comprehensive testing required

### Mitigation
✅ Run both versions in parallel on testnet  
✅ Gradual migration (adapter first, then composer)  
✅ Comprehensive test coverage  
✅ Code review by LayerZero team (community Discord)

---

## Recommendation

### For Testnet/Demo: ✅ Keep Simplified Version
**Rationale:**
- Current implementation works well for testing
- 126 tests passing
- Clear, understandable code
- Good for learning and demos

### For Production: ✅ Migrate to Official SDK
**Rationale:**
- Production deployment needs security audit
- Official SDK is already audited
- Better long-term maintainability
- Access to official support and updates
- Industry-standard patterns

### Hybrid Approach: 🎯 Recommended
1. **Launch testnet with simplified version** (now)
2. **Develop V2 with official SDK** (parallel, 3-4 weeks)
3. **Test both versions on testnet** (compare gas, functionality)
4. **Audit V2 before mainnet** (required anyway)
5. **Deploy V2 to mainnet** (production-ready)

---

## Next Steps

### Immediate (This Week)
1. ✅ Deploy simplified version to testnet (ready now!)
2. ✅ Test cross-chain flows on real networks
3. ✅ Gather user feedback

### Short-Term (Next 2-4 Weeks)
1. [ ] Install LayerZero V2 SDK
2. [ ] Create V2 contracts side-by-side
3. [ ] Write migration tests
4. [ ] Deploy V2 to testnet

### Medium-Term (1-2 Months)
1. [ ] Run both versions in parallel
2. [ ] Performance/gas comparison
3. [ ] Security review
4. [ ] Prepare for audit

### Long-Term (Pre-Mainnet)
1. [ ] Professional security audit (V2)
2. [ ] Bug bounty program
3. [ ] Gradual rollout with caps
4. [ ] Migrate to V2 for mainnet

---

## Example: Side-by-Side Deployment

```bash
# Deploy simplified version (V1) - NOW
forge script script/DeployForked.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast

# Deploy official SDK version (V2) - After migration
forge script script/DeployOfficialSDK.s.sol --rpc-url $SEPOLIA_RPC_URL --broadcast

# Test both in parallel
forge test --match-contract IntegrationE2E_Simplified
forge test --match-contract IntegrationE2E_OfficialSDK

# Compare gas costs
forge test --gas-report
```

---

## Resources

### Official Documentation
- [LayerZero V2 Docs](https://docs.layerzero.network/v2)
- [OApp SDK](https://docs.layerzero.network/v2/developers/evm/oapp/overview)
- [OFT Standard](https://docs.layerzero.network/v2/developers/evm/oft/quickstart)

### GitHub Repositories
- [LayerZero V2 Contracts](https://github.com/LayerZero-Labs/LayerZero-v2)
- [OApp Examples](https://github.com/LayerZero-Labs/devtools/tree/main/examples/oapp)
- [OFT Examples](https://github.com/LayerZero-Labs/devtools/tree/main/examples/oft)

### Community
- [LayerZero Discord](https://discord.gg/layerzero)
- [Developer Forum](https://forum.layerzero.network/)

---

## Conclusion

**Yes, we can and should migrate to the official SDK for production.**

**Timeline:**
- ✅ **Today:** Deploy simplified version to testnet
- 🔨 **Week 1-2:** Develop official SDK V2
- 🧪 **Week 3-4:** Test and compare
- 🔒 **Month 2-3:** Security audit
- 🚀 **Month 3-4:** Production deployment

**The simplified version is perfect for:**
- Learning and understanding OVault patterns
- Testnet deployment and testing
- Demos and presentations
- Rapid iteration

**The official SDK is necessary for:**
- Production deployment
- Security guarantees
- Long-term maintainability
- Industry credibility

Let's deploy the simplified version to testnet NOW, then develop the official SDK V2 in parallel for production!
