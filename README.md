# SwopX 

## Installation

Install with npm

```bash
  npm install merkletreejs
  npm install keccak256
```
    
## Lending

## 🛠 Usage/Examples

### create the root and Sign
```javascript
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

/* hashing takes :
  -counter: the loan term eg 0,1,2,3,....
  -timestampPayment: array of the loan timestamp and the monthly payment
  the file contains :
  ["timestamp", "Principal", "Interest", "pre Interet", "Per Principal"]
*/

function hashloan(counter, timestampPayment) {
  return Buffer.from(ethers.utils.solidityKeccak256(['uint256','uint256','uint256','uint256','uint256','uint256'], [counter, timestampPayment[0],timestampPayment[1],timestampPayment[2],timestampPayment[3],timestampPayment[4]]).slice(2), 'hex')
}

```

-  Generate the root before Sig

```javascript
    const leaf = Object.entries(times).map(times => hashloan(...times));
    const merkleTree = new MerkleTree(leaf, keccak256,{sortPairs: true})
    const root = merkleTree.getHexRoot()
    console.log("root", root);

```
-  Create signture for starting a loan, this sig comes from the lender and 
it gets sent to the chain by the borrower.

```javascript
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
                // nonce from the backend
                { name: 'paymentContract', type: 'address'}, 
                // erc20 address
                { name: 'offeredTime', type: 'uint256'}, 
                // offeredTime is a timestamp that should be in the future, otherwise this sig will be expired. 
                { name: 'loanAmount', type: 'uint256'}, 
                // Begining Balance
                { name: 'loanCost', type: 'uint256'}, 
                // Total Interest
                { name: 'nftcontract', type: 'address'},
                { name: 'nftOwner', type: 'address'},
                { name: 'nftTokenId', type: 'uint256'},
                { name: 'gist', type: 'bytes32'}, 
                // root
            ], },
            {
                nonce:Number(0),
                paymentContract:u20.address,
                offeredTime: Number(1656459017),
                loanAmount:lendingAmount,
                loanCost:cost,
                nftcontract:nft721.address,
                nftOwner:borrower.address,
                nftTokenId:Number(1),
                gist: root
            },);

```

- **submit** function on the contract

```javascript
    /*
    * @notice: the submit function is called by the borrowers only when there is a agreement on the lending schedule loan 
    * @param _nonce uint256 ID comes from the backend
    * @param _paymentAddress address is the crypto currncy address WETH, USDT, etc
    * @param _lender address is the lender wallet address 
    * @param _nftcontract address
    * @param _nftTokenId uint256
    * @param _loanAmounLoanCost uint256 is an arry of loan amount, loan interest and loan fee
    * @param _offeredTime uint256 needs to be a future timestamp  
    * @param _gist bytes32, the root value 
    * @param signature bytes value
    */
    const submitLanding = await swopXLanding.connect(borrower).submit(
      _nonce, _paymentContract, _lender, 
      _nftcontract, _nftTokenId, _loanAmounLoanCostFee,
      _offeredTime,root, signature);
    await submitLanding.wait();

```