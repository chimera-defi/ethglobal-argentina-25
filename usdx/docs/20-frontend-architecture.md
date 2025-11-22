# USDX Frontend Architecture & MVP Features

## Technology Stack

### Core Framework
- **Framework**: Next.js 14+ (App Router)
  - Server-side rendering for better SEO
  - API routes for backend functionality
  - Built-in optimization
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS + shadcn/ui components
  - Consistent design system
  - Accessible components
  - Dark mode support

### Web3 Integration
- **Wallet Connection**: wagmi v2 + viem
  - Multi-chain wallet support
  - Type-safe contract interactions
  - Automatic chain switching
- **Wallet UI**: RainbowKit
  - Beautiful wallet connection UI
  - Multi-wallet support (MetaMask, WalletConnect, Coinbase Wallet, etc.)
  - Chain switching interface
- **Bridge Kit**: `@circle-fin/bridge-kit` + `@circle-fin/adapter-viem-v2`
  - USDC cross-chain transfers
  - SDK-only (custom UI required)

### State Management
- **Global State**: Zustand
  - Lightweight
  - TypeScript support
  - Simple API
- **Server State**: TanStack Query (React Query)
  - Caching and synchronization
  - Background updates
  - Optimistic updates

### UI Components
- **Component Library**: shadcn/ui
  - Accessible
  - Customizable
  - Built on Radix UI primitives
- **Icons**: Lucide React
- **Animations**: Framer Motion (for transitions)

### Development Tools
- **Package Manager**: pnpm (faster, disk-efficient)
- **Linting**: ESLint + TypeScript ESLint
- **Formatting**: Prettier
- **Testing**: Vitest + React Testing Library
- **E2E Testing**: Playwright (optional for MVP)

## MVP Features

### Core Features (Must Have)

#### 1. Wallet Connection & Chain Management
- **Multi-wallet support**: MetaMask, WalletConnect, Coinbase Wallet
- **Chain selector**: Switch between supported chains
- **Network detection**: Auto-detect and prompt for correct network
- **Connection persistence**: Remember wallet connection across sessions

**Components**:
- `WalletConnectButton` - Connect/disconnect wallet
- `ChainSelector` - Select and switch chains
- `NetworkStatus` - Show current network and connection status

#### 2. Dashboard / Balance Display
- **Cross-chain balance aggregation**: Show total USDX across all chains
- **Per-chain balances**: Show USDX balance on each chain
- **USDC balance**: Show USDC balance on current chain
- **OVault/Yield Routes position**: Show position on hub chain
- **Yield display**: Show accrued yield (if applicable)

**Components**:
- `BalanceCard` - Display balances
- `ChainBalanceList` - List balances per chain
- `YieldDisplay` - Show yield information

#### 3. Deposit Flow
- **Step 1**: Select source chain (spoke chain)
- **Step 2**: Enter USDC amount
- **Step 3**: Bridge USDC to hub chain (Ethereum) via Bridge Kit
- **Step 4**: Deposit USDC into USDXVault on hub chain
- **Step 5**: Receive OVault/Yield Routes position
- **Step 6**: Confirmation and success state

**Components**:
- `DepositFlow` - Multi-step deposit wizard
- `AmountInput` - USDC amount input with validation
- `BridgeKitTransfer` - Bridge Kit integration component
- `TransactionStatus` - Show transaction progress
- `DepositConfirmation` - Success confirmation

**Flow**:
```
User on Spoke Chain
  ↓
Enter USDC amount
  ↓
Bridge Kit: Bridge USDC to Hub Chain
  ↓ (wait for bridge completion)
Deposit into USDXVault on Hub Chain
  ↓
Receive OVault/Yield Routes position
  ↓
Success: Position created
```

#### 4. Mint USDX Flow
- **Step 1**: Select destination chain (spoke chain)
- **Step 2**: Verify OVault/Yield Routes position on hub chain
- **Step 3**: Enter USDX amount to mint
- **Step 4**: Mint USDX on spoke chain
- **Step 5**: Confirmation and success state

**Components**:
- `MintFlow` - Multi-step mint wizard
- `PositionVerification` - Verify hub chain position
- `MintConfirmation` - Success confirmation

**Flow**:
```
User selects Spoke Chain
  ↓
Verify OVault/Yield Routes position on Hub Chain
  ↓
Enter USDX amount to mint
  ↓
Mint USDX on Spoke Chain
  ↓
Success: USDX minted
```

#### 5. Cross-Chain Transfer Flow
- **Step 1**: Select source chain (current chain)
- **Step 2**: Select destination chain
- **Step 3**: Enter USDX amount
- **Step 4**: Burn USDX on source chain
- **Step 5**: Send cross-chain message via LayerZero/Hyperlane
- **Step 6**: Wait for message confirmation
- **Step 7**: Mint USDX on destination chain
- **Step 8**: Confirmation and success state

**Components**:
- `TransferFlow` - Multi-step transfer wizard
- `ChainSelector` - Select source and destination chains
- `TransferStatus` - Show transfer progress
- `TransferConfirmation` - Success confirmation

**Flow**:
```
User on Chain A
  ↓
Select Chain B as destination
  ↓
Enter USDX amount
  ↓
Burn USDX on Chain A
  ↓
Send message via LayerZero/Hyperlane
  ↓ (wait for message)
Mint USDX on Chain B
  ↓
Success: Transfer complete
```

#### 6. Withdrawal Flow
- **Step 1**: Select withdrawal chain (spoke chain)
- **Step 2**: Enter USDX amount to withdraw
- **Step 3**: Burn USDX (if on spoke chain) or withdraw from hub
- **Step 4**: Withdraw USDC from USDXVault on hub chain
- **Step 5**: Bridge USDC back to spoke chain via Bridge Kit
- **Step 6**: Confirmation and success state

**Components**:
- `WithdrawalFlow` - Multi-step withdrawal wizard
- `WithdrawalConfirmation` - Success confirmation

#### 7. Transaction History
- **List all transactions**: Deposits, mints, transfers, withdrawals
- **Filter by type**: Filter by transaction type
- **Filter by chain**: Filter by chain
- **Transaction status**: Show pending/completed/failed status
- **Transaction details**: Show transaction hash, block number, timestamp

**Components**:
- `TransactionHistory` - Transaction list
- `TransactionCard` - Individual transaction display
- `TransactionFilters` - Filter controls
- `TransactionDetails` - Detailed transaction view

### Enhanced Features (Nice to Have for MVP)

#### 8. Transaction Status Tracking
- **Real-time updates**: Update transaction status in real-time
- **Progress indicators**: Show progress for multi-step transactions
- **Error handling**: Display errors clearly
- **Retry mechanism**: Allow retry for failed transactions

**Components**:
- `TransactionStatusTracker` - Track transaction status
- `ProgressIndicator` - Show progress
- `ErrorDisplay` - Display errors
- `RetryButton` - Retry failed transactions

#### 9. Yield Display
- **Accrued yield**: Show yield accrued on hub chain
- **Yield rate**: Show current yield rate
- **Yield history**: Show yield over time (if available)

**Components**:
- `YieldDisplay` - Show yield information
- `YieldChart` - Show yield over time (optional)

#### 10. Settings Page
- **Preferred chain**: Set default chain
- **Transaction settings**: Gas price preferences
- **Notifications**: Enable/disable notifications
- **Theme**: Light/dark mode toggle

**Components**:
- `SettingsPage` - Settings interface
- `ThemeToggle` - Dark/light mode toggle

## Component Architecture

### Page Structure
```
app/
├── (dashboard)/
│   ├── page.tsx              # Dashboard (balance display)
│   ├── deposit/
│   │   └── page.tsx          # Deposit flow
│   ├── mint/
│   │   └── page.tsx          # Mint USDX flow
│   ├── transfer/
│   │   └── page.tsx          # Cross-chain transfer flow
│   ├── withdraw/
│   │   └── page.tsx          # Withdrawal flow
│   └── history/
│       └── page.tsx          # Transaction history
├── api/
│   └── transactions/         # API routes for transaction data
└── components/
    ├── wallet/               # Wallet connection components
    ├── bridge/               # Bridge Kit components
    ├── transactions/         # Transaction components
    └── ui/                   # shadcn/ui components
```

### Component Hierarchy

```
App
├── Providers (wagmi, QueryClient, etc.)
├── Layout
│   ├── Header
│   │   ├── WalletConnectButton
│   │   └── ChainSelector
│   ├── Navigation
│   └── Main Content
│       ├── Dashboard (balance display)
│       ├── DepositFlow
│       ├── MintFlow
│       ├── TransferFlow
│       ├── WithdrawalFlow
│       └── TransactionHistory
└── Footer
```

## State Management

### Global State (Zustand)

```typescript
// stores/userStore.ts
interface UserStore {
  address: string | null;
  chainId: number | null;
  balances: Record<number, Balance>; // chainId => balance
  positions: {
    ovault: bigint;
    yieldRoutes: bigint;
  };
  setAddress: (address: string | null) => void;
  setChainId: (chainId: number | null) => void;
  updateBalance: (chainId: number, balance: Balance) => void;
}

// stores/transactionStore.ts
interface TransactionStore {
  transactions: Transaction[];
  pendingTransactions: Transaction[];
  addTransaction: (tx: Transaction) => void;
  updateTransaction: (hash: string, updates: Partial<Transaction>) => void;
  removePendingTransaction: (hash: string) => void;
}
```

### Server State (TanStack Query)

```typescript
// hooks/useBalances.ts
export function useBalances(address: string) {
  return useQuery({
    queryKey: ['balances', address],
    queryFn: () => fetchBalances(address),
    refetchInterval: 30000, // Refetch every 30 seconds
  });
}

// hooks/useTransactions.ts
export function useTransactions(address: string) {
  return useQuery({
    queryKey: ['transactions', address],
    queryFn: () => fetchTransactions(address),
    refetchInterval: 10000, // Refetch every 10 seconds
  });
}
```

## Bridge Kit Integration

### Custom Bridge Kit Hook

```typescript
// hooks/useBridgeKit.ts
import { BridgeKit } from '@circle-fin/bridge-kit';
import { createViemAdapter } from '@circle-fin/adapter-viem-v2';

export function useBridgeKit() {
  const { publicClient, walletClient } = useWagmi();
  
  const bridgeKit = useMemo(() => {
    if (!publicClient || !walletClient) return null;
    
    return new BridgeKit({
      adapter: createViemAdapter({
        sourcePublicClient: publicClient,
        sourceWalletClient: walletClient,
        destinationPublicClient: destinationPublicClient,
      }),
    });
  }, [publicClient, walletClient]);
  
  const transferUSDC = async (
    amount: string,
    sourceChain: Chain,
    destinationChain: Chain,
    recipient: string
  ) => {
    if (!bridgeKit) throw new Error('Bridge Kit not initialized');
    
    return bridgeKit.transfer({
      amount,
      recipient,
      sourceChain: sourceChain.id,
      destinationChain: destinationChain.id,
      onStatusUpdate: (status) => {
        // Update UI with status
      },
      onError: (error) => {
        // Handle error
      },
    });
  };
  
  return { bridgeKit, transferUSDC };
}
```

### Bridge Kit Component

```typescript
// components/bridge/BridgeKitTransfer.tsx
export function BridgeKitTransfer({
  amount,
  sourceChain,
  destinationChain,
  recipient,
  onComplete,
}: BridgeKitTransferProps) {
  const { transferUSDC } = useBridgeKit();
  const [status, setStatus] = useState<TransferStatus>('idle');
  const [error, setError] = useState<Error | null>(null);
  
  const handleTransfer = async () => {
    try {
      setStatus('pending');
      const transfer = await transferUSDC(
        amount,
        sourceChain,
        destinationChain,
        recipient
      );
      
      // Track transfer status
      transfer.onStatusUpdate((newStatus) => {
        setStatus(newStatus);
        if (newStatus === 'completed') {
          onComplete?.(transfer);
        }
      });
    } catch (err) {
      setError(err as Error);
      setStatus('failed');
    }
  };
  
  return (
    <div>
      <Button onClick={handleTransfer} disabled={status === 'pending'}>
        Transfer USDC
      </Button>
      {status !== 'idle' && <TransferStatusDisplay status={status} />}
      {error && <ErrorDisplay error={error} />}
    </div>
  );
}
```

## Responsive Design

### Breakpoints
- **Mobile**: < 640px
- **Tablet**: 640px - 1024px
- **Desktop**: > 1024px

### Mobile Considerations
- **Simplified navigation**: Bottom navigation bar
- **Touch-friendly**: Larger buttons and touch targets
- **Simplified flows**: Reduce steps where possible
- **Optimized layouts**: Stack components vertically

## Error Handling

### Error Types
1. **Wallet Errors**: Connection failures, wrong network
2. **Transaction Errors**: Insufficient gas, transaction reverted
3. **Bridge Errors**: Bridge Kit transfer failures
4. **Network Errors**: RPC failures, network issues

### Error Display
- **Toast notifications**: For transient errors
- **Inline errors**: For form validation errors
- **Error pages**: For critical errors
- **Error recovery**: Retry mechanisms where applicable

## Performance Optimization

### Strategies
1. **Code splitting**: Lazy load routes
2. **Image optimization**: Next.js Image component
3. **Caching**: TanStack Query caching
4. **Debouncing**: Debounce user inputs
5. **Optimistic updates**: Update UI before confirmation

## Testing Strategy

### Unit Tests
- Component tests with React Testing Library
- Hook tests
- Utility function tests

### Integration Tests
- Wallet connection flow
- Transaction flows
- Bridge Kit integration

### E2E Tests (Optional for MVP)
- Complete user journeys
- Cross-chain flows

## Accessibility

### Requirements
- **WCAG 2.1 AA compliance**: Meet accessibility standards
- **Keyboard navigation**: Full keyboard support
- **Screen reader support**: Proper ARIA labels
- **Color contrast**: Sufficient contrast ratios

## Security Considerations

### Frontend Security
- **Input validation**: Validate all user inputs
- **XSS prevention**: Sanitize user inputs
- **CSRF protection**: Use Next.js CSRF protection
- **Secure storage**: Don't store sensitive data in localStorage

## Deployment

### Environment Variables
```env
NEXT_PUBLIC_CHAIN_ID_ETHEREUM=1
NEXT_PUBLIC_CHAIN_ID_POLYGON=137
NEXT_PUBLIC_CHAIN_ID_ARBITRUM=42161
NEXT_PUBLIC_USDX_VAULT_ADDRESS=...
NEXT_PUBLIC_USDX_TOKEN_ADDRESS=...
```

### Build & Deploy
- **Build**: `pnpm build`
- **Deploy**: Vercel (recommended) or similar
- **CI/CD**: GitHub Actions

## MVP Scope Summary

### Must Have (MVP)
1. ✅ Wallet connection & chain management
2. ✅ Balance display (cross-chain)
3. ✅ Deposit flow (Bridge Kit + USDXVault)
4. ✅ Mint USDX flow
5. ✅ Cross-chain transfer flow
6. ✅ Withdrawal flow
7. ✅ Transaction history

### Nice to Have (Post-MVP)
- Enhanced transaction status tracking
- Yield display and charts
- Settings page
- Advanced analytics
- Mobile app

## Next Steps

1. Set up Next.js project with TypeScript
2. Install and configure wagmi, viem, RainbowKit
3. Install Bridge Kit SDK
4. Create component library structure
5. Build core components (wallet, balance, flows)
6. Integrate Bridge Kit
7. Integrate smart contract interactions
8. Add transaction history
9. Polish UI/UX
10. Testing and bug fixes
