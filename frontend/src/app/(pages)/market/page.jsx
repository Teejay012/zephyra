'use client';

import { useState, useEffect } from 'react';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';
import ConnectWalletBtn from '@/components/connectWalletBtn/ConnectWalletBtn';

export default function MarketPage() {
  const { walletAddress, getAllUsersData, liquidateUser } = useZephyra();
  const [users, setUsers] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(true);

  const [selectedUser, setSelectedUser] = useState(null);
  const [amount, setAmount] = useState('');
  const [message, setMessage] = useState('');
  const [liquidating, setLiquidating] = useState(false);

  useEffect(() => {
    const fetchUsers = async () => {
      setLoadingUsers(true);
      const fetched = await getAllUsersData();
      setUsers(fetched);
      setLoadingUsers(false);
    };
    fetchUsers();
  }, [getAllUsersData]);

  const openModal = (user) => {
    setSelectedUser(user);
    setAmount('');
    setMessage('');
  };

  const closeModal = () => {
    setSelectedUser(null);
    setAmount('');
    setMessage('');
    setLiquidating(false);
  };

  const confirmLiquidation = async () => {
    if (!amount || isNaN(amount) || Number(amount) <= 0) return;
    const isSelf = selectedUser.address.toLowerCase() === walletAddress.toLowerCase();
    if (isSelf) {
      setMessage('❌ You cannot liquidate your own account');
      return;
    }
    if (parseFloat(selectedUser.healthFactor) >= 1.0) {
      setMessage('❌ This user cannot be liquidated (healthy position)');
      return;
    }

    try {
      setLiquidating(true);
      // Find token used for collateral (the one with non-zero amount)
      const collateral = selectedUser.collateral.find(c => parseFloat(c.amount) > 0);
      if (!collateral || !collateral.address) {
        setMessage('❌ No valid collateral found');
        setLiquidating(false);
        return;
      }

      await liquidateUser({
        collateralTokenAddress: collateral.address,
        userAddress: selectedUser.address,
        rawDebtAmount: amount,
      });

      setMessage(`✅ Successfully liquidated ${amount} ZUSD from ${selectedUser.address}`);
      setTimeout(closeModal, 2000);
    } catch (err) {
      console.error(err);
      setMessage('❌ Liquidation failed');
    } finally {
      setLiquidating(false);
    }
  };

  if (!walletAddress) {
    return (
      <div className="min-h-[60vh] flex flex-col items-center justify-center text-center text-[#E4F3FF] gap-4 bg-[#1C1C28]">
        <p className="text-lg font-semibold">Connect your wallet to view the market overview.</p>
        <ConnectWalletBtn />
      </div>
    );
  }

  return (
    <section className="w-full pt-25 bg-[#2B1E5E] px-4 py-10">
      <h2 className="text-2xl font-bold text-[#00C0FF] mb-6 text-center">🧾 Market Overview</h2>

      <div className="overflow-x-auto bg-[#1C1C28] rounded-lg shadow border border-[#334155]/30">
        {loadingUsers ? (
          <p className="text-center text-[#94A3B8] p-6">Loading users...</p>
        ) : (
          <table className="w-full text-sm text-left text-[#E4F3FF]">
            <thead className="bg-[#2B1E5E] text-[#94A3B8] text-xs uppercase">
              <tr>
                <th className="px-6 py-4">User</th>
                <th className="px-6 py-4">Collateral</th>
                <th className="px-6 py-4">ZUSD Minted</th>
                <th className="px-6 py-4">Health Score</th>
                <th className="px-6 py-4">Liquidate</th>
              </tr>
            </thead>
            <tbody>
              {users.map((user) => {
                const isSelf = user.address.toLowerCase() === walletAddress.toLowerCase();
                const canLiquidate = parseFloat(user.healthFactor) < 1.0 && !isSelf;

                return (
                  <tr key={user.address} className="border-t border-[#334155]/20">
                    <td className="px-6 py-4 font-mono truncate max-w-[100px]">{user.address}</td>
                    <td className="px-6 py-4">
                      {user.collateral
                        .filter((c) => parseFloat(c.amount) > 0)
                        .map((c) => `${parseFloat(c.amount).toFixed(2)} ${c.symbol}`)
                        .join(', ') || '—'}
                    </td>
                    <td className="px-6 py-4">{parseFloat(user.zusd).toFixed(2)} ZUSD</td>
                    <td
                      className={`px-6 py-4 font-semibold ${
                        parseFloat(user.healthFactor) < 1.5 ? 'text-red-400' : 'text-green-400'
                      }`}
                    >
                      {parseFloat(user.healthFactor).toFixed(2)}
                    </td>
                    <td className="px-6 py-4">
                      {canLiquidate ? (
                        <button
                          onClick={() => openModal(user)}
                          className="text-sm px-4 py-2 rounded-md bg-red-600 hover:bg-red-700 transition cursor-pointer"
                        >
                          Liquidate
                        </button>
                      ) : (
                        <span className="text-xs text-[#94A3B8] italic">Not eligible</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      {/* Liquidation Modal */}
      {selectedUser && (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50">
          <div className="bg-[#1E1E2E] p-6 rounded-xl shadow-xl max-w-md w-full text-center border border-[#475569]/40">
            <h3 className="text-xl font-bold text-[#00C0FF] mb-4">⚠️ Liquidate User</h3>
            <p className="text-sm mb-4 text-[#94A3B8]">
              Enter the amount of ZUSD to burn for{' '}
              <span className="text-[#E4F3FF]">{selectedUser.address}</span>
            </p>

            <input
              type="number"
              step="any"
              min={0}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder="Amount to burn"
              className="w-full px-4 py-2 rounded-md bg-[#2B2B3C] text-[#E4F3FF] border border-[#475569]/40 focus:outline-none focus:ring focus:ring-[#00C0FF]/30 mb-4"
            />

            <div className="flex gap-3 justify-center">
              <button
                onClick={confirmLiquidation}
                disabled={liquidating}
                className={`px-4 py-2 rounded-md text-white text-sm cursor-pointer ${
                  liquidating
                    ? 'bg-[#8B5CF6]/40 cursor-not-allowed'
                    : 'bg-red-600 hover:bg-red-700'
                }`}
              >
                {liquidating ? 'Liquidating...' : 'Confirm Liquidation'}
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
