# USDX Technical Specification

## Smart Contract Architecture

### Contract Structure

```
USDX Protocol
├── Core Contracts
│   ├── USDXToken.sol (ERC20)
│   ├── USDXVault.sol
│   └── CrossChainBridge.sol
├── Integration Contracts
│   ├── CCTPAdapter.sol
│   ├── LayerZeroAdapter.sol
│   ├── HyperlaneAdapter.sol
│   └── YieldStrategy.sol
└── Utility Contracts
    ├── AccessControl.sol
    ├── Pausable.sol
    └── ReentrancyGuard.sol
```

## Contract Interfaces

### USDXToken.sol

```solidity
interface IUSDXToken {
    // Standard ERC20 functions
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    
    // USDX-specific functions
    function mint(address to, uint256 amount) external; // Only vault
    function burn(uint256 amount) external;
    function burnFrom(address from, uint256 amount) external;
    
    // Cross-chain functions
    function pause() external; // Only admin
    function unpause() external; // Only admin
    function paused() external view returns (bool);
}
```

### USDXVault.sol

```solidity
interface IUSDXVault {
    // Deposit functions
    function depositUSDC(uint256 amount) external returns (uint256 usdxAmount);
    function depositUSDCFor(address user, uint256 amount) external returns (uint256 usdxAmount);
    
    // Withdrawal functions
    function withdrawUSDC(uint256 usdxAmount) external returns (uint256 usdcAmount);
    function withdrawUSDCTo(address to, uint256 usdxAmount) external returns (uint256 usdcAmount);
    
    // Cross-chain deposit (called by backend service after Bridge Kit transfer)
    function mintUSDXForCrossChainDeposit(
        address user,
        uint256 usdcAmount,
        uint16 sourceChainId,
        bytes32 bridgeKitTransferId
    ) external; // Only authorized bridge service
    
    // View functions
    function getUserCollateral(address user) external view returns (uint256);
    function getTotalCollateral() external view returns (uint256);
    function getTotalUSDXMinted() external view returns (uint256);
    function getCollateralRatio() external view returns (uint256); // Should be 1:1
    function isTransferProcessed(bytes32 transferId) external view returns (bool);
    
    // Yield functions
    function depositToYieldStrategy(uint256 amount) external; // Only yield manager
    function withdrawFromYieldStrategy(uint256 amount) external; // Only yield manager
    function getYieldAccrued() external view returns (uint256);
}
```

### CrossChainBridge.sol

```solidity
interface ICrossChainBridge {
    // Transfer functions
    function transferCrossChain(
        uint256 amount,
        uint16 destinationChainId,
        address destinationAddress,
        bytes calldata adapterParams
    ) external payable returns (bytes32 messageHash);
    
    // Receive functions (called by adapters)
    function receiveMessage(
        uint16 sourceChainId,
        bytes calldata payload,
        address sourceAddress
    ) external;
    
    // Configuration
    function setBridgeAdapter(
        uint16 chainId,
        address adapter,
        bool enabled
    ) external; // Only admin
    
    function setMessageFee(uint16 chainId, uint256 fee) external; // Only admin
    
    // View functions
    function getPendingTransfers(address user) external view returns (PendingTransfer[] memory);
    function getMessageFee(uint16 chainId) external view returns (uint256);
}
```

### Bridge Kit Integration (Frontend/Backend)

**Note**: Bridge Kit is a frontend/backend SDK, not a smart contract. Integration happens in off-chain services.

#### Frontend Integration

```typescript
// Using Bridge Kit SDK in frontend
import { BridgeKit } from '@circle-fin/bridge-kit';

const bridgeKit = new BridgeKit({
  sourceChain: 'ethereum',
  destinationChain: 'polygon',
});

// Transfer USDC
const transfer = await bridgeKit.transfer({
  amount: usdcAmount,
  recipient: vaultAddress,
  onStatusUpdate: (status) => {
    if (status === 'completed') {
      // Call vault contract to mint USDX
      vaultContract.mintUSDX(userAddress, usdcAmount);
    }
  },
});
```

#### Backend Service Integration

```typescript
// Backend service using Bridge Kit SDK
class USDXBridgeService {
  async handleCrossChainDeposit(
    sourceChain: string,
    destinationChain: string,
    userAddress: string,
    amount: string
  ) {
    const bridgeKit = new BridgeKit({
      sourceChain,
      destinationChain,
    });
    
    const transfer = await bridgeKit.transfer({
      amount,
      recipient: vaultAddress,
    });
    
    // Wait for completion (or use webhook)
    await this.waitForTransfer(transfer.id);
    
    // Call vault contract
    await vaultContract.mintUSDX(userAddress, amount);
  }
}
```

#### Webhook Handler

```typescript
// Webhook endpoint for Bridge Kit
app.post('/webhook/bridge-kit', async (req, res) => {
  const { transferId, status, data } = req.body;
  
  if (status === 'completed') {
    // Call vault contract to mint USDX
    await vaultContract.mintUSDX(data.recipient, data.amount);
  }
  
  res.status(200).send('OK');
});
```

#### Vault Contract Interface (for Bridge Kit integration)

```solidity
interface IUSDXVault {
    // Called by backend service after Bridge Kit transfer completes
    function mintUSDXForCrossChainDeposit(
        address user,
        uint256 usdcAmount,
        uint16 sourceChainId,
        bytes32 transferId
    ) external; // Only authorized backend service
    
    // View function to check if transfer was already processed
    function isTransferProcessed(bytes32 transferId) external view returns (bool);
}
```

### LayerZeroAdapter.sol

```solidity
interface ILayerZeroAdapter {
    // Send message via LayerZero
    function sendMessage(
        uint16 destinationChainId,
        bytes calldata payload,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable returns (bytes32 messageHash);
    
    // Receive message (called by LayerZero endpoint)
    function lzReceive(
        uint16 sourceChainId,
        bytes calldata sourceAddress,
        uint64 nonce,
        bytes calldata payload
    ) external;
    
    // Configuration
    function setTrustedRemote(uint16 chainId, bytes calldata remoteAddress) external;
    function setUseCustomAdapterParams(bool useCustom) external;
}
```

### HyperlaneAdapter.sol

```solidity
interface IHyperlaneAdapter {
    // Send message via Hyperlane
    function sendMessage(
        uint32 destinationDomain,
        bytes calldata messageBody
    ) external payable returns (bytes32 messageHash);
    
    // Handle message (called by Hyperlane mailbox)
    function handle(
        uint32 origin,
        bytes32 sender,
        bytes calldata messageBody
    ) external;
    
    // Configuration
    function setInterchainSecurityModule(address ism) external;
    function setMailbox(address mailbox) external;
}
```

### YieldStrategy.sol

```solidity
interface IYieldStrategy {
    // Deposit to yield protocol
    function deposit(uint256 amount) external returns (uint256 shares);
    
    // Withdraw from yield protocol
    function withdraw(uint256 shares) external returns (uint256 amount);
    
    // Emergency withdraw
    function emergencyWithdraw() external;
    
    // View functions
    function getTotalDeposited() external view returns (uint256);
    function getTotalYieldAccrued() external view returns (uint256);
    function getYieldRate() external view returns (uint256); // APY
    function getSharesForAmount(uint256 amount) external view returns (uint256);
    function getAmountForShares(uint256 shares) external view returns (uint256);
    
    // Strategy management
    function setStrategy(address strategy) external; // Only admin
    function pauseStrategy() external; // Only admin
    function unpauseStrategy() external; // Only admin
}
```

## Message Formats

### Cross-Chain Transfer Message

```solidity
struct CrossChainTransferMessage {
    uint8 messageType; // 1 = transfer
    address user;
    uint256 amount;
    uint64 nonce;
    uint256 timestamp;
    bytes32 sourceTxHash;
}
```

### Mint Request Message

```solidity
struct MintRequestMessage {
    uint8 messageType; // 2 = mint request
    address user;
    uint256 amount;
    uint16 sourceChainId;
    bytes32 sourceTxHash;
    uint64 nonce;
}
```

## State Variables

### USDXVault State

```solidity
// Collateral tracking
mapping(address => uint256) public userCollateral; // user => USDC amount
uint256 public totalCollateral; // Total USDC deposited
uint256 public totalUSDXMinted; // Total USDX minted

// Yield tracking
uint256 public yieldAccrued; // Total yield earned
uint256 public yieldStrategyDeposits; // USDC in yield strategies

// CCTP tracking
mapping(bytes32 => PendingCCTPTransfer) public pendingCCTPTransfers;
```

### CrossChainBridge State

```solidity
// Message tracking
mapping(bytes32 => bool) public processedMessages; // Prevent replay
mapping(address => PendingTransfer[]) public userPendingTransfers;

// Bridge configuration
mapping(uint16 => BridgeConfig) public bridgeConfigs; // chainId => config
mapping(uint16 => uint256) public messageFees; // chainId => fee

// Nonce tracking
mapping(uint16 => uint64) public nonces; // chainId => nonce
```

## Events

### USDXToken Events

```solidity
event Mint(address indexed to, uint256 amount);
event Burn(address indexed from, uint256 amount);
event CrossChainBurn(address indexed from, uint256 amount, uint16 destinationChainId);
event CrossChainMint(address indexed to, uint256 amount, uint16 sourceChainId);
```

### USDXVault Events

```solidity
event Deposit(address indexed user, uint256 usdcAmount, uint256 usdxAmount);
event Withdrawal(address indexed user, uint256 usdxAmount, uint256 usdcAmount);
event CCTPTransferInitiated(bytes32 indexed messageHash, address indexed user, uint256 amount, uint32 destinationDomain);
event CCTPTransferCompleted(bytes32 indexed messageHash, address indexed user, uint256 amount);
event YieldDeposited(uint256 amount, address strategy);
event YieldWithdrawn(uint256 amount, uint256 yield);
```

### CrossChainBridge Events

```solidity
event CrossChainTransferInitiated(
    address indexed user,
    uint256 amount,
    uint16 sourceChainId,
    uint16 destinationChainId,
    bytes32 messageHash
);
event CrossChainTransferCompleted(
    address indexed user,
    uint256 amount,
    uint16 sourceChainId,
    uint16 destinationChainId,
    bytes32 messageHash
);
event MessageReceived(uint16 sourceChainId, bytes32 messageHash);
```

## Security Considerations

### Access Control

```solidity
// Roles
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
bytes32 public constant YIELD_MANAGER_ROLE = keccak256("YIELD_MANAGER_ROLE");
bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
```

### Reentrancy Protection

- Use OpenZeppelin's ReentrancyGuard
- Checks-effects-interactions pattern
- Lock mechanism for cross-chain callbacks

### Rate Limiting

```solidity
mapping(address => uint256) public lastMintTime;
mapping(address => uint256) public mintCount;
uint256 public constant MINT_COOLDOWN = 1 hours;
uint256 public constant MAX_MINTS_PER_DAY = 10;
```

### Pause Mechanism

- Emergency pause for all contracts
- Per-function pause capability
- Time-locked unpause (24-48 hours)

## Gas Optimization

1. **Packed Structs**: Use uint128/uint64 where possible
2. **Storage Slots**: Optimize storage layout
3. **Events**: Use indexed parameters efficiently
4. **Batch Operations**: Support batch mints/burns
5. **Libraries**: Extract common logic to libraries

## Upgradeability

### Options Considered

1. **UUPS (Universal Upgradeable Proxy Standard)**
   - Pros: Gas efficient, flexible
   - Cons: Requires careful implementation

2. **Transparent Proxy**
   - Pros: Simple, well-tested
   - Cons: Slightly more gas

3. **Diamond Pattern**
   - Pros: Very flexible, no size limits
   - Cons: Complex, harder to audit

**Decision**: UUPS for core contracts, immutable for adapters

## Testing Strategy

1. **Unit Tests**: All contract functions
2. **Integration Tests**: Cross-contract interactions
3. **Fork Tests**: Test against mainnet forks
4. **Cross-Chain Tests**: Test LayerZero/Hyperlane integration
5. **Fuzz Tests**: Property-based testing
6. **Invariant Tests**: Protocol invariants

## Deployment Plan

### Phase 1: Testnet
- Deploy to all testnets (Goerli, Mumbai, Fuji, etc.)
- Test CCTP integration
- Test LayerZero/Hyperlane integration
- Community testing

### Phase 2: Mainnet (Limited)
- Deploy to 2-3 chains initially
- Small TVL cap (e.g., $100k)
- Monitor for issues
- Gradual increase

### Phase 3: Full Launch
- All supported chains
- Full TVL capacity
- Marketing and growth

## Monitoring and Alerting

1. **Contract Events**: Monitor all events
2. **Balance Tracking**: Monitor vault balances
3. **Yield Tracking**: Monitor yield accrual
4. **Bridge Health**: Monitor LayerZero/Hyperlane status
5. **CCTP Status**: Monitor CCTP attestations
6. **Anomaly Detection**: Unusual patterns
