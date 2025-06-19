'use client';

import { useState } from 'react';
import { toast } from 'react-hot-toast';
// import { useAccount, useSigner } from 'wagmi';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';
import { WETH_TOKEN_ADDRESS, WBTC_TOKEN_ADDRESS } from '@/hooks/constants/contracts.js';

// Token map for resolving addresses
const collateralMap = {
  WETH: WETH_TOKEN_ADDRESS, // Sepolia WETH
  WBTC: WBTC_TOKEN_ADDRESS, // WBTC address
};

const collateralTokens = ['WETH', 'WBTC'];

export default function DepositPage() {
  const [collateralToken, setCollateralToken] = useState('WETH');
  const [amount, setAmount] = useState('');

  // const { address: walletAddress } = useAccount();
  // const { data: signer } = useSigner();

  const { depositCollateral } = useZephyra();

  const handleDeposit = async (e) => {
    e.preventDefault();

    if (!amount || isNaN(amount) || Number(amount) <= 0) {
      toast.error('Enter a valid amount');
      return;
    }

    const tokenAddress = collateralMap[collateralToken];
    if (!tokenAddress) {
      toast.error('Invalid token selected');
      return;
    }

    await depositCollateral({
      tokenAddress,
      rawAmount: amount,
    });
  };

  return (
    <section className="max-w-lg mx-auto px-4 py-10">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">Deposit Collateral</h2>

      <form
        onSubmit={handleDeposit}
        className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-6 space-y-6"
      >
        {/* Token Selector */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">Select Token</label>
          <select
            value={collateralToken}
            onChange={(e) => setCollateralToken(e.target.value)}
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          >
            {collateralTokens.map((token) => (
              <option key={token} value={token}>
                {token}
              </option>
            ))}
          </select>
        </div>

        {/* Amount Input */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">
            Amount ({collateralToken})
          </label>
          <input
            type="number"
            step="any"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* Submit */}
        <button
          type="submit"
          className="w-full py-3 bg-[#00C0FF] text-[#1C1C28] font-semibold rounded-md hover:bg-[#00e0ff] cursor-pointer"
        >
          Deposit
        </button>
      </form>
    </section>
  );
}
