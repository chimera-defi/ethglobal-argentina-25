"use client";

import { useState } from "react";
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { parseUnits, formatUnits } from "viem";

// Mock addresses - replace with actual deployed addresses
const VAULT_ADDRESS = "0x0000000000000000000000000000000000000000";
const USDC_ADDRESS = "0x0000000000000000000000000000000000000000";

export default function DepositFlow() {
  const { address } = useAccount();
  const [amount, setAmount] = useState("");

  const { writeContract, data: hash, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const handleDeposit = async () => {
    if (!amount || !address) return;

    try {
      const amountWei = parseUnits(amount, 6); // USDC has 6 decimals

      // Approve USDC
      await writeContract({
        address: USDC_ADDRESS as `0x${string}`,
        abi: [
          {
            name: "approve",
            type: "function",
            stateMutability: "nonpayable",
            inputs: [
              { name: "spender", type: "address" },
              { name: "amount", type: "uint256" },
            ],
            outputs: [{ name: "", type: "bool" }],
          },
        ],
        functionName: "approve",
        args: [VAULT_ADDRESS as `0x${string}`, amountWei],
      });

      // Deposit (this would be called after approval)
      // await writeContract({
      //   address: VAULT_ADDRESS,
      //   abi: vaultABI,
      //   functionName: "depositUSDC",
      //   args: [amountWei],
      // });
    } catch (error) {
      console.error("Deposit error:", error);
    }
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h3 className="text-xl font-bold mb-4">Deposit USDC</h3>
      <div className="space-y-4">
        <input
          type="number"
          placeholder="Amount"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="w-full px-4 py-2 border rounded"
        />
        <button
          onClick={handleDeposit}
          disabled={isPending || isConfirming || !amount}
          className="w-full bg-blue-500 text-white py-2 px-4 rounded hover:bg-blue-600 disabled:opacity-50"
        >
          {isPending || isConfirming
            ? "Processing..."
            : isSuccess
            ? "Deposited!"
            : "Deposit"}
        </button>
        {isSuccess && (
          <p className="text-green-600 text-sm">Deposit successful!</p>
        )}
      </div>
    </div>
  );
}
