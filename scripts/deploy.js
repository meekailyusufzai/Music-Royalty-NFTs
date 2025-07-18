const { ethers } = require("hardhat");

async function main() {
  console.log("Starting deployment of Music Royalty NFTs contract...");
  
  // Get the contract factory
  const MusicRoyaltyNFTs = await ethers.getContractFactory("MusicRoyaltyNFTs");
  
  // Get the deployer account
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contract with account:", deployer.address);
  
  // Check deployer balance
  const balance = await deployer.provider.getBalance(deployer.address);
  console.log("Deployer balance:", ethers.formatEther(balance), "ETH");
  
  // Deploy the contract
  console.log("Deploying MusicRoyaltyNFTs contract...");
  const musicRoyaltyNFTs = await MusicRoyaltyNFTs.deploy();
  
  // Wait for deployment to complete
  await musicRoyaltyNFTs.waitForDeployment();
  
  const contractAddress = await musicRoyaltyNFTs.getAddress();
  console.log("✅ MusicRoyaltyNFTs deployed to:", contractAddress);
  
  // Log deployment details
  console.log("\n📋 Deployment Summary:");
  console.log("=".repeat(50));
  console.log("Contract Name: MusicRoyaltyNFTs");
  console.log("Contract Address:", contractAddress);
  console.log("Deployer Address:", deployer.address);
  console.log("Network:", network.name);
  console.log("Chain ID:", network.config.chainId);
  
  // Verify deployment by calling a view function
  try {
    const tokenName = await musicRoyaltyNFTs.name();
    const tokenSymbol = await musicRoyaltyNFTs.symbol();
    const currentTokenId = await musicRoyaltyNFTs.getCurrentTokenId();
    
    console.log("\n🔍 Contract Verification:");
    console.log("=".repeat(50));
    console.log("Token Name:", tokenName);
    console.log("Token Symbol:", tokenSymbol);
    console.log("Current Token ID:", currentTokenId.toString());
    console.log("Contract deployed successfully! ✅");
  } catch (error) {
    console.error("❌ Error verifying contract:", error.message);
  }
  
  // Save deployment info
  const deploymentInfo = {
    contractAddress: contractAddress,
    deployer: deployer.address,
    network: network.name,
    chainId: network.config.chainId,
    deploymentTime: new Date().toISOString(),
    blockNumber: await ethers.provider.getBlockNumber()
  };
  
  console.log("\n💾 Deployment Info:");
  console.log("=".repeat(50));
  console.log(JSON.stringify(deploymentInfo, null, 2));
  
  // Example of how to interact with the deployed contract
  console.log("\n🔧 Example Usage:");
  console.log("=".repeat(50));
  console.log("To mint a Music NFT:");
  console.log(`await musicRoyaltyNFTs.mintMusicNFT(`);
  console.log(`  "${deployer.address}",`);
  console.log(`  "My Song Title",`);
  console.log(`  "Artist Name",`);
  console.log(`  1000, // 10% royalty`);
  console.log(`  "https://your-metadata-uri.com/metadata.json"`);
  console.log(`);`);
  
  console.log("\nTo distribute royalties:");
  console.log(`await musicRoyaltyNFTs.distributeRoyalties(1, { value: ethers.parseEther("0.1") });`);
  
  return contractAddress;
}

// Handle errors
main()
  .then((contractAddress) => {
    console.log(`\n🎉 Deployment completed successfully!`);
    console.log(`📋 Contract Address: ${contractAddress}`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
