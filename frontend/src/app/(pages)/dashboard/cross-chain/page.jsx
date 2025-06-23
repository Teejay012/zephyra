'use client';

import { useEffect, useState } from 'react';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';
import { toast } from 'react-hot-toast';

const chainData = {
  baseSepolia: {
    name: 'Base Sepolia',
    selector: '10344971235874465080',
  },
  fuji: {
    name: 'Avalanche Fuji',
    selector: '14767482510784806043',
  },
};

export default function CrossChainTransfer() {
  const [amount, setAmount] = useState('');
  const [sourceChain, setSourceChain] = useState('');
  const [destinationChain, setDestinationChain] = useState('');
  const [loading, setLoading] = useState(false);
  const [zusdBalance, setZusdBalance] = useState(null);

  const { signer, walletAddress, transferZusdCrossChainNative, getZusdBalance, networkName } = useZephyra();

  // Fetch balance on load
  useEffect(() => {
    const fetchBalance = async () => {
      if (!signer || !walletAddress) return;
      const balance = await getZusdBalance();
      setZusdBalance(balance);
    };
    fetchBalance();
  }, [signer, walletAddress]);




  const handleTransfer = async () => {
    if (!walletAddress || !signer || !destinationChain) return;

    if (!amount || parseFloat(amount) <= 0) {
      toast.error('Enter a valid amount');
      return;
    }

    setLoading(true);
    
    try {

      console.log("Attempting transfer", {
        selector: chainData[destinationChain].selector,
        receiver: walletAddress,
        amount,
      });

      await transferZusdCrossChainNative({
        destinationChainSelector: chainData[destinationChain].selector,
        receiverAddress: walletAddress,
        zusdAmount: amount,
      });
      setAmount('');
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  // Options excluding the source
  const destinationOptions = Object.keys(chainData).filter((key) => key !== sourceChain);

  return (
    <section className="max-w-md mx-auto px-4 py-10">
      <div className="bg-[#101524]/80 backdrop-blur-md border border-[#475569]/40 rounded-2xl p-6 shadow-xl shadow-[#00C0FF]/10">
        <h2 className="text-2xl font-bold text-[#00C0FF] mb-6 text-center tracking-wide">
          🌉 Zephyra Cross-Chain Bridge
        </h2>

        {/* Chain Display */}
        <div className="grid grid-cols-2 gap-6 mb-6">
          <div>
            <p className="text-sm text-[#94A3B8] mb-1">Source Chain</p>
            <div className="text-[#E4F3FF] bg-[#1C1C28] px-4 py-2 rounded-md border border-[#475569]/30">
              {networkName ? `${networkName}` : '...'}
            </div>
          </div>

          <div>
            <label className="block text-sm text-[#94A3B8] mb-1">Destination Chain</label>
            <select
              value={destinationChain}
              onChange={(e) => setDestinationChain(e.target.value)}
              className="w-full bg-[#1C1C28] border border-[#475569]/30 rounded-md px-4 py-2 text-[#E4F3FF]"
            >
              {destinationOptions.map((key) => (
                <option key={key} value={key}>
                  {chainData[key].name}
                </option>
              ))}
            </select>
          </div>
        </div>


        {/* ZUSD Balance */}
        <div className="mb-2 text-sm text-[#94A3B8]">
        💰 Balance:{' '}
        <span className="text-[#E4F3FF] font-medium">
          {zusdBalance !== null ? `${zusdBalance.toFixed(4)} ZUSD` : 'Loading...'}
        </span>
      </div>




        {/* Amount Input */}
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

        {/* Transfer Button */}
        <button
          onClick={handleTransfer}
          disabled={loading || !amount}
          className={`w-full px-6 py-3 font-semibold rounded-lg transition duration-200 text-white cursor-pointer ${
            loading || !amount
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