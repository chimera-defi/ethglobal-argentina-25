"use client";

import { useState } from "react";

export default function MintFlow() {
  const [amount, setAmount] = useState("");

  return (
    <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
      <h3 className="text-xl font-bold mb-4">Mint USDX</h3>
      <div className="space-y-4">
        <input
          type="number"
          placeholder="Amount"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
          className="w-full px-4 py-2 border rounded"
        />
        <button
          disabled={!amount}
          className="w-full bg-green-500 text-white py-2 px-4 rounded hover:bg-green-600 disabled:opacity-50"
        >
          Mint USDX
        </button>
        <p className="text-sm text-gray-600">
          Mint USDX using your hub chain position
        </p>
      </div>
    </div>
  );
}
