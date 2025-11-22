'use client';

import { useState } from 'react';
import { getHubUSDXContract, getHubVaultContract, waitForTransaction } from '@/lib/contracts';
import { parseAmount, CONTRACTS } from '@/config/contracts';

export function WithdrawFlow({ signer, onSuccess }) {
  const [amount, setAmount] = useState('');
  const [isApproving, setIsApproving] = useState(false);
  const [isWithdrawing, setIsWithdrawing] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);

  const handleWithdraw = async () => {
    if (!signer || !amount) return;
    
    setError(null);
    setSuccess(null);
    
    try {
      const parsedAmount = parseAmount(amount);
      
      if (parsedAmount <= 0) {
        setError('Amount must be greater than 0');
        return;
      }

      // Step 1: Approve USDX burning
      setIsApproving(true);
      const usdx = getHubUSDXContract(signer);
      const approveTx = await usdx.approve(CONTRACTS.HUB_VAULT, parsedAmount);
      await waitForTransaction(approveTx);
      setIsApproving(false);

      // Step 2: Withdraw from vault
      setIsWithdrawing(true);
      const vault = getHubVaultContract(signer);
      const withdrawTx = await vault.withdraw(parsedAmount);
      const receipt = await waitForTransaction(withdrawTx);
      setIsWithdrawing(false);

      if (receipt) {
        setSuccess(`Successfully withdrew ${amount} USDC!`);
        setAmount('');
        if (onSuccess) onSuccess();
      }
    } catch (err) {
      console.error('Withdrawal failed:', err);
      setError(err instanceof Error ? err.message : 'Transaction failed');
      setIsApproving(false);
      setIsWithdrawing(false);
    }
  };

  if (!signer) {
    return (
      <div className="card">
        <h2 className="text-xl font-bold mb-4">Withdraw USDC</h2>
        <p className="text-gray-500">Connect your wallet to withdraw</p>
      </div>
    );
  }

  return (
    <div className="card">
      <h2 className="text-xl font-bold mb-4">Burn USDX → Withdraw USDC</h2>
      <p className="text-sm text-gray-600 mb-4">
        Burn your USDX to withdraw USDC 1:1 from the vault. Your share of the yield is included.
      </p>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium mb-2">Amount (USDX)</label>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            className="input w-full"
            disabled={isApproving || isWithdrawing}
            step="0.000001"
            min="0"
          />
        </div>

        <button
          onClick={handleWithdraw}
          disabled={!amount || isApproving || isWithdrawing}
          className="btn btn-primary w-full"
        >
          {isApproving && 'Approving USDX...'}
          {isWithdrawing && 'Withdrawing...'}
          {!isApproving && !isWithdrawing && 'Burn & Withdraw'}
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

        <div className="p-4 bg-purple-50 rounded-lg">
          <h3 className="font-medium mb-2">How it works:</h3>
          <ol className="text-sm text-gray-700 space-y-1 list-decimal list-inside">
            <li>Approve USDX burning</li>
            <li>Vault burns your USDX</li>
            <li>Vault withdraws from Yearn</li>
            <li>You receive USDC + yield</li>
          </ol>
        </div>
      </div>
    </div>
  );
}
