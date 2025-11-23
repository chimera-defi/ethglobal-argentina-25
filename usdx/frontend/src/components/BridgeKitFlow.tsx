'use client';

import { useState, useEffect } from 'react';
import { useBridgeKit, TransferStatus } from '@/hooks/useBridgeKit';
import { parseAmount, CONTRACTS } from '@/config/contracts';
import { CHAINS, SPOKE, SPOKE_CHAINS } from '@/config/chains';
import { motion } from 'framer-motion';
import { Network, Loader2, Info, ArrowRightLeft } from 'lucide-react';

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

  // Set default chains based on current chain
  useEffect(() => {
    if (currentChainId) {
      // If on spoke chain, bridge to hub
      if (currentChainId === SPOKE.id || currentChainId === CHAINS.SPOKE_BASE.id || currentChainId === CHAINS.SPOKE_POLYGON.id || currentChainId === CHAINS.SPOKE_ARC.id) {
        setSourceChainId(currentChainId);
        setDestinationChainId(CHAINS.HUB.id);
      } else {
        // If on hub chain, allow bridging from spoke
        setSourceChainId(SPOKE.id);
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
          <label className="block text-sm font-semibold mb-2 text-gray-700 dark:text-gray-300">Amount (USDC)</label>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            className="input w-full"
            disabled={isBridging || !sourceChainId || !destinationChainId}
            step="0.000001"
            min="0"
          />
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
          <p className="text-xs text-gray-600 dark:text-gray-400 mt-3 pt-3 border-t border-purple-200 dark:border-purple-800">
            ⚠️ Note: Bridge Kit integration requires viem/wagmi. For full functionality,
            consider migrating to wagmi hooks or using viem directly.
          </p>
        </motion.div>
      </div>
    </motion.div>
  );
}
