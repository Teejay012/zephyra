'use client';

import { useState } from 'react';

const chains = [
  { id: 'fuji', name: 'Avalanche Fuji' },
  { id: 'sepolia', name: 'Sepolia ETH' },
  { id: 'polygon', name: 'Polygon Mumbai' },
  { id: 'bnb', name: 'BNB Testnet' },
];

export default function CrossChainPage() {
  const [sourceChain, setSourceChain] = useState('fuji');
  const [destinationChain, setDestinationChain] = useState('sepolia');
  const [amount, setAmount] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  const handleTransfer = async () => {
    setLoading(true);
    setMessage('');
    await new Promise((res) => setTimeout(res, 2000)); // Simulate network delay
    setLoading(false);
    setMessage(`✅ Transferred ${amount} ZUSD from ${sourceChain} to ${destinationChain}`);
  };

  return (
    <section className="max-w-md mx-auto px-4 py-10">
      <h2 className="text-2xl font-bold text-[#00C0FF] mb-6 text-center">
        🌉 Cross-Chain Transfer
      </h2>

      {/* Source Chain */}
      <div className="mb-4">
        <label className="block mb-1 text-sm font-medium text-[#E4F3FF]">Source Chain</label>
        <select
          className="w-full bg-[#1C1C28] border border-[#475569]/30 rounded-md px-4 py-2 text-[#E4F3FF]"
          value={sourceChain}
          onChange={(e) => setSourceChain(e.target.value)}
        >
          {chains.map((chain) => (
            <option key={chain.id} value={chain.id}>
              {chain.name}
            </option>
          ))}
        </select>
      </div>

      {/* Destination Chain */}
      <div className="mb-4">
        <label className="block mb-1 text-sm font-medium text-[#E4F3FF]">Destination Chain</label>
        <select
          className="w-full bg-[#1C1C28] border border-[#475569]/30 rounded-md px-4 py-2 text-[#E4F3FF]"
          value={destinationChain}
          onChange={(e) => setDestinationChain(e.target.value)}
        >
          {chains
            .filter((chain) => chain.id !== sourceChain)
            .map((chain) => (
              <option key={chain.id} value={chain.id}>
                {chain.name}
              </option>
            ))}
        </select>
      </div>

      {/* Amount */}
      <div className="mb-6">
        <label className="block mb-1 text-sm font-medium text-[#E4F3FF]">Amount (ZUSD)</label>
        <input
          type="number"
          min="0"
          placeholder="Enter amount"
          className="w-full bg-[#1C1C28] border border-[#475569]/30 rounded-md px-4 py-2 text-[#E4F3FF] placeholder:text-[#64748B]"
          value={amount}
          onChange={(e) => setAmount(e.target.value)}
        />
      </div>

      {/* Transfer Button */}
      <button
        onClick={handleTransfer}
        disabled={loading || !amount}
        className={`w-full px-6 py-3 font-semibold rounded-md text-white transition ${
          loading || !amount
            ? 'bg-[#8B5CF6]/40 cursor-not-allowed'
            : 'bg-[#8B5CF6] hover:bg-[#7C3AED]'
        }`}
      >
        {loading ? 'Transferring...' : 'Transfer'}
      </button>

      {/* Result Message */}
      {message && (
        <p className="mt-6 text-center text-[#4ADE80] font-medium">{message}</p>
      )}
    </section>
  );
}
