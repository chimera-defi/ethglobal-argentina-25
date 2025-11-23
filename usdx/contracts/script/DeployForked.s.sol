// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script, console2} from "forge-std/Script.sol";
import {USDXToken} from "../contracts/USDXToken.sol";
import {USDXVault} from "../contracts/USDXVault.sol";
import {USDXSpokeMinter} from "../contracts/USDXSpokeMinter.sol";
import {USDXShareOFT} from "../contracts/USDXShareOFT.sol";
import {USDXYearnVaultWrapper} from "../contracts/USDXYearnVaultWrapper.sol";
import {USDXShareOFTAdapter} from "../contracts/USDXShareOFTAdapter.sol";
import {USDXVaultComposerSync} from "../contracts/USDXVaultComposerSync.sol";
import {MockUSDC} from "../contracts/mocks/MockUSDC.sol";
import {MockYearnVault} from "../contracts/mocks/MockYearnVault.sol";
import {MockLayerZeroEndpoint} from "../contracts/mocks/MockLayerZeroEndpoint.sol";
import {LayerZeroConfig} from "./config/LayerZeroConfig.s.sol";

/**
 * @title DeployForked
 * @notice Deploys complete USDX protocol to forked mainnet for local testing
 * @dev Run with: forge script script/DeployForked.s.sol:DeployForked --fork-url $MAINNET_RPC_URL --broadcast
 */
contract DeployForked is Script {
    // Roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant POSITION_UPDATER_ROLE = keccak256("POSITION_UPDATER_ROLE");
    
    // Deployment state
    struct DeploymentState {
        address deployer;
        MockUSDC usdc;
        MockYearnVault yearnVault;
        MockLayerZeroEndpoint hubLzEndpoint;
        MockLayerZeroEndpoint spokeLzEndpoint;
        uint32 hubEid;
        uint32 spokeEid;
        USDXToken hubUSDX;
        USDXVault vault;
        USDXYearnVaultWrapper vaultWrapper;
        USDXShareOFTAdapter shareOFTAdapter;
        USDXVaultComposerSync composer;
        USDXToken spokeUSDX;
        USDXShareOFT shareOFT;
        USDXSpokeMinter spokeMinter;
    }
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n========================================");
        console2.log("  USDX Protocol - Forked Network Deploy");
        console2.log("========================================\n");
        
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);
        console2.log("Block Number:", block.number);
        
        vm.startBroadcast(deployerPrivateKey);
        
        DeploymentState memory state;
        state.deployer = deployer;
        state.hubEid = LayerZeroConfig.getEid(block.chainid);
        state.spokeEid = LayerZeroConfig.EID_POLYGON_MAINNET;
        
        state = deployMocks(state);
        state = deployHubContracts(state);
        state = deploySpokeContracts(state);
        configureCrossChain(state);
        
        vm.stopBroadcast();
        
        printSummary(state);
    }
    
    function deployMocks(DeploymentState memory state) internal returns (DeploymentState memory) {
        console2.log("\n--- Deploying Mock Contracts ---");
        
        state.usdc = new MockUSDC();
        console2.log("MockUSDC:", address(state.usdc));
        
        state.yearnVault = new MockYearnVault(address(state.usdc));
        console2.log("MockYearnVault:", address(state.yearnVault));
        
        state.hubLzEndpoint = new MockLayerZeroEndpoint(state.hubEid);
        console2.log("MockLayerZeroEndpoint (Hub):", address(state.hubLzEndpoint));
        console2.log("Hub EID:", state.hubEid);
        
        state.usdc.mint(state.deployer, 1_000_000 * 10**6);
        console2.log("Minted 1,000,000 USDC to deployer");
        
        return state;
    }
    
    function deployHubContracts(DeploymentState memory state) internal returns (DeploymentState memory) {
        console2.log("\n--- Deploying Hub Chain (Ethereum) ---");
        
        state.hubUSDX = new USDXToken(state.deployer);
        console2.log("HubUSDX:", address(state.hubUSDX));
        
        state.vault = new USDXVault(
            address(state.usdc),
            address(state.hubUSDX),
            state.deployer,
            state.deployer,
            address(0),
            address(0),
            address(0)
        );
        console2.log("HubVault:", address(state.vault));
        
        console2.log("\n--- Deploying OVault Components ---");
        
        state.vaultWrapper = new USDXYearnVaultWrapper(
            address(state.usdc),
            address(state.yearnVault),
            "USDX Yearn Wrapper",
            "USDX-YV"
        );
        console2.log("USDXYearnVaultWrapper:", address(state.vaultWrapper));
        
        state.shareOFTAdapter = new USDXShareOFTAdapter(
            address(state.vaultWrapper),
            address(state.hubLzEndpoint),
            state.hubEid,
            state.deployer
        );
        console2.log("USDXShareOFTAdapter:", address(state.shareOFTAdapter));
        
        state.composer = new USDXVaultComposerSync(
            address(state.vaultWrapper),
            address(state.shareOFTAdapter),
            address(state.usdc),
            address(state.hubLzEndpoint),
            state.hubEid,
            state.deployer
        );
        console2.log("USDXVaultComposerSync:", address(state.composer));
        
        state.hubUSDX.grantRole(MINTER_ROLE, address(state.vault));
        state.hubUSDX.grantRole(BURNER_ROLE, address(state.vault));
        console2.log("Granted vault roles on HubUSDX");
        
        state.vault.setYearnVault(address(state.yearnVault));
        console2.log("Set Yearn vault on HubVault");
        
        state.vault.setOVaultComposer(address(state.composer));
        state.vault.setShareOFTAdapter(address(state.shareOFTAdapter));
        state.vault.setVaultWrapper(address(state.vaultWrapper));
        console2.log("Set OVault components on HubVault");
        
        return state;
    }
    
    function deploySpokeContracts(DeploymentState memory state) internal returns (DeploymentState memory) {
        console2.log("\n--- Deploying Spoke Chain (Simulated) ---");
        
        state.spokeLzEndpoint = new MockLayerZeroEndpoint(state.spokeEid);
        console2.log("MockLayerZeroEndpoint (Spoke):", address(state.spokeLzEndpoint));
        console2.log("Spoke EID:", state.spokeEid);
        
        state.spokeUSDX = new USDXToken(state.deployer);
        console2.log("SpokeUSDX:", address(state.spokeUSDX));
        
        state.shareOFT = new USDXShareOFT(
            "USDX Vault Shares",
            "USDX-SHARES",
            address(state.spokeLzEndpoint),
            state.spokeEid,
            state.deployer
        );
        console2.log("USDXShareOFT:", address(state.shareOFT));
        
        state.spokeMinter = new USDXSpokeMinter(
            address(state.spokeUSDX),
            address(state.shareOFT),
            address(state.spokeLzEndpoint),
            state.hubEid,
            state.deployer
        );
        console2.log("SpokeMinter:", address(state.spokeMinter));
        
        state.spokeUSDX.grantRole(MINTER_ROLE, address(state.spokeMinter));
        state.spokeUSDX.grantRole(BURNER_ROLE, address(state.spokeMinter));
        state.shareOFT.setMinter(address(state.composer));
        console2.log("Granted minter roles on SpokeUSDX");
        
        return state;
    }
    
    function configureCrossChain(DeploymentState memory state) internal {
        state.hubLzEndpoint.setRemoteContract(state.spokeEid, address(state.spokeLzEndpoint));
        state.spokeLzEndpoint.setRemoteContract(state.hubEid, address(state.hubLzEndpoint));
        console2.log("Configured cross-chain endpoints");
        
        bytes32 spokeShareOFTPeer = bytes32(uint256(uint160(address(state.shareOFT))));
        
        state.composer.setTrustedRemote(state.spokeEid, spokeShareOFTPeer);
        state.shareOFTAdapter.setTrustedRemote(state.spokeEid, spokeShareOFTPeer);
        state.shareOFT.setTrustedRemote(state.hubEid, bytes32(uint256(uint160(address(state.shareOFTAdapter)))));
        console2.log("Set trusted remotes for cross-chain communication");
        
        state.hubLzEndpoint.setRemoteContract(state.spokeEid, address(state.shareOFT));
        state.spokeLzEndpoint.setRemoteContract(state.hubEid, address(state.shareOFTAdapter));
        console2.log("Configured mock endpoint routing");
    }
    
    function printSummary(DeploymentState memory state) internal view {
        console2.log("\n========================================");
        console2.log("  Deployment Complete!");
        console2.log("========================================\n");
        
        console2.log("Mock Contracts:");
        console2.log("  USDC:", address(state.usdc));
        console2.log("  Yearn Vault:", address(state.yearnVault));
        
        console2.log("\nHub Chain (Ethereum):");
        console2.log("  USDX Token:", address(state.hubUSDX));
        console2.log("  USDX Vault:", address(state.vault));
        console2.log("  USDXYearnVaultWrapper:", address(state.vaultWrapper));
        console2.log("  USDXShareOFTAdapter:", address(state.shareOFTAdapter));
        console2.log("  USDXVaultComposerSync:", address(state.composer));
        console2.log("  MockLayerZeroEndpoint:", address(state.hubLzEndpoint));
        
        console2.log("\nSpoke Chain (Simulated):");
        console2.log("  USDX Token:", address(state.spokeUSDX));
        console2.log("  USDXShareOFT:", address(state.shareOFT));
        console2.log("  Spoke Minter:", address(state.spokeMinter));
        console2.log("  MockLayerZeroEndpoint:", address(state.spokeLzEndpoint));
        
        console2.log("\nTest Accounts:");
        console2.log("  Deployer/Admin:", state.deployer);
        console2.log("  Treasury:", state.deployer);
        
        console2.log("\n========================================");
        console2.log("  Ready for Frontend Development!");
        console2.log("========================================\n");
    }
}
