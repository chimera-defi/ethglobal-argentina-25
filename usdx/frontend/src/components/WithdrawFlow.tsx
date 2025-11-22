'use client';

import { useState } from 'react';
import { ethers } from 'ethers';
import { getHubUSDXContract, getHubVaultContract, waitForTransaction } from '@/lib/contracts';
import { parseAmount, formatAmount, CONTRACTS } from '@/config/contracts';
import { useToast } from '@/hooks/useToast';
import { ArrowUpCircle, Loader2, Info, CircleDollarSign, Flame } from 'lucide-react';
import { motion } from 'framer-motion';

interface WithdrawFlowProps {
  signer: ethers.Signer | null;
  onSuccess?: () => void;
}

export function WithdrawFlow({ signer, onSuccess }: WithdrawFlowProps) {
  const [amount, setAmount] = useState('');
  const [isApproving, setIsApproving] = useState(false);
  const [isWithdrawing, setIsWithdrawing] = useState(false);
  const { success: showSuccess, error: showError, loading: showLoading, removeToast } = useToast();
  const [loadingToastId, setLoadingToastId] = useState<string | null>(null);

  const handleWithdraw = async () => {
    if (!signer || !amount) return;
    
    const toastId = showLoading('Processing transaction...');
    setLoadingToastId(toastId);
    
    try {
      const parsedAmount = parseAmount(amount);
      
      if (parsedAmount <= 0) {
        removeToast(toastId);
        showError('Amount must be greater than 0');
        return;
      }

      // Step 1: Approve USDX burning
      setIsApproving(true);
      removeToast(toastId);
      const approveToastId = showLoading('Approving USDX for burning...');
      setLoadingToastId(approveToastId);
      
      const usdx = getHubUSDXContract(signer);
      const approveTx = await usdx.approve(CONTRACTS.HUB_VAULT, parsedAmount);
      await waitForTransaction(approveTx);
      setIsApproving(false);
      removeToast(approveToastId);
      showSuccess('USDX approved successfully!');

      // Step 2: Withdraw from vault
      setIsWithdrawing(true);
      const withdrawToastId = showLoading('Burning USDX and withdrawing USDC...');
      setLoadingToastId(withdrawToastId);
      
      const vault = getHubVaultContract(signer);
      const withdrawTx = await vault.withdraw(parsedAmount);
      const receipt = await waitForTransaction(withdrawTx);
      setIsWithdrawing(false);
      removeToast(withdrawToastId);

      if (receipt) {
        showSuccess(`Successfully withdrew ${amount} USDC (including yield)!`);
        setAmount('');
        onSuccess?.();
      }
    } catch (err: any) {
      console.error('Withdrawal failed:', err);
      if (loadingToastId) {
        removeToast(loadingToastId);
        setLoadingToastId(null);
      }
      showError(err.message || 'Transaction failed');
      setIsApproving(false);
      setIsWithdrawing(false);
    }
  };

  if (!signer) {
    return (
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        className="card"
      >
        <div className="flex items-center gap-3 mb-4">
          <div className="p-3 bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl">
            <ArrowUpCircle className="h-6 w-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Withdraw USDC</h2>
        </div>
        <div className="flex flex-col items-center justify-center py-8 text-center">
          <div className="p-4 bg-gray-100 dark:bg-gray-800 rounded-full mb-4">
            <CircleDollarSign className="h-8 w-8 text-gray-400" />
          </div>
          <p className="text-gray-500 dark:text-gray-400 font-medium">
            Connect your wallet to withdraw
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
          <ArrowUpCircle className="h-6 w-6 text-white" />
        </div>
        <div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Withdraw USDC</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400">Burn USDX 1:1</p>
        </div>
      </div>

      <div className="space-y-5">
        <div>
          <label className="block text-sm font-semibold mb-2 text-gray-700 dark:text-gray-300">
            Amount (USDX)
          </label>
          <div className="relative">
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.00"
              className="input h-14 text-lg pr-12"
              disabled={isApproving || isWithdrawing}
              step="0.000001"
              min="0"
            />
            <div className="absolute right-4 top-1/2 -translate-y-1/2">
              <span className="text-sm font-semibold text-gray-500 dark:text-gray-400">USDX</span>
            </div>
          </div>
        </div>

        <motion.button
          whileHover={{ scale: isApproving || isWithdrawing || !amount ? 1 : 1.02 }}
          whileTap={{ scale: isApproving || isWithdrawing || !amount ? 1 : 0.98 }}
          onClick={handleWithdraw}
          disabled={!amount || isApproving || isWithdrawing}
          className="btn bg-gradient-to-r from-blue-600 to-purple-600 text-white hover:from-blue-700 hover:to-purple-700 hover:shadow-lg shadow-sm w-full text-base py-4"
        >
          {isApproving && (
            <>
              <Loader2 className="h-5 w-5 animate-spin" />
              Approving USDX...
            </>
          )}
          {isWithdrawing && (
            <>
              <Loader2 className="h-5 w-5 animate-spin" />
              Burning & Withdrawing...
            </>
          )}
          {!isApproving && !isWithdrawing && (
            <>
              <Flame className="h-5 w-5" />
              Burn & Withdraw USDC
            </>
          )}
        </motion.button>

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
              <span>Approve USDX for burning by the vault</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-purple-600 dark:text-purple-400">2.</span>
              <span>Vault burns your USDX tokens</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-purple-600 dark:text-purple-400">3.</span>
              <span>Vault withdraws USDC from Yearn Finance</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-purple-600 dark:text-purple-400">4.</span>
              <span>You receive USDC + your share of accumulated yield</span>
            </li>
          </ol>
        </motion.div>
      </div>
    </motion.div>
  );
}
