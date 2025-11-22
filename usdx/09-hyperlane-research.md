# Hyperlane Research

## Overview

Hyperlane is a permissionless interoperability protocol that enables secure cross-chain communication. It uses a validator network and Interchain Security Modules (ISMs) for message verification.

## Key Components

### 1. Mailbox Contract
- **Function**: Entry point for sending and receiving messages
- **Location**: Deployed on each supported chain
- **Key Functions**:
  - `dispatch()`: Send cross-chain message
  - `process()`: Process incoming message (called by validators)

### 2. Interchain Security Module (ISM)
- **Function**: Verifies message authenticity
- **Types**:
  - Multisig ISM: M-of-N validator signatures
  - Aggregation ISM: Combines multiple ISMs
  - Custom ISM: Application-specific verification
- **Location**: Deployed per application

### 3. Validator Network
- **Function**: Validates and relays messages
- **Type**: Permissionless validator network
- **Security**: Economic security (staked validators)

### 4. Yield Routes
- **Function**: Cross-chain yield vault that enables cross-chain access to yield positions
- **Benefits**: Simplified yield management, cross-chain access to yield positions
- **Components**:
  - Yield Routes contract (wraps underlying vault, e.g., Yearn)
  - Cross-chain position tracking via Hyperlane
  - Representative token minting on destination chains
- **Use Case**: USDX uses Yield Routes as secondary option to wrap Yearn USDC vault for cross-chain yield access

## Supported Chains

- Ethereum
- Polygon
- Avalanche
- Arbitrum
- Optimism
- Base
- BNB Chain
- Celo
- And many more...

## Integration Flow

### Step 1: Send Message

```solidity
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

function sendMessage(
    uint32 destinationDomain,
    bytes calldata messageBody
) external payable returns (bytes32 messageId) {
    messageId = mailbox.dispatch(
        destinationDomain,
        addressToBytes32(recipient),
        messageBody
    );
    
    emit MessageSent(messageId, destinationDomain);
    return messageId;
}
```

### Step 2: Receive Message

```solidity
import {IInterchainSecurityModule} from "@hyperlane-xyz/core/contracts/interfaces/IInterchainSecurityModule.sol";

function handle(
    uint32 origin,
    bytes32 sender,
    bytes calldata messageBody
) external {
    // Verify sender
    require(sender == trustedRemote, "Invalid sender");
    
    // Process message
    _processMessage(origin, messageBody);
}
```

## Message Format

```solidity
struct HyperlaneMessage {
    uint8 version;           // Version (currently 0)
    uint32 nonce;            // Nonce for replay protection
    uint32 origin;           // Origin domain
    address sender;          // Sender address
    uint32 destination;      // Destination domain
    bytes32 recipient;       // Recipient address (bytes32)
    bytes body;              // Message body
}
```

## Security Model

### Validator Network
- Permissionless validators
- Economic security (staking)
- Slashing for misbehavior
- Decentralized verification

### Interchain Security Module (ISM)
- Customizable security model
- Can combine multiple ISMs
- Application-specific verification
- Supports multisig, aggregation, etc.

## ISM Implementation

### Multisig ISM

```solidity
import {MultisigIsm} from "@hyperlane-xyz/core/contracts/isms/MultisigIsm.sol";

contract USDXISM is MultisigIsm {
    constructor(
        address[] memory validators,
        uint8 threshold
    ) MultisigIsm(validators, threshold) {}
}
```

### Custom ISM

```solidity
import {IInterchainSecurityModule} from "@hyperlane-xyz/core/contracts/interfaces/IInterchainSecurityModule.sol";

contract USDXCustomISM is IInterchainSecurityModule {
    function verify(
        bytes calldata metadata,
        bytes calldata message
    ) external view returns (bool) {
        // Custom verification logic
        // Verify message signature, nonce, etc.
        return true;
    }
}
```

## Configuration

### Set Interchain Security Module

```solidity
function setInterchainSecurityModule(
    address ism
) external onlyOwner {
    interchainSecurityModule = IInterchainSecurityModule(ism);
    emit InterchainSecurityModuleSet(ism);
}
```

### Set Trusted Remote

```solidity
mapping(uint32 => bytes32) public trustedRemotes;

function setTrustedRemote(
    uint32 domain,
    bytes32 remoteAddress
) external onlyOwner {
    trustedRemotes[domain] = remoteAddress;
    emit TrustedRemoteSet(domain, remoteAddress);
}
```

## Gas and Fees

### Fee Structure
- **Native Gas**: Paid in native token
- **Fee Calculation**: Based on destination chain gas costs
- **Payment**: Paid when calling `dispatch()`

### Fee Estimation

```solidity
function quoteDispatch(
    uint32 destinationDomain,
    bytes calldata messageBody
) external view returns (uint256 fee) {
    return mailbox.quoteDispatch(
        destinationDomain,
        addressToBytes32(recipient),
        messageBody
    );
}
```

## Key Considerations for USDX

### 1. Address Format
- Hyperlane uses `bytes32` for addresses
- Need to convert between formats:
  ```solidity
  function addressToBytes32(address addr) internal pure returns (bytes32) {
      return bytes32(uint256(uint160(addr)));
  }
  
  function bytes32ToAddress(bytes32 b32) internal pure returns (address) {
      return address(uint160(uint256(b32)));
  }
  ```

### 2. Message Ordering
- Hyperlane guarantees ordering per (origin, nonce)
- Need to track nonces per origin domain
- Can use `_nextNonce(origin)` pattern

### 3. ISM Selection
- Choose appropriate ISM for security needs
- Multisig ISM: Good for most cases
- Custom ISM: For application-specific needs
- Aggregation ISM: For combining multiple ISMs

### 4. Error Handling
- Failed messages can be retried
- Need to handle partial failures
- Consider timeout mechanisms

### 5. Security
- Always verify origin domain and sender
- Use trusted remote configuration
- Implement rate limiting if needed

## Integration Checklist

- [ ] Deploy mailbox contract (or use existing)
- [ ] Deploy/configure ISM
- [ ] Set trusted remotes
- [ ] Implement send message logic
- [ ] Implement receive message logic
- [ ] Add nonce tracking
- [ ] Add error handling
- [ ] Test on testnets
- [ ] Monitor message delivery
- [ ] Optimize gas usage

## Resources

- **Documentation**: https://docs.hyperlane.xyz/
- **GitHub**: https://github.com/hyperlane-xyz
- **Contract Addresses**: https://docs.hyperlane.xyz/docs/resources/contract-addresses
- **ISM Guide**: https://docs.hyperlane.xyz/docs/build-with-hyperlane/apis-and-sdks/ism

## Example: USDX Transfer Message

```solidity
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";

struct USDXTransferMessage {
    uint8 messageType; // 1 = transfer
    address user;
    uint256 amount;
    uint32 nonce;
    uint256 timestamp;
}

contract USDXHyperlaneBridge {
    IMailbox public mailbox;
    mapping(uint32 => bytes32) public trustedRemotes;
    mapping(uint32 => uint32) public nonces;
    
    function sendCrossChainTransfer(
        uint32 destinationDomain,
        address user,
        uint256 amount
    ) external payable returns (bytes32 messageId) {
        USDXTransferMessage memory message = USDXTransferMessage({
            messageType: 1,
            user: user,
            amount: amount,
            nonce: nonces[destinationDomain]++,
            timestamp: block.timestamp
        });
        
        bytes memory messageBody = abi.encode(message);
        bytes32 recipient = addressToBytes32(address(this));
        
        messageId = mailbox.dispatch{value: msg.value}(
            destinationDomain,
            recipient,
            messageBody
        );
        
        emit MessageSent(messageId, destinationDomain);
        return messageId;
    }
    
    function handle(
        uint32 origin,
        bytes32 sender,
        bytes calldata messageBody
    ) external {
        require(msg.sender == address(mailbox), "Not mailbox");
        require(sender == trustedRemotes[origin], "Invalid sender");
        
        USDXTransferMessage memory message = abi.decode(
            messageBody,
            (USDXTransferMessage)
        );
        
        _processMessage(origin, message);
    }
}
```

## Limitations

1. **Gas Costs**: Can be expensive for complex messages
2. **Message Size**: Limited by gas constraints
3. **Delivery Time**: Depends on validator network (usually seconds)
4. **ISM Complexity**: Custom ISMs require careful design

## Security Best Practices

1. **Verify Origin**: Always check origin domain
2. **Verify Sender**: Always check sender address
3. **Nonce Management**: Prevent replay attacks
4. **ISM Selection**: Choose appropriate ISM for use case
5. **Access Control**: Restrict who can send messages
6. **Payload Validation**: Validate all payload data
7. **Error Handling**: Handle failures gracefully
8. **Monitoring**: Monitor message delivery and failures

## Comparison with LayerZero

### Hyperlane Advantages
- Permissionless validators
- Customizable ISM
- Good for new chains
- Modular security

### LayerZero Advantages
- Mature ecosystem
- Better documentation
- OApp standard
- Larger validator network

### Recommendation
- Use both for redundancy
- LayerZero as primary
- Hyperlane as secondary/fallback
