// components/Hero.jsx
import React from 'react';
import Image from 'next/image';
import Link from 'next/link';

export default function Hero() {
  return (
    <section className="relative bg-[#1C1C28] text-[#E4F3FF] pt-32 pb-20 overflow-hidden">
      {/* Background Animation Placeholder */}
      <div className="absolute inset-0 z-0">
        {/* Animation */}
        <div className="w-full h-full bg-gradient-to-br from-[#2B1E5E] via-transparent to-[#00C0FF]/10 animate-pulse opacity-40 blur-2xl" />
      </div>

      {/* Hero Content */}
      <div className="relative z-10 max-w-5xl mx-auto px-4 text-center">
        <h1 className="text-4xl sm:text-5xl lg:text-6xl font-bold leading-tight">
          Borrow. Lend. Send. <br />
          <span className="text-[#00C0FF]">Cross-Chain Stable Finance, Redefined.</span>
        </h1>

        <p className="mt-6 text-lg sm:text-xl text-[#94A3B8] max-w-2xl mx-auto">
          Powering DeFi with overcollateralized stablecoins, cross-chain liquidity, and provably fair NFT rewards.
        </p>

        {/* CTA Buttons */}
        <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link 
            href="/dashboard"
            className="bg-[#00C0FF] hover:bg-[#8B5CF6] text-[#1C1C28] font-semibold px-6 py-3 rounded-xl text-lg transition-colors cursor-pointer"
          >
            Launch App
          </Link>
          <Link
            href="https://discord.com"
            target="_blank"
            className="text-[#E4F3FF] hover:text-[#00C0FF] border border-[#475569] hover:border-[#8B5CF6] px-6 py-3 rounded-xl text-lg transition-all"
          >
            Join Discord
          </Link>
        </div>
      </div>
    </section>
  );
}
