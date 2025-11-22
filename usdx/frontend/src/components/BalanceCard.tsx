'use client';

import { useBalances } from '@/hooks/useBalances';
import { formatAmount } from '@/config/contracts';

interface BalanceCardProps {
  address: string | null;
}

export function BalanceCard({ address }: BalanceCardProps) {
  const { usdcBalance, hubUsdxBalance, spokeUsdxBalance, isLoading } = useBalances(address);

  if (!address) {
    return (
      <div className="card">
        <h2 className="text-xl font-bold mb-4">Your Balances</h2>
        <p className="text-gray-500">Connect your wallet to see balances</p>
      </div>
    );
  }

  return (
    <div className="card">
      <h2 className="text-xl font-bold mb-4">Your Balances</h2>
      
      {isLoading ? (
        <div className="space-y-3">
          <div className="animate-pulse h-16 bg-gray-200 rounded"></div>
          <div className="animate-pulse h-16 bg-gray-200 rounded"></div>
          <div className="animate-pulse h-16 bg-gray-200 rounded"></div>
        </div>
      ) : (
        <div className="space-y-3">
          <div className="flex justify-between items-center p-4 bg-blue-50 rounded-lg">
            <div>
              <p className="text-sm text-gray-600">USDC</p>
              <p className="text-2xl font-bold text-blue-600">{formatAmount(usdcBalance)}</p>
            </div>
            <div className="text-blue-600">
              <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 24 24">
                <circle cx="12" cy="12" r="10" />
              </svg>
            </div>
          </div>
          
          <div className="flex justify-between items-center p-4 bg-purple-50 rounded-lg">
            <div>
              <p className="text-sm text-gray-600">USDX (Hub)</p>
              <p className="text-2xl font-bold text-purple-600">{formatAmount(hubUsdxBalance)}</p>
            </div>
            <div className="text-purple-600">
              <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2L2 7v10c0 5.5 3.8 10.7 10 12 6.2-1.3 10-6.5 10-12V7l-10-5z" />
              </svg>
            </div>
          </div>
          
          <div className="flex justify-between items-center p-4 bg-green-50 rounded-lg">
            <div>
              <p className="text-sm text-gray-600">USDX (Spoke)</p>
              <p className="text-2xl font-bold text-green-600">{formatAmount(spokeUsdxBalance)}</p>
            </div>
            <div className="text-green-600">
              <svg className="w-8 h-8" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 2L2 7v10c0 5.5 3.8 10.7 10 12 6.2-1.3 10-6.5 10-12V7l-10-5z" />
              </svg>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
