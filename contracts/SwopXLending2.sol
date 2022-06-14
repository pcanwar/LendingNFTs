// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.8;

// import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
// import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
// import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// contract SwopXLendingAssets is EIP712 {
//     /* 
//     SwopXLendingAssets is for lenders to sign a message  
//     */

//     constructor()  EIP712("SwopXLending","1.0"){
 
//     }

//     function _hashLending(uint256 nonce,address paymentContract,
//     uint256 offeredTime,uint256 loanAmount,uint256 loanTerm,uint256 loanCost,
//     address nftcontract,address nftOwner,
//     uint256 nftTokenId,bytes32 root) 
//     public view returns (bytes32)
//     {
//         return _hashTypedDataV4(keccak256(abi.encode(
//             keccak256("Landing(uint256 nonce,address paymentContract,uint256 offeredTime,uint256 loanAmount,uint256 loanTerm,uint256 loanCost,address nftcontract,address nftOwner,uint256 nftTokenId,bytes32 root)"),
//             nonce,
//             paymentContract,
//             offeredTime,
//             loanAmount,
//             loanTerm,
//             loanCost,
//             nftcontract,
//             nftOwner,
//             nftTokenId,            
//             root
//         )));
//     }


//     function _hashextendTime(address nftcontract,
//     uint256 nftTokenId, uint256 pirodOfTime, uint256 cost) 
//     internal view returns (bytes32)
 
//     {
//         return _hashTypedDataV4(keccak256(abi.encode(
//             keccak256("Extending(address nftcontract,uint256 nftTokenId,uint256 pirodOfTime,uint256 cost)"),
//             nftcontract,
//             nftTokenId,
//             pirodOfTime,
//             cost
//         )));
//     }

//     function _verify(address signer, bytes32 digest, bytes memory signature)
//     internal view returns (bool)
//     {
//         return SignatureChecker.isValidSignatureNow(signer, digest, signature);
//     }

// }

// contract SwopXLending is Ownable, ReentrancyGuard, IERC721Receiver, SwopXLendingAssets, Pausable {

//     using Counters for Counters.Counter;
//     Counters.Counter private _IdCounter;     
//     using SafeERC20 for IERC20;
//     uint256 private txfee;
//     uint256 private extendedTime;
//     // uint256 private maximumTenure;

//     struct LendingAssets {
//         address paymentContract;
//         uint256 listingTime;
//         uint256 loanTerm;
//         uint256 loanAmount;
//         uint256 loanCost;
//         uint256 payAmountAfterLoan;
//         uint256 payBackAfterLoan;
//         bool isPaid;
//         address lender;
//         address nftcontract;
//         address nftOwner;
//         uint256 nftTokenId;
//         bytes32 root;
//     }

//     mapping(uint256 => LendingAssets) private _assets;
//     mapping(IERC20=> bool) private erc20Addrs;
//     mapping(address => mapping(uint256 => bool)) private identifiedSignature;

//     // Event of a new lending/borowing submition 
//     event AssetsLog(
//         uint256 counter,
//         address indexed owner,
//         address indexed tokenAddress,
//         uint256 tokenId,
//         address indexed lender,
//         address currentAddress,
//         uint256 loanAmount,
//         uint256 loanCost,
//         uint256 timeRequired,
//         uint256 payAmountAfterLoan
//     );

//     // event CancelLog(address indexed lender, address nftAdress, uint256 tokenId, bool IsUninterested);

//     event CancelLog(address indexed lender, uint256 tokenId, bool IsUninterested);
//     event WithdrawLog(address indexed contracts, address indexed account, uint amount);
    
//     event ExtendTimeLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, address  lender,address borrower, uint256 _loanTerm, uint256 cost );
    
//     event PayBackLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, address indexed borrower,address lender, uint256 amount, uint fee );
    
//     event DefaultLog(uint256 indexed counterId, address nftcontract, uint256 tokenId, address indexed lender, uint fee);
//     event PusedTransferLog(address indexed nftcontract, address indexed to, uint256 tokenId);

//     constructor() {
//         txfee = 200; // fees
//         // maximumTenure = 12; // 12 months
//         extendedTime = 30 days; // 30 days
//     }


//     modifier supportInterface(address _contract) {
//         require(erc20Addrs[IERC20(_contract)] == true,"Contract address is not Supported ");
//         _;
//     }

//     // modifier expiredTime(uint256 _loanTerm) {
//     //     require(_loanTerm <= maximumTenure && _loanTerm >= 1, "It can't be more than maximum tenure value"); // add months number
//     //     _;
//     // }
//     // only owner of the contract is allowed to change fees
//     function resetTxFee(uint256 _fee) public onlyOwner { 
//         txfee = _fee;
//     }


//     // only owner of the contract is allowed to change max number of months . 
//     // 1 year = 12 month , and 2 year is 24 months
//     // function resetMaximumTenure(uint256 _maximumTenure) public onlyOwner { 
//     //     maximumTenure = _maximumTenure;
//     // }


//     // add ERC20 token contract address
//     function addToken(address _contract, bool _mode) external onlyOwner {
//         require( _contract != address(0) , "Zero Address");
//         erc20Addrs[IERC20(_contract)] = _mode;    
//     }

//     // check what ERC20 token is available
//     function currencyTokens(address _contract) external view returns(bool){
//         return erc20Addrs[IERC20(_contract)];
//     }

//     // return the assets 
//     function assets(uint256 counterId) public view returns (
//         address _paymentAddress,
//         uint256 _listingTime,
//         uint256 _loanTerm,
//         address _lender,
//         address _nftOwner,
//         address _nftContractAddress,
//         uint256 _nftTokenId,
//         uint256 _loanAmount, uint256 _lendCost, uint256 _feesCost,
//         uint256 _payAmountAfterLoan,bool _isPaid) {

//         _paymentAddress = _assets[counterId].paymentContract;
//         _listingTime = _assets[counterId].listingTime;
//         _loanTerm = _assets[counterId].loanTerm;
//         _lender = _assets[counterId].lender;
//         _nftOwner = _assets[counterId].nftOwner;
//         _nftContractAddress = _assets[counterId].nftcontract;
//         _nftTokenId = _assets[counterId].nftTokenId;
//         _loanAmount = _assets[counterId].loanCost;
//         _lendCost = _assets[counterId].loanAmount;
//         _feesCost = calculatedFee(_lendCost);
//         _payAmountAfterLoan = _assets[counterId].payAmountAfterLoan;
//         _isPaid = _assets[counterId].isPaid;
//     }
      
//     // verify the signature
//     // function verifyIt( address verifer, uint256 nonce, address paymentContract, uint256 _loanAmount,
//     // address _nftcontract,address nftowner, uint256 tokenID,uint256 loanTerm,uint256 cost,uint256 offeredTime, bytes32 _root, bytes calldata signature) private view {
//     //     require(_verify(verifer, _hashLending(nonce,
//     //         paymentContract,_loanAmount, _nftcontract,
//     //         nftowner,tokenID,loanTerm,cost,offeredTime,_root)
//     //         ,signature),"signature"); 
//     // }

//     // counter 
//     function counter() private returns(uint256 counterId){
//         _IdCounter.increment();
//         counterId = _IdCounter.current();
//     }


//     // borrowr needs to submit the lender's offer
//     // _offeredTime is time to offer and takes a future timestamp
//     // _loanTerm is number of months
    
//    function submit(uint256 [2] calldata nonceLoanTerm, address _paymentAddress, address _lender, 
//                     address _nftcontract, uint256 _nftTokenId, uint256 [2] calldata _loanAmounLoanCost,
//                     // uint256 _loanAmount, uint256 _loanCost,
//                     // uint256 _loanTerm,
//                       uint256 _offeredTime, 
//                     bytes32 _root, bytes calldata signature) 
//         public whenNotPaused nonReentrant supportInterface(_paymentAddress) 
//         // expiredTime(nonceLoanTerm[1])
//        {
        
//         LendingAssets memory _m = LendingAssets({
//         paymentContract: address(_paymentAddress),
//         listingTime: clockTimeStamp(),
//         loanTerm:nonceLoanTerm[1],
//         loanAmount:_loanAmounLoanCost[0],
//         loanCost: _loanAmounLoanCost[1],
//         payAmountAfterLoan:_loanAmounLoanCost[0] + _loanAmounLoanCost[1],
//         payBackAfterLoan:0,
//         isPaid:false,
//         lender:_lender,
//         nftcontract:_nftcontract,
//         nftOwner:msg.sender,
//         nftTokenId:_nftTokenId,
//         root: _root
//         });
//         require(_ownerOf(_m.nftcontract, _m.nftTokenId) == msg.sender ,"Not Owner");
//         require(identifiedSignature[_m.lender][nonceLoanTerm[0]] != true, "Lender is not interested");
//         require(_offeredTime >= clockTimeStamp(), "offer expired" );
//         require(IERC20(_m.paymentContract).allowance(_m.lender, address(this)) >= _m.loanCost, "Not enough allowance" );
//         uint256 fees_ = calculatedFee(_m.loanAmount);
//         require(_verify(_m.lender, _hashLending(nonceLoanTerm[0],
//             _m.paymentContract,_offeredTime,_m.loanAmount,_m.loanTerm,_m.loanCost,_m.nftcontract,
//             msg.sender,_m.nftTokenId,_m.root)
//             ,signature),"signature");
        
//         // verifyIt(_m.lender, nonce, _m.paymentContract,_m.loanAmount,
//         // _m.nftcontract, msg.sender,_m.nftTokenId,_m.loanTerm,_m.loanCost, _offeredTime, _m.root, signature);
//         uint256 counterId = counter();
//         _assets[counterId] = _m;
//         _transferNft(_nftcontract, msg.sender , _nftTokenId);
//         IERC20(_m.paymentContract).safeTransferFrom(_m.lender, owner(), fees_);
//         IERC20(_m.paymentContract).safeTransferFrom(_m.lender, msg.sender, _m.loanCost - fees_);
//         emit AssetsLog(
//             counterId,
//             _m.nftOwner,
//             _m.nftcontract,
//             _m.nftTokenId,
//             _m.lender,
//             _m.paymentContract,
//             _m.loanCost,
//             fees_,
//             _m.loanTerm,
//             _m.payAmountAfterLoan);
//     }

//     // make payment before time expired
//     function makePayment(uint256 _counterId, uint256 term_, 
//     uint256 time, uint256 loanAmountInterest, 
//     bytes32[] calldata proof) public nonReentrant {

//         LendingAssets memory _m = _assets[_counterId];

//         address contractOwner  = owner();
//         address from = msg.sender;
//         require(_m.isPaid != true, "is paid already");
//         require(_m.nftOwner == from,"Only NFT owner");
//         require(time >= block.timestamp, "expired");
     
//         require(_verifyTree(_leaf(0 , term_), proof, _m.root), "Invalid merkle proof");
//         _assets[_counterId].payAmountAfterLoan -= loanAmountInterest;
//         uint256 _time = clockTimeStamp();
//         require(_m.loanTerm  >= _time, "Default");
//         address _to = _m.lender;
//         address _contract = _m.nftcontract;
//         uint256 tokenId = _m.nftTokenId;
//         uint256 _fees = calculatedFee(_m.loanAmount);
//         uint256 amountToPay = _m.payAmountAfterLoan;
//         require(IERC20(_m.paymentContract).allowance(from, address(this)) >= amountToPay,"Not enough allowance" );
//         require(IERC20(_m.paymentContract).balanceOf(from) >= amountToPay,"Not enough Balance" );
//         IERC20(_m.paymentContract).safeTransferFrom(from, contractOwner, _fees);
//         IERC20(_m.paymentContract).safeTransferFrom(from, _m.lender, amountToPay - _fees);
//         IERC721(_contract).safeTransferFrom(address(this), from, tokenId);
//         _assets[_counterId].isPaid = true;
//         emit PayBackLog(_counterId, _contract, tokenId, from, _to, _m.payAmountAfterLoan, _fees);
//     }


//     function clockTimeStamp() private view returns(uint256 x){
//         x = block.timestamp;
//     }

//     // default NFT 
//     function defaultAsset(uint256 _counterId) external nonReentrant  {
//         address contractOwner  = owner();
//         LendingAssets memory _m = _assets[_counterId];
//         require(_m.isPaid != true, "is paid already");
//         uint256 _time = clockTimeStamp();
//         require(_m.loanTerm  < _time,"Check the Time");
//         address _to = _m.lender;
//         require(_to == msg.sender);
//         uint256 _fees = calculatedFee(_m.loanAmount);
//         require(IERC20(_m.paymentContract).allowance(_to,address(this)) >= _fees,"Not enough allowance" );
//         address e721Address = _m.nftcontract;
//         uint256 tokenId = _m.nftTokenId;
//         IERC20(_m.paymentContract).safeTransferFrom(_to, contractOwner, _fees);
//         IERC721(e721Address).safeTransferFrom(address(this), _to, tokenId);
//         emit DefaultLog(_counterId, e721Address, tokenId, msg.sender, _fees);
//     }

//     // only lender can cancel their offer usin their nonces
//     function cancel(uint256 nonce, address _lender) external   {
//         require(_lender == msg.sender, "Not a Lender");
//         require(identifiedSignature[_lender][nonce] != true, "Not interested");
//         identifiedSignature[_lender][nonce] = true;
//         emit CancelLog(_lender,nonce, true);
//     }

//     function isNonceUsed(uint256 nonce, address _lender) external view returns(bool _isNonceUsed){
//         _isNonceUsed = identifiedSignature[_lender][nonce];
//     }
    

//     function calculatedFee(uint256 _amount) public view returns(uint fee) {
//         uint _txfee = txfee;
//         uint callItFee = _amount * _txfee;
//         fee = callItFee / 1e4;
//     }

//     function _transferNft(address _nftcontract, address _nftOwner,  uint256 _nftTokenId) private {
//         IERC721(_nftcontract).safeTransferFrom(_nftOwner, address(this), _nftTokenId);
//     }

//     function _extendTimeRole(uint256 _days) public onlyOwner {
//         extendedTime = 1 days * _days;
//     }

//    // lender or borrower can extend the time with a new cost they need to submit.
//    function extendTheTime(uint256 _counterId,uint256 _loanTerm, uint256 cost,bytes calldata signature, bytes calldata signatureB) 
//    nonReentrant external {
//         LendingAssets memory _m = _assets[_counterId];
//         uint256 _extendTime = extendedTime;
//         uint256 _time = clockTimeStamp();
//         require(_m.loanTerm - _extendTime >= _time,"No Extended Time");
//         require(_m.isPaid != true,"Paid");
//         require(_m.payAmountAfterLoan > 0,"Amount");
//         require(_m.nftOwner == msg.sender || _m.lender == msg.sender,"Owners Only");

//         require(_verify(_m.lender, _hashextendTime(
//               _m.nftcontract,
//               _m.nftTokenId, _loanTerm, cost)
//             , signature), "lender signature");
//         require(_verify(_m.nftOwner, _hashextendTime(
//               _m.nftcontract,
//               _m.nftTokenId, _loanTerm, cost)
//             , signatureB), "borrower signature");
        
//         uint256 requredpayment= _m.payAmountAfterLoan;

//         _assets[_counterId].payAmountAfterLoan = requredpayment + cost;
//         _assets[_counterId].loanAmount += cost;
//         uint _timeRequired = calculatedTimeExpired(_loanTerm);
//         _assets[_counterId].loanTerm += _timeRequired;
//         emit ExtendTimeLog(
//             _counterId, 
//             _m.nftcontract,
//             _m.nftTokenId,
//             _m.lender,
//             _m.nftOwner,
//           _m.loanTerm,
//           _m.loanAmount);
//     }

    
//     // to get calculate expired time that based on the number of months 
//     function calculatedTimeExpired(uint256 _month) private pure returns(uint256) {
//         return 30 days * _month;
//     }


//     function withdraw(address _contract, address _to, uint256 _amount) external onlyOwner {
//         IERC20(_contract).safeTransfer(_to, _amount);
//         emit WithdrawLog(_contract, _to, _amount);
//     }


//     // this is only if the nft gets locked or pused contract 
//     function NFTw(address _nftcontract, address _to, uint256 tokenId) external onlyOwner {
//         IERC721(_nftcontract).safeTransferFrom(address(this), _to, tokenId);
//         emit PusedTransferLog(_nftcontract, _to, tokenId);
//     }


//     function _ownerOf(address _nftcontract, uint256 tokenId ) private view returns(address) {
//         return IERC721(_nftcontract).ownerOf(tokenId);
//     }

//     function totalSupply() public view returns (uint256 _allTokens) {
//         return _allTokens = _IdCounter.current() ;
//     }

//     function _leaf(uint256 counter, uint256 time)
//     internal pure returns (bytes32)
//     {
//         return keccak256(abi.encodePacked(counter, time));
//     }

//     function _verifyTree(bytes32 leaf,  bytes32[] memory proof, bytes32 root)
//     internal view returns (bool)
//     {
        
//         return MerkleProof.verify(proof, root, leaf);
//     }

//     function onERC721Received(address , address , uint256 , bytes memory) external pure override returns (bytes4){
//         return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
//     }

// }