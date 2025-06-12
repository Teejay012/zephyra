'use client';

import { useState } from 'react';

export default function MintPage() {
  const [mintAmount, setMintAmount] = useState('');

  const handleMint = (e) => {
    e.preventDefault();
    // TODO: Replace with actual smart contract interaction
    console.log(`Minting ${mintAmount} ZUSD`);
  };

  return (
    <section className="max-w-md mx-auto px-4 py-10">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">Mint ZUSD</h2>

      <form
        onSubmit={handleMint}
        className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-6 space-y-6"
      >
        {/* Amount to Mint */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">Amount to Mint</label>
          <input
            type="number"
            value={mintAmount}
            onChange={(e) => setMintAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* Mint Button */}
        <button
          type="submit"
          className="w-full py-3 bg-[#00C0FF] text-[#1C1C28] font-semibold rounded-md hover:bg-[#00e0ff]"
        >
          Mint ZUSD
        </button>
      </form>
    </section>
  );
}
