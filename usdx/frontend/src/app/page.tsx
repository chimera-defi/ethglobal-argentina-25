'use client';

import { useWallet } from '@/hooks/useWallet';
import { WalletConnect } from '@/components/WalletConnect';
import { BalanceCard } from '@/components/BalanceCard';
import { DepositFlow } from '@/components/DepositFlow';
import { WithdrawFlow } from '@/components/WithdrawFlow';
import { useState } from 'react';

export default function Home() {
  const { address, signer, isConnected } = useWallet();
  const [refreshKey, setRefreshKey] = useState(0);

  const handleSuccess = () => {
    // Trigger balance refresh
    setRefreshKey(prev => prev + 1);
  };

  return (
    <main className="min-h-screen">
      {/* Header */}
      <header className="border-b bg-white/50 backdrop-blur-sm sticky top-0 z-10">
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-gradient-to-br from-blue-600 to-purple-600 rounded-lg flex items-center justify-center">
              <span className="text-white font-bold text-xl">U</span>
            </div>
            <div>
              <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                USDX Protocol
              </h1>
              <p className="text-xs text-gray-600">Cross-Chain Yield-Bearing Stablecoin</p>
            </div>
          </div>
          <WalletConnect />
        </div>
      </header>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-8">
        {/* Hero Section */}
        <div className="text-center mb-12">
          <h2 className="text-4xl font-bold mb-4 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
            Yield-Bearing USDC Stablecoin
          </h2>
          <p className="text-lg text-gray-600 max-w-2xl mx-auto">
            Deposit USDC, mint USDX 1:1, and earn yield through Yearn Finance.
            Use your USDX across multiple chains seamlessly.
          </p>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
          <div className="card text-center">
            <p className="text-sm text-gray-600 mb-1">Collateral Ratio</p>
            <p className="text-3xl font-bold text-blue-600">1:1</p>
            <p className="text-xs text-gray-500 mt-1">Fully backed by USDC</p>
          </div>
          <div className="card text-center">
            <p className="text-sm text-gray-600 mb-1">Yield Source</p>
            <p className="text-3xl font-bold text-purple-600">Yearn</p>
            <p className="text-xs text-gray-500 mt-1">V3 USDC Vault</p>
          </div>
          <div className="card text-center">
            <p className="text-sm text-gray-600 mb-1">Chains Supported</p>
            <p className="text-3xl font-bold text-green-600">2+</p>
            <p className="text-xs text-gray-500 mt-1">Ethereum + Polygon</p>
          </div>
        </div>

        {/* Main Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-12">
          <BalanceCard key={refreshKey} address={address} />
          <div className="space-y-6">
            <DepositFlow signer={signer} onSuccess={handleSuccess} />
            <WithdrawFlow signer={signer} onSuccess={handleSuccess} />
          </div>
        </div>

        {/* Info Section */}
        {!isConnected && (
          <div className="card max-w-4xl mx-auto">
            <h3 className="text-2xl font-bold mb-4">Getting Started</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h4 className="font-bold mb-2 flex items-center gap-2">
                  <span className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold">1</span>
                  Connect Wallet
                </h4>
                <p className="text-sm text-gray-600 ml-10">
                  Connect MetaMask or any Web3 wallet to get started
                </p>
              </div>
              <div>
                <h4 className="font-bold mb-2 flex items-center gap-2">
                  <span className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold">2</span>
                  Deposit USDC
                </h4>
                <p className="text-sm text-gray-600 ml-10">
                  Deposit USDC to mint USDX 1:1 on the hub chain
                </p>
              </div>
              <div>
                <h4 className="font-bold mb-2 flex items-center gap-2">
                  <span className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold">3</span>
                  Earn Yield
                </h4>
                <p className="text-sm text-gray-600 ml-10">
                  Your USDC earns yield through Yearn automatically
                </p>
              </div>
              <div>
                <h4 className="font-bold mb-2 flex items-center gap-2">
                  <span className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold">4</span>
                  Use Cross-Chain
                </h4>
                <p className="text-sm text-gray-600 ml-10">
                  Mint USDX on spoke chains and use anywhere
                </p>
              </div>
            </div>
          </div>
        )}

        {/* Warning for Local Network */}
        <div className="card max-w-4xl mx-auto mt-6 bg-yellow-50 border-yellow-200">
          <h4 className="font-bold mb-2 text-yellow-800">⚠️ Local Development Mode</h4>
          <p className="text-sm text-yellow-700">
            This app is connected to a forked Ethereum mainnet running on <code className="bg-yellow-100 px-2 py-1 rounded">localhost:8545</code>.
            Make sure Anvil is running with the deployed contracts.
          </p>
          <div className="mt-3 text-xs text-yellow-600 space-y-1">
            <p>• Start Anvil: <code className="bg-yellow-100 px-1 rounded">anvil --fork-url YOUR_RPC</code></p>
            <p>• Deploy: <code className="bg-yellow-100 px-1 rounded">forge script script/DeployForked.s.sol --broadcast</code></p>
          </div>
        </div>
      </div>

      {/* Footer */}
      <footer className="border-t bg-white/50 backdrop-blur-sm mt-12">
        <div className="container mx-auto px-4 py-6 text-center text-sm text-gray-600">
          <p>USDX Protocol - Cross-Chain Yield-Bearing Stablecoin</p>
          <p className="text-xs mt-1">Built with ethers.js, Next.js, and Circle Bridge Kit</p>
        </div>
      </footer>
    </main>
  );
}
