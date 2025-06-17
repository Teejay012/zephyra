'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { ethers } from 'ethers';
import toast from 'react-hot-toast';
import { useRouter, usePathname } from 'next/navigation';

import { ZEPHYRA_VAULT_ADDRESS, WETH_TOKEN_ADDRESS, WBTC_TOKEN_ADDRESS } from '@/hooks/constants/contracts.js';
import { zephyraVaultABI, ERC20_ABI } from '@/hooks/constants/abis.js';
import { fetchContract } from '@/hooks/constants/fetchContract';






// ----------------------------------------------------------------------------------------
// FETCHING SMART CONTRACT
// ----------------------------------------------------------------------------------------



// 🏦
export const zephyraVault = (signerOrProvider) =>
  fetchContract(ZEPHYRA_VAULT_ADDRESS, zephyraVaultABI, signerOrProvider);

export const collateralContract = (tokenAddress, signerOrProvider) =>
  fetchContract(tokenAddress, ERC20_ABI, signerOrProvider);




// -----------------------------------------------------------------------------------------
// CONTEXT CREATION
// ------------------------------------------------------------------------------------------


const ZephyraContext = createContext();




// -----------------------------------------------------------------------------------------
// Provider Component
// ------------------------------------------------------------------------------------------

export const ZephyraProvider = ({ children }) => {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [walletAddress, setWalletAddress] = useState(null);
  const [networkName, setNetworkName] = useState(null);
  const [isConnecting, setIsConnecting] = useState(false);
  const pathname = usePathname();
  const router = useRouter();




  // --------------------------------------------------------------------------------
  // CHECK NETWORK IS CORRECT
  // -------------------------------------------------------------------------------


  const checkNetwork = async (signerOrProvider) => {
    const requiredChainId = 11155111; // Sepolia

    try {
      const network = await signerOrProvider.getNetwork();
      if (network.chainId !== requiredChainId) {
        toast.error("Please switch to the Sepolia network");
        return false;
      }
      return true;
    } catch (err) {
      console.error("Network check failed:", err);
      toast.error("Unable to verify network");
      return false;
    }
  };





  // --------------------------------------------------------------------------------
  // Deposit Collateral and Mint ZUSD
  // --------------------------------------------------------------------------------

  const depositCollateralAndMintZusd = async (
    tokenAddress,
    collateralAmount, 
    zusdAmount         
  ) => {
    if (!walletAddress || !signer) {
      toast.error('Missing wallet connection');
      return;
    }

    if (!tokenAddress || !collateralAmount || !zusdAmount) {
      toast.error('Missing input values');
      return;
    }

    try {
      const tokenContract = collateralContract(tokenAddress, signer); // ✅ Declare first

      const decimals = await tokenContract.decimals();
      const collateralAmountWei = ethers.parseUnits(String(collateralAmount), decimals);
      const zusdAmountWei = ethers.parseUnits(String(zusdAmount), 18);
      
      // ✅ Step 1: Check allowance
      const currentAllowance = await tokenContract.allowance(walletAddress, zephyraVault(signer).target);

      if (currentAllowance < collateralAmountWei) {
        const approvalTx = await tokenContract.approve(
          zephyraVault(signer).target,
          collateralAmountWei
        );
        toast.loading('Approving token...');
        await approvalTx.wait();
      }

      console.log("Calling with:");
      console.log("Token:", tokenAddress);
      console.log("Collateral (wei):", collateralAmountWei.toString());
      console.log("ZUSD (wei):", zusdAmountWei.toString());

      // ✅ Step 2: Deposit + Mint
      const contract = zephyraVault(signer);
      const tx = await contract.depositCollateralAndMintZusd(
        tokenAddress,
        collateralAmountWei,
        zusdAmountWei
      );

      toast.loading('Transaction submitted...');
      await tx.wait();
      toast.success('Collateral deposited and ZUSD minted!');
    } catch (err) {
      console.error(err);
      toast.error('Transaction failed. Check inputs and approval.');
    }
  };






  // --------------------------------------------------------------------------------
  // Deposit Collateral
  // --------------------------------------------------------------------------------


  const depositCollateral = async ({
    tokenAddress,
    rawAmount, // string or number like "1.25"
  }) => {
    if (!signer || !walletAddress) {
      toast.error('Wallet not connected');
      return;
    }

    if (!tokenAddress || !rawAmount || Number(rawAmount) <= 0) {
      toast.error('Invalid input');
      return;
    }
    
    try {
      const vaultContract = zephyraVault(signer);
      const tokenContract = collateralContract(tokenAddress, signer);

      const decimals = await tokenContract.decimals();
      const amountInWei = ethers.parseUnits(String(rawAmount), decimals);

      const allowance = await tokenContract.allowance(walletAddress, vaultContract);

      if (allowance < amountInWei) {
        toast.loading('Approving token...');
        const approveTx = await tokenContract.approve(vaultContract, amountInWei);
        await approveTx.wait();
        toast.success('Token approved');
      }

      toast.loading('Depositing collateral...');
      const depositTx = await vaultContract.depositCollateral(tokenAddress, amountInWei);
      await depositTx.wait();
      toast.success('Collateral deposited!');
    } catch (err) {
      console.error('Deposit failed:', err);
      toast.error('Deposit failed. Check approval and contract conditions.');
    }
  };






  // --------------------------------------------------------------------------------
  // Get ZUSD Minted
  // --------------------------------------------------------------------------------

  const getMintedZusd = async () => {
    if (!walletAddress || !signer) {
      toast.error('Missing wallet connection');
      return null;
    }

    try {
      const contract = zephyraVault(signer);
      const result = await contract.getMintedZusd(walletAddress);
      const formatted = Number(ethers.formatUnits(result, 18)); // Assuming 18 decimals
      return formatted;
    } catch (err) {
      console.error(err);
      toast.error('Failed to fetch minted ZUSD');
      return null;
    }
  };





  
  // --------------------------------------------------------------------------------
  // Get WETH Deposited
  // --------------------------------------------------------------------------------

  const getUserWETHBalance = async () => {
    if (!walletAddress || !signer) {
      toast.error('Missing wallet connection');
      return null;
    }

    if (!WETH_TOKEN_ADDRESS) {
      toast.error('Missing token address');
      return null;
    }

    try {
      const contract = zephyraVault(signer);
      const result = await contract.getUserCollateralBalance(walletAddress, WETH_TOKEN_ADDRESS);
      const formatted = Number(ethers.formatUnits(result, 18)); // Assuming 18 decimals
      return formatted;
    } catch (err) {
      console.error(err);
      toast.error('Failed to fetch user collateral balance');
      return null;
    }
  };


  // --------------------------------------------------------------------------------
  // Get WETH Deposited
  // --------------------------------------------------------------------------------

  const getUserWBTCBalance = async () => {
    if (!walletAddress || !signer) {
      toast.error('Missing wallet connection');
      return null;
    }

    if (!WBTC_TOKEN_ADDRESS) {
      toast.error('Missing token address');
      return null;
    }

    try {
      const contract = zephyraVault(signer);
      const result = await contract.getUserCollateralBalance(walletAddress, WBTC_TOKEN_ADDRESS);
      const formatted = Number(ethers.formatUnits(result, 18)); // Assuming 18 decimals
      return formatted;
    } catch (err) {
      console.error(err);
      toast.error('Failed to fetch user collateral balance');
      return null;
    }
  };









  // --------------------------------------------------------------------------------
  // Get Health Factor
  // --------------------------------------------------------------------------------

  const getHealthFactor = async () => {
    if (!walletAddress || !signer) {
      toast.error('Missing wallet connection');
      return null;
    }

    try {
      // const isCorrectNetwork = await checkNetwork(signer);
      // if (!isCorrectNetwork) return;

      const contract = zephyraVault(signer); // use your helper
      const result = await contract.getHealthFactor(walletAddress);

      const formatted = Number(ethers.formatUnits(result, 18)); // Assuming 18 decimals
      return formatted;
    } catch (err) {
      console.error(err);
      toast.error('Failed to fetch health factor');
      return null;
    }
  };






    // -----------------------------------------------------------------------------------------------
    // onnect Wallet
    // -----------------------------------------------------------------------------------------------

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
      if (pathname == '/') {
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
        isConnecting,
        connectWallet,
        disconnectWallet,
        getHealthFactor,
        getMintedZusd,
        getUserWETHBalance,
        getUserWBTCBalance,
        depositCollateralAndMintZusd,
        depositCollateral,
      }}
    >
      {children}
    </ZephyraContext.Provider>
  );
};

// 🔄 Export hook to access context
export const useZephyra = () => useContext(ZephyraContext);
