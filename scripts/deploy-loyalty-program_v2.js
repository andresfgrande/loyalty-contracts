const hre = require("hardhat");


async function main() {
    const [deployer] = await hre.ethers.getSigners();

    // Step 1: Deploy OmniToken --> OK
    console.log("Deploying OmniToken...");
    console.log("Deploying token contract with the account:", deployer.address);
    const omniToken = await hre.ethers.deployContract("OmniToken");
    await omniToken.waitForDeployment();
    console.log("/***** OmniToken deployed to:", omniToken.target, "*****/");

    // Step 2: Deploy LoyaltyProgramFactory with OmniToken address as parameter --> OK
    console.log("Deploying LoyaltyProgramFactory...");
    loyaltyProgramFactory = await hre.ethers.deployContract("LoyaltyProgramFactory",[omniToken.target]);
    await loyaltyProgramFactory.waitForDeployment();
    console.log("/***** LoyaltyProgramFactory deployed to:", loyaltyProgramFactory.target, "with token -> ", omniToken.target,"*****/");

    // Step 3: Transfer ownership of OmniToken to LoyaltyProgramFactory --> OK
    console.log("Transferring ownership of OmniToken to LoyaltyProgramFactory...");
    const transferTx = await omniToken.transferOwnership(loyaltyProgramFactory.target);
    const receipt = await transferTx.wait();
    if (receipt.status === 1) { 
        console.log("Ownership transferred successfully.");
    } else {
        console.error("Ownership transfer failed.");
    }
    console.log("/***** Ownership transferred to:", await omniToken.owner(),"*****/");

     // Step 4: Deploy a LoyaltyProgram using the factory --> OK
     console.log("Deploying LoyaltyProgram...");

     // Create a promise to wait for the event
     const loyaltyProgramAddressPromise = new Promise((resolve, reject) => {
         loyaltyProgramFactory.on("LoyaltyProgramCreated", (factoryAddress, loyaltyProgramAddress, commerceAddress, commerceName, timestamp, event) => {
            
             console.log("LoyaltyProgram created: ", loyaltyProgramAddress, commerceAddress, commerceName);
             console.log("/****** Loyalty program deployed to: ", loyaltyProgramAddress, "*****/");
             resolve(loyaltyProgramAddress);
         });
     });
 
     const createLoyaltyProgramTx = await loyaltyProgramFactory.createLoyaltyProgram("0x3e00DE4e512fcB4922842145ca425a41962d7e11","Norma","NORM");
     const createLoyaltyProgramReceipt = await createLoyaltyProgramTx.wait();
 
     if (createLoyaltyProgramReceipt.status !== 1) {
         console.error("Loyalty program creation failed.");
         return;
     }
     console.log("Loyalty program created successfully.");
 
     // Wait for the event to fire and get the address
     const loyaltyProgramAddressAux = await loyaltyProgramAddressPromise;
 
     // Step 5: Add trusted relayer to OmniToken: the address of the created LoyaltyProgram --> OK
     console.log("Adding LoyaltyProgram as a trusted relayer in OmniToken...");
     console.log("/***** Trusted relayer: ", loyaltyProgramAddressAux, "*****/");
     const addTrustedRelayerTx = await loyaltyProgramFactory.addTrustedRelayer(loyaltyProgramAddressAux);
     const addTrustedRelayeReceipt = await addTrustedRelayerTx.wait();
 
     if (addTrustedRelayeReceipt.status === 1) { 
         console.log("Added trusted relayer successfully.");
     } else {
         console.error("Added trusted relayer failed.");
     }
 
 
     // Step 6: is trusted relayer? --> OK
     console.log(`checking ${loyaltyProgramAddressAux} is trusted relayer...`);
     const isTrustedRelayerTx = await omniToken.isTrustedRelayer(loyaltyProgramAddressAux);
     console.log(`Is loyalty program ${loyaltyProgramAddressAux} a trusted relayer? -> ${isTrustedRelayerTx}`);
 
 
     /************************************************************/
     const weiValue = hre.ethers.parseEther("100");
     console.log(weiValue);
     const mintTx = await loyaltyProgramFactory.mintTokensToAddress(weiValue, loyaltyProgramAddressAux);
     console.log(mintTx);
     await mintTx.wait();
     const loyaltyProgramBalance = await omniToken.balanceOf(loyaltyProgramAddressAux);
     console.log(loyaltyProgramBalance);
   
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
