// components/Footer.tsx
import { Github, BookOpen, Mail } from 'lucide-react';

import Image from 'next/image';
import Link from 'next/link';

export function Footer() {
  return (
    <footer className="bg-[#1C1C28] text-[#E4F3FF] py-12 px-6">
      <div className="max-w-6xl mx-auto grid gap-10 sm:grid-cols-2 lg:grid-cols-3">
        {/* Column 1 */}
        <div>
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

          <p className="text-[#94A3B8] text-sm">
            Built with ❤️ by Zephyra Labs
          </p>
          <p className="text-[#94A3B8] text-sm mt-1">
            Powered by <span className="text-[#00C0FF] font-medium">Chainlink</span>
          </p>
        </div>

        {/* Column 2 */}
        <div>
          <h4 className="text-md font-semibold mb-3">Links</h4>
          <ul className="space-y-2 text-sm text-[#94A3B8]">
            <li><a href="/docs" className="hover:text-[#00C0FF]">Docs</a></li>
            <li><a href="/terms" className="hover:text-[#00C0FF]">Terms</a></li>
            <li><a href="/privacy" className="hover:text-[#00C0FF]">Privacy</a></li>
          </ul>
        </div>

        {/* Column 3 */}
        <div>
          <h4 className="text-md font-semibold mb-3">Connect</h4>
          <ul className="flex gap-6 mt-2 text-[#94A3B8]">
            <li>
              <a href="https://github.com/Teejay012/zephyra" target="_blank" rel="noreferrer" className="hover:text-[#00C0FF]">
                <Github className="w-5 h-5" />
              </a>
            </li>
            <li>
              <a href="/docs" className="hover:text-[#00C0FF]">
                <BookOpen className="w-5 h-5" />
              </a>
            </li>
            <li>
              <a href="tijesunimioluwakoya@gmail.com" className="hover:text-[#00C0FF]">
                <Mail className="w-5 h-5" />
              </a>
            </li>
          </ul>
        </div>
      </div>

      {/* Bottom Line */}
      <div className="mt-12 text-center text-xs text-[#475569]">
        © {new Date().getFullYear()} Zephyra. All rights reserved.
      </div>
    </footer>
  );
}
