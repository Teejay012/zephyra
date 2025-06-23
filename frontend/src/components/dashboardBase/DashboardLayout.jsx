'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useState } from 'react';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';
import ConnectWalletBtn from '@/components/connectWalletBtn/ConnectWalletBtn';

const navLinks = [
  { label: 'Dashboard', href: '/dashboard' },
  // { label: 'Deposit Collateral $ Mint ZUSD', href: '/dashboard/deposit-mint' },
  { label: 'Deposit Collateral', href: '/dashboard/deposit' },
  { label: 'Mint ZUSD', href: '/dashboard/mint' },
  // { label: 'Swap ZUSD', href: '/dashboard/swap' },
  { label: 'Repay ZUSD', href: '/dashboard/repay' },
  { label: 'Redeem Collateral', href: '/dashboard/redeem' },
  { label: 'NFT Perks', href: '/dashboard/nfts' },
  { label: 'Cross-Chain Transfer', href: '/dashboard/cross-chain' },
];

export default function DashboardLayout({ children }) {
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  const { walletAddress } = useZephyra();

  return (
    <div className="min-h-screen bg-[#1C1C28] text-[#E4F3FF]">
      {/* Header Nav */}
      <header className="sticky top-18 z-40 bg-[#2B1E5E]/90 backdrop-blur-md border-b border-[#475569]/30">
        <div className="max-w-7xl mx-auto px-4 py-4 flex items-center justify-between">
          <h1 className="text-xl font-bold text-[#00C0FF]">🏦</h1>

          <button
            onClick={() => setMenuOpen(!menuOpen)}
            className="md:hidden text-[#E4F3FF] focus:outline-none"
          >
            <svg
              className="w-6 h-6"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              viewBox="0 0 24 24"
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
            </svg>
          </button>

          <nav className="hidden md:flex gap-5 items-center">
            {navLinks.map(({ label, href }) => {
              const isActive = pathname === href;
              return (
                <Link
                  key={href}
                  href={href}
                  className={`text-sm font-medium transition-colors px-3 py-1.5 rounded-md ${
                    isActive
                      ? 'bg-[#8B5CF6]/20 text-[#00C0FF]'
                      : 'text-[#94A3B8] hover:text-[#00C0FF]'
                  }`}
                >
                  {label}
                </Link>
              );
            })}
          </nav>
        </div>

        {menuOpen && (
          <div className="md:hidden px-4 pb-4">
            <nav className="flex flex-col gap-2">
              {navLinks.map(({ label, href }) => {
                const isActive = pathname === href;
                return (
                  <Link
                    key={href}
                    href={href}
                    onClick={() => setMenuOpen(false)}
                    className={`text-sm font-medium transition-colors px-3 py-2 rounded-md ${
                      isActive
                        ? 'bg-[#8B5CF6]/20 text-[#00C0FF]'
                        : 'text-[#94A3B8] hover:text-[#00C0FF]'
                    }`}
                  >
                    {label}
                  </Link>
                );
              })}
            </nav>
          </div>
        )}
      </header>

      {/* Content */}
      <main className="px-4 py-6 mt-25 max-w-7xl mx-auto">
        {walletAddress ? (
          children
        ) : (
          <div className="h-[60vh] flex items-center justify-center flex-col gap-4">
            <p className="text-lg font-semibold text-[#E4F3FF]">
              Please connect your wallet to access the dashboard.
            </p>
            <ConnectWalletBtn />
          </div>
        )}
      </main>
    </div>
  );
}
