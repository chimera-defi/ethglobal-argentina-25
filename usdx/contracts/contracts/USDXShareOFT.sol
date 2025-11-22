// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ILayerZeroEndpoint} from "./interfaces/ILayerZeroEndpoint.sol";

/**
 * @title USDXShareOFT
 * @notice OFT representation of USDX vault shares on spoke chains
 * @dev This contract represents OVault shares on spoke chains
 * 
 * Key Features:
 * - Represents vault shares on spoke chains
 * - Cross-chain transfers via LayerZero
 * - Minted when shares are sent from hub chain
 * - Burned when shares are sent back to hub chain
 * 
 * NOTE: This is a simplified implementation. In production, you would use
 * LayerZero's official OFT contract from their SDK.
 */
contract USDXShareOFT is ERC20, Ownable {
    ILayerZeroEndpoint public immutable lzEndpoint;
    uint32 public immutable localEid;
    
    // Cross-chain state
    mapping(uint32 => bytes32) public trustedRemotes;
    
    // Minting control
    address public minter; // Only hub chain composer can mint
    
    // ============ Events ============
    
    event CrossChainSent(uint32 dstEid, bytes32 to, uint256 amount);
    event CrossChainReceived(uint32 srcEid, bytes32 from, uint256 amount);
    event MinterUpdated(address indexed oldMinter, address indexed newMinter);
    
    // ============ Errors ============
    
    error ZeroAddress();
    error ZeroAmount();
    error Unauthorized();
    error InvalidRemote();
    
    constructor(
        string memory _name,
        string memory _symbol,
        address _lzEndpoint,
        uint32 _localEid,
        address _owner
    ) ERC20(_name, _symbol) Ownable(_owner) {
        if (_lzEndpoint == address(0) || _owner == address(0)) {
            revert ZeroAddress();
        }
        
        lzEndpoint = ILayerZeroEndpoint(_lzEndpoint);
        localEid = _localEid;
        minter = _owner; // Will be set to composer address after deployment
    }
    
    /**
     * @notice Mint tokens (only by minter/composer)
     * @param to Address to mint to
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) external {
        if (msg.sender != minter) revert Unauthorized();
        if (to == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        
        _mint(to, amount);
    }
    
    /**
     * @notice Burn tokens
     * @param amount Amount to burn
     */
    function burn(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        _burn(msg.sender, amount);
    }
    
    /**
     * @notice Send shares cross-chain via LayerZero
     * @param dstEid Destination endpoint ID
     * @param to Destination address (bytes32 format)
     * @param amount Amount of shares to send
     * @param options LayerZero options
     */
    function send(
        uint32 dstEid,
        bytes32 to,
        uint256 amount,
        bytes calldata options
    ) external payable {
        if (amount == 0) revert ZeroAmount();
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
     * @notice Receive shares from cross-chain transfer
     * @dev Called by LayerZero endpoint
     */
    function lzReceive(
        uint32 srcEid,
        bytes32 sender,
        bytes calldata payload,
        address executor,
        bytes calldata extraData
    ) external payable {
        // Verify caller is LayerZero endpoint
        if (msg.sender != address(lzEndpoint)) revert Unauthorized();
        
        // Verify trusted remote
        if (trustedRemotes[srcEid] != sender) revert InvalidRemote();
        
        // Decode payload
        (address user, uint256 amount) = abi.decode(payload, (address, uint256));
        
        // Mint tokens to user
        _mint(user, amount);
        
        emit CrossChainReceived(srcEid, sender, amount);
    }
    
    /**
     * @notice Set trusted remote for cross-chain communication
     * @param dstEid Destination endpoint ID
     * @param remote Remote address (bytes32 format)
     */
    function setTrustedRemote(uint32 dstEid, bytes32 remote) external onlyOwner {
        trustedRemotes[dstEid] = remote;
    }
    
    /**
     * @notice Set minter address (composer on hub chain)
     * @param _minter New minter address
     */
    function setMinter(address _minter) external onlyOwner {
        if (_minter == address(0)) revert ZeroAddress();
        
        address oldMinter = minter;
        minter = _minter;
        
        emit MinterUpdated(oldMinter, _minter);
    }
    
    /**
     * @notice Get minter address
     */
    function getMinter() external view returns (address) {
        return minter;
    }
}
