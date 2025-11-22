"use client";

import { useState, useEffect } from "react";
import { ethers } from "ethers";
import { connectWallet, disconnectWallet, WalletState } from "../wallet";

export default function WalletButton() {
  const [wallet, setWallet] = useState<WalletState>({
    provider: null,
    signer: null,
    address: null,
    chainId: null,
    isConnected: false,
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    // Check if already connected
    if (typeof window !== "undefined" && window.ethereum) {
      window.ethereum.on("accountsChanged", handleAccountsChanged);
      window.ethereum.on("chainChanged", handleChainChanged);
      checkConnection();
    }

    return () => {
      if (typeof window !== "undefined" && window.ethereum) {
        window.ethereum.removeListener("accountsChanged", handleAccountsChanged);
        window.ethereum.removeListener("chainChanged", handleChainChanged);
      }
    };
  }, []);

  const checkConnection = async () => {
    if (typeof window === "undefined" || !window.ethereum) return;
    
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const accounts = await provider.listAccounts();
      if (accounts.length > 0) {
        const walletState = await connectWallet();
        setWallet(walletState);
      }
    } catch (error) {
      console.error("Error checking connection:", error);
    }
  };

  const handleAccountsChanged = (accounts: string[]) => {
    if (accounts.length === 0) {
      setWallet({
        provider: null,
        signer: null,
        address: null,
        chainId: null,
        isConnected: false,
      });
    } else {
      checkConnection();
    }
  };

  const handleChainChanged = () => {
    checkConnection();
  };

  const handleConnect = async () => {
    setLoading(true);
    try {
      const walletState = await connectWallet();
      setWallet(walletState);
    } catch (error: any) {
      alert(`Failed to connect: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleDisconnect = async () => {
    try {
      await disconnectWallet();
      setWallet({
        provider: null,
        signer: null,
        address: null,
        chainId: null,
        isConnected: false,
      });
    } catch (error: any) {
      alert(`Failed to disconnect: ${error.message}`);
    }
  };

  if (wallet.isConnected && wallet.address) {
    return (
      <div className="flex items-center gap-4">
        <span className="text-sm">
          {wallet.address.slice(0, 6)}...{wallet.address.slice(-4)}
        </span>
        <button
          onClick={handleDisconnect}
          className="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600"
        >
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <button
      onClick={handleConnect}
      disabled={loading}
      className="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600 disabled:opacity-50"
    >
      {loading ? "Connecting..." : "Connect Wallet"}
    </button>
  );
}
