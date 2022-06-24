const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const times = require('./loan.json');

// hashing ##########################################################################################

/* hashing takes :
  -the loan term eg 0,1,2,3,....
  -the loan timestamp  eg 1656025191
  -the loan payment in
*/
// (counter, timestamp, payment)
function hashloan(counter, timestampPayment) {
  return Buffer.from(ethers.utils.solidityKeccak256(['uint256','uint256','uint256'], [counter, timestampPayment[0],timestampPayment[1]]).slice(2), 'hex')
}
//##########################################################################################

describe("Landing", function () {
    it("submit", async function () {
     // init
      const [owner, borrower, lender] = await ethers.getSigners();
       // deploy contracts
      const NFT721 = await ethers.getContractFactory("NFT721");
      const U20 = await ethers.getContractFactory("U20");
      const SwopXLanding = await ethers.getContractFactory("SwopXLendingV2");
  
      const swopXLanding = await SwopXLanding.deploy();
      const u20 = await U20.deploy();
      const nft721 = await NFT721.deploy();
  
      await swopXLanding.deployed();
      await u20.deployed();
      await nft721.deployed();
  
      console.log("nft721 Address:", nft721.address);
      console.log("u20 Address:", u20.address);
      console.log("swopXLanding Address:", swopXLanding.address);
      
      // mint utility token
      await u20.connect(lender).mint();
      await u20.connect(lender).balanceOf(lender.address).then(res=>{
        console.log("lender balance ", res)
      })
      // mint nft 
      await nft721.connect(borrower).safeMint();
      await nft721.connect(borrower).safeMint();
  
      await nft721.connect(borrower).ownerOf(1).then(res=>{
        console.log("borrower of ", res);
      })
      
      
      const swopXLandingERC20 = await swopXLanding.connect(owner).addToken(u20.address, true);
      await swopXLandingERC20.wait();
      
    //##########################################################################################
  
      // borrower needs to approve their nft before sending the submit function 
      // borrower can approve all nft or single appove 
      const approveToken = await nft721.connect(borrower).approve(swopXLanding.address, 1  );
      await approveToken.wait();
      

      // get the fees from the loan amount
      let Amountfee;
      const lendingAmount = ethers.utils.parseEther('10');

      await swopXLanding.connect(lender).calculatedFee(lendingAmount).then(res=>{
        Amountfee = res;
        });
      console.log(("fee:",  Amountfee ));
      const cost = ethers.utils.parseEther('5');

      // lander needs to approve USDT token that is equal to lendingAmount + Amountfee
      const u20Token = await u20.connect(lender).approve(swopXLanding.address, Amountfee+ lendingAmount);
      await u20Token.wait();


//create root before Sig ##########################################################################################

      const leaf = Object.entries(times).map(times => hashloan(...times));
      const merkleTree = new MerkleTree(leaf, keccak256,{sortPairs: true})
      const root = merkleTree.getHexRoot()
      console.log("root", root);
    const payFirstMonth = merkleTree.getHexProof(leaf[1]);

// create signture ##########################################################################################

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
                {name: 'nonce', type: 'uint256'}, // from the backend
                { name: 'paymentContract', type: 'address'}, // erc20 address
                { name: 'offeredTime', type: 'uint256'},  // offeredTime is a timestamp that should be in the future
                { name: 'loanAmount', type: 'uint256'},
                { name: 'loanCost', type: 'uint256'},
                { name: 'nftcontract', type: 'address'},
                { name: 'nftOwner', type: 'address'},
                { name: 'nftTokenId', type: 'uint256'},
                { name: 'gist', type: 'bytes32'},
            ],
          },
          {
            nonce:Number(0),
            paymentContract:u20.address,
            offeredTime: Number(1656094663),
            loanAmount:lendingAmount,
            loanCost:cost,
            nftcontract:nft721.address,
            nftOwner:borrower.address,
            nftTokenId:Number(1),
            gist: root
            
          },
        );
  
    console.log(' signature1, ', signature);
   


    // 
    const _nonce = Number(0);
    const _paymentContract = u20.address;
    const _lender = lender.address ;
    const _nftcontract = nft721.address;
    const _nftTokenId = Number(1)
    const _loanAmounLoanCostFee = [lendingAmount, cost, Amountfee ];
    const _offeredTime  = Number(1656094663)  ;



    const submitLanding = await swopXLanding.connect(borrower).submit(
      _nonce, _paymentContract, _lender, 
      _nftcontract, _nftTokenId, _loanAmounLoanCostFee,
      _offeredTime,root, signature);
      
    await submitLanding.wait();
    console.log("________________________________________________________________");
    await swopXLanding.connect(owner).assets(1).then(res=>{
      console.log("assets before payment ", res)
    });
      
 
  
    await nft721.connect(borrower).ownerOf(1).then(res=>{
      console.log("owner of ", res);
    })
  
    await u20.connect(owner).balanceOf(owner.address).then(res=>{
        console.log("owner balance ", res)
    })

    await u20.connect(owner).balanceOf(borrower.address).then(res=>{
      console.log("borrower balance ", res)
    })

  await  swopXLanding.connect(owner).balanceOf(borrower.address).then(res=>{
    console.log("NFT borrower balance ", res)
    })
    const borrowerAmountApprove = ethers.utils.parseEther('13');
    const borrowerfee = ethers.utils.parseEther('0.1');
    console.log("________________________________________________________________");

    const u20Tokenborrower = await u20.connect(borrower).approve(swopXLanding.address, borrowerAmountApprove);
    await u20Tokenborrower.wait();


    const loanTimestampLoanPayment = [1656094663, 4927]
    const makePayment = await swopXLanding.connect(borrower).makePayment(1, 1, 
    loanTimestampLoanPayment,borrowerfee,payFirstMonth);
    await makePayment.wait();

    await u20.connect(owner).balanceOf(owner.address).then(res=>{
        console.log("first payment owner balance ", res)
    })

    console.log("________________________________________________________________");
    await swopXLanding.connect(owner).assets(1).then(res=>{
      console.log("assets after payment", res)
    });

//     await u20.connect(owner).balanceOf(borrower.address).then(res=>{
//         console.log("first payment borrower balance ", res)
//     })

//   await  swopXLanding.connect(owner).balanceOf(borrower.address).then(res=>{
//     console.log("first payment NFT borrower balance ", res)
//     })

//     console.log("________________________________________________________________");
//     await swopXLanding.connect(owner).assets(1).then(res=>{
//       console.log("assets ", res)
//     });
//     console.log("________________________________________________________________");

//     await nft721.connect(borrower).ownerOf(1).then(res=>{
//         console.log("owner of NFT ", res);
//       });
//     console.log("________________________________________________________________");

//     const u20Tokenlender = await u20.connect(lender).approve(swopXLanding.address, borrowerAmountApprove);
//     await u20Tokenlender.wait();

//     const time1 = ["1655400000","12000000000000000000","0"];

//     const defaultAsset = await swopXLanding.connect(lender).defaultAsset(1, term, 
//         time1,borrowerfee,proofFirstMonth);
//         await defaultAsset.wait();
    
//     console.log("lenderAddress__________________________________________________________");

//     await nft721.connect(borrower).ownerOf(1).then(res=>{
//             console.log("owner of NFT ", res);
//           });
    });
  });