"use client";

import { useAccount, useBalance, useReadContract } from "wagmi";
import { formatUnits } from "viem";

// Mock contract addresses - replace with actual deployed addresses
const USDX_TOKEN_ADDRESS = "0x0000000000000000000000000000000000000000";
const USDC_ADDRESS = "0x0000000000000000000000000000000000000000";

export default function BalanceDisplay() {
  const { address } = useAccount();

  const { data: usdxBalance } = useBalance({
    address,
    token: USDX_TOKEN_ADDRESS as `0x${string}`,
  });

  const { data: usdcBalance } = useBalance({
    address,
    token: USDC_ADDRESS as `0x${string}`,
  });

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h2 className="text-2xl font-bold mb-4">Your Balances</h2>
      <div className="space-y-2">
        <div className="flex justify-between">
          <span>USDX:</span>
          <span className="font-mono">
            {usdxBalance
              ? formatUnits(usdxBalance.value, usdxBalance.decimals)
              : "0.00"}
          </span>
        </div>
        <div className="flex justify-between">
          <span>USDC:</span>
          <span className="font-mono">
            {usdcBalance
              ? formatUnits(usdcBalance.value, usdcBalance.decimals)
              : "0.00"}
          </span>
        </div>
      </div>
    </div>
  );
}
