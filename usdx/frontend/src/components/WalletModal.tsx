'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Wallet, QrCode, Chrome, Shield } from 'lucide-react';
import { WalletType, detectWallets } from '@/lib/walletProvider';

interface WalletModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectWallet: (type: WalletType) => void;
  isConnecting: boolean;
  error?: string | null;
}

interface WalletOption {
  type: WalletType;
  name: string;
  description: string;
  icon: React.ComponentType<any>;
  available: boolean;
  color: string;
}

export function WalletModal({ isOpen, onClose, onSelectWallet, isConnecting, error }: WalletModalProps) {
  const [selectedWallet, setSelectedWallet] = useState<WalletType | null>(null);
  const availableWallets = detectWallets();

  const walletOptions: WalletOption[] = [
    {
      type: 'metamask',
      name: 'MetaMask',
      description: 'Connect with MetaMask browser extension',
      icon: Wallet,
      available: availableWallets.find(w => w.type === 'metamask')?.available || false,
      color: 'from-orange-500 to-yellow-500',
    },
    {
      type: 'walletconnect',
      name: 'WalletConnect',
      description: 'Scan QR code with your mobile wallet',
      icon: QrCode,
      available: true, // Always available
      color: 'from-blue-500 to-cyan-500',
    },
    {
      type: 'coinbase',
      name: 'Coinbase Wallet',
      description: 'Connect with Coinbase Wallet',
      icon: Shield,
      available: availableWallets.find(w => w.type === 'coinbase')?.available || false,
      color: 'from-blue-600 to-indigo-600',
    },
    {
      type: 'injected',
      name: 'Browser Wallet',
      description: 'Connect with any injected wallet',
      icon: Chrome,
      available: availableWallets.find(w => w.type === 'injected')?.available || false,
      color: 'from-purple-500 to-pink-500',
    },
  ];

  const handleSelectWallet = (type: WalletType, available: boolean) => {
    if (!available || isConnecting) return;
    setSelectedWallet(type);
    onSelectWallet(type);
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          {/* Backdrop */}
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50"
          />

          {/* Modal */}
          <div className="fixed inset-0 flex items-center justify-center z-50 p-8 pointer-events-none" style={{ paddingTop: '30rem' }}>
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 20 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="bg-white dark:bg-gray-900 rounded-2xl shadow-2xl border-2 border-gray-200 dark:border-gray-700 max-w-md w-full max-h-[90vh] overflow-hidden pointer-events-auto"
            >
              {/* Header */}
              <div className="flex items-center justify-between p-6 border-b-2 border-gray-200 dark:border-gray-700">
                <div>
                  <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
                    Connect Wallet
                  </h2>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                    Choose your preferred wallet
                  </p>
                </div>
                <button
                  onClick={onClose}
                  className="p-2 hover:bg-gray-100 dark:hover:bg-gray-800 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  disabled={false}
                  title={isConnecting ? "Close (connection will continue)" : "Close"}
                >
                  <X className="h-5 w-5 text-gray-500" />
                </button>
              </div>

              {/* Error Message */}
              {error && (
                <div className="mx-6 mt-4 p-3 bg-red-50 dark:bg-red-900/20 border-2 border-red-200 dark:border-red-800 rounded-lg">
                  <p className="text-sm text-red-600 dark:text-red-400 font-medium">{error}</p>
                </div>
              )}

              {/* Wallet Options */}
              <div className="p-6 space-y-3 overflow-y-auto max-h-[calc(90vh-120px)]">
                {walletOptions.map((wallet) => {
                  const Icon = wallet.icon;
                  const isSelected = selectedWallet === wallet.type;
                  const isDisabled = !wallet.available || isConnecting;

                  return (
                    <motion.button
                      key={wallet.type}
                      onClick={() => handleSelectWallet(wallet.type, wallet.available)}
                      disabled={isDisabled}
                      whileHover={!isDisabled ? { scale: 1.02, y: -2 } : {}}
                      whileTap={!isDisabled ? { scale: 0.98 } : {}}
                      className={`
                        w-full p-4 rounded-xl border-2 transition-all duration-200
                        ${isDisabled 
                          ? 'opacity-50 cursor-not-allowed bg-gray-50 dark:bg-gray-800 border-gray-200 dark:border-gray-700' 
                          : 'hover:border-blue-500 dark:hover:border-blue-400 border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800'
                        }
                        ${isSelected && isConnecting 
                          ? 'border-blue-500 dark:border-blue-400 bg-blue-50 dark:bg-blue-900/20' 
                          : ''
                        }
                      `}
                    >
                      <div className="flex items-center gap-4">
                        {/* Icon */}
                        <div className={`
                          w-12 h-12 rounded-xl flex items-center justify-center shadow-lg
                          bg-gradient-to-br ${wallet.color}
                        `}>
                          <Icon className="h-6 w-6 text-white" />
                        </div>

                        {/* Info */}
                        <div className="flex-1 text-left">
                          <div className="flex items-center gap-2">
                            <h3 className="text-base font-bold text-gray-900 dark:text-white">
                              {wallet.name}
                            </h3>
                            {!wallet.available && (
                              <span className="text-xs px-2 py-0.5 bg-yellow-100 dark:bg-yellow-900/30 text-yellow-700 dark:text-yellow-400 rounded-full font-medium">
                                {wallet.type === 'walletconnect' ? 'Not Configured' : 'Not Detected'}
                              </span>
                            )}
                          </div>
                          <p className="text-sm text-gray-600 dark:text-gray-400 mt-0.5">
                            {wallet.description}
                          </p>
                          {isSelected && isConnecting && (
                            <p className="text-sm text-blue-600 dark:text-blue-400 mt-1 font-medium">
                              Connecting...
                            </p>
                          )}
                        </div>

                        {/* Status indicator */}
                        {wallet.available && !isConnecting && (
                          <div className="w-2 h-2 bg-green-500 rounded-full" />
                        )}
                        {isSelected && isConnecting && (
                          <div className="w-5 h-5 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
                        )}
                      </div>
                    </motion.button>
                  );
                })}
              </div>

              {/* Footer */}
              <div className="p-6 border-t-2 border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-800">
                <div className="flex items-start gap-3">
                  <Shield className="h-5 w-5 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" />
                  <div>
                    <p className="text-sm text-gray-700 dark:text-gray-300 font-medium">
                      Secure Connection
                    </p>
                    <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                      We do not store your private keys. Your wallet connection is secure and encrypted.
                    </p>
                  </div>
                </div>
              </div>
            </motion.div>
          </div>
        </>
      )}
    </AnimatePresence>
  );
}
