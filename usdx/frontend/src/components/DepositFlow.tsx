'use client';

import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { getUSDCContract, getHubVaultContract, waitForTransaction } from '@/lib/contracts';
import { parseAmount, formatAmount, CONTRACTS } from '@/config/contracts';
import { CHAINS } from '@/config/chains';
import { BridgeKitFlow } from './BridgeKitFlow';

interface DepositFlowProps {
  signer: ethers.Signer | null;
  userAddress: string | null;
  chainId: number | null;
  onSuccess?: () => void;
}

export function DepositFlow({ signer, userAddress, chainId, onSuccess }: DepositFlowProps) {
  const [amount, setAmount] = useState('');
  const [isApproving, setIsApproving] = useState(false);
  const [isDepositing, setIsDepositing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [showBridgeFlow, setShowBridgeFlow] = useState(false);
  
  // Check if user is on spoke chain - if so, show bridge flow first
  useEffect(() => {
    if (chainId === CHAINS.SPOKE.id) {
      setShowBridgeFlow(true);
    } else {
      setShowBridgeFlow(false);
    }
  }, [chainId]);

  const handleDeposit = async () => {
    if (!signer || !amount) return;
    
    setError(null);
    setSuccess(null);
    
    try {
      const parsedAmount = parseAmount(amount);
      
      if (parsedAmount <= 0) {
        setError('Amount must be greater than 0');
        return;
      }

      // Step 1: Approve USDC
      setIsApproving(true);
      const usdc = getUSDCContract(signer);
      const approveTx = await usdc.approve(CONTRACTS.HUB_VAULT, parsedAmount);
      await waitForTransaction(approveTx);
      setIsApproving(false);

      // Step 2: Deposit to vault
      setIsDepositing(true);
      const vault = getHubVaultContract(signer);
      const depositTx = await vault.deposit(parsedAmount);
      const receipt = await waitForTransaction(depositTx);
      setIsDepositing(false);

      if (receipt) {
        setSuccess(`Successfully deposited ${amount} USDC and minted USDX!`);
        setAmount('');
        onSuccess?.();
      }
    } catch (err: any) {
      console.error('Deposit failed:', err);
      setError(err.message || 'Transaction failed');
      setIsApproving(false);
      setIsDepositing(false);
    }
  };

  if (!signer) {
    return (
      <div className="card">
        <h2 className="text-xl font-bold mb-4">Deposit USDC</h2>
        <p className="text-gray-500">Connect your wallet to deposit</p>
      </div>
    );
  }

  // If on spoke chain, show bridge flow first
  if (showBridgeFlow && chainId === CHAINS.SPOKE.id) {
    return (
      <div className="space-y-4">
        <BridgeKitFlow
          userAddress={userAddress}
          currentChainId={chainId}
          onSuccess={() => {
            setShowBridgeFlow(false);
            // After bridging, show success message
            // User will need to switch to hub chain to deposit
            // This is handled by the UI state change
          }}
        />
        <div className="card bg-green-50 border-green-200">
          <h3 className="text-lg font-bold mb-2 text-green-800">Next Steps After Bridging</h3>
          <ol className="text-sm text-gray-700 space-y-2 list-decimal list-inside">
            <li className="font-medium">Bridge USDC to hub chain using Bridge Kit above</li>
            <li className="font-medium">Switch your wallet to Hub chain (Ethereum Sepolia)</li>
            <li className="font-medium">Deposit the bridged USDC to mint USDX</li>
          </ol>
          <p className="text-xs text-gray-600 mt-3 pt-3 border-t border-green-200">
            💡 Tip: The bridge may take a few minutes. Once complete, switch chains and refresh this page.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="card">
      <h2 className="text-xl font-bold mb-4">Deposit USDC → Mint USDX</h2>
      <p className="text-sm text-gray-600 mb-4">
        Deposit USDC on hub chain to mint USDX 1:1. Your USDC will be deposited into Yearn for yield.
        {chainId === CHAINS.SPOKE.id && (
          <span className="block mt-2 text-yellow-600">
            ⚠️ You're on a spoke chain. Bridge USDC to hub chain first, then deposit.
          </span>
        )}
      </p>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-2">Amount (USDC)</label>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            className="input w-full"
            disabled={isApproving || isDepositing}
            step="0.000001"
            min="0"
          />
        </div>

        <button
          onClick={handleDeposit}
          disabled={!amount || isApproving || isDepositing}
          className="btn btn-primary w-full"
        >
          {isApproving && 'Approving USDC...'}
          {isDepositing && 'Depositing...'}
          {!isApproving && !isDepositing && 'Deposit & Mint'}
        </button>

        {error && (
          <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
            <p className="text-sm text-red-600">{error}</p>
          </div>
        )}

        {success && (
          <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
            <p className="text-sm text-green-600">{success}</p>
          </div>
        )}

        <div className="p-4 bg-blue-50 rounded-lg">
          <h3 className="font-medium mb-2">How it works:</h3>
          <ol className="text-sm text-gray-700 space-y-1 list-decimal list-inside">
            {chainId === CHAINS.SPOKE.id ? (
              <>
                <li>Bridge USDC from spoke chain to hub chain (Circle Bridge Kit)</li>
                <li>Switch to hub chain</li>
                <li>Approve USDC spending</li>
                <li>Vault deposits USDC into Yearn</li>
                <li>You receive USDX 1:1</li>
                <li>Earn yield on your deposit</li>
              </>
            ) : (
              <>
                <li>Approve USDC spending</li>
                <li>Vault deposits USDC into Yearn</li>
                <li>You receive USDX 1:1</li>
                <li>Earn yield on your deposit</li>
              </>
            )}
          </ol>
        </div>
      </div>
    </div>
  );
}
