'use client';

import React, { createContext, useContext, useState, useEffect } from 'react';
import { ethers } from 'ethers';
import toast from 'react-hot-toast';
import { useRouter, usePathname } from 'next/navigation';

import { ZEPHYRA_STABLECOIN_ADDRESS, WRAPPED_ZUSD, ZEPHYRA_VAULT_ADDRESS, WETH_TOKEN_ADDRESS, WBTC_TOKEN_ADDRESS, ZEPHYRA_NFT_ADDRESS, ZUSD_CCIP_PROCESSING_CONTRACT } from '@/hooks/constants/contracts.js';
import { zephyraVaultABI, zephyraNFTABI, zephyraXChainABI, ERC20_ABI } from '@/hooks/constants/abis.js';
import { fetchContract } from '@/hooks/constants/fetchContract';


const tokenList = [
  { symbol: 'WETH', address: WETH_TOKEN_ADDRESS, decimals: 18 },
  { symbol: 'WBTC', address: WBTC_TOKEN_ADDRESS, decimals: 8 },
];





// ----------------------------------------------------------------------------------------
// FETCHING SMART CONTRACT
// ----------------------------------------------------------------------------------------



// 🏦

export const zusd = (signerOrProvider) =>
  fetchContract(ZEPHYRA_STABLECOIN_ADDRESS, ERC20_ABI, signerOrProvider);

export const w_zusd = (signerOrProvider) =>
  fetchContract(WRAPPED_ZUSD, ERC20_ABI, signerOrProvider);

export const zephyraVault = (signerOrProvider) =>
  fetchContract(ZEPHYRA_VAULT_ADDRESS, zephyraVaultABI, signerOrProvider);

export const collateralContract = (tokenAddress, signerOrProvider) =>
  fetchContract(tokenAddress, ERC20_ABI, signerOrProvider);

export const zephyraNFT = (signerOrProvider) =>
  fetchContract(ZEPHYRA_NFT_ADDRESS, zephyraNFTABI, signerOrProvider);

export const zephyraCrossChain = (signerOrProvider) =>
  fetchContract(ZUSD_CCIP_PROCESSING_CONTRACT, zephyraXChainABI, signerOrProvider);




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
      const vault = zephyraVault(signer);
      const tokenContract = collateralContract(tokenAddress, signer);

      const decimals = await tokenContract.decimals();
      const collateralAmountWei = ethers.parseUnits(String(collateralAmount), decimals);
      const zusdAmountWei = ethers.parseUnits(String(zusdAmount), 18);
      
      // Check allowance
      const currentAllowance = await tokenContract.allowance(walletAddress, ZEPHYRA_VAULT_ADDRESS);

      if (currentAllowance < collateralAmountWei) {
        const toastId = toast.loading('Approving token...');
        const approvalTx = await tokenContract.approve(
          ZEPHYRA_VAULT_ADDRESS,
          collateralAmountWei
        );
        await approvalTx.wait();
        toast.dismiss(toastId);
        toast.success('Token approved!');
      }

      // Deposit + Mint
      const toastId = toast.loading('Transaction loading...');
      const tx = await vault.depositCollateralAndMintZusd(
        tokenAddress,
        collateralAmountWei,
        zusdAmountWei
      );
      await tx.wait();
      toast.dismiss(toastId);
      toast.success('Collateral deposited!');
      toast.success('ZUSD minted!');

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
    rawAmount,
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

      const allowance = await tokenContract.allowance(walletAddress, ZEPHYRA_VAULT_ADDRESS);

      if (allowance < amountInWei) {
        const toastId = toast.loading('Approving token...');
        const approveTx = await tokenContract.approve(ZEPHYRA_VAULT_ADDRESS, amountInWei);
        await approveTx.wait();
        toast.dismiss(toastId);
        toast.success('Token approved');
      }

      const toastId = toast.loading('Depositing collateral...');
      const depositTx = await vaultContract.depositCollateral(tokenAddress, amountInWei);
      await depositTx.wait();
      toast.dismiss(toastId);
      toast.success('Collateral deposited!');
    } catch (err) {
      console.error('Deposit failed:', err);
      toast.error('Deposit failed. Check approval and contract conditions.');
    }
  };








    // --------------------------------------------------------------------------------
    // Mint ZUSD
    // --------------------------------------------------------------------------------


  const mintZusd = async ({
    rawAmount
  }) => {
    if (!signer || !walletAddress) {
      toast.error('Connect your wallet');
      return;
    }

    if (!rawAmount || isNaN(rawAmount) || Number(rawAmount) <= 0) {
      toast.error('Invalid mint amount');
      return;
    }

    try {
      const vaultContract = zephyraVault(signer);

      // ZUSD has 18 decimals
      const amountInWei = ethers.parseUnits(String(rawAmount), 18);

      const toastId = toast.loading('Minting ZUSD...');
      const tx = await vaultContract.mintZusd(amountInWei);
      await tx.wait();
      toast.dismiss(toastId);
      toast.success('ZUSD minted!');
    } catch (err) {
      console.error('Mint failed:', err);
      toast.error('Mint failed. Check eligibility and health factor.');
    }
  };









  // --------------------------------------------------------------------------------
  // BURN ZUSD
  // --------------------------------------------------------------------------------

  const burnZusd = async ({
    rawAmount
  }) => {
    if (!signer || !walletAddress) {
      toast.error('Wallet not connected');
      return;
    }

    if (!rawAmount || isNaN(Number(rawAmount)) || Number(rawAmount) <= 0) {
      toast.error('Invalid burn amount');
      return;
    }

    try {
      const vault = zephyraVault(signer);
      const zusdContract = zusd(signer);
      const amountInWei = ethers.parseUnits(String(rawAmount), 18);

      const allowance = await zusdContract.allowance(walletAddress, ZEPHYRA_VAULT_ADDRESS);

      if (allowance < amountInWei) {
        const toastId = toast.loading('Approving ZUSD...');
        const approveTx = await zusdContract.approve(ZEPHYRA_VAULT_ADDRESS, amountInWei);
        await approveTx.wait();
        toast.dismiss(toastId);
        toast.success('ZUSD approved');
      }

      const toastId = toast.loading('Burning ZUSD...');
      const tx = await vault.burnZusd(amountInWei);
      await tx.wait();

      toast.dismiss(toastId);
      toast.success('ZUSD burned!');
    } catch (error) {
      console.error('Burning failed:', error);
      toast.error('Burn failed. Check contract conditions.');
    }
  };








  // --------------------------------------------------------------------------------
  // REDEEM COLLATERAL
  // --------------------------------------------------------------------------------


  const redeemCollateral = async ({
    tokenAddress,
    rawAmount,
  }) => {
    
    if (!signer || !tokenAddress || !rawAmount || Number(rawAmount) <= 0) {
      toast.error('Invalid input');
      return;
    }

    try {
      const vault = zephyraVault(signer);
      const tokenContract = collateralContract(tokenAddress, signer);

      const decimals = await tokenContract.decimals();
      const amountInWei = ethers.parseUnits(String(rawAmount), decimals);

      const toastId = toast.loading('Redeeming collateral...');
      const tx = await vault.redeemCollateral(tokenAddress, amountInWei);
      await tx.wait();
      toast.dismiss(toastId);
      toast.success('Collateral redeemed!');
    } catch (err) {
      console.error('Redeem failed:', err);
      toast.error('Redeem failed. Check health factor or vault state.');
    }
  };











  // -----------------------------------------------------------------------------------------------
  // LIQUIDATE
  // -----------------------------------------------------------------------------------------------


  const liquidateUser = async ({ collateralTokenAddress, userAddress, rawDebtAmount }) => {
    if (!signer || !walletAddress) {
      toast.error('Wallet not connected');
      return;
    }

    if (!collateralTokenAddress || !userAddress || !rawDebtAmount || Number(rawDebtAmount) <= 0) {
      toast.error('Invalid liquidation input');
      return;
    }

    try {
      const zusdContract = zusd(signer);
      const decimals = await zusdContract.decimals();
      const debtToCover = ethers.parseUnits(rawDebtAmount.toString(), decimals);

      const allowance = await zusdContract.allowance(walletAddress, ZEPHYRA_VAULT_ADDRESS);
      if (allowance < debtToCover) {
        const toastId = toast.loading('Approving ZUSD...');
        const approveTx = await zusdContract.approve(ZEPHYRA_VAULT_ADDRESS, debtToCover);
        await approveTx.wait();
        toast.dismiss(toastId);
        toast.success('ZUSD approved!');
      }

      const vault = zephyraVault(signer);
      const toastId = toast.loading('Liquidating...');
      const tx = await vault.liquidate(collateralTokenAddress, userAddress, debtToCover);
      await tx.wait();
      toast.dismiss(toastId);
      toast.success('User successfully liquidated!');
    } catch (err) {
      console.error('Liquidation failed:', err);
      toast.error('Liquidation failed. Check conditions.');
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
  // Get WBTC Deposited
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












  // --------------------------------------------------------------------------------
  // Get users Data
  // --------------------------------------------------------------------------------

  const getAllUsersData = async () => {
    if (!provider) {
      // toast.error("Provider not available");
      return [];
    }

    try {
      const vault = zephyraVault(provider);
      const users = await vault.getUsers();

      const data = await Promise.all(
        users.map(async (user) => {
          const collateral = await Promise.all(
            tokenList.map(async (token) => {
              const amount = await vault.getUserCollateralBalance(user, token.address);
              return {
                symbol: token.symbol,
                amount: ethers.formatUnits(amount, token.decimals),
              };
            })
          );

          const zusdMinted = await vault.getMintedZusd(user);
          const health = await vault.getHealthFactor(user);

          return {
            address: user,
            collateral,
            zusd: ethers.formatUnits(zusdMinted, 18),
            healthFactor: ethers.formatUnits(health, 18), 
          };
        })
      );

      return data;
    } catch (error) {
      console.error('Error fetching user data:', error);
      toast.error("Couldn't fetch user data");
      return [];
    }
  };


















    // -----------------------------------------------------------------------------------------------
    // NFT RAFFLE
    // -----------------------------------------------------------------------------------------------




    // -----------------------------------------------------------------------------------------------
    // TRY LUCK
    // -----------------------------------------------------------------------------------------------

  const tryLuck = async () => {
    if (!walletAddress || !signer) {
      toast.error('Please connect your wallet first');
      return;
    }

    try {
      const nftContract = zephyraNFT(signer);

      const entryFee = await nftContract.getEntryFee();

      const tx = await nftContract.tryLuck({
        value: entryFee
      });

      const toastId = toast.loading('Trying your luck...');
      await tx.wait();
      toast.dismiss(toastId);
      toast.success('Entry submitted!');

    } catch (err) {
      console.error(err);
      toast.error('Failed to enter the raffle');
    }
  };










    // -----------------------------------------------------------------------------------------------
    //  GET ALL PLAYERS
    // -----------------------------------------------------------------------------------------------


  const getAllPlayers = async () => {
    if (!provider) {
      toast.error('Provider not available');
      return [];
    }

    try {
      const nftContract = zephyraNFT(provider);
      const players = await nftContract.getAllPlayers();
      return players;
    } catch (err) {
      console.error(err);
      toast.error('Could not fetch players');
      return [];
    }
  };









    // -----------------------------------------------------------------------------------------------
    //  GET RECENT WINNER
    // -----------------------------------------------------------------------------------------------

  const getRecentWinner = async () => {
    if (!provider) {
      toast.error('Provider not available');
      return null;
    }

    try {
      const nftContract = zephyraNFT(provider);
      const winner = await nftContract.getRecentWinner();
      return winner;
    } catch (err) {
      console.error(err);
      toast.error('Could not fetch recent winner');
      return null;
    }
  };













    // -----------------------------------------------------------------------------------------------
    //  GET RAFFLE STATE
    // -----------------------------------------------------------------------------------------------

  const getRaffleState = async () => {
    try {
      const nftContract = zephyraNFT(provider);

      const state = await nftContract.getRaffleState();

      const stateLabel = state.toString() === '0' ? 'Open' : 'Closed';
      console.log("Raffle State: ", stateLabel);

      return stateLabel;
    } catch (error) {
      console.error('Error getting raffle state:', error);
      return null;
    }
  };










   // -----------------------------------------------------------------------------------------------
  // GET CURRENT WINNER TOKEN ID
  // -----------------------------------------------------------------------------------------------

  const getWinnerTokenId = async () => {
    if (!provider) {
      toast.error('Provider not available');
      return null;
    }

    try {
      const nftContract = zephyraNFT(provider);
      const tokenCounterRaw = await nftContract.s_tokenIdCounter();

      console.log("Raw tokenCounter:", tokenCounterRaw, typeof tokenCounterRaw);

      const winnerTokenId = tokenCounterRaw - 1n;
      return winnerTokenId.toString();
    } catch (err) {
      console.error('Error fetching token ID:', err);
      toast.error('Could not fetch token ID');
      return null;
    }
  };














  // -----------------------------------------------------------------------------------------------
//  GET USER NFTS (FIXED VERSION)
// -----------------------------------------------------------------------------------------------

// Add these helper functions to your ZephyraProvider.jsx

// Helper function to process image URIs
const processImageUri = (imageUri) => {
  if (!imageUri) return '/icons/placeholder-nft.png';
  
  if (imageUri.startsWith('data:')) return imageUri;
  if (imageUri.startsWith('http')) return imageUri;
  if (imageUri.startsWith('ipfs://')) return `https://ipfs.io/ipfs/${imageUri.slice(7)}`;
  
  // Handle base64 SVG
  try {
    const decoded = atob(imageUri);
    if (decoded.includes('<svg')) {
      return `data:image/svg+xml;base64,${imageUri}`;
    }
  } catch (e) {
    // Not valid base64, continue
  }
  
  // If image is base64 encoded SVG, ensure it has proper data URI prefix
  if (imageUri.startsWith('PHN2Zw') || imageUri.includes('<svg')) {
    if (imageUri.includes('<svg')) {
      return `data:image/svg+xml;base64,${btoa(imageUri)}`;
    } else {
      return `data:image/svg+xml;base64,${imageUri}`;
    }
  }
  
  return '/icons/placeholder-nft.png';
};




const getNFTsViaEnumerable = async (nftContract, walletAddress, limit = 50) => {
  try {
    const balance = await nftContract.balanceOf(walletAddress);
    const balanceNum = parseInt(balance.toString());
    
    if (balanceNum === 0) return [];
    
    const nftList = [];
    const maxToFetch = Math.min(balanceNum, limit);
    
    for (let i = 0; i < maxToFetch; i++) {
      try {
        const tokenId = await nftContract.tokenOfOwnerByIndex(walletAddress, i);
        const tokenURI = await nftContract.tokenURI(tokenId);
        
        let metadata;
        try {
          // Parse tokenURI (assuming it's data:application/json;base64,...)
          const metadataBase64 = tokenURI.split(',')[1];
          const metadataJson = atob(metadataBase64);
          metadata = JSON.parse(metadataJson);
          
          nftList.push({
            tokenId: tokenId.toString(),
            ...metadata,
            image: processImageUri(metadata.image),
            originalImage: metadata.image
          });
        } catch (parseError) {
          console.error(`Error parsing metadata for token ${tokenId}:`, parseError);
          nftList.push({
            tokenId: tokenId.toString(),
            name: `ZephyraNFT #${tokenId}`,
            description: 'NFT metadata could not be parsed',
            image: '/icons/placeholder-nft.png',
            error: 'Metadata parsing failed'
          });
        }
      } catch (tokenError) {
        console.error(`Error fetching token at index ${i}:`, tokenError);
      }
    }
    
    return nftList;
  } catch (error) {
    console.error('Error in getNFTsViaEnumerable:', error);
    throw error;
  }
};

// Get NFTs via events (fallback method)
const getNFTsViaEvents = async (nftContract, walletAddress, limit = 50) => {
  try {
    // Get all NftMinted events for this user
    const filter = nftContract.filters.NftMinted(walletAddress);
    const events = await nftContract.queryFilter(filter);
    
    const nftList = [];
    let processed = 0;
    
    for (const event of events) {
      if (processed >= limit) break;
      
      const tokenId = event.args.tokenIdCounter;
      
      try {
        // Verify user still owns this token
        const owner = await nftContract.ownerOf(tokenId);
        if (owner.toLowerCase() === walletAddress.toLowerCase()) {
          const tokenURI = await nftContract.tokenURI(tokenId);
          
          let metadata;
          try {
            // TokenURI format: "data:application/json;base64,{base64_encoded_json}"
            const metadataBase64 = tokenURI.split(',')[1];
            const metadataJson = atob(metadataBase64);
            metadata = JSON.parse(metadataJson);
            
            nftList.push({
              tokenId: tokenId.toString(),
              ...metadata,
              image: processImageUri(metadata.image),
              originalImage: metadata.image
            });
            
            processed++;
          } catch (parseError) {
            console.error(`Error parsing metadata for token ${tokenId}:`, parseError);
            nftList.push({
              tokenId: tokenId.toString(),
              name: `ZephyraNFT #${tokenId}`,
              description: 'NFT metadata could not be parsed',
              image: '/icons/placeholder-nft.png',
              error: 'Metadata parsing failed'
            });
            processed++;
          }
        }
      } catch (ownershipError) {
        console.log(`Token ${tokenId} no longer exists or was transferred:`, ownershipError);
      }
    }
    
    return nftList;
  } catch (error) {
    console.error('Error in getNFTsViaEvents:', error);
    throw error;
  }
};

// Main getUserNFTs function (replace your existing one)
const getUserNFTs = async (walletAddress, provider, limit = 50) => {
  try {
    const nftContract = zephyraNFT(provider);
    
    // First try to check if enumerable is supported
    let supportsEnumerable = false;
    try {
      // ERC165 interface ID for ERC721Enumerable
      supportsEnumerable = await nftContract.supportsInterface('0x780e9d63');
    } catch (error) {
      console.log('Contract does not support ERC165 or enumerable check failed, using events method');
      supportsEnumerable = false;
    }
    
    console.log('Supports enumerable:', supportsEnumerable);
    
    if (supportsEnumerable) {
      console.log('Using enumerable method to fetch NFTs');
      return await getNFTsViaEnumerable(nftContract, walletAddress, limit);
    } else {
      console.log('Using events method to fetch NFTs');
      return await getNFTsViaEvents(nftContract, walletAddress, limit);
    }
  } catch (error) {
    console.error('Error fetching NFTs:', error);
    
    // If all else fails, try the original method
    try {
      console.log('Falling back to original method');
      return await getUserNFTsOriginal(walletAddress, provider);
    } catch (fallbackError) {
      console.error('Fallback method also failed:', fallbackError);
      throw new Error('Unable to fetch NFTs');
    }
  }
};

// Your original method as fallback
const getUserNFTsOriginal = async (walletAddress, provider) => {
  try {
    const nftContract = zephyraNFT(provider);
    
    // Get all NftMinted events for this user
    const filter = nftContract.filters.NftMinted(walletAddress);
    const events = await nftContract.queryFilter(filter);
    
    const nftList = [];
    
    for (const event of events) {
      const tokenId = event.args.tokenIdCounter;
      
      try {
        // Verify user still owns this token
        const owner = await nftContract.ownerOf(tokenId);
        if (owner.toLowerCase() === walletAddress.toLowerCase()) {
          const tokenURI = await nftContract.tokenURI(tokenId);
          
          // Parse the tokenURI properly
          let metadata;
          try {
            // TokenURI format: "data:application/json;base64,{base64_encoded_json}"
            const metadataBase64 = tokenURI.split(',')[1];
            const metadataJson = atob(metadataBase64);
            metadata = JSON.parse(metadataJson);
            
            nftList.push({
              tokenId: tokenId.toString(),
              ...metadata,
              image: processImageUri(metadata.image),
              originalImage: metadata.image
            });
            
          } catch (parseError) {
            console.error(`Error parsing metadata for token ${tokenId}:`, parseError);
            console.log('Raw tokenURI:', tokenURI);
            
            // Add NFT with basic info even if metadata parsing fails
            nftList.push({
              tokenId: tokenId.toString(),
              name: `ZephyraNFT #${tokenId}`,
              description: 'NFT metadata could not be parsed',
              image: '/icons/placeholder-nft.png',
              error: 'Metadata parsing failed'
            });
          }
        }
      } catch (ownershipError) {
        console.log(`Token ${tokenId} no longer exists or was transferred:`, ownershipError);
      }
    }
    
    console.log('Fetched NFTs:', nftList);
    return nftList;
    
  } catch (error) {
    console.error('Error fetching user NFTs:', error);
    throw new Error('Unable to fetch NFTs');
  }
};



















  // --------------------------------------------------------------------------------
  // Process and Send ZUSD (Wrap + Transfer Cross-chain)
  // --------------------------------------------------------------------------------

const processAndSendZUSD = async (
  destinationChainSelector,
  receiverOnDestChain,
  amount
) => {
  if (!walletAddress || !signer) {
    toast.error('Missing wallet connection');
    return null;
  }

  if (!destinationChainSelector || !receiverOnDestChain || !amount) {
    toast.error('Missing input values');
    return null;
  }

  try {
    const zusdContract = zusd(signer);
    const cossXContract = zephyraCrossChain(signer);

    const decimals = await zusdContract.decimals();
    const amountWei = ethers.parseUnits(String(amount), decimals);

    const currentAllowance = await zusdContract.allowance(walletAddress, ZUSD_CCIP_PROCESSING_CONTRACT);

    if (currentAllowance < amountWei) {
      const toastId = toast.loading('Approving ZUSD...');
      const approvalTx = await zusdContract.approve(ZUSD_CCIP_PROCESSING_CONTRACT, amountWei);
      await approvalTx.wait();
      toast.dismiss(toastId);
      toast.success('ZUSD approved!');
    }

    const toastId = toast.loading('Processing and forwarding ZUSD...');
    const tx = await cossXContract.processAndSend(
      destinationChainSelector,
      receiverOnDestChain,
      amountWei
    );
    const receipt = await tx.wait();
    toast.dismiss(toastId);
    toast.success('ZUSD sent cross-chain!');

    return { tx, receipt, hash: tx.hash };

  } catch (err) {
    console.error(err);
    toast.error('Cross-chain transfer failed. Check inputs and approval.');
    return null;
  }
};



















// --------------------------------------------------------------------------------
// Get ZUSD Balance
// --------------------------------------------------------------------------------

const getZusdBalance = async () => {
  if (!walletAddress || !signer) {
    toast.error('Missing wallet connection');
    return null;
  }

  try {
    const zusdContract = zusd(signer);
    const balance = await zusdContract.balanceOf(walletAddress);
    const formatted = Number(ethers.formatUnits(balance, 18));
    return formatted;
  } catch (err) {
    console.error('Error fetching ZUSD balance:', err);
    toast.error('Failed to fetch ZUSD balance');
    return null;
  }
};


















    // -----------------------------------------------------------------------------------------------
    // Connect Wallet
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
        mintZusd,
        burnZusd,
        redeemCollateral,
        getAllUsersData,
        liquidateUser,
        tryLuck,
        getAllPlayers,
        getRecentWinner,
        getWinnerTokenId,
        processAndSendZUSD,
        getZusdBalance,
        getRaffleState,
        getUserNFTs,
      }}
    >
      {children}
    </ZephyraContext.Provider>
  );
};

// 🔄 Export hook to access context
export const useZephyra = () => useContext(ZephyraContext);
