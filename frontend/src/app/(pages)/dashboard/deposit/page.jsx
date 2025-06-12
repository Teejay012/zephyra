'use client';

import { useState } from 'react';

const collateralTokens = ['WETH', 'WBTC'];

export default function DepositPage() {
  const [collateralToken, setCollateralToken] = useState('WETH');
  const [amount, setAmount] = useState('');

  const handleDeposit = (e) => {
    e.preventDefault();
    // TODO: Replace with Web3 interaction
    console.log(`Depositing ${amount} ${collateralToken}`);
  };

  return (
    <section className="max-w-lg mx-auto px-4 py-10">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">Deposit Collateral</h2>

      <form
        onSubmit={handleDeposit}
        className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-6 space-y-6"
      >
        {/* Select Token */}
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
          <label className="block mb-2 text-sm text-[#94A3B8]">Amount ({collateralToken})</label>
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* Deposit Button */}
        <button
          type="submit"
          className="w-full py-3 bg-[#00C0FF] text-[#1C1C28] font-semibold rounded-md hover:bg-[#00e0ff]"
        >
          Deposit
        </button>
      </form>
    </section>
  );
}
