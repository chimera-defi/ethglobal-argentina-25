'use client';

import { useState, useEffect, useRef } from 'react';
import { ethers } from 'ethers';
import { getSpokeMinterContract, getSpokeUSDXContract, waitForTransaction } from '@/lib/contracts';
import { parseAmount, formatAmount } from '@/config/contracts';
import { getProvider } from '@/lib/ethers';
import { SPOKE_CHAINS } from '@/config/chains';
import { Network, ChevronDown } from 'lucide-react';

interface SpokeMintFlowProps {
  signer: ethers.Signer | null;
  userAddress: string | null;
  onSuccess?: () => void;
}

type SpokeChainConfig = typeof SPOKE_CHAINS[number];

export function SpokeMintFlow({ signer, userAddress, onSuccess }: SpokeMintFlowProps) {
  const dropdownRef = useRef<HTMLDivElement>(null);
  const [selectedChain, setSelectedChain] = useState<SpokeChainConfig>(SPOKE_CHAINS[0]);
  const [showChainDropdown, setShowChainDropdown] = useState(false);
  const [amount, setAmount] = useState('');
  const [isMinting, setIsMinting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [hubPosition, setHubPosition] = useState<bigint>(BigInt(0));
  const [spokeBalance, setSpokeBalance] = useState<bigint>(BigInt(0));
  const [isLoading, setIsLoading] = useState(false);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setShowChainDropdown(false);
      }
    };

    if (showChainDropdown) {
      document.addEventListener('mousedown', handleClickOutside);
      return () => document.removeEventListener('mousedown', handleClickOutside);
    }
  }, [showChainDropdown]);

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
        setSuccess(`Successfully minted ${amount} USDX on ${selectedChain.name}!`);
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
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-xl font-bold">Mint USDX on Spoke Chain</h2>
        <Network className="h-5 w-5 text-purple-600" />
      </div>
      <p className="text-sm text-gray-600 mb-4">
        Mint USDX on a spoke chain based on your hub chain position. No additional collateral needed!
      </p>

      {/* Chain Selector */}
      <div className="mb-4">
        <label className="block text-sm font-medium mb-2">Select Destination Chain</label>
        <div className="relative" ref={dropdownRef}>
          <button
            onClick={() => setShowChainDropdown(!showChainDropdown)}
            className="w-full flex items-center justify-between p-3 bg-white dark:bg-gray-800 border-2 border-gray-300 dark:border-gray-600 rounded-lg hover:border-purple-400 dark:hover:border-purple-500 transition-colors"
            disabled={isMinting}
          >
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center">
                <span className="text-white text-xs font-bold">{selectedChain.name.substring(0, 2).toUpperCase()}</span>
              </div>
              <div className="text-left">
                <p className="font-bold text-gray-900 dark:text-white">{selectedChain.name}</p>
                <p className="text-xs text-gray-500 dark:text-gray-400">Chain ID: {selectedChain.id}</p>
              </div>
            </div>
            <ChevronDown className={`h-5 w-5 text-gray-500 transition-transform ${showChainDropdown ? 'rotate-180' : ''}`} />
          </button>

          {/* Dropdown Menu */}
          {showChainDropdown && (
            <div className="absolute z-10 w-full mt-2 bg-white dark:bg-gray-800 border-2 border-gray-300 dark:border-gray-600 rounded-lg shadow-xl max-h-64 overflow-y-auto">
              {SPOKE_CHAINS.map((chain) => (
                <button
                  key={chain.id}
                  onClick={() => {
                    setSelectedChain(chain);
                    setShowChainDropdown(false);
                    setError(null);
                    setSuccess(null);
                  }}
                  className={`w-full flex items-center gap-3 p-3 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors ${
                    selectedChain.id === chain.id ? 'bg-purple-50 dark:bg-purple-900/20' : ''
                  }`}
                >
                  <div className={`w-8 h-8 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center ${
                    selectedChain.id === chain.id ? 'ring-2 ring-purple-500' : ''
                  }`}>
                    <span className="text-white text-xs font-bold">{chain.name.substring(0, 2).toUpperCase()}</span>
                  </div>
                  <div className="text-left flex-1">
                    <p className="font-bold text-gray-900 dark:text-white">{chain.name}</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">Chain ID: {chain.id} • {chain.currency}</p>
                  </div>
                  {selectedChain.id === chain.id && (
                    <div className="w-2 h-2 bg-purple-500 rounded-full" />
                  )}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

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
                className="btn btn-primary w-full"
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

          <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
            <h3 className="font-medium mb-2 text-gray-900 dark:text-white">How it works:</h3>
            <ol className="text-sm text-gray-700 dark:text-gray-300 space-y-1 list-decimal list-inside">
              <li>Deposit USDC on Hub (Ethereum)</li>
              <li>Bridge relayer syncs your position</li>
              <li>Mint USDX on {selectedChain.name}</li>
              <li>Use USDX with low gas fees!</li>
            </ol>
          </div>
        </div>
      )}
    </div>
  );
}
