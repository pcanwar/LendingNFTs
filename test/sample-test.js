// const { ethers } = require('hardhat');
// const { MerkleTree } = require('merkletreejs');
// const keccak256 = require('keccak256');
// const { expect } = require('chai');
// const times = require('./pay.json');

// function hashToken(time, counter) {
//   return Buffer.from(ethers.utils.solidityKeccak256(['uint256', 'uint256'], [time, counter]).slice(2), 'hex')
// }




// describe('Merkle', function () {
//   it("Test mint White List  ", async function () {
//   accounts = await ethers.getSigners();
//   const [owner, buyer1, buyer2, buyer3, buyer4] = await ethers.getSigners();

//   merkleTree = new MerkleTree(Object.entries(times).map(times => hashToken(...times)), keccak256, { sortPairs: true }); 
//   let token = {};
//   cal = {};
//   let root ;
//   for (const [time, counter] of Object.entries(times)){
//     console.log(time, counter);
//     root = merkleTree.getHexRoot(hashToken(time, counter))
    
//     token.proof = merkleTree.getHexProof(hashToken(time, counter));
//     [cal.counter, cal.time ] = Object.entries(times).find(Boolean);
//     cal.proof = merkleTree.getHexProof(hashToken(cal.counter, cal.time))
//    }
//    console.log('token', token.proof);
//    console.log('root:- ', root);
//   //  console.log('tome:- ', time);


 
//   // cal.proof = merkleTree.getHexProof(hashToken(cal.time, cal.counter))
//   console.log("counter", cal);

//     // token = {};
//     // [ token.counter, token.time ] = Object.entries(times).find(Boolean);
//     // token.proof = merkleTree.getHexProof(hashToken(token.counter, token.time));
//     // console.log(token.proof);
   
//     // const root = merkleTree.getRoot();
//     // console.log("root", merkleTree.getHexRoot());
//     // user side using msg.sender
//     // const claimingBuyer1 = merkleTree.getHexProof(leaf[3]);
//     // console.log("claimingBuyer1", merkleTree.getHexProof(leaf[3]));
    
    
    
//     const SwopXFactory = await ethers.getContractFactory("Merkle");
//     registry = await SwopXFactory.deploy('Name', 'Symbol');
//     await registry.deployed();
//     await registry.connect(owner).setRoot(root)

//     // const adr = whiteList[3];
//     await registry.connect(buyer3).redeem(buyer3.address, cal.time, cal.proof)
//     // await registry.balanceOf(adr).then(res=>{
//     //     console.log("balanceOf ", res);
//     // });
//     // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)
//     // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)

//     // await registry.balanceOf(adr).then(res=>{
//     //     console.log("balanceOf ", res);
//     // });

//     // await registry._leaf(adr).then(res=>{
//     //     le = res;
//     //     console.log("_leaf ", res);
//     // });

    
//   });

// });