const { ethers } = require('hardhat');
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const { expect } = require('chai');
const times = require('./time.json');

function hashToken(time, counter) {
  return Buffer.from(ethers.utils.solidityKeccak256(['uint256', 'uint256'], [time, counter]).slice(2), 'hex')
}




describe('Merkle', function () {
    it("Test mint White List  ", async function () {
    accounts = await ethers.getSigners();
    const [owner, buyer1, buyer2, buyer3, buyer4] = await ethers.getSigners();
  

    // collection owner:
    // const leaf = whiteList.map(addr=> ethers.utils.solidityKeccak256(['address'], [addr]));
    // console.log("-+", leaf[3]);
    merkleTree = new MerkleTree(Object.entries(times).map(token => hashToken(...token)), keccak256, { sortPairs: true }); 
    // const merkleTree = new MerkleTree(leaf, keccak256,{sortPairs: true})
    // const root = merkleTree.getRoot();
    console.log("root", merkleTree.getHexRoot());
    // user side using msg.sender
    // const claimingBuyer1 = merkleTree.getHexProof(leaf[3]);
    // console.log("claimingBuyer1", merkleTree.getHexProof(leaf[3]));
    
    
    
    // const SwopXFactory = await ethers.getContractFactory("Merkle");
    // registry = await SwopXFactory.deploy('Name', 'Symbol', merkleTree.getHexRoot());
    // await registry.deployed();

    // const adr = whiteList[3];
    // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)
    // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)
    // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)
    // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)
    // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)
    // await registry.balanceOf(adr).then(res=>{
    //     console.log("balanceOf ", res);
    // });
    // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)
    // await registry.connect(buyer3).redeem(buyer3.address, claimingBuyer1)

    // await registry.balanceOf(adr).then(res=>{
    //     console.log("balanceOf ", res);
    // });

    // await registry._leaf(adr).then(res=>{
    //     le = res;
    //     console.log("_leaf ", res);
    // });

    
  });

});