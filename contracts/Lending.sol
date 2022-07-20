
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./iSwopXLending.sol";

contract LendingAPI {
    
    
    address private immutable swopXLending = 0x7fE9a07F48bcde7E0ee7D31CbAF24c7e8934b383;
    
    function startLoan(
            uint256 [2] calldata nonces , 
            address _paymentAddress, 
            address _lender, 
            address _nftcontract, 
            uint256 _nftTokenId,
            uint256 [3] calldata _loanAmounLoanCost,
            uint256 _offeredTime, bytes32 _gist, bytes calldata borrowerSignature, bytes calldata lenderSignature, address api)
             external  {

                iSwopXLending(swopXLending).submit(nonces,
                    _paymentAddress, _lender, 
                    _nftcontract, 
                    _nftTokenId,
                    _loanAmounLoanCost,
                    _offeredTime, _gist, borrowerSignature,lenderSignature
                );


                
               // https://api.bazaarxchanges.com/api/lending/client/1/

            }


    
}
