'use client';

import { useState, useEffect } from 'react';
import { useBridgeKit, TransferStatus } from '@/hooks/useBridgeKit';
import { useBalances } from '@/hooks/useBalances';
import { parseAmount, formatAmount, CONTRACTS } from '@/config/contracts';
import { CHAINS, SPOKE_CHAINS, isSpokeChain, isHubChain, isMainnetChain, isTestnetChain } from '@/config/chains';
import { motion } from 'framer-motion';
import { Network, Loader2, Info, ArrowRightLeft, AlertTriangle, Wallet } from 'lucide-react';

interface BridgeKitFlowProps {
  userAddress: string | null;
  currentChainId: number | null;
  onSuccess?: () => void;
}

export function BridgeKitFlow({ userAddress, currentChainId, onSuccess }: BridgeKitFlowProps) {
  const [amount, setAmount] = useState('');
  const [sourceChainId, setSourceChainId] = useState<number | null>(null);
  const [destinationChainId, setDestinationChainId] = useState<number | null>(null);
  const [isBridging, setIsBridging] = useState(false);
  
  const { bridgeUSDC, transferStatus, error, reset } = useBridgeKit();
  const { usdcBalance } = useBalances(userAddress);

  // Set default chains based on current chain
  useEffect(() => {
    if (currentChainId) {
      if (isSpokeChain(currentChainId)) {
        // If on spoke chain, bridge to hub
        setSourceChainId(currentChainId);
        setDestinationChainId(CHAINS.HUB.id);
      } else if (isHubChain(currentChainId)) {
        // If on hub chain, default to bridging from first spoke chain
        setSourceChainId(SPOKE_CHAINS[0]?.id || null);
        setDestinationChainId(CHAINS.HUB.id);
      }
    }
  }, [currentChainId]);

  const handleBridge = async () => {
    if (!userAddress || !sourceChainId || !destinationChainId || !amount) return;

    setIsBridging(true);
    reset();

    try {
      const parsedAmount = parseAmount(amount);
      
      if (parsedAmount <= 0) {
        setIsBridging(false);
        return;
      }
      
      const amountString = parsedAmount.toString();

      await bridgeUSDC({
        sourceChainId,
        destinationChainId,
        amount: amountString,
        recipientAddress: CONTRACTS.HUB_VAULT as `0x${string}`, // Bridge to vault address
        onStatusUpdate: (status) => {
          if (status === 'success') {
            setIsBridging(false);
            setAmount('');
            onSuccess?.();
          } else if (status === 'error') {
            setIsBridging(false);
          }
        },
      });
    } catch (err: any) {
      console.error('Bridge failed:', err);
      setIsBridging(false);
      // Error is already handled by useBridgeKit hook and displayed via error state
    }
  };

  const getStatusMessage = (status: TransferStatus): string => {
    switch (status) {
      case 'pending':
        return 'Bridge in progress...';
      case 'success':
        return 'Bridge completed successfully!';
      case 'error':
        return 'Bridge failed';
      default:
        return '';
    }
  };

  // Check if bridging from mainnet to testnet (risky operation)
  const isMainnetToTestnet = sourceChainId && destinationChainId && 
    isMainnetChain(sourceChainId) && isTestnetChain(destinationChainId);

  // Handle Max button click - use USDC balance from current chain
  const handleMaxClick = () => {
    if (usdcBalance) {
      const maxAmount = formatAmount(usdcBalance, 6);
      setAmount(maxAmount);
    }
  };

  if (!userAddress) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="card"
      >
        <div className="flex items-center gap-3 mb-4">
          <div className="p-3 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl">
            <Network className="h-6 w-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Bridge USDC</h2>
        </div>
        <div className="flex flex-col items-center justify-center py-8 text-center">
          <div className="p-4 bg-gray-100 dark:bg-gray-800 rounded-full mb-4">
            <Network className="h-8 w-8 text-gray-400" />
          </div>
          <p className="text-gray-500 dark:text-gray-400 font-medium">
            Connect your wallet to bridge USDC
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
      <div className="flex items-center gap-3 mb-4">
        <div className="p-3 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl shadow-lg">
          <ArrowRightLeft className="h-6 w-6 text-white" />
        </div>
        <div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Bridge USDC</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400">Cross-chain via Circle Bridge Kit (CCTP)</p>
        </div>
      </div>
      <p className="text-sm text-gray-600 dark:text-gray-400 mb-6">
        Bridge USDC from a spoke chain to the hub chain using Circle Bridge Kit (CCTP).
        The bridged USDC will be sent directly to the USDX Vault.
      </p>

      <div className="space-y-4">
        {/* Chain Selection */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-semibold mb-2 text-gray-700 dark:text-gray-300">From Chain</label>
            <select
              value={sourceChainId || ''}
              onChange={(e) => setSourceChainId(Number(e.target.value))}
              className="input w-full"
              disabled={isBridging}
            >
              {SPOKE_CHAINS.map((chain) => (
                <option key={chain.id} value={chain.id}>
                  {chain.name}
                </option>
              ))}
              <option value={CHAINS.HUB.id}>{CHAINS.HUB.name}</option>
              <option value={CHAINS.ETHEREUM_MAINNET.id}>{CHAINS.ETHEREUM_MAINNET.name}</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-semibold mb-2 text-gray-700 dark:text-gray-300">To Chain</label>
            <select
              value={destinationChainId || ''}
              onChange={(e) => setDestinationChainId(Number(e.target.value))}
              className="input w-full"
              disabled={isBridging}
            >
              <option value={CHAINS.HUB.id}>{CHAINS.HUB.name}</option>
              <option value={CHAINS.ETHEREUM_MAINNET.id}>{CHAINS.ETHEREUM_MAINNET.name}</option>
              {SPOKE_CHAINS.map((chain) => (
                <option key={chain.id} value={chain.id}>
                  {chain.name}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* Amount Input */}
        <div>
          <div className="flex items-center justify-between mb-2">
            <label className="block text-sm font-semibold text-gray-700 dark:text-gray-300">Amount (USDC)</label>
            <div className="flex items-center gap-2 text-xs text-gray-600 dark:text-gray-400">
              <Wallet className="h-3 w-3" />
              <span>Balance: {formatAmount(usdcBalance, 6)} USDC</span>
            </div>
          </div>
          <div className="relative">
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.00"
              className="input w-full pr-20"
              disabled={isBridging || !sourceChainId || !destinationChainId}
              step="0.000001"
              min="0"
            />
            <button
              type="button"
              onClick={handleMaxClick}
              disabled={isBridging || !sourceChainId || !destinationChainId || usdcBalance === BigInt(0)}
              className="absolute right-2 top-1/2 -translate-y-1/2 px-3 py-1 text-xs font-semibold bg-gradient-to-r from-blue-500 to-purple-500 text-white rounded-lg hover:from-blue-600 hover:to-purple-600 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
            >
              MAX
            </button>
          </div>
        </div>

        {/* Bridge Button */}
        <motion.button
          whileHover={{ scale: isBridging || !amount || !sourceChainId || !destinationChainId || sourceChainId === destinationChainId ? 1 : 1.02 }}
          whileTap={{ scale: isBridging || !amount || !sourceChainId || !destinationChainId || sourceChainId === destinationChainId ? 1 : 0.98 }}
          onClick={handleBridge}
          disabled={
            !amount ||
            isBridging ||
            !sourceChainId ||
            !destinationChainId ||
            sourceChainId === destinationChainId
          }
          className="btn bg-gradient-to-r from-purple-600 to-pink-600 text-white hover:from-purple-700 hover:to-pink-700 hover:shadow-lg shadow-sm w-full text-base py-4"
        >
          {isBridging && transferStatus !== 'idle' && (
            <>
              <Loader2 className="h-5 w-5 animate-spin" />
              {getStatusMessage(transferStatus)}
            </>
          )}
          {!isBridging && (
            <>
              <ArrowRightLeft className="h-5 w-5" />
              Bridge USDC
            </>
          )}
        </motion.button>

        {/* Status Display */}
        {transferStatus !== 'idle' && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="p-5 bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 rounded-xl border border-blue-200 dark:border-blue-800"
          >
            <div className="flex items-center gap-2 mb-2">
              <div className={`w-3 h-3 rounded-full ${
                transferStatus === 'success' ? 'bg-green-500' :
                transferStatus === 'error' ? 'bg-red-500' :
                'bg-blue-500 animate-pulse'
              }`}></div>
              <p className="text-sm font-semibold text-gray-900 dark:text-gray-100">{getStatusMessage(transferStatus)}</p>
            </div>
            {transferStatus === 'pending' && (
              <p className="text-xs text-gray-600 dark:text-gray-400 mt-2">
                This may take a few minutes. Please wait...
              </p>
            )}
          </motion.div>
        )}

        {/* Mainnet to Testnet Warning */}
        {isMainnetToTestnet && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="p-4 bg-yellow-50 dark:bg-yellow-900/20 border-2 border-yellow-400 dark:border-yellow-600 rounded-xl"
          >
            <div className="flex items-start gap-3">
              <AlertTriangle className="h-5 w-5 text-yellow-600 dark:text-yellow-400 flex-shrink-0 mt-0.5" />
              <div>
                <p className="text-sm font-semibold text-yellow-800 dark:text-yellow-200 mb-1">
                  ⚠️ Warning: Mainnet to Testnet Transfer
                </p>
                <p className="text-sm text-yellow-700 dark:text-yellow-300">
                  You are bridging USDC from a mainnet chain to a testnet chain. This may result in loss of funds as testnet tokens have no real value. Only proceed if you understand the risks.
                </p>
              </div>
            </div>
          </motion.div>
        )}

        {/* Error Display */}
        {error && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-xl"
          >
            <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
          </motion.div>
        )}

        {/* Info Box */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="p-5 bg-gradient-to-br from-purple-50 to-pink-50 dark:from-purple-900/20 dark:to-pink-900/20 rounded-xl border border-purple-200 dark:border-purple-800"
        >
          <div className="flex items-start gap-3 mb-3">
            <Info className="h-5 w-5 text-purple-600 dark:text-purple-400 flex-shrink-0 mt-0.5" />
            <h3 className="font-semibold text-gray-900 dark:text-gray-100">How it works:</h3>
          </div>
          <ol className="text-sm text-gray-700 dark:text-gray-300 space-y-2 ml-8">
            <li className="flex items-start gap-2">
              <span className="font-bold text-purple-600 dark:text-purple-400">1.</span>
              <span>Bridge USDC from spoke chain to hub chain using Circle CCTP</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-purple-600 dark:text-purple-400">2.</span>
              <span>USDC arrives at the USDX Vault on hub chain</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-purple-600 dark:text-purple-400">3.</span>
              <span>Deposit the bridged USDC to mint USDX</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-purple-600 dark:text-purple-400">4.</span>
              <span>Your position syncs to spoke chains automatically</span>
            </li>
          </ol>
        </motion.div>
      </div>
    </motion.div>
  );
}
