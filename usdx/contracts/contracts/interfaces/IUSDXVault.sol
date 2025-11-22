// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IUSDXVault {
    function depositUSDC(uint256 amount) external returns (uint256 usdxAmount);
    function depositUSDCFor(address user, uint256 amount) external returns (uint256 usdxAmount);
    function withdrawUSDC(uint256 usdxAmount) external returns (uint256 usdcAmount);
    function withdrawUSDCTo(address to, uint256 usdxAmount) external returns (uint256 usdcAmount);
    function getUserCollateral(address user) external view returns (uint256);
    function getTotalCollateral() external view returns (uint256);
    function getTotalUSDXMinted() external view returns (uint256);
    function getCollateralRatio() external view returns (uint256);
}
