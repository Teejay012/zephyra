// components/HowItWorks.jsx
import { ShieldCheck, Coins, Send, Gift } from 'lucide-react'; 

const steps = [
  {
    title: 'Deposit Collateral',
    description: 'Securely lock your crypto assets.',
    icon: <ShieldCheck className="h-10 w-10 text-[#00C0FF]" />,
  },
  {
    title: 'Mint ZUSD',
    description: 'Generate stablecoins backed by your assets.',
    icon: <Coins className="h-10 w-10 text-[#00C0FF]" />,
  },
  {
    title: 'Use ZUSD Cross-Chain',
    description: 'Trade, send, or utilize across ecosystems.',
    icon: <Send className="h-10 w-10 text-[#00C0FF]" />,
  },
  {
    title: 'Unlock NFT Rewards',
    description: 'Hold ZUSD to earn provably fair NFT perks.',
    icon: <Gift className="h-10 w-10 text-[#00C0FF]" />,
  },
];

export default function HowItWorks() {
  return (
    <section className="bg-[#1C1C28] py-20 px-6 text-[#E4F3FF]">
      <div className="max-w-6xl mx-auto text-center">
        <h2 className="text-3xl sm:text-4xl font-bold mb-12">
          How Zephyra Works
        </h2>

        <div className="grid gap-10 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map((step, index) => (
            <div
              key={index}
              className="bg-[#2B1E5E] rounded-2xl p-6 flex flex-col items-center text-center shadow-md hover:shadow-lg transition-shadow"
            >
              <div className="mb-4">{step.icon}</div>
              <h3 className="text-xl font-semibold mb-2">{step.title}</h3>
              <p className="text-[#94A3B8] text-sm">{step.description}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
