// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/**
 * @title LayerZeroConfig
 * @notice Configuration for LayerZero endpoints and EIDs
 * @dev This contract provides LayerZero endpoint addresses and endpoint IDs for all supported networks
 */
library LayerZeroConfig {
    // ============ LayerZero Endpoint Addresses ============
    
    // Mainnet Endpoints
    address public constant LZ_ENDPOINT_ETHEREUM_MAINNET = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant LZ_ENDPOINT_POLYGON_MAINNET = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant LZ_ENDPOINT_ARBITRUM_MAINNET = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant LZ_ENDPOINT_BASE_MAINNET = 0x1a44076050125825900e736c501f859c50fE728c;
    address public constant LZ_ENDPOINT_OPTIMISM_MAINNET = 0x1a44076050125825900e736c501f859c50fE728c;
    
    // Testnet Endpoints
    address public constant LZ_ENDPOINT_ETHEREUM_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant LZ_ENDPOINT_POLYGON_MUMBAI = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant LZ_ENDPOINT_ARBITRUM_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant LZ_ENDPOINT_BASE_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    address public constant LZ_ENDPOINT_OPTIMISM_SEPOLIA = 0x6EDCE65403992e310A62460808c4b910D972f10f;
    
    // ============ Endpoint IDs (EIDs) ============
    
    // Mainnet EIDs
    uint32 public constant EID_ETHEREUM_MAINNET = 30101;
    uint32 public constant EID_POLYGON_MAINNET = 30109;
    uint32 public constant EID_ARBITRUM_MAINNET = 30110;
    uint32 public constant EID_BASE_MAINNET = 30184;
    uint32 public constant EID_OPTIMISM_MAINNET = 30111;
    
    // Testnet EIDs
    uint32 public constant EID_ETHEREUM_SEPOLIA = 40161;
    uint32 public constant EID_POLYGON_MUMBAI = 40109;
    uint32 public constant EID_ARBITRUM_SEPOLIA = 40231;
    uint32 public constant EID_BASE_SEPOLIA = 40245;
    uint32 public constant EID_OPTIMISM_SEPOLIA = 40232;
    
    // ============ Helper Functions ============
    
    /**
     * @notice Get LayerZero endpoint address for a given chain ID
     * @param chainId Chain ID
     * @return endpoint LayerZero endpoint address
     */
    function getEndpoint(uint256 chainId) internal pure returns (address endpoint) {
        if (chainId == 1) {
            return LZ_ENDPOINT_ETHEREUM_MAINNET;
        } else if (chainId == 11155111) {
            return LZ_ENDPOINT_ETHEREUM_SEPOLIA;
        } else if (chainId == 137) {
            return LZ_ENDPOINT_POLYGON_MAINNET;
        } else if (chainId == 80001) {
            return LZ_ENDPOINT_POLYGON_MUMBAI;
        } else if (chainId == 42161) {
            return LZ_ENDPOINT_ARBITRUM_MAINNET;
        } else if (chainId == 421614) {
            return LZ_ENDPOINT_ARBITRUM_SEPOLIA;
        } else if (chainId == 8453) {
            return LZ_ENDPOINT_BASE_MAINNET;
        } else if (chainId == 84532) {
            return LZ_ENDPOINT_BASE_SEPOLIA;
        } else if (chainId == 10) {
            return LZ_ENDPOINT_OPTIMISM_MAINNET;
        } else if (chainId == 11155420) {
            return LZ_ENDPOINT_OPTIMISM_SEPOLIA;
        } else {
            revert("Unsupported chain");
        }
    }
    
    /**
     * @notice Get LayerZero endpoint ID (EID) for a given chain ID
     * @param chainId Chain ID
     * @return eid LayerZero endpoint ID
     */
    function getEid(uint256 chainId) internal pure returns (uint32 eid) {
        if (chainId == 1) {
            return EID_ETHEREUM_MAINNET;
        } else if (chainId == 11155111) {
            return EID_ETHEREUM_SEPOLIA;
        } else if (chainId == 137) {
            return EID_POLYGON_MAINNET;
        } else if (chainId == 80001) {
            return EID_POLYGON_MUMBAI;
        } else if (chainId == 42161) {
            return EID_ARBITRUM_MAINNET;
        } else if (chainId == 421614) {
            return EID_ARBITRUM_SEPOLIA;
        } else if (chainId == 8453) {
            return EID_BASE_MAINNET;
        } else if (chainId == 84532) {
            return EID_BASE_SEPOLIA;
        } else if (chainId == 10) {
            return EID_OPTIMISM_MAINNET;
        } else if (chainId == 11155420) {
            return EID_OPTIMISM_SEPOLIA;
        } else {
            revert("Unsupported chain");
        }
    }
    
    /**
     * @notice Check if LayerZero is supported on a given chain
     * @param chainId Chain ID
     * @return supported True if LayerZero is supported
     */
    function isLayerZeroSupported(uint256 chainId) internal pure returns (bool supported) {
        // Arc Testnet (5042002) does not support LayerZero
        if (chainId == 5042002) {
            return false;
        }
        
        // Check if we have endpoint configuration for this chain
        // Try to get endpoint - if it reverts, LayerZero is not supported
        address endpoint;
        if (chainId == 1) {
            endpoint = LZ_ENDPOINT_ETHEREUM_MAINNET;
        } else if (chainId == 11155111) {
            endpoint = LZ_ENDPOINT_ETHEREUM_SEPOLIA;
        } else if (chainId == 137) {
            endpoint = LZ_ENDPOINT_POLYGON_MAINNET;
        } else if (chainId == 80001) {
            endpoint = LZ_ENDPOINT_POLYGON_MUMBAI;
        } else if (chainId == 42161) {
            endpoint = LZ_ENDPOINT_ARBITRUM_MAINNET;
        } else if (chainId == 421614) {
            endpoint = LZ_ENDPOINT_ARBITRUM_SEPOLIA;
        } else if (chainId == 8453) {
            endpoint = LZ_ENDPOINT_BASE_MAINNET;
        } else if (chainId == 84532) {
            endpoint = LZ_ENDPOINT_BASE_SEPOLIA;
        } else if (chainId == 10) {
            endpoint = LZ_ENDPOINT_OPTIMISM_MAINNET;
        } else if (chainId == 11155420) {
            endpoint = LZ_ENDPOINT_OPTIMISM_SEPOLIA;
        } else {
            return false;
        }
        
        return endpoint != address(0);
    }
}

