import { Contract } from 'ethers';

export const fetchContract = (address, abi, signerOrProvider) => {
  if (!signerOrProvider) throw new Error('No signer or provider available');
  return new Contract(address, abi, signerOrProvider);
};
