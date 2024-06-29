import hre from "hardhat";

async function Main() {
    const token = await hre.ethers.getContractFactory("TokenShop");
    const result = await token.deploy("0x234EFa5f14b70c5932E47d52cf78006D3BD78D79");
    console.log("token deployed to:", result.target);
}

Main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});