'use client';

import { useState, useEffect, useCallback } from 'react';
import Image from 'next/image';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';

export default function DashboardHome() {
  const {
    getHealthFactor,
    getMintedZusd,
    getUserWETHBalance,
    getUserWBTCBalance,
    getUserNFTs,
    walletAddress,
    provider,
  } = useZephyra();

  // Data states
  const [health, setHealth] = useState(null);
  const [zusdMinted, setZusdMinted] = useState(null);
  const [wethDeposited, setWethDeposited] = useState(null);
  const [wbtcDeposited, setWbtcDeposited] = useState(null);
  const [nfts, setNfts] = useState([]);

  // Loading states
  const [isLoadingData, setIsLoadingData] = useState(true);
  const [isLoadingNFTs, setIsLoadingNFTs] = useState(true);

  // Error states
  const [dataError, setDataError] = useState(null);
  const [nftError, setNftError] = useState(null);

  // Fetch NFTs function - memoized to prevent unnecessary re-renders
  const fetchNFTs = useCallback(async () => {
    if (!walletAddress || !provider) {
      setIsLoadingNFTs(false);
      return;
    }

    setIsLoadingNFTs(true);
    setNftError(null);

    try {
      console.log('Fetching NFTs for wallet:', walletAddress);
      const ownedNFTs = await getUserNFTs(walletAddress, provider);
      console.log('Fetched NFTs:', ownedNFTs);
      setNfts(ownedNFTs || []);
    } catch (error) {
      console.error('Error fetching NFTs:', error);
      setNftError('Failed to load NFTs');
      setNfts([]);
    } finally {
      setIsLoadingNFTs(false);
    }
  }, [walletAddress, provider, getUserNFTs]);

  // Fetch main dashboard data
  useEffect(() => {
    const fetchData = async () => {
      if (!walletAddress) {
        setIsLoadingData(false);
        return;
      }

      setIsLoadingData(true);
      setDataError(null);

      try {
        const [hf, zusd, weth, wbtc] = await Promise.all([
          getHealthFactor(),
          getMintedZusd(),
          getUserWETHBalance(),
          getUserWBTCBalance(),
        ]);

        setHealth(hf);
        setZusdMinted(zusd);
        setWethDeposited(weth);
        setWbtcDeposited(wbtc);
      } catch (error) {
        console.error('Error fetching dashboard data:', error);
        setDataError('Failed to load dashboard data');
      } finally {
        setIsLoadingData(false);
      }
    };

    fetchData();
  }, [walletAddress, getHealthFactor, getMintedZusd, getUserWETHBalance, getUserWBTCBalance]);

  // Fetch NFTs
  useEffect(() => {
    fetchNFTs();
  }, [fetchNFTs]);

  // Handle image loading errors
  const handleImageError = (e) => {
    console.log('Image failed to load:', e.target.src);
    e.target.src = '/icons/placeholder-nft.png';
  };

  // Manual refresh function
  const handleRefreshNFTs = () => {
    fetchNFTs();
  };

  // Wallet not connected
  if (!walletAddress) {
    return (
      <section className="max-w-7xl mx-auto px-4 py-8">
        <div className="text-center py-12">
          <h2 className="text-2xl font-bold mb-4 text-[#00C0FF]">Dashboard</h2>
          <p className="text-[#94A3B8]">Please connect your wallet to view your dashboard</p>
        </div>
      </section>
    );
  }

  return (
    <section className="max-w-7xl mx-auto px-4 py-8">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">Dashboard Overview</h2>

      {/* Error Messages */}
      {dataError && (
        <div className="bg-red-900/20 border border-red-500/30 rounded-xl p-4 mb-6">
          <p className="text-red-400">{dataError}</p>
        </div>
      )}

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
            {isLoadingData ? (
              <span className="animate-pulse">Loading...</span>
            ) : wethDeposited !== null ? (
              `${wethDeposited.toFixed(4)} WETH`
            ) : (
              '0.0000 WETH'
            )}
          </p>
        </div>
        
        <div className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-4 shadow-md">
          <h4 className="text-sm text-[#94A3B8] mb-1">WBTC Balance</h4>
          <p className="text-xl font-semibold text-white">
            {isLoadingData ? (
              <span className="animate-pulse">Loading...</span>
            ) : wbtcDeposited !== null ? (
              `${wbtcDeposited.toFixed(4)} WBTC`
            ) : (
              '0.0000 WBTC'
            )}
          </p>
        </div>
        
        <div className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-4 shadow-md">
          <h4 className="text-sm text-[#94A3B8] mb-1">ZUSD Minted</h4>
          <p className="text-xl font-semibold text-white">
            {isLoadingData ? (
              <span className="animate-pulse">Loading...</span>
            ) : zusdMinted !== null ? (
              `${zusdMinted.toFixed(2)} ZUSD`
            ) : (
              '0.00 ZUSD'
            )}
          </p>
        </div>
      </div>

      {/* Health Score */}
      <div className="mb-8">
        <h3 className="text-lg font-semibold mb-2 text-[#E4F3FF]">Health Score</h3>
        <div className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-4 w-full max-w-sm">
          <p className="text-3xl font-bold text-[#00C0FF]">
            {isLoadingData ? (
              <span className="animate-pulse">Loading...</span>
            ) : health !== null ? (
              health > 1e10 ? '∞' : health.toFixed(2)
            ) : (
              '0.00'
            )}
          </p>
          <p className="text-sm text-[#94A3B8] mt-1">Your position health score</p>
        </div>
      </div>

      {/* My NFTs */}
      <div className="mb-8">
        <div className="flex justify-between items-center mb-2">
          <h3 className="text-lg font-semibold text-[#E4F3FF]">My NFTs</h3>
          <button
            onClick={handleRefreshNFTs}
            disabled={isLoadingNFTs}
            className="px-3 py-1 text-sm bg-[#00C0FF]/20 hover:bg-[#00C0FF]/30 text-[#00C0FF] rounded-lg transition-colors duration-200 disabled:opacity-50"
          >
            {isLoadingNFTs ? 'Loading...' : 'Refresh'}
          </button>
        </div>
        
        {nftError && (
          <div className="bg-red-900/20 border border-red-500/30 rounded-xl p-4 mb-4">
            <p className="text-red-400 text-sm">{nftError}</p>
            <button
              onClick={handleRefreshNFTs}
              className="text-red-300 hover:text-red-200 text-sm underline mt-1"
            >
              Try again
            </button>
          </div>
        )}

        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
          {isLoadingNFTs ? (
            Array.from({ length: 4 }).map((_, index) => (
              <div
                key={index}
                className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-3 flex flex-col items-center justify-center animate-pulse"
              >
                <div className="w-24 h-24 bg-gray-600 rounded-lg mb-2"></div>
                <div className="w-16 h-3 bg-gray-600 rounded"></div>
              </div>
            ))
          ) : nfts.length > 0 ? (
            nfts.map((nft, index) => (
              <div
                key={nft.tokenId || index}
                className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-3 flex flex-col items-center justify-center hover:border-[#00C0FF]/50 transition-colors duration-200"
              >
                <img
                  src={nft.image || '/icons/placeholder-nft.png'}
                  alt={nft.name || 'NFT'}
                  className="w-24 h-24 rounded-lg mb-2 object-cover"
                  onError={handleImageError}
                  loading="lazy"
                />
                <span className="text-xs text-[#94A3B8] text-center truncate w-full">
                  {nft.name || `Token #${nft.tokenId}`}
                </span>
                {nft.error && (
                  <span className="text-xs text-red-400 text-center mt-1">
                    Metadata Error
                  </span>
                )}
              </div>
            ))
          ) : (
            <div className="col-span-full text-center py-8">
              <p className="text-sm text-[#94A3B8] mb-2">No NFTs found in your wallet</p>
              <button
                onClick={handleRefreshNFTs}
                className="text-[#00C0FF] hover:text-[#00C0FF]/80 text-sm underline"
              >
                Refresh to check again
              </button>
            </div>
          )}
        </div>
      </div>
    </section>
  );
}