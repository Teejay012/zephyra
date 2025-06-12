'use client';

import { useState } from 'react';

export default function RepayPage() {
  const [repayAmount, setRepayAmount] = useState('');

  const handleRepay = (e) => {
    e.preventDefault();
    // TODO: Add smart contract interaction to burn ZUSD
    console.log(`Repaying ${repayAmount} ZUSD`);
  };

  return (
    <section className="max-w-md mx-auto px-4 py-10">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">Repay ZUSD</h2>

      <form
        onSubmit={handleRepay}
        className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-6 space-y-6"
      >
        {/* ZUSD Amount Input */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">Amount to Repay</label>
          <input
            type="number"
            value={repayAmount}
            onChange={(e) => setRepayAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* Repay Button */}
        <button
          type="submit"
          className="w-full py-3 bg-[#00C0FF] text-[#1C1C28] font-semibold rounded-md hover:bg-[#00e0ff]"
        >
          Repay ZUSD
        </button>
      </form>
    </section>
  );
}
