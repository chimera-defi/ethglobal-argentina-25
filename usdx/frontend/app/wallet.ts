"use client";

import { ethers } from "ethers";

export interface WalletState {
  provider: ethers.BrowserProvider | null;
  signer: ethers.JsonRpcSigner | null;
  address: string | null;
  chainId: number | null;
  isConnected: boolean;
}

export async function connectWallet(): Promise<WalletState> {
  if (typeof window === "undefined" || !window.ethereum) {
    throw new Error("MetaMask not installed");
  }

  const provider = new ethers.BrowserProvider(window.ethereum);
  await provider.send("eth_requestAccounts", []);
  const signer = await provider.getSigner();
  const address = await signer.getAddress();
  const network = await provider.getNetwork();
  
  return {
    provider,
    signer,
    address,
    chainId: Number(network.chainId),
    isConnected: true,
  };
}

export async function disconnectWallet(): Promise<void> {
  // MetaMask doesn't have a disconnect method, just clear state
}

export async function switchChain(chainId: number): Promise<void> {
  if (typeof window === "undefined" || !window.ethereum) {
    throw new Error("MetaMask not installed");
  }

  try {
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: `0x${chainId.toString(16)}` }],
    });
  } catch (error: any) {
    // Chain not added, need to add it
    if (error.code === 4902) {
      throw new Error("Chain not added to wallet");
    }
    throw error;
  }
}
