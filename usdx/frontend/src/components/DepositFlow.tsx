'use client';

import { useState } from 'react';
import { ethers } from 'ethers';
import { getUSDCContract, getHubVaultContract, waitForTransaction } from '@/lib/contracts';
import { parseAmount, formatAmount, CONTRACTS } from '@/config/contracts';
import { useToast } from '@/hooks/useToast';
import { ArrowDownCircle, Loader2, CheckCircle2, Info, Coins } from 'lucide-react';
import { motion } from 'framer-motion';

interface DepositFlowProps {
  signer: ethers.Signer | null;
  onSuccess?: () => void;
}

export function DepositFlow({ signer, onSuccess }: DepositFlowProps) {
  const [amount, setAmount] = useState('');
  const [isApproving, setIsApproving] = useState(false);
  const [isDepositing, setIsDepositing] = useState(false);
  const { success: showSuccess, error: showError, loading: showLoading, removeToast } = useToast();
  const [loadingToastId, setLoadingToastId] = useState<string | null>(null);

  const handleDeposit = async () => {
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

      // Step 1: Approve USDC
      setIsApproving(true);
      removeToast(toastId);
      const approveToastId = showLoading('Approving USDC spending...');
      setLoadingToastId(approveToastId);
      
      const usdc = getUSDCContract(signer);
      const approveTx = await usdc.approve(CONTRACTS.HUB_VAULT, parsedAmount);
      await waitForTransaction(approveTx);
      setIsApproving(false);
      removeToast(approveToastId);
      showSuccess('USDC approved successfully!');

      // Step 2: Deposit to vault
      setIsDepositing(true);
      const depositToastId = showLoading('Depositing USDC and minting USDX...');
      setLoadingToastId(depositToastId);
      
      const vault = getHubVaultContract(signer);
      const depositTx = await vault.deposit(parsedAmount);
      const receipt = await waitForTransaction(depositTx);
      setIsDepositing(false);
      removeToast(depositToastId);

      if (receipt) {
        showSuccess(`Successfully deposited ${amount} USDC and minted USDX!`);
        setAmount('');
        onSuccess?.();
      }
    } catch (err: any) {
      console.error('Deposit failed:', err);
      if (loadingToastId) {
        removeToast(loadingToastId);
        setLoadingToastId(null);
      }
      showError(err.message || 'Transaction failed');
      setIsApproving(false);
      setIsDepositing(false);
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
          <div className="p-3 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-xl">
            <ArrowDownCircle className="h-6 w-6 text-white" />
          </div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Deposit USDC</h2>
        </div>
        <div className="flex flex-col items-center justify-center py-8 text-center">
          <div className="p-4 bg-gray-100 dark:bg-gray-800 rounded-full mb-4">
            <Coins className="h-8 w-8 text-gray-400" />
          </div>
          <p className="text-gray-500 dark:text-gray-400 font-medium">
            Connect your wallet to deposit
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
        <div className="p-3 bg-gradient-to-br from-blue-500 to-cyan-500 rounded-xl shadow-lg">
          <ArrowDownCircle className="h-6 w-6 text-white" />
        </div>
        <div>
          <h2 className="text-2xl font-bold bg-gradient-to-r from-blue-600 via-purple-600 to-pink-600 bg-clip-text text-transparent">Deposit USDC</h2>
          <p className="text-sm text-gray-600 dark:text-gray-400">Mint USDX 1:1</p>
        </div>
      </div>

      <div className="space-y-5">
        <div>
          <label className="block text-sm font-semibold mb-2 text-gray-700 dark:text-gray-300">
            Amount (USDC)
          </label>
          <div className="relative">
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="0.00"
              className="input h-14 text-lg pr-12"
              disabled={isApproving || isDepositing}
              step="0.000001"
              min="0"
            />
            <div className="absolute right-4 top-1/2 -translate-y-1/2">
              <span className="text-sm font-semibold text-gray-500 dark:text-gray-400">USDC</span>
            </div>
          </div>
        </div>

        <motion.button
          whileHover={{ scale: isApproving || isDepositing || !amount ? 1 : 1.02 }}
          whileTap={{ scale: isApproving || isDepositing || !amount ? 1 : 0.98 }}
          onClick={handleDeposit}
          disabled={!amount || isApproving || isDepositing}
          className="btn bg-gradient-to-r from-blue-600 to-purple-600 text-white hover:from-blue-700 hover:to-purple-700 hover:shadow-lg shadow-sm w-full text-base py-4"
        >
          {isApproving && (
            <>
              <Loader2 className="h-5 w-5 animate-spin" />
              Approving USDC...
            </>
          )}
          {isDepositing && (
            <>
              <Loader2 className="h-5 w-5 animate-spin" />
              Depositing & Minting...
            </>
          )}
          {!isApproving && !isDepositing && (
            <>
              <ArrowDownCircle className="h-5 w-5" />
              Deposit & Mint USDX
            </>
          )}
        </motion.button>

        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          className="p-5 bg-gradient-to-br from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 rounded-xl border border-blue-200 dark:border-blue-800"
        >
          <div className="flex items-start gap-3 mb-3">
            <Info className="h-5 w-5 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" />
            <h3 className="font-semibold text-gray-900 dark:text-gray-100">How it works:</h3>
          </div>
          <ol className="text-sm text-gray-700 dark:text-gray-300 space-y-2 ml-8">
            <li className="flex items-start gap-2">
              <span className="font-bold text-blue-600 dark:text-blue-400">1.</span>
              <span>Approve USDC spending for the vault</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-blue-600 dark:text-blue-400">2.</span>
              <span>Vault deposits USDC into Yearn Finance</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-blue-600 dark:text-blue-400">3.</span>
              <span>You receive USDX tokens 1:1</span>
            </li>
            <li className="flex items-start gap-2">
              <span className="font-bold text-blue-600 dark:text-blue-400">4.</span>
              <span>Earn yield automatically on your deposit</span>
            </li>
          </ol>
        </motion.div>
      </div>
    </motion.div>
  );
}
