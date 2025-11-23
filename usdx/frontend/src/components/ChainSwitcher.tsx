'use client';

import { CHAINS, ChainType } from '@/config/chains';

interface ChainSwitcherProps {
  currentChain: ChainType;
  onSwitch: (chain: ChainType) => void;
}

export function ChainSwitcher({ currentChain, onSwitch }: ChainSwitcherProps) {
  return (
    <div className="card">
      <h3 className="font-bold mb-4">Select Chain</h3>
      <div className="grid grid-cols-2 gap-3">
        <button
          onClick={() => onSwitch('HUB')}
          className={`p-4 rounded-lg border-2 transition-all ${
            currentChain === 'HUB'
              ? 'border-blue-500 bg-blue-50'
              : 'border-gray-200 hover:border-blue-300'
          }`}
        >
          <div className="flex items-center gap-2 mb-2">
            <div className={`w-3 h-3 rounded-full ${currentChain === 'HUB' ? 'bg-blue-500' : 'bg-gray-300'}`} />
            <span className="font-bold">Hub Chain</span>
          </div>
          <p className="text-sm text-gray-600">Ethereum</p>
          <p className="text-xs text-gray-500">Deposit & Vault</p>
        </button>

        <button
          onClick={() => onSwitch('SPOKE_BASE')}
          className={`p-4 rounded-lg border-2 transition-all ${
            currentChain === 'SPOKE_BASE'
              ? 'border-purple-500 bg-purple-50'
              : 'border-gray-200 hover:border-purple-300'
          }`}
        >
          <div className="flex items-center gap-2 mb-2">
            <div className={`w-3 h-3 rounded-full ${currentChain === 'SPOKE_BASE' ? 'bg-purple-500' : 'bg-gray-300'}`} />
            <span className="font-bold">Spoke Chain</span>
          </div>
          <p className="text-sm text-gray-600">Base</p>
          <p className="text-xs text-gray-500">Mint & Use USDX</p>
        </button>
      </div>

      <div className="mt-4 p-3 bg-yellow-50 border border-yellow-200 rounded-lg">
        <p className="text-xs text-yellow-800">
          <strong>💡 Tip:</strong> Deposit USDC on Hub chain, then switch to Spoke chain to mint USDX there.
        </p>
      </div>
    </div>
  );
}
