'use client';

import { useEffect, useState } from 'react';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';
import { toast } from 'react-hot-toast';

const chainData = {
  baseSepolia: {
    name: 'Base Sepolia',
    selector: '10344971235874465080',
    wrappedZusd: '0xae4f4c9997f6d3ec6378e7365b5e587126907306', 
  },
  fuji: {
    name: 'Avalanche Fuji',
    selector: '14767482510784806043',
    wrappedZusd: '0x2b0f837b3a3d7210e296529c99ce46f5d1d90043',
  },
};

export default function CrossChainTransfer() {
  const [amount, setAmount] = useState('');
  const [receiver, setReceiver] = useState('');
  const [destinationChain, setDestinationChain] = useState('');
  const [loading, setLoading] = useState(false);
  const [zusdBalance, setZusdBalance] = useState(null);

  const {
    signer,
    walletAddress,
    processAndSendZUSD, // ✅ your custom handler
    getZusdBalance,
    networkName,
  } = useZephyra();

  useEffect(() => {
    const fetchBalance = async () => {
      if (!signer || !walletAddress) return;
      const balance = await getZusdBalance();
      setZusdBalance(balance);
    };
    fetchBalance();
  }, [signer, walletAddress]);

  const handleTransfer = async () => {
    if (!walletAddress || !signer || !destinationChain || !receiver) {
      toast.error('Missing required fields');
      return;
    }

    if (!amount || parseFloat(amount) <= 0) {
      toast.error('Enter a valid amount');
      return;
    }

    const { selector } = chainData[destinationChain];
    setLoading(true);

    try {
      const result = await processAndSendZUSD(selector, receiver, amount);

      if (result && result.hash) {
        toast.success(
          <span>
            ✅ Tx Sent:&nbsp;
            <a
              href={`https://ccip.chain.link/msg/${result.hash}`}
              target="_blank"
              rel="noopener noreferrer"
              className="underline text-blue-400"
            >
              View on CCIP Explorer
            </a>
          </span>,
          { duration: 10000 }
        );
      }

      setAmount('');
      setReceiver('');
    } catch (err) {
      console.error(err);
      toast.error('Transaction failed');
    } finally {
      setLoading(false);
    }
  };



  return (
    <section className="max-w-md mx-auto px-4 py-10">
      <div className="mb-6 text-sm text-[#94A3B8] bg-[#1C1C28] p-4 rounded-md border border-[#475569]/30">
         ℹ️ Since ZUSD ownership was transferred for security reasons,
         we built a seamless abstraction layer using WrappedZUSD, 
          which mirrors user holdings and enables cross-chain transfers using <strong>Chainlink CCIP</strong> — all without burdening the user.
      </div>

      {/* <div className="mb-6 text-sm text-[#94A3B8] bg-[#1C1C28] p-4 rounded-md border border-[#475569]/30">
        ⚠️ <strong>Note:</strong> Link test token required for transaction fee
      </div> */}

      <div className="bg-[#101524]/80 backdrop-blur-md border border-[#475569]/40 rounded-2xl p-6 shadow-xl shadow-[#00C0FF]/10">
        <h2 className="text-2xl font-bold text-[#00C0FF] mb-6 text-center tracking-wide">
          🌉 Zephyra Cross-Chain Bridge
        </h2>

        <div className="grid grid-cols-2 gap-6 mb-6">
          <div>
            <p className="text-sm text-[#94A3B8] mb-1">Source Chain</p>
            <div className="text-[#E4F3FF] bg-[#1C1C28] px-4 py-2 rounded-md border border-[#475569]/30">
              {networkName || '...'}
            </div>
          </div>

          <div>
            <label className="block text-sm text-[#94A3B8] mb-1">Destination Chain</label>
            <select
              value={destinationChain}
              onChange={(e) => setDestinationChain(e.target.value)}
              className="w-full bg-[#1C1C28] border border-[#475569]/30 rounded-md px-4 py-2 text-[#E4F3FF]"
            >
              <option value="">Select a chain</option>
              {Object.entries(chainData).map(([key, { name }]) => (
                <option key={key} value={key}>
                  {name}
                </option>
              ))}
            </select>
          </div>
        </div>

        {destinationChain && (
          <div className="mb-4 text-sm text-[#94A3B8]">
            🧾 wZUSD Address:{' '}
            <span className="text-[#E4F3FF] font-medium break-all">
              {chainData[destinationChain].wrappedZusd}
            </span>
          </div>
        )}

        <div className="mb-2 text-sm text-[#94A3B8]">
          💰 Balance:{' '}
          <span className="text-[#E4F3FF] font-medium">
            {zusdBalance !== null ? `${zusdBalance.toFixed(4)} ZUSD` : 'Loading...'}
          </span>
        </div>

        <div className="mb-4">
          <label className="block mb-1 text-sm font-medium text-[#E4F3FF]">Receiver Address</label>
          <input
            type="text"
            placeholder="Enter receiver address"
            className="w-full bg-[#1C1C28] border border-[#475569]/30 rounded-lg px-4 py-2 text-[#E4F3FF] placeholder:text-[#64748B] focus:outline-none focus:ring-2 focus:ring-[#00C0FF]"
            value={receiver}
            onChange={(e) => setReceiver(e.target.value)}
          />
        </div>

        <div className="mb-6">
          <label className="block mb-1 text-sm font-medium text-[#E4F3FF]">Amount (ZUSD)</label>
          <input
            type="number"
            step="any"
            min="0"
            placeholder="Enter amount"
            className="w-full bg-[#1C1C28] border border-[#475569]/30 rounded-lg px-4 py-2 text-[#E4F3FF] placeholder:text-[#64748B] focus:outline-none focus:ring-2 focus:ring-[#00C0FF]"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
        </div>

        <button
          onClick={handleTransfer}
          disabled={loading || !amount || !receiver || !destinationChain}
          className={`w-full px-6 py-3 font-semibold rounded-lg transition duration-200 text-white cursor-pointer ${
            loading || !amount || !receiver || !destinationChain
              ? 'bg-[#00C0FF]/30 cursor-not-allowed'
              : 'bg-[#00C0FF] hover:bg-[#00B0F0]'
          }`}
        >
          {loading ? 'Transferring...' : 'Transfer ZUSD'}
        </button>
      </div>
    </section>
  );
}