'use client';

import { useWallet } from '@/hooks/useWallet';
import { formatAddress } from '@/lib/ethers';

export function WalletConnect() {
  const { address, isConnected, isConnecting, isCorrectChain, error, connect, disconnect, switchNetwork } = useWallet();

  if (isConnecting) {
    return (
      <button className="btn btn-secondary" disabled>
        Connecting...
      </button>
    );
  }

  if (isConnected && address) {
    return (
      <div className="flex items-center gap-2">
        {!isCorrectChain && (
          <button
            onClick={() => switchNetwork(1)}
            className="btn bg-yellow-500 text-white hover:bg-yellow-600"
          >
            Switch Network
          </button>
        )}
        <div className="flex items-center gap-2 px-4 py-2 bg-white rounded-lg border shadow-sm">
          <div className="w-2 h-2 bg-green-500 rounded-full"></div>
          <span className="text-sm font-medium">{formatAddress(address)}</span>
        </div>
        <button onClick={disconnect} className="btn btn-secondary">
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <div className="flex flex-col items-end gap-2">
      <button onClick={connect} className="btn btn-primary">
        Connect Wallet
      </button>
      {error && (
        <p className="text-sm text-red-600">{error}</p>
      )}
    </div>
  );
}
