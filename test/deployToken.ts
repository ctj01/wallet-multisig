import hre from "hardhat";

async function Main() {
    const token = await hre.ethers.getContractFactory("TokenGovernance");
    const result = await token.deploy();
    console.log("token deployed to:", result.target);
}

Main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});