import hre from "hardhat";
console.log("hre keys:", Object.keys(hre).slice(0, 10));
console.log("ethers:", typeof hre.ethers);
