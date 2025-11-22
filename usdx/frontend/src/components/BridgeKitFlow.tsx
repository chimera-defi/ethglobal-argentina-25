'use client';

import { useState, useEffect } from 'react';
import { useBridgeKit, TransferStatus } from '@/hooks/useBridgeKit';
import { parseAmount, formatAmount, CONTRACTS } from '@/config/contracts';
import { CHAINS } from '@/config/chains';

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
      if (currentChainId === CHAINS.SPOKE.id) {
        setSourceChainId(CHAINS.SPOKE.id);
        setDestinationChainId(CHAINS.HUB.id);
      } else {
        // If on hub chain, allow bridging from spoke
        setSourceChainId(CHAINS.SPOKE.id);
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
      <div className="card">
        <h2 className="text-xl font-bold mb-4">Bridge USDC</h2>
        <p className="text-gray-500">Connect your wallet to bridge USDC</p>
      </div>
    );
  }

  return (
    <div className="card">
      <h2 className="text-xl font-bold mb-4">Bridge USDC to Hub Chain</h2>
      <p className="text-sm text-gray-600 mb-4">
        Bridge USDC from a spoke chain to the hub chain using Circle Bridge Kit (CCTP).
        The bridged USDC will be sent directly to the USDX Vault.
      </p>

      <div className="space-y-4">
        {/* Chain Selection */}
        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium mb-2">From Chain</label>
            <select
              value={sourceChainId || ''}
              onChange={(e) => setSourceChainId(Number(e.target.value))}
              className="input w-full"
              disabled={isBridging}
            >
              <option value={CHAINS.SPOKE.id}>Spoke Chain (Base Sepolia)</option>
              <option value={CHAINS.HUB.id}>Hub Chain (Ethereum Sepolia)</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium mb-2">To Chain</label>
            <select
              value={destinationChainId || ''}
              onChange={(e) => setDestinationChainId(Number(e.target.value))}
              className="input w-full"
              disabled={isBridging}
            >
              <option value={CHAINS.HUB.id}>Hub Chain (Ethereum Sepolia)</option>
              <option value={CHAINS.SPOKE.id}>Spoke Chain (Base Sepolia)</option>
            </select>
          </div>
        </div>

        {/* Amount Input */}
        <div>
          <label className="block text-sm font-medium mb-2">Amount (USDC)</label>
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
        <button
          onClick={handleBridge}
          disabled={
            !amount ||
            isBridging ||
            !sourceChainId ||
            !destinationChainId ||
            sourceChainId === destinationChainId
          }
          className="btn btn-primary w-full"
        >
          {isBridging && transferStatus !== 'idle' && getStatusMessage(transferStatus)}
          {!isBridging && 'Bridge USDC'}
        </button>

        {/* Status Display */}
        {transferStatus !== 'idle' && (
          <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <div className="flex items-center gap-2 mb-2">
              <div className={`w-2 h-2 rounded-full ${
                transferStatus === 'success' ? 'bg-green-500' :
                transferStatus === 'error' ? 'bg-red-500' :
                'bg-blue-500 animate-pulse'
              }`}></div>
              <p className="text-sm font-medium">{getStatusMessage(transferStatus)}</p>
            </div>
            {transferStatus === 'pending' && (
              <p className="text-xs text-gray-600 mt-2">
                This may take a few minutes. Please wait...
              </p>
            )}
          </div>
        )}

        {/* Error Display */}
        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {/* Info Box */}
        <div className="p-4 bg-blue-50 rounded-lg">
          <h3 className="font-medium mb-2">How it works:</h3>
          <ol className="text-sm text-gray-700 space-y-1 list-decimal list-inside">
            <li>Bridge USDC from spoke chain to hub chain using Circle CCTP</li>
            <li>USDC arrives at the USDX Vault on hub chain</li>
            <li>Deposit the bridged USDC to mint USDX</li>
            <li>Your position syncs to spoke chains automatically</li>
          </ol>
          <p className="text-xs text-gray-600 mt-2">
            ⚠️ Note: Bridge Kit integration requires viem/wagmi. For full functionality,
            consider migrating to wagmi hooks or using viem directly.
          </p>
        </div>
      </div>
    </div>
  );
}
