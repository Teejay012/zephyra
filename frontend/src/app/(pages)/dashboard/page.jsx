'use client';

import Image from 'next/image';

export default function DashboardHome() {
  return (
    <section className="max-w-7xl mx-auto px-4 py-8">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">Dashboard Overview</h2>

      {/* Supported Tokens */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-2 text-[#E4F3FF]">Supported Collateral Tokens</h3>
        <div className="flex items-center gap-6">
          <div className="flex items-center gap-2">
            <Image src="/icons/weth.png" alt="WETH" width={24} height={24} />
            <span className="text-sm text-[#94A3B8]">WETH</span>
          </div>
          <div className="flex items-center gap-2">
            <Image src="/icons/wbtc.png" alt="WBTC" width={24} height={24} />
            <span className="text-sm text-[#94A3B8]">WBTC</span>
          </div>
        </div>
      </div>

      {/* Balances Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
        {[
          { label: 'WETH Balance', value: '0.00 WETH' },
          { label: 'WBTC Balance', value: '0.00 WBTC' },
          { label: 'ZUSD Balance', value: '0.00 ZUSD' },
        ].map(({ label, value }) => (
          <div
            key={label}
            className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-4 shadow-md"
          >
            <h4 className="text-sm text-[#94A3B8] mb-1">{label}</h4>
            <p className="text-xl font-semibold text-white">{value}</p>
          </div>
        ))}
      </div>

      {/* Health Score */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-2 text-[#E4F3FF]">Health Score</h3>
        <div className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-4 w-full max-w-sm">
          <p className="text-3xl font-bold text-[#00C0FF]">N/A</p>
          <p className="text-sm text-[#94A3B8] mt-1">Your position health score</p>
        </div>
      </div>

      {/* My NFTs */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-2 text-[#E4F3FF]">My NFTs</h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {/* Placeholder NFTs */}
          {[1, 2, 3].map((id) => (
            <div
              key={id}
              className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-3 flex flex-col items-center justify-center"
            >
              <div className="w-24 h-24 bg-[#475569]/30 rounded-lg mb-2 flex items-center justify-center text-sm text-[#94A3B8]">
                NFT #{id}
              </div>
              <span className="text-xs text-[#94A3B8]">Reward NFT</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
