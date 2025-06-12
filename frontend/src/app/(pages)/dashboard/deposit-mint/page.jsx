'use client';

import { useState } from 'react';

const collateralTokens = ['WETH', 'WBTC'];

export default function DepositMintPage() {
  const [collateralToken, setCollateralToken] = useState('WETH');
  const [collateralAmount, setCollateralAmount] = useState('');
  const [zusdAmount, setZusdAmount] = useState('');

  const handleSubmit = (e) => {
    e.preventDefault();
    // TODO: Connect to smart contract / backend logic
    console.log({ collateralToken, collateralAmount, zusdAmount });
  };

  return (
    <section className="max-w-xl mx-auto px-4 py-10">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">
        Deposit Collateral & Mint ZUSD
      </h2>

      <form
        onSubmit={handleSubmit}
        className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-6 space-y-6"
      >
        {/* Token Select */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">Select Collateral</label>
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

        {/* Collateral Amount */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">
            Collateral Amount ({collateralToken})
          </label>
          <input
            type="number"
            value={collateralAmount}
            onChange={(e) => setCollateralAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* ZUSD Amount */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">ZUSD to Mint</label>
          <input
            type="number"
            value={zusdAmount}
            onChange={(e) => setZusdAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          className="w-full py-3 bg-[#00C0FF] text-[#1C1C28] font-semibold rounded-md hover:bg-[#00e0ff] cursor-pointer"
        >
          Deposit & Mint
        </button>
      </form>
    </section>
  );
}
