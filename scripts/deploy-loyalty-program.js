const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();

    // Step 1: Deploy OmniToken --> OK
    console.log("Deploying OmniToken...");
    console.log("Deploying token contract with the account:", deployer.address);
    const omniToken = await ethers.deployContract("OmniToken");
    const omniTokenAddress = await omniToken.getAddress()
    console.log("OmniToken deployed to:", omniTokenAddress);

    // Step 2: Deploy LoyaltyProgramFactory with OmniToken address as parameter --> OK
    console.log("Deploying LoyaltyProgramFactory...");
    loyaltyProgramFactory = await ethers.deployContract("LoyaltyProgramFactory",[omniTokenAddress]);
    loyaltyProgramFactoryAddress = await loyaltyProgramFactory.getAddress();
    console.log("LoyaltyProgramFactory deployed to:", loyaltyProgramFactoryAddress, "with token -> ", omniTokenAddress);

    // Step 3: Transfer ownership of OmniToken to LoyaltyProgramFactory --> OK
    console.log("Transferring ownership of OmniToken to LoyaltyProgramFactory...");
    const transferTx = await omniToken.transferOwnership(loyaltyProgramFactoryAddress);
    const receipt = await transferTx.wait();
    if (receipt.status === 1) { 
        console.log("Ownership transferred successfully.");
    } else {
        console.error("Ownership transfer failed.");
    }
    console.log("Ownership transferred to:", await omniToken.owner());


    // Step 4: Deploy a LoyaltyProgram using the factory
    console.log("Deploying LoyaltyProgram...");

    loyaltyProgramFactory.on("LoyaltyProgramCreated", (loyaltyProgramAddress, commerceAddress, commerceName, event) => {
        console.log("LoyaltyProgram created: ", loyaltyProgramAddress, commerceAddress, commerceName);
        console.log("Loyalty program deployed to: ", loyaltyProgramAddress);
    });

    const createLoyaltyProgramTx = await loyaltyProgramFactory.createLoyaltyProgram("0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199","Norma","NOR");
    const createLoyaltyProgramReceipt = await createLoyaltyProgramTx.wait();
    if (createLoyaltyProgramReceipt.status === 1) { 
        console.log("Loyalty program created successfully.");
    } else {
        console.error("Loyalty program creation failed.");
    }
    
    /*
    // Step 5: Add trusted relayer to OmniToken: the address of the created LoyaltyProgram
    console.log("Adding LoyaltyProgram as a trusted relayer in OmniToken...");
    await omniToken.addTrustedRelayer(loyaltyProgramAddress);
    console.log("Trusted relayer added:", loyaltyProgramAddress);*/
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
