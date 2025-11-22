"use client";

import { useState } from "react";

export default function TransferFlow() {
  const [amount, setAmount] = useState("");
  const [destinationChain, setDestinationChain] = useState("");

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h3 className="text-xl font-bold mb-4">Transfer USDX</h3>
      <div className="space-y-4">
        <input
          type="number"
          placeholder="Amount"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="w-full px-4 py-2 border rounded"
        />
        <select
          value={destinationChain}
          onChange={(e) => setDestinationChain(e.target.value)}
          className="w-full px-4 py-2 border rounded"
        >
          <option value="">Select destination chain</option>
          <option value="polygon">Polygon</option>
          <option value="arbitrum">Arbitrum</option>
          <option value="optimism">Optimism</option>
        </select>
        <button
          disabled={!amount || !destinationChain}
          className="w-full bg-purple-500 text-white py-2 px-4 rounded hover:bg-purple-600 disabled:opacity-50"
        >
          Transfer
        </button>
        <p className="text-sm text-gray-600">
          Transfer USDX cross-chain
        </p>
      </div>
    </div>
  );
}
