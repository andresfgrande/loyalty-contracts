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

    /***********************************************************************************************/
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
 
     const createLoyaltyProgramTx = await loyaltyProgramFactory.createLoyaltyProgram("0x626DB02134CB1E1a61483057a61315801809a71c","Norma-Comics","NORM");
     const createLoyaltyProgramReceipt = await createLoyaltyProgramTx.wait();
 
     if (createLoyaltyProgramReceipt.status !== 1) {
         console.error("Loyalty program creation failed.");
         return;
     }
     console.log("Loyalty program created successfully.");
 
     // Wait for the event to fire and get the address
     const loyaltyProgramAddressAux = await loyaltyProgramAddressPromise;
     /***********************************************************************************************/
     console.log("Deploying LoyaltyProgram 2...");

     // Create a promise to wait for the event
     const loyaltyProgramAddressPromise2 = new Promise((resolve, reject) => {
         loyaltyProgramFactory.on("LoyaltyProgramCreated", (factoryAddress, loyaltyProgramAddress, commerceAddress, commerceName, timestamp, event) => {
             console.log("LoyaltyProgram created: ", loyaltyProgramAddress, commerceAddress, commerceName);
             console.log("/****** Loyalty program deployed to: ", loyaltyProgramAddress, "*****/");
             resolve(loyaltyProgramAddress);
         });
     });
 
     const createLoyaltyProgramTx2 = await loyaltyProgramFactory.createLoyaltyProgram("0x8E112F2BfCFdA3EDa4f379c014623e4d80a4E559","Bartoletti-Corwin","BART");
     const createLoyaltyProgramReceipt2 = await createLoyaltyProgramTx2.wait();
 
     if (createLoyaltyProgramReceipt2.status !== 1) {
         console.error("Loyalty program creation failed.");
         return;
     }
     console.log("Loyalty program created successfully.");
 
     // Wait for the event to fire and get the address
     const loyaltyProgramAddressAux2 = await loyaltyProgramAddressPromise2;

     /**********************************************************************************************/
 
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

     console.log("Adding LoyaltyProgram 2 as a trusted relayer in OmniToken...");
     console.log("/***** Trusted relayer 2: ", loyaltyProgramAddressAux2, "*****/");
     const addTrustedRelayerTx2 = await loyaltyProgramFactory.addTrustedRelayer(loyaltyProgramAddressAux2);
     const addTrustedRelayeReceipt2 = await addTrustedRelayerTx2.wait();
 
     if (addTrustedRelayeReceipt2.status === 1) { 
         console.log("Added trusted relayer successfully.");
     } else {
         console.error("Added trusted relayer failed.");
     }
 
 
     // Step 6: is trusted relayer? --> OK
     console.log(`checking ${loyaltyProgramAddressAux} is trusted relayer...`);
     const isTrustedRelayerTx = await omniToken.isTrustedRelayer(loyaltyProgramAddressAux);
     console.log(`Is loyalty program ${loyaltyProgramAddressAux} a trusted relayer? -> ${isTrustedRelayerTx}`);

     console.log(`checking ${loyaltyProgramAddressAux2} is trusted relayer...`);
     const isTrustedRelayerTx2 = await omniToken.isTrustedRelayer(loyaltyProgramAddressAux2);
     console.log(`Is loyalty program ${loyaltyProgramAddressAux2} a trusted relayer? -> ${isTrustedRelayerTx2}`);
 
 
     /************************************************************/
     const weiValue = hre.ethers.parseEther("500000");
     const mintTx = await loyaltyProgramFactory.mintTokensToAddress(weiValue, loyaltyProgramAddressAux);
     await mintTx.wait();
     const loyaltyProgramBalance = await omniToken.balanceOf(loyaltyProgramAddressAux);
     console.log(`Balance of: ${loyaltyProgramAddressAux} is ${hre.ethers.formatEther(loyaltyProgramBalance)}`);

     const mintTx2 = await loyaltyProgramFactory.mintTokensToAddress(weiValue, loyaltyProgramAddressAux2);
     await mintTx2.wait();
     const loyaltyProgramBalance2 = await omniToken.balanceOf(loyaltyProgramAddressAux2);
     console.log(`Balance of: ${loyaltyProgramAddressAux2} is ${hre.ethers.formatEther(loyaltyProgramBalance2)}`);
   
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
