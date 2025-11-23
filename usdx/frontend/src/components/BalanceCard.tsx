'use client';

import { useBalances } from '@/hooks/useBalances';
import { formatAmount } from '@/config/contracts';
import { Wallet, Coins, CircleDollarSign, Loader2 } from 'lucide-react';
import { motion } from 'framer-motion';

interface BalanceCardProps {
  address: string | null;
}

const getBalanceItems = (chainName: string) => [
  {
    key: 'usdc',
    label: 'USDC',
    description: `USDC balance on ${chainName}`,
    icon: Coins,
    bgGradient: 'from-blue-500 to-cyan-500',
    bgLight: 'bg-gradient-to-br from-blue-50 to-cyan-50 dark:from-blue-900/20 dark:to-cyan-900/20',
    borderColor: 'border-blue-200 dark:border-blue-800',
    textColor: 'text-blue-600 dark:text-blue-400',
    iconColor: 'text-blue-400 dark:text-blue-500',
  },
  {
    key: 'hubUsdx',
    label: 'USDX (Hub)',
    description: 'USDX on hub chain (Ethereum)',
    icon: CircleDollarSign,
    bgGradient: 'from-purple-500 to-pink-500',
    bgLight: 'bg-gradient-to-br from-purple-50 to-pink-50 dark:from-purple-900/20 dark:to-pink-900/20',
    borderColor: 'border-purple-200 dark:border-purple-800',
    textColor: 'text-purple-600 dark:text-purple-400',
    iconColor: 'text-purple-400 dark:text-purple-500',
  },
  {
    key: 'spokeUsdx',
    label: 'USDX (Spoke)',
    description: 'USDX on this spoke chain',
    icon: CircleDollarSign,
    bgGradient: 'from-green-500 to-emerald-500',
    bgLight: 'bg-gradient-to-br from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20',
    borderColor: 'border-green-200 dark:border-green-800',
    textColor: 'text-green-600 dark:text-green-400',
    iconColor: 'text-green-400 dark:text-green-500',
  },
];

export function BalanceCard({ address }: BalanceCardProps) {
  const { usdcBalance, hubUsdxBalance, spokeUsdxBalance, isLoading, currentChainName, chainId } = useBalances(address);
  
  const balanceItems = getBalanceItems(currentChainName);

  const getBalance = (key: string): bigint => {
    switch (key) {
      case 'usdc':
        return usdcBalance;
      case 'hubUsdx':
        return hubUsdxBalance;
      case 'spokeUsdx':
        return spokeUsdxBalance;
      default:
        return BigInt(0);
    }
  };

  if (!address) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="card"
      >
        <div className="flex items-center gap-3 mb-6">
          <div className="p-3 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl">
            <Wallet className="h-6 w-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Your Balances</h2>
        </div>
        <div className="flex flex-col items-center justify-center py-12 text-center">
          <div className="p-4 bg-gray-100 dark:bg-gray-800 rounded-full mb-4">
            <Wallet className="h-8 w-8 text-gray-400" />
          </div>
          <p className="text-gray-500 dark:text-gray-400 font-medium">
            Connect your wallet to see balances
          </p>
        </div>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      className="card"
    >
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-3">
          <div className="p-3 bg-gradient-to-br from-blue-500 to-purple-600 rounded-xl shadow-lg">
            <Wallet className="h-6 w-6 text-white" />
          </div>
          <div>
            <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Your Balances</h2>
            <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
              On {currentChainName} {chainId && `(Chain ID: ${chainId})`}
            </p>
          </div>
        </div>
      </div>
      
      {isLoading ? (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div
              key={i}
              className="h-24 animate-pulse rounded-xl border border-gray-200 dark:border-gray-800 bg-gray-100 dark:bg-gray-800"
            />
          ))}
        </div>
      ) : (
        <div className="space-y-4">
          {balanceItems.map((item, index) => {
            const Icon = item.icon;
            const balance = getBalance(item.key);
            const amount = formatAmount(balance);
            
            return (
              <motion.div
                key={item.key}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.1 }}
                whileHover={{ scale: 1.02 }}
                className={`flex items-center justify-between p-5 rounded-xl border-2 ${item.bgLight} ${item.borderColor} transition-all duration-300 hover:shadow-lg`}
              >
                <div className="flex items-center gap-4 flex-1">
                  <div className={`p-3 bg-gradient-to-br ${item.bgGradient} rounded-xl shadow-md`}>
                    <Icon className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-gray-600 dark:text-gray-300 mb-1">
                      {item.label}
                    </p>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mb-1">
                      {item.description}
                    </p>
                    <p className={`text-3xl font-bold ${item.textColor}`}>
                      {amount}
                    </p>
                  </div>
                </div>
                <div className={`${item.iconColor} opacity-20`}>
                  <Icon className="h-16 w-16" />
                </div>
              </motion.div>
            );
          })}
        </div>
      )}
    </motion.div>
  );
}
