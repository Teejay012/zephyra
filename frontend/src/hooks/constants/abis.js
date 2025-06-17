import zephyraVault from '@/hooks/abis/ZephyraVaultABI.json';

export const zephyraVaultABI = zephyraVault.abi;

export const ERC20_ABI = [
  // Only the functions you need
  "function approve(address spender, uint256 amount) external returns (bool)",
  "function allowance(address owner, address spender) view returns (uint256)",
  "function transferFrom(address from, address to, uint256 amount) external returns (bool)",
  "function balanceOf(address account) view returns (uint256)",
  "function decimals() view returns (uint8)",
];