const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Landing", function () {
    it("Should pass", async function () {
     
      const [owner, borrower, lender] = await ethers.getSigners();
      
      const NFT721 = await ethers.getContractFactory("NFT721");
      const U20 = await ethers.getContractFactory("U20");
      const SwopXLanding = await ethers.getContractFactory("SwopXLending");
  
      const swopXLanding = await SwopXLanding.deploy();
      const u20 = await U20.deploy();
      const nft721 = await NFT721.deploy();
  
      await swopXLanding.deployed();
      await u20.deployed();
      await nft721.deployed();
  
      console.log("nft721 Address:", nft721.address);
      console.log("u20 Address:", u20.address);
      console.log("swopXLanding Address:", swopXLanding.address);
      await u20.connect(lender).mint();
  
      await u20.connect(lender).balanceOf(lender.address).then(res=>{
        console.log("lender balance ", res)
      })
  
      await nft721.connect(borrower).safeMint();
      await nft721.connect(borrower).safeMint();
  
      await nft721.connect(borrower).ownerOf(1).then(res=>{
        console.log("owner of ", res);
      })
      
      
      const swopXLandingERC20 = await swopXLanding.connect(owner).addToken(u20.address, true);
      await swopXLandingERC20.wait();
      
    //##########################################################################################
      // const amountLend = lendingAmount.toString();
      // console.log("lendingAmount ", amountLend);
  
      // borrower needs to approve their nft before sending the submit function 
      // borrower can approve all nft or single appove 
      const approveToken = await nft721.connect(borrower).approve(swopXLanding.address, 1  );
      await approveToken.wait();
  
      // 15 eth as the amount of the nft
      let Amountfee;
      const lendingAmount = ethers.utils.parseEther('100');
   
      // from the lender data, first, run calculatedFee of the lendingAmount
      await swopXLanding.connect(lender).calculatedFee(lendingAmount).then(res=>{
        Amountfee = res;
        });
    
      console.log(("fee:",  lendingAmount ));
      // lander needs to approve USDT token that is equal to lendingAmount + Amountfee
      const u20Token = await u20.connect(lender).approve(swopXLanding.address, Amountfee+ lendingAmount);
      await u20Token.wait();
  
      
      // signture 
      let {chainId:chainid} = await ethers.provider.getNetwork();
  
      const signature = await lender._signTypedData(
        // Domain
          {
              name: 'SwopXLending',
              version: '1.0',
              chainId: chainid,
              verifyingContract: swopXLanding.address
          },
          {
            Landing: [
                { name: 'paymentContractAddress', type: 'address'},
                { name: 'loanAmount', type: 'uint256'},
                { name: 'nftContractAddress', type: 'address'},
                { name: 'nftOwner', type: 'address'},
                { name: 'nftTokenId', type: 'uint256'},
                { name: 'pirodOfTime', type: 'uint256'},
                { name: 'cost', type: 'uint256'},
            ],
          },
          { 
            paymentContractAddress:u20.address,
            loanAmount:lendingAmount,
            nftContractAddress:nft721.address,
            nftOwner:borrower.address,
            nftTokenId:Number(1),
            pirodOfTime:Number(1),
            cost:ethers.utils.parseEther('20'),
          },
        );
  
    console.log(' signature1, ', signature);
  
  
    // borrower submit the signature of the lender.  
    const paymentContractAddress = u20.address
    const loanAmount = lendingAmount
    const nftContractAddress = nft721.address
    const nftTokenId = Number(1)
    const pirodOfTime = Number(1)// 1 is 1 month, 2 is two month and so on
    const cost = ethers.utils.parseEther('20');
  
    const submitLanding = await swopXLanding.connect(borrower).submit(
          paymentContractAddress, lender.address, nftContractAddress, nftTokenId,
          loanAmount, pirodOfTime, cost, signature);
      
    await submitLanding.wait();
    console.log("________________________________________________________________");
    await swopXLanding.connect(owner).assets(1).then(res=>{
      console.log("assets ", res)
    });
  
    await nft721.connect(borrower).ownerOf(1).then(res=>{
      console.log("owner of ", res);
    })
  
    await u20.connect(owner).balanceOf(swopXLanding.address).then(res=>{
        console.log("swopXLanding balance ", res)
    })
//   
    await u20.connect(owner).balanceOf(borrower.address).then(res=>{
      console.log("borrower balance ", res)
  })
  
    // console.log(ethers.utils.formatEther(100000000000000000000));
      // expect(await greeter.greet()).to.equal("Hello, world!");
  
      // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");
  
      // // wait until the transaction is mined
      // await setGreetingTx.wait();
  
      // expect(await greeter.greet()).to.equal("Hola, mundo!");
    });
  });