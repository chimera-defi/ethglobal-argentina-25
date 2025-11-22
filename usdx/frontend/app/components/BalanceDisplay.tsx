"use client";

import { useState, useEffect } from "react";
import { ethers } from "ethers";
import { WalletState } from "../wallet";

// Mock contract addresses - replace with actual deployed addresses
const USDX_TOKEN_ADDRESS = "0x0000000000000000000000000000000000000000";
const USDC_ADDRESS = "0x0000000000000000000000000000000000000000";

// ERC20 ABI for balance checking
const ERC20_ABI = [
  "function balanceOf(address owner) view returns (uint256)",
  "function decimals() view returns (uint8)",
];

export default function BalanceDisplay() {
  const [wallet, setWallet] = useState<WalletState | null>(null);
  const [usdxBalance, setUsdxBalance] = useState<string>("0.00");
  const [usdcBalance, setUsdcBalance] = useState<string>("0.00");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    checkWallet();
    if (typeof window !== "undefined" && window.ethereum) {
      window.ethereum.on("accountsChanged", checkWallet);
      window.ethereum.on("chainChanged", checkWallet);
    }
    return () => {
      if (typeof window !== "undefined" && window.ethereum) {
        window.ethereum.removeListener("accountsChanged", checkWallet);
        window.ethereum.removeListener("chainChanged", checkWallet);
      }
    };
  }, []);

  useEffect(() => {
    if (wallet?.address && wallet?.provider) {
      loadBalances();
    }
  }, [wallet?.address, wallet?.provider]);

  const checkWallet = async () => {
    if (typeof window === "undefined" || !window.ethereum) return;
    
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum as any);
      const accounts = await provider.listAccounts();
      if (accounts.length > 0) {
        const signer = provider.getSigner();
        const address = await signer.getAddress();
        setWallet({ provider, signer, address, chainId: null, isConnected: true });
      }
    } catch (error) {
      console.error("Error checking wallet:", error);
    }
  };

  const loadBalances = async () => {
    if (!wallet?.address || !wallet?.provider) return;
    
    setLoading(true);
    try {
      // Load USDX balance
      if (USDX_TOKEN_ADDRESS !== "0x0000000000000000000000000000000000000000") {
        const usdxContract = new ethers.Contract(USDX_TOKEN_ADDRESS, ERC20_ABI, wallet.provider);
        const balance = await usdxContract.balanceOf(wallet.address);
        const decimals = await usdxContract.decimals();
        setUsdxBalance(ethers.utils.formatUnits(balance, decimals));
      }

      // Load USDC balance
      if (USDC_ADDRESS !== "0x0000000000000000000000000000000000000000") {
        const usdcContract = new ethers.Contract(USDC_ADDRESS, ERC20_ABI, wallet.provider);
        const balance = await usdcContract.balanceOf(wallet.address);
        const decimals = await usdcContract.decimals();
        setUsdcBalance(ethers.utils.formatUnits(balance, decimals));
      }
    } catch (error) {
      console.error("Error loading balances:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h2 className="text-2xl font-bold mb-4">Your Balances</h2>
      {loading ? (
        <p>Loading...</p>
      ) : (
        <div className="space-y-2">
          <div className="flex justify-between">
            <span>USDX:</span>
            <span className="font-mono">{usdxBalance}</span>
          </div>
          <div className="flex justify-between">
            <span>USDC:</span>
            <span className="font-mono">{usdcBalance}</span>
          </div>
        </div>
      )}
    </div>
  );
}
