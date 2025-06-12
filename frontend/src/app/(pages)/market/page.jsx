'use client';

import { useState } from 'react';

const dummyUsers = [
  {
    address: '0xF3...9A7b',
    collateral: '1.5 WETH',
    zusd: '800 ZUSD',
    health: 1.3,
  },
  {
    address: '0xAc...47C1',
    collateral: '0.9 WBTC',
    zusd: '1500 ZUSD',
    health: 2.1,
  },
  {
    address: '0xBa...D16f',
    collateral: '2.0 WETH',
    zusd: '1000 ZUSD',
    health: 1.0,
  },
];

export default function MarketPage() {
  const [selectedUser, setSelectedUser] = useState(null);
  const [amount, setAmount] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);

  const openModal = (user) => {
    setSelectedUser(user);
    setAmount('');
    setMessage('');
  };

  const closeModal = () => {
    setSelectedUser(null);
    setAmount('');
    setLoading(false);
    setMessage('');
  };

  const confirmLiquidation = async () => {
    if (!amount) return;
    setLoading(true);
    await new Promise((res) => setTimeout(res, 1500)); // Simulate delay
    setLoading(false);
    setMessage(`Successfully liquidated ${amount} ZUSD from ${selectedUser.address}`);
    setTimeout(closeModal, 2000);
  };

  return (
    <section className="w-full pt-25 bg-[#2B1E5E] px-4 py-10">
      <h2 className="text-2xl font-bold text-[#00C0FF] mb-6 text-center">
        🧾 Market Overview
      </h2>

      <div className="overflow-x-auto bg-[#1C1C28] rounded-lg shadow border border-[#334155]/30">
        <table className="w-full text-sm text-left text-[#E4F3FF]">
          <thead className="bg-[#2B1E5E] text-[#94A3B8] text-xs uppercase">
            <tr>
              <th className="px-6 py-4">User</th>
              <th className="px-6 py-4">Collateral</th>
              <th className="px-6 py-4">ZUSD Minted</th>
              <th className="px-6 py-4">Health Score</th>
              <th className="px-6 py-4">Action</th>
            </tr>
          </thead>
          <tbody>
            {dummyUsers.map((user) => (
              <tr key={user.address} className="border-t border-[#334155]/20">
                <td className="px-6 py-4 font-mono">{user.address}</td>
                <td className="px-6 py-4">{user.collateral}</td>
                <td className="px-6 py-4">{user.zusd}</td>
                <td className={`px-6 py-4 font-semibold ${
                    user.health < 1.5 ? 'text-red-400' : 'text-green-400'
                  }`}>
                  {user.health.toFixed(2)}
                </td>
                <td className="px-6 py-4">
                  <button
                    onClick={() => openModal(user)}
                    className="text-sm px-4 py-2 rounded-md bg-red-600 hover:bg-red-700 transition cursor-pointer"
                  >
                    Liquidate
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Modal */}
      {selectedUser && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50">
          <div className="bg-[#1E1E2E] p-6 rounded-xl shadow-xl max-w-md w-full text-center border border-[#475569]/40">
            <h3 className="text-xl font-bold text-[#00C0FF] mb-4">⚠️ Liquidate User</h3>
            <p className="text-sm mb-4 text-[#94A3B8]">
              Enter the amount of ZUSD to burn for <span className="text-[#E4F3FF]">{selectedUser.address}</span>
            </p>

            <input
              type="number"
              min={0}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="Amount to burn"
              className="w-full px-4 py-2 rounded-md bg-[#2B2B3C] text-[#E4F3FF] border border-[#475569]/40 focus:outline-none focus:ring focus:ring-[#00C0FF]/30 mb-4"
            />

            <div className="flex gap-3 justify-center">
              <button
                onClick={confirmLiquidation}
                disabled={loading}
                className={`px-4 py-2 rounded-md text-white text-sm cursor-pointer ${
                  loading
                    ? 'bg-[#8B5CF6]/40 cursor-not-allowed'
                    : 'bg-red-600 hover:bg-red-700'
                }`}
              >
                {loading ? 'Liquidating...' : 'Confirm Liquidation'}
              </button>
              <button
                onClick={closeModal}
                className="px-4 py-2 rounded-md text-sm bg-gray-600 hover:bg-gray-700 text-white cursor-pointer"
              >
                Cancel
              </button>
            </div>

            {message && (
              <p className="mt-4 text-[#4ADE80] text-sm font-medium">{message}</p>
            )}
          </div>
        </div>
      )}
    </section>
  );
}
