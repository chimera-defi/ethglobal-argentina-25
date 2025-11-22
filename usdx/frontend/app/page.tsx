"use client";

import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount } from "wagmi";
import DepositFlow from "./components/DepositFlow";
import MintFlow from "./components/MintFlow";
import TransferFlow from "./components/TransferFlow";
import BalanceDisplay from "./components/BalanceDisplay";

export default function Home() {
  const { isConnected } = useAccount();

  return (
    <main className="min-h-screen p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex justify-between items-center mb-8">
          <h1 className="text-4xl font-bold">USDX Protocol</h1>
          <ConnectButton />
        </div>

        {isConnected ? (
          <div className="space-y-8">
            <BalanceDisplay />
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <DepositFlow />
              <MintFlow />
              <TransferFlow />
            </div>
          </div>
        ) : (
          <div className="text-center py-20">
            <p className="text-xl text-gray-600">
              Connect your wallet to get started
            </p>
          </div>
        )}
      </div>
    </main>
  );
}
