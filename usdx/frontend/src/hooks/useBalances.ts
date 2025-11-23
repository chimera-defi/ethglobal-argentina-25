import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import {
  getUSDCContract,
  getHubUSDXContract,
  getSpokeUSDXContract,
} from '@/lib/contracts';
import { useWallet } from './useWallet';
import { CHAINS } from '@/config/chains';

export function useBalances(address: string | null) {
  const { provider, chainId } = useWallet();
  const [usdcBalance, setUsdcBalance] = useState<bigint>(BigInt(0));
  const [hubUsdxBalance, setHubUsdxBalance] = useState<bigint>(BigInt(0));
  const [spokeUsdxBalance, setSpokeUsdxBalance] = useState<bigint>(BigInt(0));
  const [isLoading, setIsLoading] = useState(false);
  const [currentChainName, setCurrentChainName] = useState<string>('Unknown');

  useEffect(() => {
    if (!address || !provider) {
      setUsdcBalance(BigInt(0));
      setHubUsdxBalance(BigInt(0));
      setSpokeUsdxBalance(BigInt(0));
      setCurrentChainName('Not Connected');
      return;
    }

    const loadBalances = async () => {
      setIsLoading(true);
      try {
        // Get chain name
        let chainName = 'Unknown Chain';
        if (chainId) {
          if (chainId === CHAINS.HUB.id || chainId === CHAINS.HUB.localhost.id) {
            chainName = CHAINS.HUB.name;
          } else if (chainId === CHAINS.SPOKE_BASE.id || chainId === CHAINS.SPOKE_BASE.localhost.id) {
            chainName = CHAINS.SPOKE_BASE.name;
          } else if (chainId === CHAINS.SPOKE_POLYGON.id || chainId === CHAINS.SPOKE_POLYGON.localhost.id) {
            chainName = CHAINS.SPOKE_POLYGON.name;
          } else if (chainId === CHAINS.SPOKE_ARC.id || chainId === CHAINS.SPOKE_ARC.localhost.id) {
            chainName = CHAINS.SPOKE_ARC.name;
          } else {
            const network = await provider.getNetwork();
            chainName = network.name || `Chain ${chainId}`;
          }
        }
        setCurrentChainName(chainName);
        
        // Get balances on the current chain
        const usdc = getUSDCContract(provider);
        const hubUsdx = getHubUSDXContract(provider);
        const spokeUsdx = getSpokeUSDXContract(provider);

        const [usdcBal, hubBal, spokeBal] = await Promise.all([
          usdc.balanceOf(address).catch(() => BigInt(0)),
          hubUsdx.balanceOf(address).catch(() => BigInt(0)),
          spokeUsdx.balanceOf(address).catch(() => BigInt(0)),
        ]);

        setUsdcBalance(usdcBal);
        setHubUsdxBalance(hubBal);
        setSpokeUsdxBalance(spokeBal);
      } catch (error) {
        console.error('Failed to load balances:', error);
      } finally {
        setIsLoading(false);
      }
    };

    loadBalances();

    // Refresh every 10 seconds
    const interval = setInterval(loadBalances, 10000);
    return () => clearInterval(interval);
  }, [address, provider, chainId]);

  return {
    usdcBalance,
    hubUsdxBalance,
    spokeUsdxBalance,
    isLoading,
    currentChainName,
    chainId,
  };
}
