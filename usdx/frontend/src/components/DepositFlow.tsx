'use client';

import { useState } from 'react';
import { ethers } from 'ethers';
import { getUSDCContract, getHubVaultContract, waitForTransaction } from '@/lib/contracts';
import { parseAmount, formatAmount, CONTRACTS } from '@/config/contracts';

interface DepositFlowProps {
  signer: ethers.Signer | null;
  onSuccess?: () => void;
}

export function DepositFlow({ signer, onSuccess }: DepositFlowProps) {
  const [amount, setAmount] = useState('');
  const [isApproving, setIsApproving] = useState(false);
  const [isDepositing, setIsDepositing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

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

  return (
    <div className="card">
      <h2 className="text-xl font-bold mb-4">Deposit USDC → Mint USDX</h2>
      <p className="text-sm text-gray-600 mb-4">
        Deposit USDC on hub chain to mint USDX 1:1. Your USDC will be deposited into Yearn for yield.
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
            <li>Approve USDC spending</li>
            <li>Vault deposits USDC into Yearn</li>
            <li>You receive USDX 1:1</li>
            <li>Earn yield on your deposit</li>
          </ol>
        </div>
      </div>
    </div>
  );
}
