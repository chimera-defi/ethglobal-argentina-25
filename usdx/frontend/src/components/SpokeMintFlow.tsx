'use client';

import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { getSpokeMinterContract, getSpokeUSDXContract, waitForTransaction } from '@/lib/contracts';
import { parseAmount, formatAmount } from '@/config/contracts';
import { getProvider } from '@/lib/ethers';

interface SpokeMintFlowProps {
  signer: ethers.Signer | null;
  userAddress: string | null;
  onSuccess?: () => void;
}

export function SpokeMintFlow({ signer, userAddress, onSuccess }: SpokeMintFlowProps) {
  const [amount, setAmount] = useState('');
  const [isMinting, setIsMinting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [hubPosition, setHubPosition] = useState<bigint>(BigInt(0));
  const [spokeBalance, setSpokeBalance] = useState<bigint>(BigInt(0));
  const [isLoading, setIsLoading] = useState(false);

  // Load user's hub position and spoke balance
  useEffect(() => {
    if (!userAddress) return;

    const loadPositions = async () => {
      setIsLoading(true);
      try {
        const provider = getProvider();
        const minter = getSpokeMinterContract(provider);
        const spokeUSDX = getSpokeUSDXContract(provider);

        const [position, balance] = await Promise.all([
          minter.getUserPosition(userAddress),
          spokeUSDX.balanceOf(userAddress),
        ]);

        setHubPosition(position);
        setSpokeBalance(balance);
      } catch (error) {
        console.error('Failed to load positions:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadPositions();
    const interval = setInterval(loadPositions, 10000);
    return () => clearInterval(interval);
  }, [userAddress]);

  const handleMint = async () => {
    if (!signer || !amount) return;
    
    setError(null);
    setSuccess(null);
    
    try {
      const parsedAmount = parseAmount(amount);
      
      if (parsedAmount <= 0) {
        setError('Amount must be greater than 0');
        return;
      }

      // Check if user has enough hub position
      if (parsedAmount > hubPosition - spokeBalance) {
        setError(`Insufficient hub position. Available: ${formatAmount(hubPosition - spokeBalance)}`);
        return;
      }

      // Mint USDX on spoke chain
      setIsMinting(true);
      const minter = getSpokeMinterContract(signer);
      const mintTx = await minter.mint(parsedAmount);
      const receipt = await waitForTransaction(mintTx);
      setIsMinting(false);

      if (receipt) {
        setSuccess(`Successfully minted ${amount} USDX on Polygon!`);
        setAmount('');
        onSuccess?.();
      }
    } catch (err: any) {
      console.error('Mint failed:', err);
      setError(err.message || 'Transaction failed');
      setIsMinting(false);
    }
  };

  if (!signer) {
    return (
      <div className="card">
        <h2 className="text-xl font-bold mb-4">Mint USDX on Spoke</h2>
        <p className="text-gray-500">Connect your wallet to mint</p>
      </div>
    );
  }

  const availableToMint = hubPosition - spokeBalance;

  return (
    <div className="card">
      <h2 className="text-xl font-bold mb-4">Mint USDX on Polygon</h2>
      <p className="text-sm text-gray-600 mb-4">
        Mint USDX on Polygon based on your hub chain position. No additional collateral needed!
      </p>

      {isLoading ? (
        <div className="text-center py-8">
          <div className="animate-spin w-8 h-8 border-4 border-purple-500 border-t-transparent rounded-full mx-auto"></div>
          <p className="text-sm text-gray-600 mt-2">Loading position...</p>
        </div>
      ) : (
        <div className="space-y-4">
          {/* Position Info */}
          <div className="p-4 bg-purple-50 rounded-lg space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Hub Position:</span>
              <span className="font-bold text-purple-600">{formatAmount(hubPosition)} USDX</span>
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Already Minted:</span>
              <span className="font-bold text-gray-700">{formatAmount(spokeBalance)} USDX</span>
            </div>
            <div className="flex justify-between text-sm pt-2 border-t border-purple-200">
              <span className="text-gray-600">Available to Mint:</span>
              <span className="font-bold text-green-600">{formatAmount(availableToMint)} USDX</span>
            </div>
          </div>

          {hubPosition === BigInt(0) && (
            <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
              <p className="text-sm text-yellow-800">
                <strong>⚠️ No hub position found.</strong><br />
                Switch to Hub chain and deposit USDC first, then come back here to mint.
              </p>
            </div>
          )}

          {hubPosition > BigInt(0) && (
            <>
              <div>
                <label className="block text-sm font-medium mb-2">Amount to Mint</label>
                <input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0.00"
                  className="input w-full"
                  disabled={isMinting || availableToMint === BigInt(0)}
                  step="0.000001"
                  min="0"
                  max={formatAmount(availableToMint)}
                />
                {availableToMint > BigInt(0) && (
                  <button
                    onClick={() => setAmount(formatAmount(availableToMint))}
                    className="text-xs text-purple-600 hover:text-purple-700 mt-1"
                  >
                    Max: {formatAmount(availableToMint)}
                  </button>
                )}
              </div>

              <button
                onClick={handleMint}
                disabled={!amount || isMinting || availableToMint === BigInt(0)}
                className="btn bg-gradient-to-r from-blue-600 to-purple-600 text-white hover:from-blue-700 hover:to-purple-700 hover:shadow-lg shadow-sm w-full"
              >
                {isMinting ? 'Minting...' : 'Mint USDX'}
              </button>
            </>
          )}

          {error && (
            <div className="p-3 bg-red-50 border border-red-200 rounded-lg">
              <p className="text-sm text-red-600">{error}</p>
            </div>
          )}

          {success && (
            <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
              <p className="text-sm text-green-600">{success}</p>
            </div>
          )}

          <div className="p-4 bg-blue-50 rounded-lg">
            <h3 className="font-medium mb-2">How it works:</h3>
            <ol className="text-sm text-gray-700 space-y-1 list-decimal list-inside">
              <li>Deposit USDC on Hub (Ethereum)</li>
              <li>Bridge relayer syncs your position</li>
              <li>Mint USDX here on Spoke (Polygon)</li>
              <li>Use USDX with low gas fees!</li>
            </ol>
          </div>
        </div>
      )}
    </div>
  );
}
