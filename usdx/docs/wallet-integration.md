# Wallet Integration Guide

## Overview

The USDX Protocol frontend now supports multiple wallet connection methods, including:

- **MetaMask** - Browser extension wallet
- **WalletConnect** - QR code scanning for mobile wallets
- **Coinbase Wallet** - Coinbase's browser wallet
- **Browser Wallet** - Any injected Web3 wallet

## Features

### 🔌 Multiple Wallet Support
Users can connect using any of the supported wallet types through an intuitive modal interface.

### 📱 WalletConnect QR Code
Mobile wallet users can scan a QR code to connect their wallets securely without browser extensions.

### 🔄 Auto-Reconnection
The app automatically reconnects to the last used wallet on page reload.

### 🎨 Beautiful UI
Modern, animated wallet selection modal with clear status indicators and helpful error messages.

### 🔐 Secure Connection
- No private keys are stored
- Wallet connections are encrypted
- Proper event listeners for account and chain changes
- Clean disconnection handling

## Setup

### 1. WalletConnect Project ID

To use WalletConnect, you need to create a free project at [WalletConnect Cloud](https://cloud.walletconnect.com/).

1. Sign up at https://cloud.walletconnect.com/
2. Create a new project
3. Copy your Project ID
4. Add it to your `.env.local` file:

```bash
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id_here
```

### 2. Supported Chains

The wallet provider is configured to support the following chains:

- Ethereum Mainnet (Chain ID: 1)
- Sepolia Testnet (Chain ID: 11155111)
- Base (Chain ID: 8453)
- Base Sepolia (Chain ID: 84532)
- Polygon (Chain ID: 137)
- Arc Testnet (Chain ID: 5042002)

## Usage

### For Developers

#### Using the Wallet Hook

```typescript
import { useWallet } from '@/hooks/useWallet';

function MyComponent() {
  const { 
    address,           // Connected wallet address
    signer,           // Ethers signer for transactions
    provider,         // Ethers provider for read operations
    chainId,          // Current chain ID
    walletType,       // Type of connected wallet
    isConnected,      // Connection status
    isConnecting,     // Loading state
    isCorrectChain,   // Chain verification
    error,            // Error message if any
    connectByType,    // Function to connect by wallet type
    disconnect,       // Function to disconnect
    switchNetwork,    // Function to switch networks
  } = useWallet();

  // Connect to MetaMask
  const handleConnectMetaMask = async () => {
    await connectByType('metamask');
  };

  // Connect to WalletConnect
  const handleConnectWalletConnect = async () => {
    await connectByType('walletconnect');
  };

  // Disconnect wallet
  const handleDisconnect = async () => {
    await disconnect();
  };

  return (
    <div>
      {isConnected ? (
        <p>Connected: {address}</p>
      ) : (
        <button onClick={handleConnectMetaMask}>
          Connect MetaMask
        </button>
      )}
    </div>
  );
}
```

#### Using the Wallet Modal

The `WalletConnect` component handles the entire connection flow:

```typescript
import { WalletConnect } from '@/components/WalletConnect';

function Header() {
  return (
    <header>
      <WalletConnect />
    </header>
  );
}
```

### For Users

#### Connecting with MetaMask

1. Click "Connect Wallet" button
2. Select "MetaMask" from the modal
3. Approve the connection in MetaMask

#### Connecting with WalletConnect

1. Click "Connect Wallet" button
2. Select "WalletConnect" from the modal
3. Scan the QR code with your mobile wallet app
4. Approve the connection in your mobile wallet

#### Connecting with Other Wallets

1. Click "Connect Wallet" button
2. Select your wallet type (Coinbase Wallet or Browser Wallet)
3. Approve the connection in your wallet

## Architecture

### Files Structure

```
src/
├── components/
│   ├── WalletConnect.tsx      # Main wallet connect button component
│   └── WalletModal.tsx         # Wallet selection modal
├── hooks/
│   └── useWallet.ts            # Wallet connection hook
└── lib/
    └── walletProvider.ts       # Wallet provider service
```

### Wallet Provider Service

The `walletProvider.ts` file contains all wallet connection logic:

- **`connectWallet(type)`** - Connect to a specific wallet type
- **`disconnectWallet(wallet)`** - Disconnect from wallet
- **`detectWallets()`** - Detect available wallets
- **`getEthersProvider(wallet)`** - Get ethers provider
- **`getEthersSigner(wallet)`** - Get ethers signer
- **`setupWalletListeners(wallet, callbacks)`** - Setup event listeners

### Event Handling

The wallet system properly handles:

- **Account Changes** - Updates UI when user switches accounts
- **Chain Changes** - Detects and notifies when user switches networks
- **Disconnection** - Cleans up state when wallet disconnects
- **Errors** - Displays helpful error messages

## Troubleshooting

### WalletConnect QR Code Not Showing

- Make sure you have set `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` in your `.env.local`
- Clear browser cache and try again
- Check browser console for errors

### MetaMask Not Detected

- Ensure MetaMask extension is installed and enabled
- Try refreshing the page
- Check that MetaMask is not locked

### Wrong Network Error

- The app will prompt you to switch to the correct network
- Click "Switch Network" button to change chains
- If the chain is not in your wallet, add it manually

### Connection Issues

- Clear localStorage: `localStorage.removeItem('usdx_wallet_type')`
- Disconnect from the wallet manually
- Refresh the page and try again

## Security Best Practices

1. **Never store private keys** - The app only stores the wallet type preference
2. **Validate all transactions** - Always check transaction details before signing
3. **Use HTTPS** - WalletConnect requires secure connections
4. **Keep wallet software updated** - Use the latest versions of wallet apps
5. **Be cautious of phishing** - Always verify the URL before connecting

## Testing

### Local Development

1. Start the development server:
   ```bash
   npm run dev
   ```

2. Test different wallet types:
   - MetaMask: Install MetaMask extension
   - WalletConnect: Use your mobile wallet app
   - Coinbase: Install Coinbase Wallet extension

### Build Testing

Always test the build before deploying:

```bash
npm run build
npm run type-check
```

## Contributing

When adding new wallet types:

1. Add the wallet type to `WalletType` in `walletProvider.ts`
2. Implement the connection function
3. Add the wallet to `detectWallets()`
4. Update the `WalletModal` with the new option
5. Test thoroughly
6. Update this documentation

## License

MIT License - See LICENSE file for details
