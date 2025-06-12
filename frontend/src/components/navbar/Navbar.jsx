// components/Navbar.tsx
'use client';

import { useEffect, useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { Menu, X } from 'lucide-react';
// import { logo } from "/images/logo.png";

export function Navbar() {
  const [scrolled, setScrolled] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => {
      setScrolled(window.scrollY > 10);
    };
    window.addEventListener('scroll', onScroll);
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  const navLinks = [
    { name: 'Home', href: '/' },
    { name: 'Dashboard', href: '/dashboard' },
    { name: 'Market', href: '/market' },
  ];

  return (
    <header
      className={`fixed top-0 w-full z-50 transition-all ${
        scrolled ? 'backdrop-blur-md bg-[#1C1C28]/70 shadow-sm' : ''
      }`}
    >
      <nav className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
        {/* Logo */}
        <Link href="/" className="flex items-center">
          <Image
            src="/images/logo.png" 
            alt="Zephyra Logo"
            width={40}
            height={40}
            className="rounded-full"
          />

          <h3 className="text-[#E4F3FF] hover:text-[#00C0FF] transition-colors font-bold">Zephyra</h3>
        </Link>

        {/* Desktop Links */}
        <div className="hidden md:flex space-x-8 items-center">
          {navLinks.map((link) => (
            <Link
              key={link.name}
              href={link.href}
              className="text-[#E4F3FF] hover:text-[#00C0FF] transition-colors font-semibold"
            >
              {link.name}
            </Link>
          ))}
        </div>

        
        <button className="hidden md:flex bg-[#00C0FF] hover:bg-[#8B5CF6] text-[#1C1C28] font-semibold px-4 py-2 rounded-xl transition-colors cursor-pointer">
            Connect Wallet
        </button>

        {/* Mobile Menu Button */}
        <div className="md:hidden">
          <button onClick={() => setMobileOpen(!mobileOpen)}>
            {mobileOpen ? <X className="text-[#E4F3FF]" /> : <Menu className="text-[#E4F3FF]" />}
          </button>
        </div>
      </nav>

      {/* Mobile Menu */}
      {mobileOpen && (
        <div className="md:hidden bg-[#1C1C28] px-4 pb-4 space-y-4">
          {navLinks.map((link) => (
            <Link
              key={link.name}
              href={link.href}
              className="block text-[#E4F3FF] hover:text-[#00C0FF] font-semibold"
              onClick={() => setMobileOpen(false)}
            >
              {link.name}
            </Link>
          ))}
          <button className="w-full bg-[#00C0FF] hover:bg-[#8B5CF6] text-[#1C1C28] font-semibold px-4 py-2 rounded-xl transition-colors">
            Connect Wallet
          </button>
        </div>
      )}
    </header>
  );
}

