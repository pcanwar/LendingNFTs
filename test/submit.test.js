const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const times = require('./pay.json');

function hashToken(counter, time ) {
  return Buffer.from(ethers.utils.solidityKeccak256(['uint256','uint256','uint256','uint256'], [counter, time[0],time[1],time[2]]).slice(2), 'hex')
}

describe("Landing", function () {
    it("Should pass", async function () {
     
      const [owner, borrower, lender] = await ethers.getSigners();
      
      const NFT721 = await ethers.getContractFactory("NFT721");
      const U20 = await ethers.getContractFactory("U20");
      const SwopXLanding = await ethers.getContractFactory("SwopXLending2");
  
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
        console.log("borrower of ", res);
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
      const lendingAmount = ethers.utils.parseEther('10');
      // from the lender data, first, run calculatedFee of the lendingAmount
      await swopXLanding.connect(lender).calculatedFee(lendingAmount).then(res=>{
        Amountfee = res;
        });
      console.log(("fee:",  lendingAmount ));
      const cost = ethers.utils.parseEther('5');

      // lander needs to approve USDT token that is equal to lendingAmount + Amountfee
      const u20Token = await u20.connect(lender).approve(swopXLanding.address, Amountfee+ lendingAmount);
      await u20Token.wait();
  
      //root:
      const leaf = Object.entries(times).map(times => hashToken(...times)); 
      const merkleTree = new MerkleTree(leaf, keccak256,{sortPairs: true})
      const root = merkleTree.getHexRoot()
      console.log("root", root);
      const payFirstMonth = merkleTree.getHexProof(leaf[0]);
      const term = Number(0);
      const time = ["1655338240","25000","0"];
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
                {name: 'nonce', type: 'uint256'},
                { name: 'paymentContract', type: 'address'},
                { name: 'offeredTime', type: 'uint256'},
                { name: 'loanAmount', type: 'uint256'},
                { name: 'loanTerm', type: 'uint256'},
                { name: 'loanCost', type: 'uint256'},
                { name: 'nftcontract', type: 'address'},
                { name: 'nftOwner', type: 'address'},
                { name: 'nftTokenId', type: 'uint256'},
                { name: 'root', type: 'bytes32'},
            ],
          },
          {
            nonce:Number(0),
            paymentContract:u20.address,
            offeredTime: Number(1655418191),
            loanAmount:lendingAmount,
            loanTerm:Number(12),
            loanCost:cost,
            nftcontract:nft721.address,
            nftOwner:borrower.address,
            nftTokenId:Number(1),
            root: root
            
          },
        );
  
    console.log(' signature1, ', signature);
   
    const _nonceLoanTerm = [Number(0),Number(12)];
    const _paymentContract = u20.address;
    const _lender = lender.address ;
    const _nftcontract = nft721.address;
    const _nftTokenId = Number(1)
    const _loanAmounLoanCost = [lendingAmount, cost ];
    const _offeredTime  = Number(1655418191)  ;
    // _root and  signature



    const submitLanding = await swopXLanding.connect(borrower).submit(
      _nonceLoanTerm, _paymentContract, _lender, 
      _nftcontract, _nftTokenId, _loanAmounLoanCost,
          _offeredTime,root, signature);
      
    await submitLanding.wait();
    console.log("________________________________________________________________");
    await swopXLanding.connect(owner).assets(1).then(res=>{
      console.log("assets ", res)
    });
  
//     await nft721.connect(borrower).ownerOf(1).then(res=>{
//       console.log("owner of ", res);
//     })
  
//     await u20.connect(owner).balanceOf(swopXLanding.address).then(res=>{
//         console.log("swopXLanding balance ", res)
//     })
// //   
//     await u20.connect(owner).balanceOf(borrower.address).then(res=>{
//       console.log("borrower balance ", res)
//   })
  
    // console.log(ethers.utils.formatEther(100000000000000000000));
      // expect(await greeter.greet()).to.equal("Hello, world!");
  
      // const setGreetingTx = await greeter.setGreeting("Hola, mundo!");
  
      // // wait until the transaction is mined
      // await setGreetingTx.wait();
  
      // expect(await greeter.greet()).to.equal("Hola, mundo!");
    });
  });