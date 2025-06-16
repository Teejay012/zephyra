'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { ethers } from 'ethers';
import toast from 'react-hot-toast';
import { useRouter, usePathname } from 'next/navigation';

const ZephyraContext = createContext();

export const ZephyraProvider = ({ children }) => {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [walletAddress, setWalletAddress] = useState(null);
  const [networkName, setNetworkName] = useState(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const pathname = usePathname();
  const router = useRouter();

  // 🔌 Connect Wallet
  const connectWallet = async () => {
    if (!window.ethereum) {
      toast.error('MetaMask not detected!');
      console.error('MetaMask not detected!');
      return;
    }

    try {
      setIsConnecting(true);
      const _provider = new ethers.BrowserProvider(window.ethereum);
      await _provider.send('eth_requestAccounts', []);
      const _signer = await _provider.getSigner();
      const address = await _signer.getAddress();
      const network = await _provider.getNetwork();

      setProvider(_provider);
      setSigner(_signer);
      setWalletAddress(address);
      setNetworkName(network.name);

      toast.success(`Connected to ${address.slice(0, 6)}...${address.slice(-4)}`);
      toast(`Network: ${network.name}`, { icon: '🛰️' });

      // ✅ Navigate to dashboard if not already there
      if (pathname !== '/dashboard') {
        router.push('/dashboard');
      }
    } catch (err) {
      // toast.error('Connection failed');
      console.error(err);
    } finally {
      setIsConnecting(false);
    }
  };

  // 🔌 Disconnect Wallet
  const disconnectWallet = () => {
    setProvider(null);
    setSigner(null);
    setWalletAddress(null);
    setContracts({});
    setNetworkName(null);
    toast.success('Disconnected');
  };


  // 🔁 Watch for account or network changes
  useEffect(() => {
    if (!window.ethereum) return;

    const handleAccountsChanged = (accounts) => {
      if (accounts.length === 0) {
        disconnectWallet();
      } else {
        connectWallet();
      }
    };

    const handleChainChanged = () => {
      connectWallet(); // Refresh network & contracts
    };

    window.ethereum.on('accountsChanged', handleAccountsChanged);
    window.ethereum.on('chainChanged', handleChainChanged);

    return () => {
      window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
      window.ethereum.removeListener('chainChanged', handleChainChanged);
    };
  }, []);

  return (
    <ZephyraContext.Provider
      value={{
        provider,
        signer,
        walletAddress,
        networkName,
        connectWallet,
        disconnectWallet,
        isConnecting,
        // contracts,
      }}
    >
      {children}
    </ZephyraContext.Provider>
  );
};

// 🔄 Export hook to access context
export const useZephyra = () => useContext(ZephyraContext);
