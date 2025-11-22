// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";

/**
 * @title USDXToken
 * @author USDX Protocol
 * @notice Cross-chain yield-bearing stablecoin token backed 1:1 by USDC
 * @dev Implements ERC20 with minting/burning, access control, and pausability
 * 
 * Key Features:
 * - 1:1 USDC backing
 * - Cross-chain compatible via LayerZero OFT (Omnichain Fungible Token)
 * - Role-based access control for minting/burning
 * - Emergency pause mechanism
 * - ERC-2612 permit support for gasless approvals
 * - LayerZero integration for decentralized cross-chain transfers
 */
contract USDXToken is ERC20, ERC20Burnable, ERC20Permit, AccessControl, Pausable {
    // ============ Roles ============
    
    /// @notice Role that can mint new tokens
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    
    /// @notice Role that can burn tokens from any address
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    
    /// @notice Role that can pause/unpause the contract
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    
    // ============ LayerZero State ============
    
    /// @notice LayerZero endpoint (optional, for OFT functionality)
    ILayerZeroEndpoint public lzEndpoint;
    
    /// @notice Local endpoint ID
    uint32 public localEid;
    
    /// @notice Trusted remotes for cross-chain communication
    mapping(uint32 => bytes32) public trustedRemotes;
    
    // ============ Events ============
    
    /// @notice Emitted when tokens are minted
    event Minted(address indexed to, uint256 amount, address indexed minter);
    
    /// @notice Emitted when tokens are burned
    event Burned(address indexed from, uint256 amount, address indexed burner);
    
    /// @notice Emitted when tokens are burned for cross-chain transfer
    event CrossChainBurn(
        address indexed from,
        uint256 amount,
        uint256 indexed destinationChainId,
        address indexed destinationAddress
    );
    
    /// @notice Emitted when tokens are minted from cross-chain transfer
    event CrossChainMint(
        address indexed to,
        uint256 amount,
        uint256 indexed sourceChainId,
        bytes32 indexed messageHash
    );
    
    /// @notice Emitted when LayerZero endpoint is set
    event LayerZeroEndpointSet(address indexed endpoint, uint32 eid);
    
    /// @notice Emitted when trusted remote is set
    event TrustedRemoteSet(uint32 dstEid, bytes32 remote);
    
    /// @notice Emitted when tokens are sent cross-chain via LayerZero
    event CrossChainSent(uint32 dstEid, bytes32 to, uint256 amount);
    
    /// @notice Emitted when tokens are received cross-chain via LayerZero
    event CrossChainReceived(uint32 srcEid, bytes32 from, uint256 amount);
    
    // ============ Constructor ============
    
    /**
     * @notice Initializes the USDX token
     * @param admin Address that will receive DEFAULT_ADMIN_ROLE
     */
    constructor(address admin) 
        ERC20("USDX Stablecoin", "USDX") 
        ERC20Permit("USDX Stablecoin")
    {
        require(admin != address(0), "USDXToken: admin is zero address");
        
        // Grant admin all roles
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(MINTER_ROLE, admin);
        _grantRole(BURNER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }
    
    // ============ External Functions ============
    
    /**
     * @notice Mints new USDX tokens
     * @dev Only callable by addresses with MINTER_ROLE
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(to != address(0), "USDXToken: mint to zero address");
        require(amount > 0, "USDXToken: mint amount is zero");
        
        _mint(to, amount);
        emit Minted(to, amount, msg.sender);
    }
    
    /**
     * @notice Burns tokens from a specific address (role-based)
     * @dev Only callable by addresses with BURNER_ROLE
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFromRole(address from, uint256 amount) 
        public 
        onlyRole(BURNER_ROLE) 
        whenNotPaused 
    {
        require(from != address(0), "USDXToken: burn from zero address");
        require(amount > 0, "USDXToken: burn amount is zero");
        
        _burn(from, amount);
        emit Burned(from, amount, msg.sender);
    }
    
    /**
     * @notice Burns tokens from a specific address using allowance
     * @dev Standard ERC20Burnable behavior - anyone with allowance can call
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address from, uint256 amount) 
        public 
        override 
        whenNotPaused 
    {
        // Standard ERC20Burnable - uses allowance mechanism
        super.burnFrom(from, amount);
        emit Burned(from, amount, msg.sender);
    }
    
    /**
     * @notice Burns tokens for cross-chain transfer (legacy, use sendCrossChain instead)
     * @dev Burns tokens from sender and emits event for cross-chain bridge
     * @param amount Amount of tokens to burn
     * @param destinationChainId Chain ID where tokens should be minted
     * @param destinationAddress Address to receive tokens on destination chain
     */
    function burnForCrossChain(
        uint256 amount,
        uint256 destinationChainId,
        address destinationAddress
    ) external whenNotPaused {
        require(amount > 0, "USDXToken: burn amount is zero");
        require(destinationAddress != address(0), "USDXToken: destination is zero address");
        require(destinationChainId != block.chainid, "USDXToken: same chain transfer");
        
        _burn(msg.sender, amount);
        emit CrossChainBurn(msg.sender, amount, destinationChainId, destinationAddress);
    }
    
    /**
     * @notice Send tokens cross-chain via LayerZero OFT
     * @param dstEid Destination endpoint ID
     * @param to Destination address (bytes32 format)
     * @param amount Amount of tokens to send
     * @param options LayerZero options
     */
    function sendCrossChain(
        uint32 dstEid,
        bytes32 to,
        uint256 amount,
        bytes calldata options
    ) external payable whenNotPaused {
        if (address(lzEndpoint) == address(0)) revert ZeroAddress();
        if (amount == 0) revert("USDXToken: amount is zero");
        if (trustedRemotes[dstEid] == bytes32(0)) revert InvalidRemote();
        
        // Burn tokens from sender
        _burn(msg.sender, amount);
        
        // Build payload
        bytes memory payload = abi.encode(msg.sender, amount);
        
        // Send via LayerZero
        ILayerZeroEndpoint.MessagingParams memory params = ILayerZeroEndpoint.MessagingParams({
            dstEid: dstEid,
            receiver: to,
            message: payload,
            options: options,
            payInLzToken: false
        });
        
        lzEndpoint.send{value: msg.value}(params, msg.sender);
        
        emit CrossChainSent(dstEid, to, amount);
    }
    
    /**
     * @notice Receive tokens from cross-chain transfer via LayerZero
     * @dev Called by LayerZero endpoint
     * @dev This function mints tokens without MINTER_ROLE because LayerZero endpoint
     *      verification provides sufficient security. The endpoint ensures only valid
     *      cross-chain messages are delivered.
     */
    function lzReceive(
        uint32 srcEid,
        bytes32 sender,
        bytes calldata payload,
        address executor,
        bytes calldata extraData
    ) external payable whenNotPaused {
        // Verify caller is LayerZero endpoint
        if (msg.sender != address(lzEndpoint)) revert Unauthorized();
        
        // Verify trusted remote
        if (trustedRemotes[srcEid] == bytes32(0) || trustedRemotes[srcEid] != sender) {
            revert InvalidRemote();
        }
        
        // Decode payload
        (address user, uint256 amount) = abi.decode(payload, (address, uint256));
        
        if (user == address(0)) revert ZeroAddress();
        if (amount == 0) revert("USDXToken: amount is zero");
        
        // Mint tokens to user
        // Security: LayerZero endpoint verification ensures this is a valid cross-chain message
        _mint(user, amount);
        
        emit CrossChainReceived(srcEid, sender, amount);
        emit CrossChainMint(user, amount, srcEid, keccak256(payload));
    }
    
    /**
     * @notice Mints tokens from cross-chain transfer
     * @dev Only callable by addresses with MINTER_ROLE (typically the bridge contract)
     * @param to Address to receive the minted tokens
     * @param amount Amount of tokens to mint
     * @param sourceChainId Chain ID where tokens were burned
     * @param messageHash Hash of the cross-chain message for tracking
     */
    function mintFromCrossChain(
        address to,
        uint256 amount,
        uint256 sourceChainId,
        bytes32 messageHash
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(to != address(0), "USDXToken: mint to zero address");
        require(amount > 0, "USDXToken: mint amount is zero");
        require(sourceChainId != block.chainid, "USDXToken: same chain transfer");
        
        _mint(to, amount);
        emit CrossChainMint(to, amount, sourceChainId, messageHash);
    }
    
    /**
     * @notice Pauses all token transfers
     * @dev Only callable by addresses with PAUSER_ROLE
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }
    
    /**
     * @notice Unpauses all token transfers
     * @dev Only callable by addresses with PAUSER_ROLE
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }
    
    /**
     * @notice Sets LayerZero endpoint for cross-chain functionality
     * @param _lzEndpoint LayerZero endpoint address
     * @param _localEid Local endpoint ID
     */
    function setLayerZeroEndpoint(address _lzEndpoint, uint32 _localEid) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_lzEndpoint == address(0)) revert ZeroAddress();
        
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        localEid = _localEid;
        
        emit LayerZeroEndpointSet(_lzEndpoint, _localEid);
    }
    
    /**
     * @notice Sets trusted remote for cross-chain communication
     * @param dstEid Destination endpoint ID
     * @param remote Remote address (bytes32 format)
     */
    function setTrustedRemote(uint32 dstEid, bytes32 remote) external onlyRole(DEFAULT_ADMIN_ROLE) {
        trustedRemotes[dstEid] = remote;
        emit TrustedRemoteSet(dstEid, remote);
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Hook that is called before any transfer of tokens
     * @param from Address tokens are transferred from
     * @param to Address tokens are transferred to
     * @param amount Amount of tokens being transferred
     */
    function _update(address from, address to, uint256 amount) 
        internal 
        override 
        whenNotPaused 
    {
        super._update(from, to, amount);
    }
    
    // ============ View Functions ============
    
    /**
     * @notice Returns the number of decimals used for token amounts
     * @return Number of decimals (6, same as USDC)
     */
    function decimals() public pure override returns (uint8) {
        return 6;
    }
}
