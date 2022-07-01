const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const times = require('./loan.json');

// hashing ##########################################################################################

/* hashing takes :
  -counter: the loan term eg 0,1,2,3,....
  -timestampPayment: array of the loan timestamp and the monthly payment
*/
//  ["timestamp", "Principal", "Interest", "pre Interet", "Per Principal" ],
function hashloan(counter, timestampPayment) {
  
  return Buffer.from(ethers.utils.solidityKeccak256(['uint256','uint256','uint256','uint256','uint256','uint256'], [counter, timestampPayment[0],timestampPayment[1],timestampPayment[2],timestampPayment[3],timestampPayment[4]]).slice(2), 'hex')
}
//##########################################################################################

describe("Landing", function () {
    it("submit", async function () {
     // init
      const [owner, borrower, lender] = await ethers.getSigners();
       // deploy contracts
      const NFT721 = await ethers.getContractFactory("NFT721");
      const U20 = await ethers.getContractFactory("U20");
      const SwopXLanding = await ethers.getContractFactory("SwopXLendingV3");
  
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
      await u20.connect(borrower).mint();

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
      
    //approve ##########################################################################################
  
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
      const cost = ethers.utils.parseEther('2');

      // lander needs to approve USDT token that is equal to lendingAmount + Amountfee
      const u20Token = await u20.connect(lender).approve(swopXLanding.address, Amountfee+ lendingAmount);
      await u20Token.wait();


//create root before Sig ##########################################################################################

      const leaf = Object.entries(times).map(times => hashloan(...times));
      const merkleTree = new MerkleTree(leaf, keccak256,{sortPairs: true})
      const root = merkleTree.getHexRoot()
      console.log("root", root);

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
                {name: 'nonce', type: 'uint256'}, // nonce from the backend
                { name: 'paymentContract', type: 'address'}, // erc20 address
                { name: 'offeredTime', type: 'uint256'}, // offeredTime is a timestamp that should be in the future
                { name: 'loanAmount', type: 'uint256'}, // Begining Balance
                { name: 'loanCost', type: 'uint256'}, // Total Interest
                { name: 'nftcontract', type: 'address'},
                { name: 'nftOwner', type: 'address'},
                { name: 'nftTokenId', type: 'uint256'},
                { name: 'gist', type: 'bytes32'}, // root
            ],
          },
          {
            nonce:Number(0),
            paymentContract:u20.address,
            offeredTime: Number(1656719350),
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
    const _offeredTime  = Number(1656719350)  ;

    let Amountfee2;
    await swopXLanding.connect(lender).calculatedFee(lendingAmount).then(res=>{
        Amountfee2 = res;
        });
    const _loanAmounLoanCostFee = [lendingAmount, cost, Amountfee2 ];

    // noties: amountfee value gets by calling in calculatedFee func
    // _loanAmounLoanCostFee array of lendingAmount, cost, and amountfee.
    const submitLanding = await swopXLanding.connect(borrower).submit(
      _nonce, _paymentContract, _lender, 
      _nftcontract, _nftTokenId, _loanAmounLoanCostFee,
      _offeredTime,root, signature);
    await submitLanding.wait();
    
    console.log("________________________________________________________________");
    await swopXLanding.connect(owner).receipt(0).then(res=>{
      console.log("receipt ", res)
    });

    console.log("________________________________________________________________");
    await swopXLanding.connect(owner).assets(0).then(res=>{
      console.log("assets ", res)
    });
  
    await swopXLanding.connect(borrower).ownerOf(1).then(res=>{
      console.log("swopXLanding NFT 1 owner is  ", res);
    })
    await swopXLanding.connect(borrower).ownerOf(2).then(res=>{
      console.log("swopXLanding NFT 2 owner is ", res);
    })
  
// ##########################################################################################
// // make payment ##########################################################################################
// loanTimestampLoanPayment is an arry of timestamp and payment
// payFirstMonth is the leaf of the fist month
// payFirstMonth is the leaf of the 2nd month
const borrowerAmountApprove = ethers.utils.parseEther('200');

const u20Tokenborrower = await u20.connect(borrower).approve(swopXLanding.address, borrowerAmountApprove);
    await u20Tokenborrower.wait();
const nftreceipt = Number(0);
const term1st = Number(1);
// const term2nd = Number(2);
// const term3rd = Number(3);
const payFirstMonth = merkleTree.getHexProof(leaf[term1st]);
// const paySecondMonth = merkleTree.getHexProof(leaf[term2nd]);
// const pay3rdMonth = merkleTree.getHexProof(leaf[term3rd]);
const interest = ethers.utils.parseEther('0.016666666666666667');
const loanTimestampLoanPayment= ["1656719350", "0","16666666666666667", "2000000000000000000","10000000000000000000"];
// const loanTimestampLoanPayment = ["1656459017", "0",interest, "2000000000000000000","10000000000000000000"]
let feefirst ;
await swopXLanding.connect(borrower).calculatedInterestFee(interest).then(res=>{
    feefirst = res;
});

// const makePayment = await swopXLanding.connect(borrower).makePayment(nftreceipt, term1st, 
// loanTimestampLoanPayment,feefirst,payFirstMonth);
// await makePayment.wait();
// console.log("________________________________________________________________");
   
console.log("1st__________________________________________________________");
const preProof = merkleTree.getHexProof(leaf[0]);
const firstproof = merkleTree.getHexProof(leaf[1]);
let feePerinterest ;
const perInterest = ethers.utils.parseEther('2000000000000000000');

await swopXLanding.connect(borrower).calculatedInterestFee(perInterest).then(res=>{
  feePerinterest = res;
});
    const preloanTimes = ["1656719350", "0","16666666666666667", "2000000000000000000","10000000000000000000"];
    const makePerPaymentloanTimestampLoanPayment = ["1656719350", "0","16666666666666667", "2000000000000000000","10000000000000000000"];
    // function makePrePayment(uint256 _counterId, uint256 term_, 
    //   uint256[] calldata loanTimesPaymentInterest, uint256[] calldata preLoanTimes,uint256 fee_, bytes32 [] calldata proof,bytes32 [] calldata preProof) external nonReentrant {
          
      

      await u20.connect(borrower).allowance(borrower.address, swopXLanding.address).then(res=>{
        console.log("allowance: ", res);
      });
    const makePerPayment = await swopXLanding.connect(borrower).makePrePayment(nftreceipt, 1,
        makePerPaymentloanTimestampLoanPayment,preloanTimes,feePerinterest,firstproof,preProof);
    await makePerPayment.wait();
        // try {
        //     const makePayment2 = await swopXLanding.connect(borrower).makePayment(nftreceipt, term2nd, 
        //         loanTimestampLoanPayment,borrowerfee,paySecondMonth);
        //         await makePayment2.wait();
        //         console.log("2nd_____________________________________________________________");
        //     const makePayment3 = await swopXLanding.connect(borrower).makePayment(nftreceipt, term3rd, 
        //             loanTimestampLoanPayment,borrowerfee,pay3rdMonth);
        //     await makePayment3.wait();
        //     console.log("3rd_____________________________________________________________");
                
        // } catch (error) {
        //     console.log("paid");
        // }

    await u20.connect(owner).balanceOf(owner.address).then(res=>{
        console.log("first payment owner balance ", res)
    })

    console.log("________________________________________________________________");
  

    await u20.connect(owner).balanceOf(borrower.address).then(res=>{
        console.log("first payment borrower balance ", res)
    })
    // try check the owner of nft receipt id
    try {
        await  swopXLanding.connect(owner).balanceOf(borrower.address).then(res=>{
            console.log("first payment NFT borrower balance ", res)
            })
        await swopXLanding.connect(owner).ownerOf(1).then(res=>{
                console.log("owner of receipt NFT ", res)
              });
    } catch (error) {
        console.log("burned ---");
    }
   

    
    console.log("________________________________________________________________");

    await nft721.connect(borrower).ownerOf(1).then(res=>{
        console.log("owner of NFT ", res);
      });
    console.log("________________________________________________________________");
    await swopXLanding.connect(owner).assets(0).then(res=>{
        console.log("assets after payment", res)
      });
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