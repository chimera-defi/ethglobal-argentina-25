import { useState, useEffect } from 'react';
import {
  getUSDCContract,
  getHubUSDXContract,
  getSpokeUSDXContract,
} from '@/lib/contracts';
import { getProvider } from '@/lib/ethers';

export function useBalances(address) {
  const [usdcBalance, setUsdcBalance] = useState(BigInt(0));
  const [hubUsdxBalance, setHubUsdxBalance] = useState(BigInt(0));
  const [spokeUsdxBalance, setSpokeUsdxBalance] = useState(BigInt(0));
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!address) {
      setUsdcBalance(BigInt(0));
      setHubUsdxBalance(BigInt(0));
      setSpokeUsdxBalance(BigInt(0));
      return;
    }

    const loadBalances = async () => {
      setIsLoading(true);
      try {
        const provider = getProvider();
        
        const usdc = getUSDCContract(provider);
        const hubUsdx = getHubUSDXContract(provider);
        const spokeUsdx = getSpokeUSDXContract(provider);

        const [usdcBal, hubBal, spokeBal] = await Promise.all([
          usdc.balanceOf(address),
          hubUsdx.balanceOf(address),
          spokeUsdx.balanceOf(address),
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
  }, [address]);

  return {
    usdcBalance,
    hubUsdxBalance,
    spokeUsdxBalance,
    isLoading,
  };
}
