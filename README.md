# SwopX 

## Installation

Install with npm

```bash
  npm install merkletreejs
  npm install keccak256
```
    
## Lending

## Usage/Examples

### Sign
```javascript
const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');

/* hashing takes :
  -counter: the loan term eg 0,1,2,3,....
  -timestampPayment: array of the loan timestamp and the monthly payment
*/
//  ["timestamp", "Principal", "Interest", "pre Interet", "Per Principal" ],
function hashloan(counter, timestampPayment) {

  return Buffer.from(ethers.utils.solidityKeccak256(['uint256','uint256','uint256','uint256','uint256','uint256'], [counter, timestampPayment[0],timestampPayment[1],timestampPayment[2],timestampPayment[3],timestampPayment[4]]).slice(2), 'hex')
}


```
