# LayerZero OVault Integration Examples for USDX

This document provides practical code examples for integrating LayerZero OVault with USDX. All examples are based on the comprehensive understanding of OVault architecture and USDX's hub-and-spoke model.

## Table of Contents

1. [Smart Contract Examples](#smart-contract-examples)
2. [Integration Examples](#integration-examples)
3. [Frontend Integration Examples](#frontend-integration-examples)
4. [Testing Examples](#testing-examples)
5. [Complete User Flow Examples](#complete-user-flow-examples)

---

## Smart Contract Examples

### Example 1: USDXYearnVaultWrapper Contract

Complete ERC-4626 wrapper for Yearn USDC vault:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

interface IYearnVault {
    function deposit(uint256 amount) external returns (uint256);
    function withdraw(uint256 shares) external returns (uint256);
    function pricePerShare() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/**
 * @title USDXYearnVaultWrapper
 * @notice ERC-4626 wrapper for Yearn USDC vault, enabling OVault integration
 * @dev This contract wraps Yearn vault to make it ERC-4626 compatible for OVault
 */
contract USDXYearnVaultWrapper is ERC4626, Ownable, ReentrancyGuard, Pausable {
    IYearnVault public immutable yearnVault;
    IERC20 public immutable asset; // USDC

    constructor(
        address _asset, // USDC address
        address _yearnVault, // Yearn USDC vault address
        string memory _name,
        string memory _symbol
    ) ERC4626(IERC20(_asset)) Ownable(msg.sender) {
        require(_asset != address(0), "Invalid asset");
        require(_yearnVault != address(0), "Invalid yearn vault");
        
        asset = IERC20(_asset);
        yearnVault = IYearnVault(_yearnVault);
        
        // Approve Yearn vault to spend USDC
        IERC20(_asset).approve(_yearnVault, type(uint256).max);
    }

    /**
     * @notice Deposit assets into Yearn vault and mint shares
     * @param assets Amount of assets to deposit
     * @param receiver Address to receive shares
     * @return shares Amount of shares minted
     */
    function deposit(uint256 assets, address receiver)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        require(assets > 0, "Amount must be greater than zero");
        require(receiver != address(0), "Invalid receiver");

        // Transfer assets from user
        asset.transferFrom(msg.sender, address(this), assets);

        // Deposit into Yearn vault
        uint256 yearnShares = yearnVault.deposit(assets);

        // Mint ERC-4626 shares to receiver
        shares = _convertToShares(yearnShares, Math.Rounding.Down);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice Redeem shares for underlying assets
     * @param shares Amount of shares to redeem
     * @param receiver Address to receive assets
     * @param owner Address that owns the shares
     * @return assets Amount of assets withdrawn
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256 assets)
    {
        require(shares > 0, "Shares must be greater than zero");
        require(receiver != address(0), "Invalid receiver");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        // Burn shares
        _burn(owner, shares);

        // Convert shares to Yearn shares
        uint256 yearnShares = _convertToAssets(shares, Math.Rounding.Down);

        // Withdraw from Yearn vault
        assets = yearnVault.withdraw(yearnShares);

        // Transfer assets to receiver
        asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /**
     * @notice Total assets managed by vault
     * @return Total assets in Yearn vault
     */
    function totalAssets() public view override returns (uint256) {
        return yearnVault.totalAssets();
    }

    /**
     * @notice Convert assets to shares
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return assets;
        }
        return assets.mulDiv(supply, totalAssets(), rounding);
    }

    /**
     * @notice Convert shares to assets
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding)
        internal
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply();
        if (supply == 0) {
            return shares;
        }
        return shares.mulDiv(totalAssets(), supply, rounding);
    }

    /**
     * @notice Pause contract (emergency only)
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}
```

### Example 2: USDXShareOFTAdapter Contract

OFTAdapter for transforming vault shares to OFT on hub chain:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OFTAdapter} from "@layerzerolabs/oft-evm/contracts/OFTAdapter.sol";
import {IUSDXYearnVaultWrapper} from "../interfaces/IUSDXYearnVaultWrapper.sol";

/**
 * @title USDXShareOFTAdapter
 * @notice OFTAdapter for USDX vault shares on hub chain
 * @dev Transforms ERC-4626 vault shares into omnichain fungible tokens
 */
contract USDXShareOFTAdapter is OFTAdapter {
    IUSDXYearnVaultWrapper public immutable vault;

    constructor(
        address _vault, // USDXYearnVaultWrapper address
        address _lzEndpoint, // LayerZero endpoint
        address _delegate // Owner address
    ) OFTAdapter(
        _vault,
        _lzEndpoint,
        _delegate
    ) {
        require(_vault != address(0), "Invalid vault");
        vault = IUSDXYearnVaultWrapper(_vault);
    }

    /**
     * @notice Get the underlying vault address
     */
    function getVault() external view returns (address) {
        return address(vault);
    }
}
```

### Example 3: USDXVaultComposerSync Contract

Composer for orchestrating OVault operations:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {VaultComposerSync} from "@layerzerolabs/ovault-evm/contracts/VaultComposerSync.sol";
import {IUSDXYearnVaultWrapper} from "../interfaces/IUSDXYearnVaultWrapper.sol";
import {IUSDXShareOFTAdapter} from "../interfaces/IUSDXShareOFTAdapter.sol";
import {IOFT} from "@layerzerolabs/oft-evm/contracts/interfaces/IOFT.sol";

/**
 * @title USDXVaultComposerSync
 * @notice Composer for orchestrating USDX OVault operations
 * @dev Handles cross-chain deposits and redemptions
 */
contract USDXVaultComposerSync is VaultComposerSync {
    IUSDXYearnVaultWrapper public immutable vault;
    IUSDXShareOFTAdapter public immutable shareOFT;
    IOFT public immutable assetOFT;

    constructor(
        address _vault,
        address _shareOFT,
        address _assetOFT,
        address _lzEndpoint,
        address _delegate
    ) VaultComposerSync(
        _vault,
        _shareOFT,
        _assetOFT,
        _lzEndpoint,
        _delegate
    ) {
        require(_vault != address(0), "Invalid vault");
        require(_shareOFT != address(0), "Invalid share OFT");
        require(_assetOFT != address(0), "Invalid asset OFT");
        
        vault = IUSDXYearnVaultWrapper(_vault);
        shareOFT = IUSDXShareOFTAdapter(_shareOFT);
        assetOFT = IOFT(_assetOFT);
    }

    /**
     * @notice Get vault address
     */
    function getVault() external view returns (address) {
        return address(vault);
    }

    /**
     * @notice Get share OFT address
     */
    function getShareOFT() external view returns (address) {
        return address(shareOFT);
    }

    /**
     * @notice Get asset OFT address
     */
    function getAssetOFT() external view returns (address) {
        return address(assetOFT);
    }
}
```

### Example 4: USDXShareOFT Contract (Spoke Chains)

Standard OFT for vault shares on spoke chains:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {OFT} from "@layerzerolabs/oft-evm/contracts/OFT.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title USDXShareOFT
 * @notice OFT representation of USDX vault shares on spoke chains
 * @dev This contract represents OVault shares on spoke chains
 */
contract USDXShareOFT is OFT, Ownable {
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        address _delegate
    ) OFT(_name, _symbol, _lzEndpoint, _delegate) Ownable(_delegate) {
        // WARNING: Do NOT mint share tokens directly
        // Share tokens should only be minted by the vault contract during deposits
        // to maintain the correct relationship between shares and underlying assets
    }

    /**
     * @notice Pause transfers (emergency only)
     */
    function pause() external onlyOwner {
        // Implementation depends on OFT version
        // May need to override if pause functionality is needed
    }
}
```

### Example 5: Updated USDXVault Integration

Integration of USDXVault with OVault:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUSDXVaultComposerSync} from "../interfaces/IUSDXVaultComposerSync.sol";
import {IUSDXShareOFTAdapter} from "../interfaces/IUSDXShareOFTAdapter.sol";
import {IUSDXYearnVaultWrapper} from "../interfaces/IUSDXYearnVaultWrapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title USDXVault
 * @notice Main vault contract integrating with OVault
 * @dev Manages USDC deposits and USDX minting via OVault
 */
contract USDXVault is Ownable, ReentrancyGuard {
    IUSDXVaultComposerSync public ovaultComposer;
    IUSDXShareOFTAdapter public shareOFTAdapter;
    IUSDXYearnVaultWrapper public vaultWrapper;
    IERC20 public usdc;
    IERC20 public usdxToken;

    mapping(address => uint256) public userOVaultShares;
    uint256 shares
    uint256 public totalCollateral;
    uint256 public totalUSDXMinted;

    event Deposit(address indexed user, uint256 usdcAmount, uint256 shares);
    event Withdrawal(address indexed user, uint256 usdxAmount, uint256 usdcAmount);
    event OVaultSharesUpdated(address indexed user, uint256 shares);

    constructor(
        address _usdc,
        address _usdxToken,
        address _vaultWrapper,
        address _shareOFTAdapter,
        address _ovaultComposer
    ) Ownable(msg.sender) {
        require(_usdc != address(0), "Invalid USDC");
        require(_usdxToken != address(0), "Invalid USDX token");
        require(_vaultWrapper != address(0), "Invalid vault wrapper");
        require(_shareOFTAdapter != address(0), "Invalid share OFT adapter");
        require(_ovaultComposer != address(0), "Invalid composer");

        usdc = IERC20(_usdc);
        usdxToken = IERC20(_usdxToken);
        vaultWrapper = IUSDXYearnVaultWrapper(_vaultWrapper);
        shareOFTAdapter = IUSDXShareOFTAdapter(_shareOFTAdapter);
        ovaultComposer = IUSDXVaultComposerSync(_ovaultComposer);

        // Approve vault wrapper to spend USDC
        usdc.approve(address(_vaultWrapper), type(uint256).max);
    }

    /**
     * @notice Deposit USDC and receive OVault shares
     * @param amount Amount of USDC to deposit
     * @return shares Amount of OVault shares received
     */
    function depositUSDC(uint256 amount)
        external
        nonReentrant
        returns (uint256 shares)
    {
        require(amount > 0, "Amount must be greater than zero");

        // Transfer USDC from user
        usdc.transferFrom(msg.sender, address(this), amount);

        // Deposit into vault wrapper (which deposits into Yearn)
        shares = vaultWrapper.deposit(amount, address(this));

        // Update user's OVault shares
        userOVaultShares[msg.sender] += shares;
        totalCollateral += amount;

        emit Deposit(msg.sender, amount, shares);
        emit OVaultSharesUpdated(msg.sender, userOVaultShares[msg.sender]);

        return shares;
    }

    /**
     * @notice Get user's OVault shares
     * @param user User address
     * @return shares Amount of OVault shares
     */
    function getUserOVaultShares(address user)
        external
        view
        returns (uint256 shares)
    {
        return userOVaultShares[user];
    }

    /**
     * @notice Get total collateral
     * @return Total USDC collateral
     */
    function getTotalCollateral() external view returns (uint256) {
        return totalCollateral;
    }

    /**
     * @notice Get collateral ratio (should be 1:1)
     * @return ratio Collateral ratio (1e6 = 1.0)
     */
    function getCollateralRatio() external view returns (uint256 ratio) {
        if (totalUSDXMinted == 0) {
            return 1e6; // 1:1
        }
        return (totalCollateral * 1e6) / totalUSDXMinted;
    }
}
```

### Example 6: Updated USDXSpokeMinter Integration

Minting USDX on spoke chains using OVault shares:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IUSDXShareOFT} from "../interfaces/IUSDXShareOFT.sol";
import {IUSDXToken} from "../interfaces/IUSDXToken.sol";
import {IOApp} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title USDXSpokeMinter
 * @notice Allows minting USDX on spoke chains using OVault shares
 * @dev Verifies user's OVault position on hub chain and mints USDX
 */
contract USDXSpokeMinter is OApp, Ownable {
    IUSDXShareOFT public shareOFT;
    IUSDXToken public usdxToken;
    uint16 public hubChainId; // Ethereum = 101

    mapping(address => uint256) public mintedUSDX; // Track minted USDX per user

    event USDXMinted(address indexed user, uint256 shares, uint256 usdxAmount);

    constructor(
        address _shareOFT,
        address _usdxToken,
        address _endpoint,
        address _owner,
        uint16 _hubChainId
    ) OApp(_endpoint, _owner) Ownable(_owner) {
        require(_shareOFT != address(0), "Invalid share OFT");
        require(_usdxToken != address(0), "Invalid USDX token");
        
        shareOFT = IUSDXShareOFT(_shareOFT);
        usdxToken = IUSDXToken(_usdxToken);
        hubChainId = _hubChainId;
    }

    /**
     * @notice Mint USDX using OVault shares
     * @param ovaultShares Amount of OVault shares to use
     * @return usdxAmount Amount of USDX minted
     */
    function mintUSDXFromOVault(uint256 ovaultShares)
        external
        returns (uint256 usdxAmount)
    {
        require(ovaultShares > 0, "Shares must be greater than zero");

        // Check user has OVault shares on this chain
        uint256 userShares = shareOFT.balanceOf(msg.sender);
        require(userShares >= ovaultShares, "Insufficient OVault shares");

        // Calculate USDC value of shares
        // Note: This requires cross-chain query or local calculation
        // For simplicity, assuming 1:1 ratio (should be calculated from vault)
        usdxAmount = ovaultShares; // 1 share = 1 USDX (simplified)

        // Transfer shares from user (will be burned or locked)
        shareOFT.transferFrom(msg.sender, address(this), ovaultShares);

        // Mint USDX to user
        usdxToken.mint(msg.sender, usdxAmount);

        // Track minted USDX
        mintedUSDX[msg.sender] += usdxAmount;

        emit USDXMinted(msg.sender, ovaultShares, usdxAmount);

        return usdxAmount;
    }

    /**
     * @notice Get minted USDX for user
     * @param user User address
     * @return Amount of USDX minted
     */
    function getMintedUSDX(address user) external view returns (uint256) {
        return mintedUSDX[user];
    }
}
```

---

## Integration Examples

### Example 7: Complete Deposit Flow (TypeScript)

Complete deposit flow from frontend:

```typescript
import { ethers } from 'ethers';
import { BridgeKit } from '@circle-fin/bridge-kit';

/**
 * Complete deposit flow: Spoke Chain → Hub Chain → OVault → Shares
 */
async function depositUSDCAndGetOVaultShares(
  userAddress: string,
  usdcAmount: string,
  sourceChain: string, // e.g., 'polygon'
  hubChain: string = 'ethereum'
) {
  // Step 1: Bridge USDC from Spoke to Hub using Bridge Kit
  const bridgeKit = new BridgeKit({
    sourceChain,
    destinationChain: hubChain,
  });

  console.log('Step 1: Bridging USDC via Bridge Kit...');
  const bridgeTransfer = await bridgeKit.transfer({
    amount: usdcAmount,
    recipient: USDX_VAULT_ADDRESS, // USDXVault on hub chain
    onStatusUpdate: (status) => {
      console.log(`Bridge status: ${status}`);
    },
  });

  // Wait for bridge completion
  await waitForBridgeCompletion(bridgeTransfer.id);

  // Step 2: Deposit USDC into USDXVault on Hub Chain
  console.log('Step 2: Depositing USDC into USDXVault...');
  const hubProvider = new ethers.JsonRpcProvider(HUB_CHAIN_RPC);
  const vaultContract = new ethers.Contract(
    USDX_VAULT_ADDRESS,
    USDX_VAULT_ABI,
    hubProvider
  );

  const signer = await hubProvider.getSigner(userAddress);
  const vaultWithSigner = vaultContract.connect(signer);

  const depositTx = await vaultWithSigner.depositUSDC(usdcAmount);
  const depositReceipt = await depositTx.wait();

  // Get shares from event
  const depositEvent = depositReceipt.logs.find(
    (log: any) => log.eventName === 'Deposit'
  );
  const shares = depositEvent.args.shares;

  console.log(`Received ${shares.toString()} OVault shares`);

  // Step 3: Shares are now available on Hub Chain
  // User can mint USDX on any spoke chain using these shares
  return {
    shares: shares.toString(),
    transactionHash: depositReceipt.hash,
  };
}

/**
 * Helper: Wait for bridge completion
 */
async function waitForBridgeCompletion(transferId: string): Promise<void> {
  // Poll bridge status until completed
  // Implementation depends on Bridge Kit SDK
  return new Promise((resolve) => {
    const interval = setInterval(async () => {
      const status = await checkBridgeStatus(transferId);
      if (status === 'completed') {
        clearInterval(interval);
        resolve();
      }
    }, 5000);
  });
}
```

### Example 8: Cross-Chain Share Transfer

Transfer OVault shares from Hub to Spoke chain:

```typescript
import { ethers } from 'ethers';
import { ComposerMessageBuilder } from '@layerzerolabs/ovault-evm';

/**
 * Transfer OVault shares from Hub Chain to Spoke Chain
 */
async function transferSharesToSpoke(
  userAddress: string,
  shares: string,
  hubChainId: number, // Ethereum = 101
  spokeChainId: number, // Polygon = 109
  spokeAddress: string
) {
  // Get share OFT adapter on hub chain
  const hubProvider = new ethers.JsonRpcProvider(HUB_CHAIN_RPC);
  const shareOFTAdapter = new ethers.Contract(
    SHARE_OFT_ADAPTER_ADDRESS,
    SHARE_OFT_ADAPTER_ABI,
    hubProvider
  );

  const signer = await hubProvider.getSigner(userAddress);
  const adapterWithSigner = shareOFTAdapter.connect(signer);

  // Build composer message for cross-chain transfer
  const composerMsg = ComposerMessageBuilder.buildTransferMessage({
    destinationChain: spokeChainId,
    destinationAddress: spokeAddress,
    shares: shares,
  });

  // Estimate fees
  const fees = await adapterWithSigner.estimateSendFee(
    spokeChainId,
    shares,
    composerMsg,
    false,
    '0x'
  );

  // Send shares cross-chain
  const tx = await adapterWithSigner.send(
    spokeChainId,
    shares,
    composerMsg,
    {
      value: fees.nativeFee,
    }
  );

  const receipt = await tx.wait();
  console.log(`Shares sent: ${receipt.hash}`);

  return receipt.hash;
}
```

### Example 9: Mint USDX on Spoke Chain

Mint USDX using OVault shares on spoke chain:

```typescript
/**
 * Mint USDX on Spoke Chain using OVault shares
 */
async function mintUSDXOnSpoke(
  userAddress: string,
  ovaultShares: string,
  spokeChain: string
) {
  const spokeProvider = new ethers.JsonRpcProvider(SPOKE_CHAIN_RPC[spokeChain]);
  const spokeMinter = new ethers.Contract(
    USDX_SPOKE_MINTER_ADDRESS,
    USDX_SPOKE_MINTER_ABI,
    spokeProvider
  );

  const signer = await spokeProvider.getSigner(userAddress);
  const minterWithSigner = spokeMinter.connect(signer);

  // Check user has shares on spoke chain
  const shareOFT = new ethers.Contract(
    SHARE_OFT_ADDRESS,
    SHARE_OFT_ABI,
    spokeProvider
  );
  const userShares = await shareOFT.balanceOf(userAddress);
  
  if (userShares < BigInt(ovaultShares)) {
    throw new Error('Insufficient OVault shares on spoke chain');
  }

  // Mint USDX
  const tx = await minterWithSigner.mintUSDXFromOVault(ovaultShares);
  const receipt = await tx.wait();

  // Get minted amount from event
  const mintEvent = receipt.logs.find(
    (log: any) => log.eventName === 'USDXMinted'
  );
  const usdxAmount = mintEvent.args.usdxAmount;

  console.log(`Minted ${usdxAmount.toString()} USDX`);

  return {
    usdxAmount: usdxAmount.toString(),
    transactionHash: receipt.hash,
  };
}
```

---

## Frontend Integration Examples

### Example 10: React Hook for OVault Operations

React hook for OVault operations:

```typescript
// hooks/useOVault.ts
import { useState, useEffect } from 'react';
import { useAccount, useChainId, useWriteContract, useReadContract } from 'wagmi';
import { parseUnits, formatUnits } from 'viem';

export function useOVault() {
  const { address } = useAccount();
  const chainId = useChainId();
  const [shares, setShares] = useState<bigint>(0n);
  const [loading, setLoading] = useState(false);

  // Read user's OVault shares
  const { data: userShares, refetch: refetchShares } = useReadContract({
    address: SHARE_OFT_ADDRESS,
    abi: SHARE_OFT_ABI,
    functionName: 'balanceOf',
    args: [address],
    query: {
      enabled: !!address,
    },
  });

  // Read USDX balance
  const { data: usdxBalance } = useReadContract({
    address: USDX_TOKEN_ADDRESS,
    abi: USDX_TOKEN_ABI,
    functionName: 'balanceOf',
    args: [address],
    query: {
      enabled: !!address,
    },
  });

  // Write: Mint USDX from OVault shares
  const { writeContract: mintUSDX, isPending: isMinting } = useWriteContract();

  // Write: Transfer shares cross-chain
  const { writeContract: transferShares, isPending: isTransferring } = useWriteContract();

  useEffect(() => {
    if (userShares) {
      setShares(userShares as bigint);
    }
  }, [userShares]);

  const mintUSDXFromShares = async (sharesAmount: string) => {
    if (!address) throw new Error('Not connected');

    try {
      setLoading(true);
      await mintUSDX({
        address: USDX_SPOKE_MINTER_ADDRESS,
        abi: USDX_SPOKE_MINTER_ABI,
        functionName: 'mintUSDXFromOVault',
        args: [parseUnits(sharesAmount, 18)],
      });
      await refetchShares();
    } catch (error) {
      console.error('Error minting USDX:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  const transferSharesCrossChain = async (
    sharesAmount: string,
    destinationChainId: number,
    destinationAddress: string
  ) => {
    if (!address) throw new Error('Not connected');

    try {
      setLoading(true);
      // Build composer message
      const composerMsg = buildComposerMessage({
        destinationChain: destinationChainId,
        destinationAddress,
        shares: sharesAmount,
      });

      await transferShares({
        address: SHARE_OFT_ADAPTER_ADDRESS,
        abi: SHARE_OFT_ADAPTER_ABI,
        functionName: 'send',
        args: [
          destinationChainId,
          parseUnits(sharesAmount, 18),
          composerMsg,
        ],
        value: await estimateFees(destinationChainId, sharesAmount),
      });
    } catch (error) {
      console.error('Error transferring shares:', error);
      throw error;
    } finally {
      setLoading(false);
    }
  };

  return {
    shares: shares ? formatUnits(shares, 18) : '0',
    usdxBalance: usdxBalance ? formatUnits(usdxBalance as bigint, 18) : '0',
    loading: loading || isMinting || isTransferring,
    mintUSDXFromShares,
    transferSharesCrossChain,
    refetchShares,
  };
}
```

### Example 11: React Component for OVault Deposit

React component for depositing USDC and getting OVault shares:

```typescript
// components/OVaultDeposit.tsx
import React, { useState } from 'react';
import { useOVault } from '../hooks/useOVault';
import { useBridgeKit } from '../hooks/useBridgeKit';
import { Button, Input, Card } from './ui';

export function OVaultDeposit() {
  const [amount, setAmount] = useState('');
  const { depositUSDC, loading } = useOVault();
  const { bridgeUSDC } = useBridgeKit();

  const handleDeposit = async () => {
    try {
      // Step 1: Bridge USDC to hub chain
      const bridgeResult = await bridgeUSDC({
        amount,
        destinationChain: 'ethereum',
        recipient: USDX_VAULT_ADDRESS,
      });

      // Step 2: Wait for bridge completion
      await waitForBridgeCompletion(bridgeResult.transferId);

      // Step 3: Deposit into vault
      await depositUSDC(amount);
      
      alert('Deposit successful! You now have OVault shares.');
    } catch (error) {
      console.error('Deposit error:', error);
      alert('Deposit failed. Please try again.');
    }
  };

  return (
    <Card>
      <h2>Deposit USDC and Get OVault Shares</h2>
      <Input
        type="number"
        placeholder="Amount (USDC)"
        value={amount}
        onChange={(e) => setAmount(e.target.value)}
      />
      <Button onClick={handleDeposit} disabled={loading || !amount}>
        {loading ? 'Processing...' : 'Deposit'}
      </Button>
    </Card>
  );
}
```

---

## Testing Examples

### Example 12: Foundry Test for USDXYearnVaultWrapper

```solidity
// test/forge/USDXYearnVaultWrapper.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {USDXYearnVaultWrapper} from "../../contracts/USDXYearnVaultWrapper.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract USDXYearnVaultWrapperTest is Test {
    USDXYearnVaultWrapper vaultWrapper;
    IERC20 usdc;
    address yearnVault = address(0x5f18C75AbDAe578b483E5F43f12a39cF75b973a9); // Yearn USDC vault

    address user = address(0x1234);
    uint256 constant DEPOSIT_AMOUNT = 1000e6; // 1000 USDC

    function setUp() public {
        usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC
        vaultWrapper = new USDXYearnVaultWrapper(
            address(usdc),
            yearnVault,
            "USDX Yearn Wrapper",
            "USDX-YV"
        );

        // Give user some USDC
        deal(address(usdc), user, DEPOSIT_AMOUNT * 10);
        vm.prank(user);
        usdc.approve(address(vaultWrapper), type(uint256).max);
    }

    function testDeposit() public {
        vm.prank(user);
        uint256 shares = vaultWrapper.deposit(DEPOSIT_AMOUNT, user);

        assertGt(shares, 0, "Shares should be greater than zero");
        assertEq(vaultWrapper.balanceOf(user), shares, "User should have shares");
    }

    function testRedeem() public {
        // First deposit
        vm.prank(user);
        uint256 shares = vaultWrapper.deposit(DEPOSIT_AMOUNT, user);

        // Then redeem
        vm.prank(user);
        uint256 assets = vaultWrapper.redeem(shares, user, user);

        assertGt(assets, 0, "Assets should be greater than zero");
        assertEq(vaultWrapper.balanceOf(user), 0, "User should have no shares");
    }

    function testTotalAssets() public {
        vm.prank(user);
        vaultWrapper.deposit(DEPOSIT_AMOUNT, user);

        uint256 totalAssets = vaultWrapper.totalAssets();
        assertGt(totalAssets, 0, "Total assets should be greater than zero");
    }
}
```

### Example 13: Hardhat Test for USDXVault Integration

```typescript
// test/hardhat/USDXVault.integration.test.ts
import { expect } from 'chai';
import { ethers } from 'hardhat';
import { USDXVault } from '../../typechain-types';
import { USDXYearnVaultWrapper } from '../../typechain-types';
import { USDXShareOFTAdapter } from '../../typechain-types';
import { USDXVaultComposerSync } from '../../typechain-types';

describe('USDXVault OVault Integration', function () {
  let vault: USDXVault;
  let vaultWrapper: USDXYearnVaultWrapper;
  let shareOFTAdapter: USDXShareOFTAdapter;
  let composer: USDXVaultComposerSync;
  let usdc: any;
  let usdxToken: any;

  const DEPOSIT_AMOUNT = ethers.parseUnits('1000', 6); // 1000 USDC

  beforeEach(async function () {
    // Deploy contracts
    [owner, user] = await ethers.getSigners();

    // Deploy USDC mock
    const USDC = await ethers.getContractFactory('ERC20Mock');
    usdc = await USDC.deploy('USDC', 'USDC', 6);

    // Deploy USDX token
    const USDXToken = await ethers.getContractFactory('USDXToken');
    usdxToken = await USDXToken.deploy();

    // Deploy vault wrapper
    const VaultWrapper = await ethers.getContractFactory('USDXYearnVaultWrapper');
    vaultWrapper = await VaultWrapper.deploy(
      await usdc.getAddress(),
      YEARN_VAULT_ADDRESS,
      'USDX Yearn Wrapper',
      'USDX-YV'
    );

    // Deploy share OFT adapter
    const ShareOFTAdapter = await ethers.getContractFactory('USDXShareOFTAdapter');
    shareOFTAdapter = await ShareOFTAdapter.deploy(
      await vaultWrapper.getAddress(),
      LAYERZERO_ENDPOINT,
      owner.address
    );

    // Deploy composer
    const Composer = await ethers.getContractFactory('USDXVaultComposerSync');
    composer = await Composer.deploy(
      await vaultWrapper.getAddress(),
      await shareOFTAdapter.getAddress(),
      await usdc.getAddress(), // Asset OFT (simplified)
      LAYERZERO_ENDPOINT,
      owner.address
    );

    // Deploy USDXVault
    const Vault = await ethers.getContractFactory('USDXVault');
    vault = await Vault.deploy(
      await usdc.getAddress(),
      await usdxToken.getAddress(),
      await vaultWrapper.getAddress(),
      await shareOFTAdapter.getAddress(),
      await composer.getAddress()
    );

    // Give user USDC
    await usdc.mint(user.address, DEPOSIT_AMOUNT * 10n);
    await usdc.connect(user).approve(await vault.getAddress(), ethers.MaxUint256);
  });

  it('Should deposit USDC and receive OVault shares', async function () {
    const initialShares = await vault.getUserOVaultShares(user.address);

    await vault.connect(user).depositUSDC(DEPOSIT_AMOUNT);

    const finalShares = await vault.getUserOVaultShares(user.address);
    expect(finalShares).to.be.gt(initialShares);
  });

  it('Should update total collateral after deposit', async function () {
    const initialCollateral = await vault.getTotalCollateral();

    await vault.connect(user).depositUSDC(DEPOSIT_AMOUNT);

    const finalCollateral = await vault.getTotalCollateral();
    expect(finalCollateral).to.equal(initialCollateral + DEPOSIT_AMOUNT);
  });

  it('Should maintain 1:1 collateral ratio', async function () {
    await vault.connect(user).depositUSDC(DEPOSIT_AMOUNT);

    const ratio = await vault.getCollateralRatio();
    expect(ratio).to.be.closeTo(ethers.parseUnits('1', 6), ethers.parseUnits('0.01', 6));
  });
});
```

---

## Complete User Flow Examples

### Example 14: End-to-End Flow: Deposit → Mint USDX → Transfer

Complete flow from deposit to USDX usage:

```typescript
/**
 * Complete user flow:
 * 1. Bridge USDC from Polygon to Ethereum
 * 2. Deposit into USDXVault (gets OVault shares)
 * 3. Transfer shares to Arbitrum
 * 4. Mint USDX on Arbitrum
 * 5. Use USDX on Arbitrum
 */
async function completeUserFlow(
  userAddress: string,
  usdcAmount: string
) {
  console.log('=== Complete USDX OVault Flow ===\n');

  // Step 1: Bridge USDC from Polygon to Ethereum
  console.log('Step 1: Bridging USDC from Polygon to Ethereum...');
  const bridgeResult = await bridgeUSDC({
    sourceChain: 'polygon',
    destinationChain: 'ethereum',
    amount: usdcAmount,
    recipient: USDX_VAULT_ADDRESS,
  });
  console.log(`Bridge initiated: ${bridgeResult.transferId}`);

  // Wait for bridge
  await waitForBridgeCompletion(bridgeResult.transferId);
  console.log('✓ USDC bridged to Ethereum\n');

  // Step 2: Deposit USDC into USDXVault
  console.log('Step 2: Depositing USDC into USDXVault...');
  const depositResult = await depositUSDCAndGetOVaultShares(
    userAddress,
    usdcAmount,
    'polygon',
    'ethereum'
  );
  console.log(`✓ Received ${depositResult.shares} OVault shares\n`);

  // Step 3: Transfer shares to Arbitrum
  console.log('Step 3: Transferring OVault shares to Arbitrum...');
  const transferHash = await transferSharesToSpoke(
    userAddress,
    depositResult.shares,
    101, // Ethereum
    110, // Arbitrum
    userAddress // Receive on Arbitrum
  );
  console.log(`✓ Shares transferred: ${transferHash}\n`);

  // Wait for cross-chain message
  await waitForLayerZeroMessage(transferHash);
  console.log('✓ Shares received on Arbitrum\n');

  // Step 4: Mint USDX on Arbitrum
  console.log('Step 4: Minting USDX on Arbitrum...');
  const mintResult = await mintUSDXOnSpoke(
    userAddress,
    depositResult.shares,
    'arbitrum'
  );
  console.log(`✓ Minted ${mintResult.usdxAmount} USDX\n`);

  // Step 5: Use USDX (example: check balance)
  console.log('Step 5: Checking USDX balance...');
  const balance = await getUSDXBalance(userAddress, 'arbitrum');
  console.log(`✓ USDX balance: ${balance}\n`);

  console.log('=== Flow Complete ===');
  return {
    shares: depositResult.shares,
    usdxAmount: mintResult.usdxAmount,
    balance,
  };
}
```

### Example 15: Error Recovery Example

Handling OVault error recovery:

```typescript
/**
 * Example: Recover from failed OVault operation
 */
async function recoverFromFailedOperation(
  operationId: string,
  composerAddress: string
) {
  const hubProvider = new ethers.JsonRpcProvider(HUB_CHAIN_RPC);
  const composer = new ethers.Contract(
    composerAddress,
    COMPOSER_ABI,
    hubProvider
  );

  // Check operation status
  const operation = await composer.getOperation(operationId);
  
  if (operation.status === 'FAILED') {
    // Attempt recovery
    const signer = await hubProvider.getSigner();
    const composerWithSigner = composer.connect(signer);

    try {
      // Refund operation
      const tx = await composerWithSigner.refund(operationId);
      await tx.wait();
      console.log('✓ Operation refunded');
    } catch (error) {
      // If refund fails, try retry
      console.log('Refund failed, attempting retry...');
      const retryTx = await composerWithSigner.retry(operationId);
      await retryTx.wait();
      console.log('✓ Operation retried');
    }
  }
}
```

---

## Summary

These examples demonstrate:

1. **Smart Contract Integration**: Complete contracts for OVault integration
2. **Cross-Chain Flows**: Deposit, transfer, and mint operations
3. **Frontend Integration**: React hooks and components
4. **Testing**: Foundry and Hardhat test examples
5. **Complete Flows**: End-to-end user journeys
6. **Error Handling**: Recovery mechanisms

All examples are designed to work together and integrate properly with USDX's hub-and-spoke architecture. They follow best practices for security, gas optimization, and user experience.
