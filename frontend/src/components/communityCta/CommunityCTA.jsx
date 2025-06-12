// components/CommunityCTA.tsx
import { Mail, Twitter, MessageCircle } from 'lucide-react';

export default function CommunityCTA() {
  return (
    <section className="bg-[#1C1C28] py-20 px-6 text-[#E4F3FF]">
      <div className="max-w-4xl mx-auto text-center">
        <h2 className="text-3xl sm:text-4xl font-bold mb-6">
          Join Our Community
        </h2>
        <p className="text-[#94A3B8] mb-8">
          Stay updated, chat with the team, or vibe with fellow DeFi pioneers.
        </p>

        {/* Social Icons */}
        <div className="flex justify-center gap-6 mb-10">
          <a
            href="https://twitter.com/zephyra"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-[#00C0FF] transition"
          >
            <Twitter className="h-7 w-7" />
          </a>
          <a
            href="https://discord.gg/zephyra"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-[#8B5CF6] transition"
          >
            <MessageCircle className="h-7 w-7" />
          </a>
        </div>

        {/* Newsletter Signup */}
        <form className="flex flex-col sm:flex-row gap-4 justify-center">
          <input
            type="email"
            placeholder="Enter your email"
            className="bg-[#2B1E5E] border border-[#475569] rounded-xl px-4 py-3 text-white placeholder-[#94A3B8] focus:outline-none focus:ring-2 focus:ring-[#00C0FF] w-full sm:w-auto"
          />
          <button
            type="submit"
            className="bg-[#00C0FF] hover:bg-[#8B5CF6] text-[#1C1C28] font-semibold rounded-xl px-6 py-3 transition cursor-pointer"
          >
            Subscribe
          </button>
        </form>
      </div>
    </section>
  );
}
