'use client';

import { useState, useEffect } from 'react';
import Image from 'next/image';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';

export default function DashboardHome() {



  // ----------------------------------------------------------------------
  // =========================================================================

  const {
    getHealthFactor,
    getMintedZusd,
    getUserWETHBalance,
    getUserWBTCBalance,
    getUserNFTs,
    walletAddress,
    provider,
  } = useZephyra();

  const [health, setHealth] = useState(null);
  const [zusdMinted, setZusdMinted] = useState(null);
  const [wethDeposited, setWethDeposited] = useState(null);
  const [wbtcDeposited, setWbtcDeposited] = useState(null);
  const [nfts, setNfts] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      const [hf, zusd, weth, wbtc] = await Promise.all([
        getHealthFactor(),
        getMintedZusd(),
        getUserWETHBalance(),
        getUserWBTCBalance(),
      ]);

      if (hf !== null) setHealth(hf);
      if (zusd !== null) setZusdMinted(zusd);
      if (weth !== null) setWethDeposited(weth);
      if (wbtc !== null) setWbtcDeposited(wbtc);
    };

    fetchData();
  }, []);


  useEffect(() => {
    const fetchNFTs = async () => {
      if (!walletAddress || !provider) return;
      const ownedNFTs = await getUserNFTs(walletAddress, provider);
      setNfts(ownedNFTs);
    };

    fetchNFTs();
  }, [walletAddress]);






  // -------------------------------------------------------------------------------
  // The return
  // -------------------------------------------------------------------------------

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
        <div className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-4 shadow-md">
          <h4 className="text-sm text-[#94A3B8] mb-1">WETH Balance</h4>
          <p className="text-xl font-semibold text-white">
            {wethDeposited !== null ? `${wethDeposited.toFixed(4)} WETH` : 'Loading...'}
          </p>
        </div>
        <div className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-4 shadow-md">
          <h4 className="text-sm text-[#94A3B8] mb-1">WBTC Balance</h4>
          <p className="text-xl font-semibold text-white">
            {wbtcDeposited !== null ? `${wbtcDeposited.toFixed(4)} WBTC` : 'Loading...'}
          </p>
        </div>
        <div className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-4 shadow-md">
          <h4 className="text-sm text-[#94A3B8] mb-1">ZUSD Minted</h4>
          <p className="text-xl font-semibold text-white">
            {zusdMinted !== null ? `${zusdMinted.toFixed(2)} ZUSD` : 'Loading...'}
          </p>
        </div>
      </div>

      {/* Health Score */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-2 text-[#E4F3FF]">Health Score</h3>
        <div className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-4 w-full max-w-sm">
          <p className="text-3xl font-bold text-[#00C0FF]">
            {health !== null
              ? health > 1e10
                ? '∞'
                : health.toFixed(2)
              : 'Loading...'}
          </p>
          <p className="text-sm text-[#94A3B8] mt-1">Your position health score</p>
        </div>
      </div>

      {/* My NFTs */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-2 text-[#E4F3FF]">My NFTs</h3>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {nfts.length > 0 ? (
            nfts.map((nft) => (
              <div
                key={nft.tokenId}
                className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-3 flex flex-col items-center justify-center"
              >
                <img
                  src={nft.image}
                  alt={nft.name}
                  className="w-24 h-24 rounded-lg mb-2 object-cover"
                />
                <span className="text-xs text-[#94A3B8]">{nft.name}</span>
              </div>
            ))
          ) : (
            <p className="text-sm text-[#94A3B8]">No NFTs yet.</p>
          )}
        </div>

      </div>
    </section>
  );
}
