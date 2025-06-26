'use client';

import { useState } from 'react';
// import { useAccount, useSigner } from 'wagmi';
import { toast } from 'react-hot-toast';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';

export default function MintPage() {
  const [mintAmount, setMintAmount] = useState('');

  const { mintZusd } = useZephyra();

  // const { address: walletAddress } = useAccount();
  // const { data: signer } = useSigner();

  const handleMint = async (e) => {
    e.preventDefault();

    if (!mintAmount || isNaN(mintAmount) || Number(mintAmount) <= 0) {
      toast.error('Enter a valid amount');
      return;
    }

    await mintZusd({
      rawAmount: mintAmount
    });
  };

  return (
    <section className="max-w-md mx-auto px-4 py-10">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">Mint ZUSD</h2>

      <div className="mb-6 text-sm text-[#94A3B8] bg-[#1C1C28] p-4 rounded-md border border-[#475569]/30">
        ⚠️ <strong>Note:</strong> ZUSD is <strong>200% overcollateralized</strong>. That means:
        <br />
        <span className="text-[#E2E8F0]">
          For every 1 ZUSD you mint, you must deposit at least 2 USD worth of collateral.
        </span>
      </div>

      <form
        onSubmit={handleMint}
        className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-6 space-y-6"
      >
        {/* Amount to Mint */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">Amount to Mint</label>
          <input
            type="number"
            step="any"
            value={mintAmount}
            onChange={(e) => setMintAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* Mint Button */}
        <button
          type="submit"
          className="w-full py-3 bg-[#00C0FF] text-[#1C1C28] font-semibold rounded-md hover:bg-[#00e0ff] cursor-pointer"
        >
          Mint ZUSD
        </button>
      </form>

      <div className="mb-6 text-sm text-[#94A3B8] bg-[#1C1C28] p-4 rounded-md border border-[#475569]/30">
        <strong>ZUSD CONTRACT ADDRESS:</strong> 0x792c6B6Cd8CdC39cA45D19438E8b53674CdB73E5
      </div>
    </section>
  );
}
