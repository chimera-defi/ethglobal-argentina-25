'use client';

import { useState, useEffect } from 'react';
import { useWallet } from '@/hooks/useWallet';
import { formatAddress } from '@/lib/ethers';
import { WalletModal } from './WalletModal';
import { WalletType } from '@/lib/walletProvider';
import { motion } from 'framer-motion';
import { Wallet, ChevronDown } from 'lucide-react';

export function WalletConnect() {
  const { address, isConnected, isConnecting, isCorrectChain, error, walletType, connectByType, disconnect, switchNetwork } = useWallet();
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Close modal when connection succeeds
  useEffect(() => {
    if (isConnected && !isConnecting) {
      setIsModalOpen(false);
    }
  }, [isConnected, isConnecting]);

  const handleConnectClick = () => {
    setIsModalOpen(true);
  };

  const handleSelectWallet = async (type: WalletType) => {
    try {
      // Add timeout for WalletConnect (30 seconds)
      const connectionPromise = connectByType(type);
      const timeoutPromise = new Promise((_, reject) => {
        setTimeout(() => reject(new Error('Connection timeout. Please try again.')), 30000);
      });
      
      await Promise.race([connectionPromise, timeoutPromise]);
      setIsModalOpen(false);
    } catch (err: any) {
      console.error('Connection failed:', err);
      // Modal will stay open on error so user can try again
      // Error is already set in useWallet hook
    }
  };

  const handleCloseModal = () => {
    // Always allow closing, even when connecting
    setIsModalOpen(false);
  };

  const handleDisconnect = async () => {
    await disconnect();
  };

  if (isConnecting) {
    return (
      <button className="px-4 py-2 bg-gray-200 dark:bg-gray-700 text-gray-600 dark:text-gray-400 rounded-lg font-medium" disabled>
        Connecting...
      </button>
    );
  }

  if (isConnected && address) {
    return (
      <>
        <div className="flex items-center gap-2">
          {!isCorrectChain && (
            <motion.button
              whileHover={{ scale: 1.05 }}
              whileTap={{ scale: 0.95 }}
              onClick={() => switchNetwork(1)}
              className="px-3 py-2 bg-yellow-500 text-white rounded-lg font-medium hover:bg-yellow-600 transition-colors text-sm shadow-lg"
            >
              Switch Network
            </motion.button>
          )}
          
          <div className="flex items-center gap-2 px-4 py-2 bg-white dark:bg-gray-800 rounded-lg border-2 border-gray-200 dark:border-gray-700 shadow-sm">
            <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
            <span className="text-sm font-medium text-gray-900 dark:text-white">
              {formatAddress(address)}
            </span>
            {walletType && (
              <span className="text-xs px-2 py-0.5 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 rounded-full font-medium capitalize">
                {walletType === 'walletconnect' ? 'WC' : walletType.slice(0, 3)}
              </span>
            )}
          </div>
          
          <motion.button
            whileHover={{ scale: 1.05 }}
            whileTap={{ scale: 0.95 }}
            onClick={handleDisconnect}
            className="px-4 py-2 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-lg font-medium hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors border-2 border-gray-200 dark:border-gray-700"
          >
            Disconnect
          </motion.button>
        </div>
        
        {error && (
          <p className="text-sm text-red-600 dark:text-red-400 mt-2">{error}</p>
        )}
      </>
    );
  }

  return (
    <>
      <div className="flex flex-col items-end gap-2">
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          onClick={handleConnectClick}
          className="flex items-center gap-2 px-6 py-2.5 bg-gradient-to-r from-blue-600 to-purple-600 text-white rounded-lg font-bold hover:from-blue-700 hover:to-purple-700 transition-all shadow-lg hover:shadow-xl"
        >
          <Wallet className="h-4 w-4" />
          Connect Wallet
          <ChevronDown className="h-3 w-3" />
        </motion.button>
        
        {error && (
          <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
        )}
      </div>

      <WalletModal
        isOpen={isModalOpen}
        onClose={handleCloseModal}
        onSelectWallet={handleSelectWallet}
        isConnecting={isConnecting}
        error={error}
      />
    </>
  );
}
