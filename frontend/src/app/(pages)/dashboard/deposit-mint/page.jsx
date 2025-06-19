'use client';

import { useState } from 'react';
import { ethers } from 'ethers';
import { toast } from 'react-hot-toast';
import { useZephyra } from '@/hooks/contexts/ZephyraProvider';
import { WETH_TOKEN_ADDRESS, WBTC_TOKEN_ADDRESS } from '@/hooks/constants/contracts.js';

// Token to address map (replace with actual addresses)
const TOKEN_ADDRESS_MAP = {
  WETH: WETH_TOKEN_ADDRESS,
  WBTC: WBTC_TOKEN_ADDRESS,
};

const collateralTokens = Object.keys(TOKEN_ADDRESS_MAP);

export default function DepositMintPage() {
  const [collateralToken, setCollateralToken] = useState('WETH');
  const [collateralAmount, setCollateralAmount] = useState('');
  const [zusdAmount, setZusdAmount] = useState('');
  const { depositCollateralAndMintZusd } = useZephyra();

  const handleSubmit = async (e) => {
    e.preventDefault();

    const tokenAddress = TOKEN_ADDRESS_MAP[collateralToken];

    if (!tokenAddress) {
      toast.error('Unsupported token');
      return;
    }

    if (
      !tokenAddress ||
      isNaN(collateralAmount) || Number(collateralAmount) <= 0 ||
      isNaN(zusdAmount) || Number(zusdAmount) <= 0
    ) {
      toast.error('Please enter valid positive numbers');
      return;
    }

    const PRICE_FEED = {
      WETH: 3000,
      WBTC: 100000,
    };

    const usdValue = parseFloat(collateralAmount) * PRICE_FEED[collateralToken];
    const allowedZusd = usdValue / 2; // This is just an assumption, must be removed when real logic is implemented
    
    if (parseFloat(zusdAmount) > allowedZusd) {
      toast.error(`You can only mint up to ${allowedZusd.toFixed(2)} ZUSD with this amount of ${collateralToken}`);
      return;
    }

    try {

      const TOKEN_DECIMALS = {
        WETH: 18,
        WBTC: 8,
      };

      // const decimals = await tokenContract.decimals();
      // const collateralInWei = ethers.parseUnits(String(collateralAmount), decimals);
      const decimals = TOKEN_DECIMALS[collateralToken];
      const collateralInWei = ethers.parseUnits(String(collateralAmount), decimals);
      const zusdInWei = ethers.parseUnits(String(zusdAmount), 18);

      await depositCollateralAndMintZusd(tokenAddress, collateralInWei, zusdInWei);
      setCollateralAmount('');
      setZusdAmount('');
    } catch (err) {
      console.error(err);
      toast.error('Transaction failed');
    }
  };



  return (
    <section className="max-w-xl mx-auto px-4 py-10">
      <h2 className="text-2xl font-bold mb-6 text-[#00C0FF]">
        Deposit Collateral & Mint ZUSD
      </h2>

      <div className="mb-6 text-sm text-[#94A3B8] bg-[#1C1C28] p-4 rounded-md border border-[#475569]/30">
        ⚠️ <strong>Note:</strong> ZUSD is <strong>200% overcollateralized</strong>. That means:
        <br />
        <span className="text-[#E2E8F0]">
          For every 1 ZUSD you mint, you must deposit at least 2 USD worth of collateral.
        </span>
      </div>

      <form
        onSubmit={handleSubmit}
        className="bg-[#2B1E5E]/60 border border-[#475569]/30 rounded-xl p-6 space-y-6"
      >
        {/* Token Select */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">Select Collateral</label>
          <select
            value={collateralToken}
            onChange={(e) => setCollateralToken(e.target.value)}
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          >
            {collateralTokens.map((token) => (
              <option key={token} value={token}>
                {token}
              </option>
            ))}
          </select>
        </div>

        {/* Collateral Amount */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">
            Collateral Amount ({collateralToken})
          </label>
          <input
            type="number"
            step="any"
            min="0"
            value={collateralAmount}
            onChange={(e) => setCollateralAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* ZUSD Amount */}
        <div>
          <label className="block mb-2 text-sm text-[#94A3B8]">ZUSD to Mint</label>
          <input
            type="number"
            step="any"
            min="0"
            value={zusdAmount}
            onChange={(e) => setZusdAmount(e.target.value)}
            placeholder="0.00"
            className="w-full p-3 rounded-md bg-[#1C1C28] border border-[#475569]/40 text-white focus:outline-none"
          />
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          className="w-full py-3 bg-[#00C0FF] text-[#1C1C28] font-semibold rounded-md hover:bg-[#00e0ff] cursor-pointer"
        >
          Deposit & Mint
        </button>
      </form>
    </section>
  );
}




// This is just an assumption, must be removed when real logic is implemented