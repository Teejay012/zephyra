// components/KeyFeatures.tsx
import {
  LockKeyhole,
  Link2,
  Shuffle,
  Shield,
  BrainCircuit,
  Layers3,
} from 'lucide-react'; // You can replace icons as needed

const features = [
  {
    title: 'Overcollateralized Stablecoin (ZUSD)',
    icon: <LockKeyhole className="h-8 w-8 text-[#00C0FF]" />,
  },
  {
    title: 'Chainlink-Powered Price Feeds',
    icon: <Link2 className="h-8 w-8 text-[#00C0FF]" />,
  },
  {
    title: 'Cross-Chain Transfer with CCIP',
    icon: <Layers3 className="h-8 w-8 text-[#00C0FF]" />,
  },
  {
    title: 'Random NFT Rewards via VRF & Automation',
    icon: <Shuffle className="h-8 w-8 text-[#00C0FF]" />,
  },
  {
    title: 'Secure Liquidation Mechanics',
    icon: <Shield className="h-8 w-8 text-[#00C0FF]" />,
  },
  {
    title: 'Smart Architecture (Built with Foundry)',
    icon: <BrainCircuit className="h-8 w-8 text-[#00C0FF]" />,
  },
];

export default function KeyFeatures() {
  return (
    <section className="bg-[#1C1C28] py-20 px-6 text-[#E4F3FF]">
      <div className="max-w-6xl mx-auto text-center">
        <h2 className="text-3xl sm:text-4xl font-bold mb-12">
          Key Features of Zephyra
        </h2>

        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-3">
          {features.map((feature, idx) => (
            <div
              key={idx}
              className="bg-[#2B1E5E] border border-[#2B1E5E] hover:border-[#8B5CF6] rounded-2xl p-6 text-left shadow transition-all"
            >
              <div className="mb-4">{feature.icon}</div>
              <h3 className="text-lg font-semibold">{feature.title}</h3>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
