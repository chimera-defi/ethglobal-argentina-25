// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title LayerZeroConfig
 * @notice LayerZero V2 endpoint addresses for various networks
 * @dev Source: https://docs.layerzero.network/v2/developers/evm/technical-reference/deployed-contracts
 */
library LayerZeroConfig {
    // ============ Mainnet Endpoints ============
    
    address internal constant ETHEREUM_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant POLYGON_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant BASE_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant ARBITRUM_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant OPTIMISM_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant AVALANCHE_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant BNB_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    
    // ============ Testnet Endpoints ============
    
    address public constant SEPOLIA_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant AMOY_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant BASE_SEPOLIA_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant ARBITRUM_SEPOLIA_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant OPTIMISM_SEPOLIA_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant AVALANCHE_FUJI_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant BNB_TESTNET_ENDPOINT = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    
    // ============ Endpoint IDs (EIDs) ============
    
    // Mainnet EIDs
    uint32 public constant ETHEREUM_EID = 30101;
    uint32 public constant POLYGON_EID = 30109;
    uint32 public constant BASE_EID = 30184;
    uint32 public constant ARBITRUM_EID = 30110;
    uint32 public constant OPTIMISM_EID = 30111;
    uint32 public constant AVALANCHE_EID = 30106;
    uint32 public constant BNB_EID = 30102;
    
    // Testnet EIDs
    uint32 public constant SEPOLIA_EID = 40161;
    uint32 public constant AMOY_EID = 40267;
    uint32 public constant BASE_SEPOLIA_EID = 40245;
    uint32 public constant ARBITRUM_SEPOLIA_EID = 40231;
    uint32 public constant OPTIMISM_SEPOLIA_EID = 40232;
    uint32 public constant AVALANCHE_FUJI_EID = 40106;
    uint32 public constant BNB_TESTNET_EID = 40102;
    
    /**
     * @notice Get LayerZero endpoint for a given chain ID
     * @param chainId EVM chain ID
     * @return endpoint LayerZero V2 endpoint address
     */
    function getEndpoint(uint256 chainId) internal pure returns (address endpoint) {
        // Mainnets
        if (chainId == 1) return ETHEREUM_ENDPOINT; // Ethereum
        if (chainId == 137) return POLYGON_ENDPOINT; // Polygon
        if (chainId == 8453) return BASE_ENDPOINT; // Base
        if (chainId == 42161) return ARBITRUM_ENDPOINT; // Arbitrum
        if (chainId == 10) return OPTIMISM_ENDPOINT; // Optimism
        if (chainId == 43114) return AVALANCHE_ENDPOINT; // Avalanche
        if (chainId == 56) return BNB_ENDPOINT; // BNB Chain
        
        // Testnets
        if (chainId == 11155111) return SEPOLIA_ENDPOINT; // Sepolia
        if (chainId == 80002) return AMOY_ENDPOINT; // Polygon Amoy
        if (chainId == 84532) return BASE_SEPOLIA_ENDPOINT; // Base Sepolia
        if (chainId == 421614) return ARBITRUM_SEPOLIA_ENDPOINT; // Arbitrum Sepolia
        if (chainId == 11155420) return OPTIMISM_SEPOLIA_ENDPOINT; // Optimism Sepolia
        if (chainId == 43113) return AVALANCHE_FUJI_ENDPOINT; // Avalanche Fuji
        if (chainId == 97) return BNB_TESTNET_ENDPOINT; // BNB Testnet
        
        revert("Unsupported chain ID");
    }
    
    /**
     * @notice Get LayerZero EID for a given chain ID
     * @param chainId EVM chain ID
     * @return eid LayerZero endpoint ID
     */
    function getEid(uint256 chainId) internal pure returns (uint32 eid) {
        // Mainnets
        if (chainId == 1) return ETHEREUM_EID;
        if (chainId == 137) return POLYGON_EID;
        if (chainId == 8453) return BASE_EID;
        if (chainId == 42161) return ARBITRUM_EID;
        if (chainId == 10) return OPTIMISM_EID;
        if (chainId == 43114) return AVALANCHE_EID;
        if (chainId == 56) return BNB_EID;
        
        // Testnets
        if (chainId == 11155111) return SEPOLIA_EID;
        if (chainId == 80002) return AMOY_EID;
        if (chainId == 84532) return BASE_SEPOLIA_EID;
        if (chainId == 421614) return ARBITRUM_SEPOLIA_EID;
        if (chainId == 11155420) return OPTIMISM_SEPOLIA_EID;
        if (chainId == 43113) return AVALANCHE_FUJI_EID;
        if (chainId == 97) return BNB_TESTNET_EID;
        
        revert("Unsupported chain ID");
    }
}
