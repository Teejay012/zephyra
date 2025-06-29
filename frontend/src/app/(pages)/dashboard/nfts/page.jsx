'use client';

import { useEffect, useState } from 'react';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';

export default function NFTPerksPage() {
  const [loading, setLoading] = useState(false);
  const [players, setPlayers] = useState([]);
  const [winner, setWinner] = useState(null);
  const [raffleOpen, setRaffleOpen] = useState(false);
  const [isParticipant, setIsParticipant] = useState(false);
  const [winnerTokenId, setWinnerTokenId] = useState(null);


  const {
    tryLuck,
    getAllPlayers,
    getRecentWinner,
    getWinnerTokenId,
    getRaffleState,
    walletAddress, 
  } = useZephyra();

  const handleTryLuck = async () => {
    setLoading(true);
    await tryLuck();
    await fetchPlayers(); 
    setLoading(false);
  };

  const fetchPlayers = async () => {
    const fetchedPlayers = await getAllPlayers();
    setPlayers(fetchedPlayers);
    setIsParticipant(fetchedPlayers.includes(walletAddress));
  };

  const fetchWinner = async () => {
    const fetchedWinner = await getRecentWinner();
    setWinner(fetchedWinner);
  };

  const fetchWinnerTokenId = async () => {
    const tokenId = await getWinnerTokenId();
    setWinnerTokenId(tokenId);
  };

  const fetchRaffleState = async () => {
    const stateLabel = await getRaffleState(); // This now returns 'Open' or 'Closed'
    setRaffleOpen(stateLabel === 'Open');
  };
  

  useEffect(() => {
    fetchPlayers();
    fetchWinner();
    fetchWinnerTokenId();
    fetchRaffleState();
  }, []);

  const isButtonDisabled = loading || !raffleOpen || isParticipant;

  return (
    <section className="max-w-xl mx-auto px-4 py-10 text-center">
      <h2 className="text-2xl font-bold text-[#00C0FF] mb-4">🎲 NFT Raffle</h2>
      <p className="text-[#94A3B8] mb-6">Enter the raffle and win exclusive ZEPHY NFTs!</p>

      <div className="mb-6 text-sm text-[#94A3B8] bg-[#1C1C28] p-4 rounded-md border border-[#475569]/30">
        ⚠️ <strong>Note:</strong> To participate in this <strong>NFT Raffle Game</strong>, You must hold up to 10 ZUSD
        <br />
      </div>

      {/* Show message if raffle is not open */}
      {!raffleOpen && (
        <p className="text-yellow-400 mb-4 font-medium">
          🚧 Raffle is currently closed. Please check back later.
        </p>
      )}

      {/* Show message if already a participant */}
      {raffleOpen && isParticipant && (
        <p className="text-blue-400 mb-4 font-medium">
          ✅ You’ve already entered this raffle.
        </p>
      )}

      <button
        onClick={handleTryLuck}
        disabled={isButtonDisabled}
        className={`px-6 py-3 font-semibold rounded-md transition cursor-pointer ${
          isButtonDisabled
            ? 'bg-[#8B5CF6]/40 cursor-not-allowed'
            : 'bg-[#8B5CF6] hover:bg-[#7C3AED]'
        } text-white`}
      >
        {loading ? 'Entering...' : 'Try Your Luck'}
      </button>

      {/* Players List */}
      <div className="mt-10">
        <h3 className="text-xl font-semibold mb-2">👥 Players</h3>
        <ul className="text-sm text-left bg-[#1E293B]/30 rounded-md p-4 max-h-60 overflow-y-auto">
          {players.length > 0 ? (
            players.map((addr, idx) => (
              <li key={idx} className="text-[#E4F3FF] border-b border-[#334155]/30 py-1">
                {addr}
              </li>
            ))
          ) : (
            <p className="text-[#94A3B8] italic">No entries yet.</p>
          )}
        </ul>
      </div>

      {/* Winner Display */}
      <div className="mt-6">
        <h3 className="text-lg font-semibold">🏆 Recent Winner</h3>
        {winner ? (
          <>
            <p className="text-green-400">{winner}</p>
            {winnerTokenId && (
              <p className="text-[#94A3B8] mt-1 text-sm">
                🏅 <strong>Won Token ID:</strong> {winnerTokenId}
              </p>
            )}
            <div className="mb-6 text-sm text-[#94A3B8] bg-[#1C1C28] p-4 rounded-md border border-[#475569]/30">
              <strong>NFT Contract Address:</strong> 0x26ACde522bc7c5EbB9A0614E7710f45A063B09ED
            </div>
          </>
        ) : (
          <p className="text-[#94A3B8] italic">No winner yet. Stay tuned!</p>
        )}
      </div>
    </section>
  );
}
