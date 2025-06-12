'use client';

import { useState } from 'react';

export default function NFTPerksPage() {
  const [isAvailable, setIsAvailable] = useState(true); // mock state
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  const tryYourLuck = async () => {
    setLoading(true);
    setResult(null);

    // Simulate async randomness or contract call
    await new Promise((res) => setTimeout(res, 2000));

    // Mock result (random win/loss)
    const didWin = Math.random() < 0.5;
    setResult(didWin ? 'won' : 'lost');
    setLoading(false);
  };

  return (
    <section className="max-w-md mx-auto px-4 py-10 text-center">
      <h2 className="text-2xl font-bold text-[#00C0FF] mb-4">🎲 NFT Perks</h2>
      <p className="text-[#94A3B8] mb-6">Mint exclusive ZEPHY NFTs by trying your luck!</p>

      {/* Availability Status */}
      <div className="mb-4">
        {isAvailable ? (
          <span className="text-[#8B5CF6] font-semibold">ZEPHY NFTs are available to mint!</span>
        ) : (
          <span className="text-red-400 font-medium">No NFTs available right now.</span>
        )}
      </div>

      {/* Try Your Luck Button */}
      <button
        disabled={!isAvailable || loading}
        onClick={tryYourLuck}
        className={`px-6 py-3 font-semibold rounded-md transition ${
          loading
            ? 'bg-[#8B5CF6]/40 cursor-not-allowed'
            : 'bg-[#8B5CF6] hover:bg-[#7C3AED]'
        } text-white`}
      >
        {loading ? 'Rolling...' : 'Try Your Luck'}
      </button>

      {/* NFT Preview */}
      <div className="mt-8">
        <h3 className="text-xl font-semibold mb-2">🎁 ZEPHY NFT</h3>
        <div className="bg-[#2B1E5E]/70 border border-[#475569]/30 p-6 rounded-xl">
          <p className="text-[#E4F3FF]">Name: ZEPHY</p>
          <p className="text-[#94A3B8] text-sm mt-1">A mysterious reward for daring users.</p>
        </div>
      </div>

      {/* Result Message */}
      {result && (
        <div className="mt-6 text-lg font-semibold">
          {result === 'won' ? (
            <span className="text-green-400">🎉 You won the ZEPHY NFT!</span>
          ) : (
            <span className="text-red-400">😢 You didn’t win this time. Try again later!</span>
          )}
        </div>
      )}
    </section>
  );
}
