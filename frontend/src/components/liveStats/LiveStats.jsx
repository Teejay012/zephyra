// components/LiveStats.tsx
export default function LiveStats() {
  const stats = [
    { label: 'Total Value Locked', value: '$12.4M' },
    { label: 'Total ZUSD Minted', value: '8.1M ZUSD' },
    { label: 'NFTs Minted', value: '3' },
    { label: 'Supported Chains', value: '5' },
  ];

  return (
    <section className="bg-[#2B1E5E] py-16 px-6 text-[#E4F3FF]">
      <div className="max-w-6xl mx-auto text-center">
        <h2 className="text-3xl sm:text-4xl font-bold mb-10">
          Zephyra Live Stats
        </h2>

        <div className="grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
          {stats.map((stat, index) => (
            <div
              key={index}
              className="bg-[#1C1C28] rounded-2xl p-6 shadow hover:shadow-lg transition-all"
            >
              <div className="text-2xl font-bold text-[#00C0FF]">{stat.value}</div>
              <p className="mt-2 text-sm text-[#94A3B8]">{stat.label}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
