// components/ConnectWalletButton.jsx
'use client';

import { useZephyra } from '@/hooks/contexts/ZephyraProvider';

export default function ConnectWalletBtn({ className = '' }) {
  const {
    walletAddress,
    connectWallet,
    disconnectWallet,
    isConnecting,
    networkName,
  } = useZephyra();

  const formatAddress = (addr) => addr.slice(0, 6) + '...' + addr.slice(-4);

  if (walletAddress) {
    return (
      <div className={`flex items-center space-x-2 ${className}`}>
        <span className="text-[#E4F3FF] font-semibold bg-[#00C0FF]/20 px-3 py-1 rounded-xl">
          {formatAddress(walletAddress)}
        </span>
        <span className="text-xs text-[#9CA3AF] italic">
          {networkName ? `(${networkName})` : '...'}
        </span>
        <button
          onClick={disconnectWallet}
          className="bg-red-500 hover:bg-red-600 text-white font-semibold px-3 py-2 rounded-xl cursor-pointer"
        >
          Disconnect
        </button>
      </div>
    );
  }

  return (
    <button
      onClick={connectWallet}
      disabled={isConnecting}
      className={`bg-[#00C0FF] hover:bg-[#8B5CF6] text-[#1C1C28] font-semibold px-4 py-2 rounded-xl transition-colors cursor-pointer ${className}`}
    >
      {isConnecting ? 'Connecting...' : 'Connect Wallet'}
    </button>
  );
}
