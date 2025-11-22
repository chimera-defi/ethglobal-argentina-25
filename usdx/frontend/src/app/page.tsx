'use client';

import { useWallet } from '@/hooks/useWallet';
import { WalletConnect } from '@/components/WalletConnect';
import { BalanceCard } from '@/components/BalanceCard';
import { DepositFlow } from '@/components/DepositFlow';
import { WithdrawFlow } from '@/components/WithdrawFlow';
import { ToastContainer } from '@/components/Toast';
import { useToast } from '@/hooks/useToast';
import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  Coins, 
  TrendingUp, 
  Network, 
  Shield, 
  Zap, 
  ArrowRight,
  Moon,
  Sun,
  AlertCircle
} from 'lucide-react';

export default function Home() {
  const { address, signer, isConnected } = useWallet();
  const [refreshKey, setRefreshKey] = useState(0);
  const [darkMode, setDarkMode] = useState(false);
  const { toasts, removeToast } = useToast();

  useEffect(() => {
    const isDark = document.documentElement.classList.contains('dark');
    setDarkMode(isDark);
  }, []);

  const toggleDarkMode = () => {
    const newDarkMode = !darkMode;
    setDarkMode(newDarkMode);
    if (newDarkMode) {
      document.documentElement.classList.add('dark');
    } else {
      document.documentElement.classList.remove('dark');
    }
  };

  const handleSuccess = () => {
    setRefreshKey(prev => prev + 1);
  };

  const stats = [
    {
      icon: Shield,
      label: 'Collateral Ratio',
      value: '1:1',
      description: 'Fully backed by USDC',
      gradient: 'from-blue-500 to-cyan-500',
      textColor: 'text-blue-600 dark:text-blue-400',
    },
    {
      icon: TrendingUp,
      label: 'Yield Source',
      value: 'Yearn',
      description: 'V3 USDC Vault',
      gradient: 'from-purple-500 to-pink-500',
      textColor: 'text-purple-600 dark:text-purple-400',
    },
    {
      icon: Network,
      label: 'Chains Supported',
      value: '2+',
      description: 'Ethereum + Polygon',
      gradient: 'from-green-500 to-emerald-500',
      textColor: 'text-green-600 dark:text-green-400',
    },
  ];

  const steps = [
    {
      number: 1,
      title: 'Connect Wallet',
      description: 'Connect MetaMask or any Web3 wallet to get started',
      icon: Coins,
    },
    {
      number: 2,
      title: 'Deposit USDC',
      description: 'Deposit USDC to mint USDX 1:1 on the hub chain',
      icon: ArrowRight,
    },
    {
      number: 3,
      title: 'Earn Yield',
      description: 'Your USDC earns yield through Yearn automatically',
      icon: TrendingUp,
    },
    {
      number: 4,
      title: 'Use Cross-Chain',
      description: 'Mint USDX on spoke chains and use anywhere',
      icon: Network,
    },
  ];

  return (
    <main className="min-h-screen relative overflow-hidden">
      {/* Animated background gradient */}
      <div className="fixed inset-0 -z-10">
        <div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-gray-900 dark:via-blue-900/20 dark:to-purple-900/20" />
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-blue-400/20 rounded-full blur-3xl animate-pulse" style={{ animationDuration: '3s' }} />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-purple-400/20 rounded-full blur-3xl animate-pulse" style={{ animationDuration: '3s', animationDelay: '1s' }} />
      </div>

      {/* Header */}
      <motion.header
        initial={{ y: -20, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        className="border-b border-gray-200 dark:border-gray-800 bg-white/80 dark:bg-gray-900/80 backdrop-blur-xl sticky top-0 z-50 shadow-sm"
      >
        <div className="container mx-auto px-4 py-4 flex justify-between items-center">
          <motion.div
            whileHover={{ scale: 1.05 }}
            className="flex items-center gap-3"
          >
            <div className="w-12 h-12 bg-gradient-to-br from-blue-600 to-purple-600 rounded-xl flex items-center justify-center shadow-lg">
              <Coins className="h-7 w-7 text-white" />
            </div>
            <div>
              <h1 className="text-2xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
                USDX Protocol
              </h1>
              <p className="text-xs text-gray-600 dark:text-gray-400 font-medium">
                Cross-Chain Yield-Bearing Stablecoin
              </p>
            </div>
          </motion.div>
          <div className="flex items-center gap-3">
            <motion.button
              whileHover={{ scale: 1.1 }}
              whileTap={{ scale: 0.9 }}
              onClick={toggleDarkMode}
              className="p-2 rounded-lg bg-gray-100 dark:bg-gray-800 hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
            >
              {darkMode ? (
                <Sun className="h-5 w-5 text-yellow-500" />
              ) : (
                <Moon className="h-5 w-5 text-gray-700" />
              )}
            </motion.button>
            <WalletConnect />
          </div>
        </div>
      </motion.header>

      {/* Toast Container */}
      <ToastContainer toasts={toasts} onClose={removeToast} />

      {/* Main Content */}
      <div className="container mx-auto px-4 py-12">
        {/* Hero Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.6 }}
          className="text-center mb-16"
        >
          <motion.div
            initial={{ scale: 0.9 }}
            animate={{ scale: 1 }}
            transition={{ delay: 0.2 }}
            className="inline-block mb-6"
          >
            <div className="px-4 py-2 bg-gradient-to-r from-blue-100 to-purple-100 dark:from-blue-900/30 dark:to-purple-900/30 rounded-full border border-blue-200 dark:border-blue-800">
              <span className="text-sm font-semibold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Yield-Bearing Stablecoin</span>
            </div>
          </motion.div>
          <h2 className="text-5xl md:text-6xl font-bold mb-6 bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
            Deposit USDC, Earn Yield
          </h2>
          <p className="text-xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto mb-8 leading-relaxed">
            Mint USDX 1:1 backed by USDC and earn yield automatically through Yearn Finance.
            Use your USDX seamlessly across multiple chains.
          </p>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.4 }}
            className="flex items-center justify-center gap-2 text-sm text-gray-500 dark:text-gray-400"
          >
            <Zap className="h-4 w-4" />
            <span>Powered by Yearn Finance & Circle Bridge Kit</span>
          </motion.div>
        </motion.div>

        {/* Stats */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-16"
        >
          {stats.map((stat, index) => {
            const Icon = stat.icon;
            return (
              <motion.div
                key={stat.label}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 + index * 0.1 }}
                whileHover={{ scale: 1.05, y: -5 }}
                className="card text-center p-6 hover:scale-105 transition-transform duration-300"
              >
                <div className={`inline-flex p-3 bg-gradient-to-br ${stat.gradient} rounded-xl mb-4 shadow-lg`}>
                  <Icon className="h-6 w-6 text-white" />
                </div>
                <p className="text-sm font-semibold text-gray-600 dark:text-gray-400 mb-2">{stat.label}</p>
                <p className={`text-4xl font-bold ${stat.textColor} mb-1`}>
                  {stat.value}
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400">{stat.description}</p>
              </motion.div>
            );
          })}
        </motion.div>

        {/* Main Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-16">
          <motion.div
            initial={{ opacity: 0, x: -20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.5 }}
          >
            <BalanceCard key={refreshKey} address={address} />
          </motion.div>
          <motion.div
            initial={{ opacity: 0, x: 20 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.6 }}
            className="space-y-6"
          >
            <DepositFlow signer={signer} onSuccess={handleSuccess} />
            <WithdrawFlow signer={signer} onSuccess={handleSuccess} />
          </motion.div>
        </div>

        {/* Getting Started Section */}
        {!isConnected && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 }}
            className="card max-w-5xl mx-auto mb-8"
          >
            <h3 className="text-3xl font-bold mb-8 bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent text-center">Getting Started</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {steps.map((step, index) => {
                const Icon = step.icon;
                return (
                  <motion.div
                    key={step.number}
                    initial={{ opacity: 0, x: -20 }}
                    animate={{ opacity: 1, x: 0 }}
                    transition={{ delay: 0.7 + index * 0.1 }}
                    whileHover={{ scale: 1.02 }}
                    className="p-6 rounded-xl bg-gradient-to-br from-gray-50 to-blue-50 dark:from-gray-800 dark:to-blue-900/20 border border-gray-200 dark:border-gray-700"
                  >
                    <div className="flex items-start gap-4">
                      <div className="flex-shrink-0 w-12 h-12 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl flex items-center justify-center shadow-md">
                        <span className="text-white font-bold text-lg">{step.number}</span>
                      </div>
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h4 className="font-bold text-lg text-gray-900 dark:text-gray-100">{step.title}</h4>
                          <Icon className="h-5 w-5 text-blue-600 dark:text-blue-400" />
                        </div>
                        <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                          {step.description}
                        </p>
                      </div>
                    </div>
                  </motion.div>
                );
              })}
            </div>
          </motion.div>
        )}

        {/* Warning for Local Network */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.8 }}
          className="card max-w-5xl mx-auto bg-gradient-to-br from-yellow-50 to-orange-50 dark:from-yellow-900/20 dark:to-orange-900/20 border-yellow-200 dark:border-yellow-800"
        >
          <div className="flex items-start gap-4">
            <AlertCircle className="h-6 w-6 text-yellow-600 dark:text-yellow-400 flex-shrink-0 mt-1" />
            <div className="flex-1">
              <h4 className="font-bold mb-2 text-yellow-800 dark:text-yellow-300">⚠️ Local Development Mode</h4>
              <p className="text-sm text-yellow-700 dark:text-yellow-400 mb-3">
                This app is connected to a forked Ethereum mainnet running on{' '}
                <code className="bg-yellow-100 dark:bg-yellow-900/50 px-2 py-1 rounded font-mono text-xs">
                  localhost:8545
                </code>
                . Make sure Anvil is running with the deployed contracts.
              </p>
              <div className="mt-3 text-xs text-yellow-600 dark:text-yellow-500 space-y-1 font-mono">
                <p>
                  • Start Anvil:{' '}
                  <code className="bg-yellow-100 dark:bg-yellow-900/50 px-2 py-1 rounded">
                    anvil --fork-url YOUR_RPC
                  </code>
                </p>
                <p>
                  • Deploy:{' '}
                  <code className="bg-yellow-100 dark:bg-yellow-900/50 px-2 py-1 rounded">
                    forge script script/DeployForked.s.sol --broadcast
                  </code>
                </p>
              </div>
            </div>
          </div>
        </motion.div>
      </div>

      {/* Footer */}
      <motion.footer
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1 }}
        className="border-t border-gray-200 dark:border-gray-800 bg-white/80 dark:bg-gray-900/80 backdrop-blur-xl mt-20"
      >
        <div className="container mx-auto px-4 py-8 text-center">
          <div className="flex items-center justify-center gap-2 mb-2">
            <Coins className="h-5 w-5 text-blue-600 dark:text-blue-400" />
            <p className="text-sm font-semibold text-gray-700 dark:text-gray-300">
              USDX Protocol - Cross-Chain Yield-Bearing Stablecoin
            </p>
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400">
            Built with ethers.js, Next.js, Tailwind CSS, and Circle Bridge Kit
          </p>
        </div>
      </motion.footer>
    </main>
  );
}
