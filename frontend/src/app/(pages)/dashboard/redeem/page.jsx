'use client';

import { useState } from 'react';
import { toast } from 'react-hot-toast';
import { ethers } from 'ethers';
// import { useAccount, useSigner } from 'wagmi';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';
import { WETH_TOKEN_ADDRESS, WBTC_TOKEN_ADDRESS } from '@/hooks/constants/contracts.js';

const tokenAddressMap = {
  WETH: WETH_TOKEN_ADDRESS,
  WBTC: WBTC_TOKEN_ADDRESS, 
};

export default function RedeemPage() {

  const [token, setToken] = useState('WETH');
  const [amount, setAmount] = useState('');

  // const { data: signer } = useSigner();
  // const { address: walletAddress } = useAccount();

  const { redeemCollateral } = useZephyra();

  const handleRedeem = async (e) => {
    e.preventDefault();

    if (!amount || isNaN(amount) || Number(amount) <= 0) {
      toast.error('Enter a valid amount');
      return;
    }

    const tokenAddress = tokenAddressMap[token];
    if (!tokenAddress) {
      toast.error('Invalid token selected');
      return;
    }

    await redeemCollateral({
      tokenAddress,
      rawAmount: amount,
    });
  };

  return (
    <section className="max-w-md mx-auto px-4 py-10">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">Redeem Collateral</h2>

      <form
        onSubmit={handleRedeem}
        className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-6 space-y-6"
      >
        {/* Token Select */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">Select Token</label>
          <select
            value={token}
            onChange={(e) => setToken(e.target.value)}
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white"
          >
            {Object.keys(tokenAddressMap).map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </div>

        {/* Amount Input */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">Amount</label>
          <input
            type="number"
            step="any"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* Redeem Button */}
        <button
          type="submit"
          className="w-full py-3 bg-[#00C0FF] text-[#1C1C28] font-semibold rounded-md hover:bg-[#00e0ff] cursor-pointer"
        >
          Redeem
        </button>
      </form>
    </section>
  );
}
