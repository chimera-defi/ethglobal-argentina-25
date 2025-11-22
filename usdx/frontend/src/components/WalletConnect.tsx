'use client';

import { useWallet } from '@/hooks/useWallet';
import { formatAddress } from '@/lib/ethers';
import { Wallet, Loader2, AlertTriangle, LogOut, RefreshCw } from 'lucide-react';
import { motion } from 'framer-motion';

export function WalletConnect() {
  const { address, isConnected, isConnecting, isCorrectChain, error, connect, disconnect, switchNetwork } = useWallet();

  if (isConnecting) {
    return (
      <motion.button
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="btn bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100 hover:bg-gray-200 dark:hover:bg-gray-700 border border-gray-200 dark:border-gray-700 shadow-sm"
        disabled
      >
        <Loader2 className="h-4 w-4 animate-spin" />
        Connecting...
      </motion.button>
    );
  }

  if (isConnected && address) {
    return (
      <motion.div
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        className="flex items-center gap-3"
      >
        {!isCorrectChain && (
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={() => switchNetwork(1)}
            className="btn bg-gradient-to-r from-yellow-500 to-orange-500 text-white hover:from-yellow-600 hover:to-orange-600 shadow-lg"
          >
            <RefreshCw className="h-4 w-4" />
            Switch Network
          </motion.button>
        )}
        <motion.div
          whileHover={{ scale: 1.02 }}
          className="flex items-center gap-3 px-4 py-2.5 bg-gradient-to-r from-green-50 to-emerald-50 dark:from-green-900/20 dark:to-emerald-900/20 rounded-xl border-2 border-green-200 dark:border-green-800 shadow-md"
        >
          <div className="relative">
            <div className="w-3 h-3 bg-green-500 rounded-full animate-pulse"></div>
            <div className="absolute inset-0 w-3 h-3 bg-green-500 rounded-full animate-ping opacity-75"></div>
          </div>
          <span className="text-sm font-semibold text-gray-900 dark:text-gray-100 font-mono">
            {formatAddress(address)}
          </span>
        </motion.div>
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={disconnect}
          className="btn bg-gray-100 dark:bg-gray-800 text-gray-900 dark:text-gray-100 hover:bg-gray-200 dark:hover:bg-gray-700 border border-gray-200 dark:border-gray-700 shadow-sm"
        >
          <LogOut className="h-4 w-4" />
          Disconnect
        </motion.button>
      </motion.div>
    );
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      className="flex flex-col items-end gap-2"
    >
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95 }}
        onClick={connect}
        className="btn bg-gradient-to-r from-blue-600 to-purple-600 text-white hover:from-blue-700 hover:to-purple-700 hover:shadow-lg shadow-sm"
      >
        <Wallet className="h-4 w-4" />
        Connect Wallet
      </motion.button>
      {error && (
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-center gap-2 px-3 py-2 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg"
        >
          <AlertTriangle className="h-4 w-4 text-red-600 dark:text-red-400" />
          <p className="text-sm text-red-600 dark:text-red-400 font-medium">{error}</p>
        </motion.div>
      )}
    </motion.div>
  );
}
