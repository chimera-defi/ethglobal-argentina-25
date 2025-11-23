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
  AlertCircle,
  Lock,
  Repeat,
  Wallet,
  ChevronRight,
  CheckCircle2,
  Layers,
  CircleDollarSign,
  Sparkles
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
      icon: TrendingUp,
      label: 'APY',
      value: '4.2%',
      description: 'Current Yield Rate',
      gradient: 'from-emerald-500 via-green-500 to-teal-500',
      textColor: 'text-emerald-600 dark:text-emerald-400',
      bgLight: 'bg-emerald-50 dark:bg-emerald-900/10',
    },
    {
      icon: CircleDollarSign,
      label: 'TVL',
      value: '$12.4M',
      description: 'Total Value Locked',
      gradient: 'from-blue-500 via-cyan-500 to-sky-500',
      textColor: 'text-blue-600 dark:text-blue-400',
      bgLight: 'bg-blue-50 dark:bg-blue-900/10',
    },
    {
      icon: Shield,
      label: 'Collateral',
      value: '100%',
      description: 'Fully backed by USDC',
      gradient: 'from-purple-500 via-violet-500 to-fuchsia-500',
      textColor: 'text-purple-600 dark:text-purple-400',
      bgLight: 'bg-purple-50 dark:bg-purple-900/10',
    },
    {
      icon: Network,
      label: 'Chains',
      value: '2+',
      description: 'Multi-chain Support',
      gradient: 'from-orange-500 via-amber-500 to-yellow-500',
      textColor: 'text-orange-600 dark:text-orange-400',
      bgLight: 'bg-orange-50 dark:bg-orange-900/10',
    },
  ];

  const features = [
    {
      icon: Shield,
      title: '1:1 USDC Backing',
      description: 'Every USDX is fully backed by USDC deposited into audited smart contracts.',
      gradient: 'from-blue-500 to-cyan-500',
    },
    {
      icon: TrendingUp,
      title: 'Automatic Yield',
      description: 'Earn yield automatically through Yearn Finance\'s battle-tested vaults.',
      gradient: 'from-emerald-500 to-green-500',
    },
    {
      icon: Network,
      title: 'Cross-Chain',
      description: 'Use USDX across multiple chains with LayerZero OFT technology.',
      gradient: 'from-purple-500 to-pink-500',
    },
    {
      icon: Lock,
      title: 'Non-Custodial',
      description: 'You maintain full control of your assets through smart contracts.',
      gradient: 'from-orange-500 to-amber-500',
    },
    {
      icon: Zap,
      title: 'Instant Minting',
      description: 'Mint and redeem USDX instantly with no delays or waiting periods.',
      gradient: 'from-rose-500 to-red-500',
    },
    {
      icon: Sparkles,
      title: 'Transparent',
      description: 'All transactions and yields are fully transparent and auditable on-chain.',
      gradient: 'from-indigo-500 to-blue-500',
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
        <div className="absolute inset-0 bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 dark:from-gray-950 dark:via-blue-950/40 dark:to-purple-950/40" />
        <div className="absolute top-0 left-1/3 w-[500px] h-[500px] bg-blue-500/10 rounded-full blur-3xl animate-pulse" style={{ animationDuration: '4s' }} />
        <div className="absolute bottom-0 right-1/3 w-[500px] h-[500px] bg-purple-500/10 rounded-full blur-3xl animate-pulse" style={{ animationDuration: '4s', animationDelay: '2s' }} />
        <div className="absolute top-1/2 left-1/2 w-[600px] h-[600px] bg-emerald-500/5 rounded-full blur-3xl animate-pulse" style={{ animationDuration: '5s', animationDelay: '1s' }} />
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
          className="relative text-center mb-16"
        >
          {/* Decorative hero background */}
          <div className="absolute inset-0 -mx-8 bg-gradient-to-b from-blue-50 via-purple-50/30 to-transparent dark:from-blue-950/30 dark:via-purple-950/20 dark:to-transparent rounded-3xl blur-3xl" />
          
          <div className="relative">
            <motion.div
              initial={{ scale: 0.9 }}
              animate={{ scale: 1 }}
              transition={{ delay: 0.2 }}
              className="inline-block mb-6"
            >
              <div className="px-6 py-3 bg-gradient-to-r from-blue-100 via-purple-100 to-pink-100 dark:from-blue-900/30 dark:via-purple-900/30 dark:to-pink-900/30 rounded-full border-2 border-blue-200 dark:border-blue-800 shadow-lg">
                <div className="flex items-center gap-2">
                  <Sparkles className="h-4 w-4 text-purple-600 dark:text-purple-400" />
                  <span className="text-sm font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Yield-Bearing Stablecoin</span>
                  <Sparkles className="h-4 w-4 text-pink-600 dark:text-pink-400" />
                </div>
              </div>
            </motion.div>
            <h2 className="text-5xl md:text-7xl font-black mb-6 bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent leading-tight">
              Deposit USDC, Earn Yield
            </h2>
            <div className="h-2 w-32 mx-auto mb-8 bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 rounded-full" />
            <p className="text-xl text-gray-600 dark:text-gray-300 max-w-3xl mx-auto mb-8 leading-relaxed">
              Mint USDX 1:1 backed by USDC and earn yield automatically through Yearn Finance.
              Use your USDX seamlessly across multiple chains.
            </p>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
              className="inline-flex items-center gap-3 px-6 py-3 bg-white/80 dark:bg-gray-900/80 backdrop-blur-sm rounded-2xl border-2 border-gray-200 dark:border-gray-700 shadow-xl"
            >
              <div className="flex items-center gap-2">
                <div className="p-2 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-lg">
                  <Zap className="h-4 w-4 text-white" />
                </div>
                <span className="text-sm font-semibold text-gray-700 dark:text-gray-300">Powered by</span>
              </div>
              <div className="flex items-center gap-2">
                <Shield className="h-4 w-4 text-blue-600 dark:text-blue-400" />
                <span className="text-sm font-bold text-gray-900 dark:text-white">Yearn Finance</span>
              </div>
              <span className="text-gray-400">•</span>
              <div className="flex items-center gap-2">
                <Network className="h-4 w-4 text-purple-600 dark:text-purple-400" />
                <span className="text-sm font-bold text-gray-900 dark:text-white">Circle Bridge Kit</span>
              </div>
            </motion.div>
          </div>
        </motion.div>

        {/* Stats Grid */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-12"
        >
          {/* Decorative top border */}
          <div className="absolute -top-6 left-0 right-0 h-1 bg-gradient-to-r from-transparent via-blue-500 to-transparent opacity-30 blur-sm" />
          {stats.map((stat, index) => {
            const Icon = stat.icon;
            return (
              <motion.div
                key={stat.label}
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 + index * 0.1 }}
                whileHover={{ scale: 1.03, y: -4 }}
                className={`relative overflow-hidden rounded-2xl p-6 border-2 ${stat.bgLight} border-gray-200/50 dark:border-gray-700/50 backdrop-blur-sm shadow-lg hover:shadow-xl transition-all duration-300`}
              >
                <div className="relative z-10">
                  <div className={`inline-flex p-3 bg-gradient-to-br ${stat.gradient} rounded-xl mb-3 shadow-md`}>
                    <Icon className="h-5 w-5 text-white" />
                  </div>
                  <p className="text-xs font-bold text-gray-500 dark:text-gray-400 uppercase tracking-wider mb-1">
                    {stat.label}
                  </p>
                  <p className={`text-3xl font-black ${stat.textColor} mb-1`}>
                    {stat.value}
                  </p>
                  <p className="text-xs text-gray-600 dark:text-gray-400 font-medium">
                    {stat.description}
                  </p>
                </div>
                {/* Decorative gradient overlay */}
                <div className={`absolute -right-8 -bottom-8 w-32 h-32 bg-gradient-to-br ${stat.gradient} opacity-5 rounded-full`} />
              </motion.div>
            );
          }          )}
        </motion.div>

        {/* Section Divider */}
        <motion.div
          initial={{ scaleX: 0 }}
          animate={{ scaleX: 1 }}
          transition={{ delay: 0.5, duration: 0.8 }}
          className="relative mb-20"
        >
          <div className="h-px bg-gradient-to-r from-transparent via-gray-300 dark:via-gray-700 to-transparent" />
          <div className="absolute inset-0 h-px bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500 opacity-50 blur-sm" />
          <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
            <div className="px-4 py-1.5 bg-white dark:bg-gray-900 border-2 border-gray-200 dark:border-gray-700 rounded-full">
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-gradient-to-r from-blue-500 to-purple-500 animate-pulse" />
                <div className="w-2 h-2 rounded-full bg-gradient-to-r from-purple-500 to-pink-500 animate-pulse" style={{ animationDelay: '0.3s' }} />
                <div className="w-2 h-2 rounded-full bg-gradient-to-r from-pink-500 to-orange-500 animate-pulse" style={{ animationDelay: '0.6s' }} />
              </div>
            </div>
          </div>
        </motion.div>

        {/* Protocol Flow Diagram */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="relative mb-20"
        >
          {/* Decorative background for this section */}
          <div className="absolute inset-0 -mx-4 bg-gradient-to-br from-blue-50/50 via-transparent to-purple-50/50 dark:from-blue-950/20 dark:via-transparent dark:to-purple-950/20 rounded-3xl" />
          
          <div className="relative text-center mb-12 pt-8">
            <motion.h2
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.5 }}
              className="text-4xl font-black mb-4 bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent"
            >
              How USDX Works
            </motion.h2>
            <motion.p
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.6 }}
              className="text-lg text-gray-600 dark:text-gray-300 max-w-2xl mx-auto"
            >
              A visual guide to the USDX protocol flow
            </motion.p>
          </div>

          <div className="card max-w-6xl mx-auto p-8 md:p-12">
            <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
              {/* Step 1: Deposit */}
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.6 }}
                className="relative"
              >
                <div className="relative z-10">
                  <div className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-2xl flex items-center justify-center shadow-xl">
                    <Wallet className="h-8 w-8 text-white" />
                  </div>
                  <div className="text-center mb-3">
                    <div className="inline-block px-3 py-1 bg-blue-100 dark:bg-blue-900/30 rounded-full mb-2">
                      <span className="text-xs font-bold text-blue-700 dark:text-blue-300">STEP 1</span>
                    </div>
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Deposit USDC</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      Users deposit USDC into the USDX Vault contract
                    </p>
                  </div>
                </div>
                {/* Arrow */}
                <div className="hidden md:block absolute top-8 -right-3 z-0">
                  <ChevronRight className="h-6 w-6 text-gray-300 dark:text-gray-600" />
                </div>
              </motion.div>

              {/* Step 2: Yearn Deposit */}
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.7 }}
                className="relative"
              >
                <div className="relative z-10">
                  <div className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-emerald-500 to-green-500 rounded-2xl flex items-center justify-center shadow-xl">
                    <TrendingUp className="h-8 w-8 text-white" />
                  </div>
                  <div className="text-center mb-3">
                    <div className="inline-block px-3 py-1 bg-emerald-100 dark:bg-emerald-900/30 rounded-full mb-2">
                      <span className="text-xs font-bold text-emerald-700 dark:text-emerald-300">STEP 2</span>
                    </div>
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Earn Yield</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      Vault deposits USDC into Yearn Finance to generate yield
                    </p>
                  </div>
                </div>
                {/* Arrow */}
                <div className="hidden md:block absolute top-8 -right-3 z-0">
                  <ChevronRight className="h-6 w-6 text-gray-300 dark:text-gray-600" />
                </div>
              </motion.div>

              {/* Step 3: Mint USDX */}
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.8 }}
                className="relative"
              >
                <div className="relative z-10">
                  <div className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-purple-500 to-pink-500 rounded-2xl flex items-center justify-center shadow-xl">
                    <Coins className="h-8 w-8 text-white" />
                  </div>
                  <div className="text-center mb-3">
                    <div className="inline-block px-3 py-1 bg-purple-100 dark:bg-purple-900/30 rounded-full mb-2">
                      <span className="text-xs font-bold text-purple-700 dark:text-purple-300">STEP 3</span>
                    </div>
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Mint USDX</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      Receive USDX tokens 1:1 with your deposited USDC
                    </p>
                  </div>
                </div>
                {/* Arrow */}
                <div className="hidden md:block absolute top-8 -right-3 z-0">
                  <ChevronRight className="h-6 w-6 text-gray-300 dark:text-gray-600" />
                </div>
              </motion.div>

              {/* Step 4: Use Cross-Chain */}
              <motion.div
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.9 }}
                className="relative"
              >
                <div className="relative z-10">
                  <div className="w-16 h-16 mx-auto mb-4 bg-gradient-to-br from-orange-500 to-amber-500 rounded-2xl flex items-center justify-center shadow-xl">
                    <Network className="h-8 w-8 text-white" />
                  </div>
                  <div className="text-center mb-3">
                    <div className="inline-block px-3 py-1 bg-orange-100 dark:bg-orange-900/30 rounded-full mb-2">
                      <span className="text-xs font-bold text-orange-700 dark:text-orange-300">STEP 4</span>
                    </div>
                    <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-2">Cross-Chain</h3>
                    <p className="text-sm text-gray-600 dark:text-gray-400">
                      Bridge and use USDX across multiple blockchain networks
                    </p>
                  </div>
                </div>
              </motion.div>
            </div>

            {/* Additional info */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 1.0 }}
              className="mt-8 p-6 bg-gradient-to-br from-blue-50 via-purple-50 to-pink-50 dark:from-blue-900/10 dark:via-purple-900/10 dark:to-pink-900/10 rounded-xl border-2 border-blue-200/50 dark:border-blue-800/50"
            >
              <div className="flex items-start gap-3">
                <Sparkles className="h-6 w-6 text-purple-600 dark:text-purple-400 flex-shrink-0 mt-0.5" />
                <div>
                  <h4 className="font-bold text-gray-900 dark:text-white mb-2">The Complete Cycle</h4>
                  <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
                    Your USDC remains securely locked in Yearn vaults earning yield continuously. 
                    USDX represents your share of the vault, which increases in value over time as yield accrues. 
                    You can redeem USDX for USDC (plus earned yield) at any time, or use it across multiple chains via LayerZero OFT.
                  </p>
                </div>
              </div>
            </motion.div>
          </div>
        </motion.div>

        {/* Gradient Divider */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.6 }}
          className="relative my-20"
        >
          <div className="flex items-center justify-center gap-4">
            <div className="flex-1 h-px bg-gradient-to-r from-transparent via-emerald-500 to-teal-500 opacity-50" />
            <div className="flex items-center gap-2">
              <Sparkles className="h-5 w-5 text-emerald-500 dark:text-emerald-400 animate-pulse" />
              <span className="text-sm font-bold text-gray-400 dark:text-gray-500 uppercase tracking-wider">Features</span>
              <Sparkles className="h-5 w-5 text-teal-500 dark:text-teal-400 animate-pulse" />
            </div>
            <div className="flex-1 h-px bg-gradient-to-l from-transparent via-emerald-500 to-teal-500 opacity-50" />
          </div>
        </motion.div>

        {/* Features Section */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.5 }}
          className="relative mb-20"
        >
          {/* Colorful background accent */}
          <div className="absolute inset-0 bg-gradient-to-br from-emerald-50/30 via-green-50/30 to-teal-50/30 dark:from-emerald-950/10 dark:via-green-950/10 dark:to-teal-950/10 rounded-3xl -mx-4" />
          
          <div className="relative text-center mb-12">
            <h2 className="text-4xl font-black mb-4 bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
              Why Choose USDX?
            </h2>
            <p className="text-lg text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
              Built with security, transparency, and user experience in mind
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((feature, index) => {
              const Icon = feature.icon;
              return (
                <motion.div
                  key={feature.title}
                  initial={{ opacity: 0, y: 20 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ delay: 0.6 + index * 0.1 }}
                  whileHover={{ scale: 1.03, y: -5 }}
                  className="card group"
                >
                  <div className={`inline-flex p-4 bg-gradient-to-br ${feature.gradient} rounded-xl mb-4 shadow-lg group-hover:shadow-xl transition-shadow duration-300`}>
                    <Icon className="h-6 w-6 text-white" />
                  </div>
                  <h3 className="text-xl font-bold mb-2 text-gray-900 dark:text-white">
                    {feature.title}
                  </h3>
                  <p className="text-sm text-gray-600 dark:text-gray-400 leading-relaxed">
                    {feature.description}
                  </p>
                </motion.div>
              );
            })}
          </div>
        </motion.div>

        {/* Decorative Divider with Icon */}
        <motion.div
          initial={{ scaleX: 0 }}
          animate={{ scaleX: 1 }}
          transition={{ delay: 0.7, duration: 0.8 }}
          className="relative my-20"
        >
          <div className="absolute inset-0 bg-gradient-to-r from-rose-500/20 via-pink-500/20 to-purple-500/20 h-24 blur-3xl" />
          <div className="relative flex items-center justify-center">
            <div className="flex-1 h-1 bg-gradient-to-r from-transparent via-rose-500 to-pink-500 rounded-full" />
            <div className="mx-6 p-4 bg-white dark:bg-gray-900 rounded-2xl border-2 border-rose-200 dark:border-rose-800 shadow-xl">
              <Wallet className="h-8 w-8 text-rose-600 dark:text-rose-400" />
            </div>
            <div className="flex-1 h-1 bg-gradient-to-l from-transparent via-pink-500 to-purple-500 rounded-full" />
          </div>
        </motion.div>

        {/* Interactive Section Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.8 }}
          className="text-center mb-12"
        >
          <div className="inline-block p-6 bg-gradient-to-br from-rose-50 via-pink-50 to-purple-50 dark:from-rose-950/30 dark:via-pink-950/30 dark:to-purple-950/30 rounded-3xl border-2 border-rose-200 dark:border-rose-800 mb-4">
            <h2 className="text-4xl font-black bg-gradient-to-r from-rose-600 via-pink-600 to-purple-600 bg-clip-text text-transparent">
              Start Using USDX
            </h2>
          </div>
          <p className="text-lg text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
            Connect your wallet and interact with the protocol
          </p>
        </motion.div>

        {/* Main Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-20">
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

        {/* Animated Wave Divider */}
        {!isConnected && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.9 }}
            className="relative my-20"
          >
            <div className="flex items-center gap-3">
              <div className="flex-1">
                <div className="h-px bg-gradient-to-r from-transparent via-orange-400 to-amber-400" />
                <div className="h-px bg-gradient-to-r from-transparent via-orange-300 to-amber-300 mt-1" />
              </div>
              <div className="px-6 py-2 bg-gradient-to-r from-orange-500 to-amber-500 rounded-full shadow-lg">
                <span className="text-white font-bold text-sm uppercase tracking-wider">Get Started</span>
              </div>
              <div className="flex-1">
                <div className="h-px bg-gradient-to-l from-transparent via-amber-400 to-yellow-400" />
                <div className="h-px bg-gradient-to-l from-transparent via-amber-300 to-yellow-300 mt-1" />
              </div>
            </div>
          </motion.div>
        )}

        {/* Quick Start Guide */}
        {!isConnected && (
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.7 }}
            className="relative mb-20"
          >
            {/* Warm background glow */}
            <div className="absolute inset-0 bg-gradient-to-br from-orange-50/40 via-amber-50/40 to-yellow-50/40 dark:from-orange-950/20 dark:via-amber-950/20 dark:to-yellow-950/20 rounded-3xl -mx-4" />
            
            <div className="relative text-center mb-12">
              <h2 className="text-4xl font-black mb-4 bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
                Get Started in 4 Steps
              </h2>
              <p className="text-lg text-gray-600 dark:text-gray-300 max-w-2xl mx-auto">
                Connect your wallet and start earning yield in minutes
              </p>
            </div>

            <div className="max-w-5xl mx-auto grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {steps.map((step, index) => {
                const Icon = step.icon;
                return (
                  <motion.div
                    key={step.number}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.8 + index * 0.1 }}
                    whileHover={{ y: -5 }}
                    className="relative group"
                  >
                    <div className="card p-6 h-full flex flex-col items-center text-center">
                      <div className="relative mb-4">
                        <div className="w-14 h-14 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center shadow-lg group-hover:shadow-xl transition-shadow">
                          <span className="text-white font-black text-xl">{step.number}</span>
                        </div>
                        <div className="absolute -top-2 -right-2 w-6 h-6 bg-gradient-to-br from-emerald-500 to-green-500 rounded-full flex items-center justify-center shadow-md">
                          <Icon className="h-3 w-3 text-white" />
                        </div>
                      </div>
                      <h4 className="font-bold text-base text-gray-900 dark:text-white mb-2">
                        {step.title}
                      </h4>
                      <p className="text-xs text-gray-600 dark:text-gray-400 leading-relaxed">
                        {step.description}
                      </p>
                    </div>
                  </motion.div>
                );
              })}
            </div>
          </motion.div>
        )}

        {/* Final Section Divider */}
        <motion.div
          initial={{ opacity: 0, scaleX: 0 }}
          animate={{ opacity: 1, scaleX: 1 }}
          transition={{ delay: 1.0, duration: 0.8 }}
          className="relative my-20"
        >
          <div className="relative h-20 flex items-center justify-center">
            <div className="absolute inset-0 bg-gradient-to-r from-cyan-500/10 via-blue-500/10 to-indigo-500/10 blur-2xl" />
            <div className="relative flex items-center gap-6 w-full">
              <div className="flex-1 flex flex-col gap-2">
                <div className="h-0.5 bg-gradient-to-r from-transparent via-cyan-500 to-blue-500 rounded-full" />
                <div className="h-px bg-gradient-to-r from-transparent via-cyan-400 to-blue-400 rounded-full" />
              </div>
              <div className="flex items-center gap-3 px-6 py-3 bg-gradient-to-r from-cyan-500 via-blue-500 to-indigo-500 rounded-2xl shadow-2xl">
                <AlertCircle className="h-6 w-6 text-white" />
                <span className="text-white font-black text-sm uppercase tracking-wider">Developer Mode</span>
                <Zap className="h-6 w-6 text-yellow-300" />
              </div>
              <div className="flex-1 flex flex-col gap-2">
                <div className="h-0.5 bg-gradient-to-l from-transparent via-blue-500 to-indigo-500 rounded-full" />
                <div className="h-px bg-gradient-to-l from-transparent via-blue-400 to-indigo-400 rounded-full" />
              </div>
            </div>
          </div>
        </motion.div>

        {/* Developer Info */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.9 }}
          className="max-w-4xl mx-auto"
        >
          <div className="card bg-gradient-to-br from-amber-50 via-yellow-50 to-orange-50 dark:from-amber-900/10 dark:via-yellow-900/10 dark:to-orange-900/10 border-2 border-amber-200/50 dark:border-amber-800/50">
            <div className="flex items-start gap-4">
              <div className="flex-shrink-0">
                <div className="w-12 h-12 bg-gradient-to-br from-amber-500 to-orange-500 rounded-xl flex items-center justify-center shadow-lg">
                  <AlertCircle className="h-6 w-6 text-white" />
                </div>
              </div>
              <div className="flex-1">
                <h4 className="font-black text-lg mb-2 text-amber-900 dark:text-amber-300 flex items-center gap-2">
                  <Zap className="h-5 w-5" />
                  Local Development Mode
                </h4>
                <p className="text-sm text-amber-800 dark:text-amber-400 mb-4 leading-relaxed">
                  Currently connected to a forked Ethereum mainnet on{' '}
                  <code className="bg-amber-100 dark:bg-amber-900/50 px-2 py-1 rounded font-mono font-bold">
                    localhost:8545
                  </code>
                  . Ensure Anvil is running with deployed contracts before interacting.
                </p>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <div className="flex items-start gap-2 p-3 bg-white/50 dark:bg-gray-900/30 rounded-lg">
                    <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="text-xs font-bold text-gray-900 dark:text-white mb-1">Start Anvil</p>
                      <code className="text-xs text-gray-700 dark:text-gray-300 font-mono">
                        anvil --fork-url YOUR_RPC
                      </code>
                    </div>
                  </div>
                  <div className="flex items-start gap-2 p-3 bg-white/50 dark:bg-gray-900/30 rounded-lg">
                    <CheckCircle2 className="h-4 w-4 text-emerald-600 dark:text-emerald-400 flex-shrink-0 mt-0.5" />
                    <div>
                      <p className="text-xs font-bold text-gray-900 dark:text-white mb-1">Deploy Contracts</p>
                      <code className="text-xs text-gray-700 dark:text-gray-300 font-mono break-all">
                        forge script DeployForked.s.sol
                      </code>
                    </div>
                  </div>
                </div>
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
        className="relative border-t-4 border-transparent bg-gradient-to-r from-blue-200 via-purple-200 to-pink-200 dark:from-blue-900 dark:via-purple-900 dark:to-pink-900 mt-24"
      >
        {/* Decorative top border gradient */}
        <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-500 via-purple-500 to-pink-500" />
        
        {/* Background with gradient */}
        <div className="relative bg-white/95 dark:bg-gray-900/95 backdrop-blur-xl">
          {/* Subtle gradient overlay */}
          <div className="absolute inset-0 bg-gradient-to-br from-blue-50/50 via-purple-50/50 to-pink-50/50 dark:from-blue-950/30 dark:via-purple-950/30 dark:to-pink-950/30" />
          
          <div className="relative container mx-auto px-4 py-16">
            <div className="flex flex-col items-center text-center max-w-4xl mx-auto">
              {/* Logo and brand */}
              <motion.div
                whileHover={{ scale: 1.05, rotate: 2 }}
                className="flex items-center gap-3 mb-6 p-4 bg-white dark:bg-gray-800 rounded-2xl shadow-2xl border-2 border-gray-200 dark:border-gray-700"
              >
                <div className="w-14 h-14 bg-gradient-to-br from-blue-600 via-purple-600 to-pink-600 rounded-xl flex items-center justify-center shadow-lg">
                  <Coins className="h-8 w-8 text-white" />
                </div>
                <div className="text-left">
                  <h3 className="text-2xl font-black bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">
                    USDX Protocol
                  </h3>
                  <p className="text-xs text-gray-600 dark:text-gray-400 font-bold">
                    Cross-Chain Yield Stablecoin
                  </p>
                </div>
              </motion.div>
              
              <p className="text-base text-gray-600 dark:text-gray-300 mb-8 max-w-2xl leading-relaxed font-medium">
                A next-generation stablecoin protocol that combines USDC backing with automatic yield generation 
                and seamless cross-chain functionality.
              </p>

              {/* Technology badges */}
              <div className="flex flex-wrap items-center justify-center gap-4 mb-8">
                <motion.div whileHover={{ scale: 1.05 }} className="flex items-center gap-2 px-4 py-3 bg-gradient-to-r from-blue-500 to-cyan-500 rounded-xl shadow-lg">
                  <Shield className="h-5 w-5 text-white" />
                  <span className="text-sm font-bold text-white">Yearn Finance</span>
                </motion.div>
                <motion.div whileHover={{ scale: 1.05 }} className="flex items-center gap-2 px-4 py-3 bg-gradient-to-r from-purple-500 to-pink-500 rounded-xl shadow-lg">
                  <Network className="h-5 w-5 text-white" />
                  <span className="text-sm font-bold text-white">LayerZero OFT</span>
                </motion.div>
                <motion.div whileHover={{ scale: 1.05 }} className="flex items-center gap-2 px-4 py-3 bg-gradient-to-r from-emerald-500 to-green-500 rounded-xl shadow-lg">
                  <Layers className="h-5 w-5 text-white" />
                  <span className="text-sm font-bold text-white">Circle Bridge Kit</span>
                </motion.div>
              </div>

              {/* Decorative divider */}
              <div className="w-full max-w-md mb-8">
                <div className="flex items-center gap-3">
                  <div className="flex-1 h-px bg-gradient-to-r from-transparent via-blue-500 to-purple-500" />
                  <div className="flex gap-1.5">
                    <div className="w-2 h-2 rounded-full bg-blue-500 animate-pulse" />
                    <div className="w-2 h-2 rounded-full bg-purple-500 animate-pulse" style={{ animationDelay: '0.2s' }} />
                    <div className="w-2 h-2 rounded-full bg-pink-500 animate-pulse" style={{ animationDelay: '0.4s' }} />
                  </div>
                  <div className="flex-1 h-px bg-gradient-to-l from-transparent via-purple-500 to-pink-500" />
                </div>
              </div>

              {/* Tech stack */}
              <div className="p-4 bg-gradient-to-r from-gray-50 to-gray-100 dark:from-gray-800 dark:to-gray-850 rounded-xl border-2 border-gray-200 dark:border-gray-700">
                <p className="text-sm text-gray-600 dark:text-gray-400 font-semibold">
                  Built with <span className="text-blue-600 dark:text-blue-400 font-bold">Next.js</span>, <span className="text-purple-600 dark:text-purple-400 font-bold">ethers.js</span>, and <span className="text-cyan-600 dark:text-cyan-400 font-bold">Tailwind CSS</span>
                </p>
              </div>
            </div>
          </div>
        </div>
      </motion.footer>
    </main>
  );
}
