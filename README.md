# SwopX 

## Installation

Install with npm

```bash
  npm install merkletreejs
  npm install keccak256
```
    
## Lending

## 🛠 Usage/Examples


**Amortization schedule example**
- the 0 term represents the per payment timestamp, after this timestamp borrower can not run the pre payment 
- other terms represent the monthly payment, eg.

** json file follows this formate 
Term Seq: ["timestamp", "Principal", "Interest", "pre Interet", "Per Principal" ]

```json
{   
    "0": ["1656719350", "0","16666666666666667", "2000000000000000000","10000000000000000000"],
    "1": ["1656719350", "0","16666666666666667", "2000000000000000000","10000000000000000000"],
    "2": ["1656719350", "0","16666666666666667", "1888888888888888883","10000000000000000000"],
    "3": ["1656719350", "0","16666666666666667", "1666666666666666663","10000000000000000000"],
    "4": ["1656719350", "10000000000000000000","1666666666666666667", "0","0"]

}

```

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

- **cancel** function on the contract

Lender can cancel their sig and root at any time before the borrower start the loan. Once the loan starts, the lender can not cancel the deal.
```javascript
/*
* @notice: only lender can cancel their offer usin their nonces that they use to sign the loan deal
* @param nonce uint256 ID comes from the backend and it can be used  once   
* @param _lender address 
*/

await swopXLanding.connect(lender).cancel(nonce, _lender);

```
- **submit** function on the contract
The borrower start a loan when they submit the deal

```javascript
    /*
    * @notice: the submit function is called by the borrowers only when there is a agreement on the lending schedule loan 
    * @param _nonce uint256 ID comes from the backend and it can be used  once   .
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

- **makePayment** function on the contract
```javascript
/*
* @notice: needs to get calculate interest fee before make a payment
* On the backend  there is two events needs to be ran
* @param termInterest uint256 is a the interest value from a json file 
*/
let feeInterest ;
await swopXLanding.calculatedInterestFee(termInterest).then(res=>{
    feeInterest = res;
});

/*
* @notice: make payment is a way to pay a loan by a borrower, and 
* the payment has to follow the term's array in the json file.
* at the end of the payment term both nft receite tokens will get  burned.
* On the backend  there is two events needs to be ran
* @param nftreceipt or counterid uint256 is the main id of the lending and each counter contains two nft receites 
* @param term1st uint256 each term to pay the pre payment 
* @param loanTimestampLoanPayment the arry of the term
* @param feeInterest uint256 is based on the interest fee
* @param payFirstMonth 
*/


const makePayment = await swopXLanding.connect(borrower).makePayment(nftreceipt, term1st, 
loanTimestampLoanPayment,feeInterest,payFirstMonth);
await makePayment.wait();

```

- **makePerPayment** function on the contract
```javascript

/*
* @notice: needs to get calculate interest fee before make a payment
* On the backend  there is two events needs to be ran
* @param termInterest uint256 is a the interest value from a json file 
*/
let feeInterest ;
await swopXLanding.calculatedInterestFee(termInterest).then(res=>{
    feeInterest = res;
});

/*
    * @notice: make pre payment is an early repayment of all amount loan and interest loan by a borrower, NFT receipt can identify the addresses of the lender and borrower. 
    * verifiying tow proofs, the per Proof which needs to be beofre the per timestamp and proof which is the current term.
    * Both NFT receipts get burn. 
    For backend, there is two events needs to be ran.
  
    * @param nftreceipt/_counterId uint256 is the main id of the lending receipt. 
    * @param _counterId/nftreceipt uint256 is the main id of the lending 
    * @param term_ uint256 each term to pay the pre payment 
    * @param loanTimesPaymentInterest uint256 is an arry of the current term timestamp , payment loan, and interest.
    * @param preLoanTimes uint256 is an arry of the timestamp of the 0 index term
    * @param fee_ of the interest
    * @param proof of the _term 
    * @param preProof of the 0 term's interest
*/
const makePerPayment = await swopXLanding.connect(borrower).makePrePayment(nftreceipt, term_,
    loanTimesPaymentInterest,preloanTimes,feePerinterest,firstproof,preProof);
await makePerPayment.wait();

```

- **default** function on the contract
When the borrower fail to pay the loan 
```javascript
/*
* @notice: lender can run the defaultAsset func if the borrower didn't make pay of current term, the lender needs to pay the interest fee in order to receive the NFT. 
* @param nftreceipt/_counterId uint256 is the main id of the lending receipt. 
* @param _counterId/ uint256 each term to pay the pre payment 
* @param loanTimestampLoanPayment uint256 is an arry of the current term timestamp , and payment loan
* @param preLoanTimes uint256 is an arry of the timestamp of the 0 index term
* @param fee_ uint256 is the interest fees that need to be paid by the lender
* @param proof bytes of the current _term 
*/
const defaultAsset = await swopXLanding.connect(lender).
defaultAsset(_counterId, loanTimestampLoanPayment, fee_,proof);
await defaultAsset.wait();

```


- **extendTime** function on the contract
this to renew the root 
```javascript

```