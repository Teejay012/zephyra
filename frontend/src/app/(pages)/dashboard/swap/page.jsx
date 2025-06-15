'use client';

import { useState } from 'react';

export default function SwapPage() {
  const [token, setToken] = useState('WETH');
  const [zusdAmount, setZusdAmount] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSwap = async () => {
    if (!zusdAmount || parseFloat(zusdAmount) <= 0) return;
    setLoading(true);
    await new Promise((res) => setTimeout(res, 1500)); // simulate API
    setLoading(false);
    setMessage(`✅ Swapped ${zusdAmount} ZUSD to ${token}`);
    setTimeout(() => setMessage(''), 3000);
    setZusdAmount('');
  };

  return (
    <section className="max-w-lg mx-auto px-4 py-10 text-center">
      <h2 className="text-2xl font-bold text-[#00C0FF] mb-6">
        🔁 Swap ZUSD to Collateral
      </h2>

      <div className="bg-[#1C1C28] p-6 rounded-xl border border-[#334155]/40 space-y-4 shadow">
        {/* Select Token */}
        <div className="text-left">
          <label className="block mb-1 text-sm text-[#94A3B8]">Select Collateral Token</label>
          <select
            value={token}
            onChange={(e) => setToken(e.target.value)}
            className="w-full px-4 py-2 rounded-md bg-[#2B2B3C] text-[#E4F3FF] border border-[#475569]/40 focus:outline-none"
          >
            <option value="WETH">WETH</option>
            <option value="WBTC">WBTC</option>
          </select>
        </div>

        {/* ZUSD Amount */}
        <div className="text-left">
          <label className="block mb-1 text-sm text-[#94A3B8]">ZUSD Amount</label>
          <input
            type="number"
            min={0}
            value={zusdAmount}
            onChange={(e) => setZusdAmount(e.target.value)}
            placeholder="Enter ZUSD to swap"
            className="w-full px-4 py-2 rounded-md bg-[#2B2B3C] text-[#E4F3FF] border border-[#475569]/40 focus:outline-none"
          />
        </div>

        {/* Swap Button */}
        <button
          onClick={handleSwap}
          disabled={loading}
          className={`w-full py-2 rounded-md text-white font-medium transition ${
            loading
              ? 'bg-[#8B5CF6]/40 cursor-not-allowed'
              : 'bg-[#8B5CF6] hover:bg-[#7C3AED]'
          }`}
        >
          {loading ? 'Swapping...' : 'Swap'}
        </button>

        {message && (
          <p className="text-green-400 font-medium text-sm mt-3">{message}</p>
        )}
      </div>
    </section>
  );
}
