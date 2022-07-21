// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface iSwopXLending {
    function currencyTokens(address _contract) external
    view returns(bool);

    function assets(uint256 counterId) 
    external view returns (
        address paymentAddress,
        uint256 listingTime,
        uint256 termId,
        address nftContractAddress, uint256 nftTokenId,
        uint256 loanAmount, uint256 loanInterest, uint256 paidInterest,
        uint256 paymentLoan, uint256 totalPaid, bool isPaid) ;

    function receipt(uint256 counterId) 
    external view returns (
        uint256 lenderToken,
        uint256 borrowerToken);
    
    function submit(uint256 [2] calldata nonces , address _paymentAddress, address _lender, 
            address _nftcontract, 
            uint256 _nftTokenId,
            uint256 [3] calldata _loanAmounLoanCost,
            uint256 _offeredTime, bytes32 _gist, bytes calldata borrowerSignature, bytes calldata lenderSignature) 
    external ;

    function makePayment(uint256 _counterId, uint256 term_, 
                        uint256[] calldata loanTimestampPaymentInterest, uint256 fee_, bytes32[] calldata proof) 
    external;

    function makePrePayment(uint256 _counterId, uint256 term_, 
                        uint256[] calldata loanTimesPaymentInterest, uint256[] calldata preLoanTimes,
                        uint256 fee_, bytes32 [] calldata proof,bytes32 [] calldata preProof) 
    external;

    function defaultAsset(uint256 _counterId, 
    uint256[] calldata loanTimesPaymentInterest, uint256 fee_, bytes32[] calldata proof) external;

    function isDefaulted(uint256 _counterId,  uint256[] calldata loanTimesPaymentInterest, bytes32[] calldata proof) 
    view external returns(bool);

    function cancel(uint256 nonce, address _account) 
    external ;

    function isNonceUsed(uint256 nonce, address _lender)
    external view returns(bool _isNonceUsed);

    function calculatedFee(uint256 _amount) 
    external view returns(uint fee);

    function calculatedInterestFee(uint256 _amount) 
    external view returns(uint fee) ;

    function extendTheTime(uint256 [2] calldata nonces, uint256 _counterId, uint256 loanInterest, uint256 currentTerm_, uint256 _offeredTime, bytes32 gist ,
    bytes [2] calldata signatures) 
   external; 

   function transferFrom(address from, address to, uint256 token) external;
   function approve( address to, uint256 token) external;
   function ownerOf(uint256 token) external view returns(address _address);


}