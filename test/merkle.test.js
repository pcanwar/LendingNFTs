// const { ethers } = require('hardhat');
// const { MerkleTree } = require('merkletreejs');
// const keccak256 = require('keccak256');
// const { expect } = require('chai');
// const times = require('./pay.json');
// // 
// function hashToken(counter, time ) {
//   return Buffer.from(ethers.utils.solidityKeccak256(['uint256','uint256','uint256','uint256'], [counter, time[0],time[1],time[2]]).slice(2), 'hex')
// }






// describe('Merkle', function () {
//   it("Merkle contract Test mint  ", async function () {
//     accounts = await ethers.getSigners();
//     const [owner, buyer1, buyer2, buyer3, buyer4] = await ethers.getSigners();
//     // root hash
//     const  leaf = Object.entries(times).map(times => hashToken(...times)); 
//     console.log("leaf: ", leaf);
//     const merkleTree = new MerkleTree(leaf, keccak256,{sortPairs: true})
//     const root = merkleTree.getHexRoot()
//     console.log("root", root);
//     const payFirstMonth = merkleTree.getHexProof(leaf[0]);
//     console.log("pay First Month : ", payFirstMonth);

//     const instance = await ethers.getContractFactory("Merkle");
//     registry = await instance.deploy('Name', 'Symbol');
//     await registry.deployed();

//     await registry.connect(owner).setRoot(merkleTree.getHexRoot())
//     await registry.connect(owner).redeem(owner.address, 0,["1655338240","25000","0"], payFirstMonth)
    
//     await registry.balanceOf(owner.address).then(res=>{
//         console.log("balanceOf ", res);
//     });

// //   for (const [ counter, time] of Object.entries(times)){
// //     // console.log("counters and times: ", counter, time[0], time[1]);

// //     root = merkleTree.getHexRoot()
// //     console.log(root);
// //     token.proof = merkleTree.getHexProof(hashToken( counter, time));
// //     console.log('proof', token.proof);
// //     // [cal.counter, cal.time ] = Object.entries(times).find(Boolean);
// //     // hashToken(cal.counter, cal.time)

// //     // console.log("counter: ", cal.counter);
// //     // console.log("time: ", cal.time[0]);
// //     // console.log( "ETH: ", cal.time[1]);
// //     // console.log( "interest: ", cal.time[2]);
// //     // cal.proof = merkleTree.getHexProof(hashToken(counter, cal.time ))
// //    }
  
// //   // cal.proof = merkleTree.getHexProof(hashToken(cal.time, cal.counter))
// //   // console.log("counter: ", cal.counter);
// //   // console.log("time: ", cal.time[0]);
// //   // console.log( "ETH: ", cal.time[1]);
// //   // console.log( "interest: ", cal.time[2]);

// //   // console.log( "ETH: ", cal.time[Object.keys(cal.time)[0]][0]);
// //   // console.log( "rate inter: ", cal.time[Object.keys(cal.time)[0]][1]);

// //   // var allTrue = Object.keys(times).every(function(k){ return times[k] });
// //   //  console.log(allTrue);
// //     // token = {};
// //     // [ token.counter, token.time ] = Object.entries(times).find(Boolean);
// //     // token.proof = merkleTree.getHexProof(hashToken(token.counter, token.time));
// //     // console.log(token.proof);
   
// //     // const root = merkleTree.getRoot();
// //     // console.log("root", merkleTree.getHexRoot());
// //     // user side using msg.sender
// //     // const claimingBuyer1 = merkleTree.getHexProof(leaf[3]);
// //     // console.log("claimingBuyer1", merkleTree.getHexProof(leaf[3]));
    
    
    
// //     // const SwopXFactory = await ethers.getContractFactory("Merkle");
// //     // registry = await SwopXFactory.deploy('Name', 'Symbol');
// //     // await registry.deployed();
// //     // await registry.connect(owner).setRoot(root)

// //     // // const adr = whiteList[3];
// //     // await registry.connect(buyer3).redeem(buyer3.address, cal.time, cal.proof)
// //     // await registry.balanceOf(adr).then(res=>{
// //     //     console.log("balanceOf ", res);
// //     // });
// //     // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)
// //     // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)

// //     // await registry.balanceOf(adr).then(res=>{
// //     //     console.log("balanceOf ", res);
// //     // });

// //     // await registry._leaf(adr).then(res=>{
// //     //     le = res;
// //     //     console.log("_leaf ", res);
// //     // });

    
//   });

// });