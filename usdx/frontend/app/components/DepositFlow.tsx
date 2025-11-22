"use client";

import { useState } from "react";
import { ethers } from "ethers";
import { WalletState } from "../wallet";

// Mock addresses - replace with actual deployed addresses
const VAULT_ADDRESS = "0x0000000000000000000000000000000000000000";
const USDC_ADDRESS = "0x0000000000000000000000000000000000000000";

// ERC20 ABI
const ERC20_ABI = [
  "function approve(address spender, uint256 amount) returns (bool)",
  "function balanceOf(address owner) view returns (uint256)",
];

export default function DepositFlow() {
  const [wallet, setWallet] = useState<WalletState | null>(null);
  const [amount, setAmount] = useState("");
  const [loading, setLoading] = useState(false);
  const [status, setStatus] = useState<"idle" | "pending" | "success" | "error">("idle");

  const handleDeposit = async () => {
    if (!amount || !wallet?.signer) {
      alert("Please connect your wallet first");
      return;
    }

    setLoading(true);
    setStatus("pending");

    try {
      const amountWei = ethers.utils.parseUnits(amount, 6); // USDC has 6 decimals

      // Approve USDC
      const usdcContract = new ethers.Contract(USDC_ADDRESS, ERC20_ABI, wallet.signer);
      const approveTx = await usdcContract.approve(VAULT_ADDRESS, amountWei);
      await approveTx.wait();

      // TODO: Call vault deposit function once ABI is available
      // const vaultContract = new ethers.Contract(VAULT_ADDRESS, VAULT_ABI, wallet.signer);
      // const depositTx = await vaultContract.depositUSDC(amountWei);
      // await depositTx.wait();

      setStatus("success");
    } catch (error: any) {
      console.error("Deposit error:", error);
      setStatus("error");
      alert(`Deposit failed: ${error.message}`);
    } finally {
      setLoading(false);
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
          disabled={loading || !amount || !wallet?.isConnected}
          className="w-full bg-blue-500 text-white py-2 px-4 rounded hover:bg-blue-600 disabled:opacity-50"
        >
          {loading
            ? "Processing..."
            : status === "success"
            ? "Deposited!"
            : "Deposit"}
        </button>
        {status === "success" && (
          <p className="text-green-600 text-sm">Deposit successful!</p>
        )}
        {status === "error" && (
          <p className="text-red-600 text-sm">Deposit failed. Please try again.</p>
        )}
      </div>
    </div>
  );
}
