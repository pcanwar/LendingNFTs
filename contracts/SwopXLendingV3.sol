// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract SwopXLendingAssets is EIP712 {

    /* 
        SwopXLendingAssets is for lenders to sign a message  
    */

    constructor()  EIP712("SwopXLending","1.0"){
 
    }

    function _hashLending(uint256 nonce,address paymentContract,
        uint256 offeredTime,uint256 loanAmount,uint256 loanCost,
        address nftcontract,address nftOwner,
        uint256 nftTokenId,bytes32 gist) 
        public view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Landing(uint256 nonce,address paymentContract,uint256 offeredTime,uint256 loanAmount,uint256 loanCost,address nftcontract,address nftOwner,uint256 nftTokenId,bytes32 gist)"),
            nonce,
            paymentContract,
            offeredTime,
            loanAmount,
            loanCost,
            nftcontract,
            nftOwner,
            nftTokenId,            
            gist
        )));
    }

    function _hashextend(address nftcontract,
    uint256 nftTokenId, uint256 offerTime, uint256 cost, bytes32 gist) 
    internal view returns (bytes32)
 
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Extending(address nftcontract,uint256 nftTokenId,uint256 offerTime,uint256 cost,bytes32 gist)"),
            nftcontract,
            nftTokenId,
            offerTime,
            cost,
            gist
        )));
    }

    function _verify(address signer, bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
        return SignatureChecker.isValidSignatureNow(signer, digest, signature);
    }

}


contract SwopXLendingV3 is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, ReentrancyGuard, IERC721Receiver, SwopXLendingAssets, Pausable {

    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter private _IdCounter;  
    Counters.Counter private _nftCounter;  
    // Counters.Counter private _termId;  
    uint256 private txfee;

    uint256 private txInterestfee;
    string private _baseMetadata;

    // mapping(uint256 => uint256) private interest;
    // mapping(uint256 => mapping(address => uint256)) private balances;

    struct LendingAssets {
        address paymentContract;
        uint256 listingTime;
        uint256 loanAmount;
        uint256 loanCost;
        uint256 paidInterest;
        uint256 payAmountAfterLoan;
        uint256 payBackAfterLoan;
        uint256 termId;
        bool isPaid;
        // address lender;
        address nftcontract;
        // address nftOwner;
        uint256 nftTokenId;
        bytes32 gist;
    }
    struct Receipt {
        uint256 lenderBalances;
        uint256 borrowerBalances;
    }

    mapping(uint256 => LendingAssets) private _assets;
    mapping(uint256 => Receipt) private _receipt;

    mapping(IERC20=> bool) private erc20Addrs;
    mapping(address => mapping(uint256 => bool)) private identifiedSignature;

    // Event of a new lending/borowing submition 
    event AssetsLog(
        uint256 counter,
        address indexed owner,
        address indexed tokenAddress,
        uint256 tokenId,
        address indexed lender,
        address currentAddress,
        uint256 loanAmount,
        uint256 loanCost,
        uint256 payAmountAfterLoan,
        bytes32 gist
    );

    event CancelLog(address indexed lender, uint256 nonce, bool IsUninterested);
    
    event WithdrawLog(address indexed contracts, address indexed account, uint amount);
    
    event ExtendTimeLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, address lender,address borrower, uint256 currentTerm, uint256 payAmountAfterLoan, bytes32 gist  );
    
    event PayBackLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, address indexed borrower,address lender, uint256 paidAmount, uint256 currentTerm, uint256 fee,bytes32 [] proof );
    
    event PrePayLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, address indexed borrower,address lender, uint256 fee,bytes32 [] proof );

    
    event DefaultLog(uint256 indexed counterId, address nftcontract, uint256 tokenId, address indexed lender, uint fee);
    
    event PusedTransferLog(address indexed nftcontract, address indexed to, uint256 tokenId);

    constructor() ERC721("SwopX", "SWING") {
        txfee = 200;
        txInterestfee = 1000;
    }


    modifier supportInterface(address _contract) {
        require(erc20Addrs[IERC20(_contract)] == true,"Contract address is not Supported ");
        _;
    }

    modifier timeExpired(uint256 _time) {
        require(_time>= block.timestamp,"Expired");
        _;
    }


  
    /*
    * @notice: only owner of the contract is allowed to change fees
    * @param _fee uint256 is the submit fees 
    * @param _txInterestfee interest's fees
    */
    function resetTxFee(uint256 _fee, uint256 _txInterestfee) public onlyOwner { 
        txfee = _fee;
        txInterestfee = _txInterestfee;
    }


    // only owner of the contract is allowed to change max number of months . 
    // 1 year = 12 month , and 2 year is 24 months
    // function resetMaximumTenure(uint256 _maximumTenure) public onlyOwner { 
    //     maximumTenure = _maximumTenure;
    // }


    // add ERC20 token contract address
    function addToken(address _contract, bool _mode) external onlyOwner {
        require( _contract != address(0) , "Zero Address");
        erc20Addrs[IERC20(_contract)] = _mode;    
    }

    // check what ERC20 token is available
    function currencyTokens(address _contract) external view returns(bool){
        return erc20Addrs[IERC20(_contract)];
    }


    function _timeExpired(uint256 time) private pure returns(uint256) {
        return 7 days * time;
    }



    // return the assets 
    // function assets(uint256 counterId) public view returns (
    //     address paymentAddress,
    //     uint256 listingTime,
    //     uint256 termId,
    //     // address lender,
    //     // address nftOwner,
    //     address nftContractAddress,
    //     uint256 nftTokenId,
    //     uint256 loanAmount, uint256 loanCost, 
    //     uint256 payAmountAfterLoan, uint256 payBackAfterLoan, bool isPaid) {

    //     paymentAddress = _assets[counterId].paymentContract;
    //     listingTime = _assets[counterId].listingTime;
    //     termId = _assets[counterId].termId;
    //     // lender = _assets[counterId].lender;
    //     // nftOwner = _assets[counterId].nftOwner;
    //     nftContractAddress = _assets[counterId].nftcontract;
    //     nftTokenId = _assets[counterId].nftTokenId;
    //     loanAmount = _assets[counterId].loanAmount;
    //     loanCost = _assets[counterId].loanCost;
    //     // feesCost = calculatedFee(lendCost);
    //     payAmountAfterLoan = _assets[counterId].payAmountAfterLoan;
    //     payBackAfterLoan = _assets[counterId].payBackAfterLoan;
    //     isPaid = _assets[counterId].isPaid;
    // }

    // function receipt(uint256 counterId) public view returns (
    //     uint256 lenderToken,
    //     uint256 borrowerToken) {
    //         lenderToken = _receipt[counterId].lenderBalances;
    //         borrowerToken = _receipt[counterId].borrowerBalances;
    //     }
      

    // counter 
    function counter() private returns(uint256 counterId){
        counterId = _IdCounter.current();
        _IdCounter.increment();
    }

    function nftCounter() private returns(uint256 counterId){
        counterId = _nftCounter.current();
        _nftCounter.increment();

    }

 

    // borrowr needs to submit the lender's offer
    // _offeredTime is time to offer and takes a future timestamp
    // _loanTerm is number of months
    /*
    * @notice: the submit function is called by only the borrowers if they 
    * agree on the lending schedule loan 
    * @param nonce uint256 ID is  
    * @param _paymentAddress address 
    * @param _lender address
    * @param _nftcontract address
    * @param _nftTokenId uint256
    * @param _loanAmounLoanCost is an arry of uint256
    * @param _offeredTime uint256
    * @param _gist bytes32
    * @param signature bytes
    */
   function submit(uint256 nonce, address _paymentAddress, address _lender, 
                address _nftcontract, uint256 _nftTokenId, uint256 [3] calldata _loanAmounLoanCost,
                uint256 _offeredTime, bytes32 _gist, bytes calldata signature) 
        external whenNotPaused nonReentrant supportInterface(_paymentAddress) 
       {
        LendingAssets memory _m = LendingAssets({
        paymentContract: address(_paymentAddress),
        listingTime: clockTimeStamp(),
        loanAmount:_loanAmounLoanCost[0],
        loanCost: _loanAmounLoanCost[1],
        paidInterest:0,
        payAmountAfterLoan:_loanAmounLoanCost[0] + _loanAmounLoanCost[1],
        payBackAfterLoan:0,
        termId:1,
        isPaid:false,
        // lender:_lender,
        nftcontract:_nftcontract,
        // nftOwner:msg.sender,
        nftTokenId:_nftTokenId,
        gist: _gist
        });
        require(IERC721(_m.nftcontract).ownerOf( _m.nftTokenId) == msg.sender ,"Not Owner");
        require(identifiedSignature[_lender][nonce] != true, "Lender is not interested");
        require(_offeredTime >= clockTimeStamp(), "offer expired" );
        require(IERC20(_m.paymentContract).allowance(_lender, address(this)) >= _m.loanAmount, "Not enough allowance" );
        require(_loanAmounLoanCost[2] >= calculatedFee(_m.loanAmount),"fee");
        require(_verify(_lender, _hashLending (
            nonce,_m.paymentContract,_offeredTime,
            _m.loanAmount,_m.loanCost,_m.nftcontract,
            msg.sender,_m.nftTokenId,_m.gist)
            ,signature),"Invalid signature");
        
        uint256 counterId = counter();
        _assets[counterId] = _m;
        _receipt[counterId].lenderBalances = nftCounter();

        _receipt[counterId].borrowerBalances = nftCounter();
        Receipt memory _nft = _receipt[counterId];
        _safeMint(_lender, _nft.lenderBalances ) ;
        _safeMint(msg.sender, _nft.borrowerBalances ) ;
        
        IERC721(_nftcontract).safeTransferFrom(msg.sender, address(this), _nftTokenId);
        IERC20(_m.paymentContract).safeTransferFrom(_lender, owner(), _loanAmounLoanCost[2]);
        IERC20(_m.paymentContract).safeTransferFrom(_lender, msg.sender, _m.loanAmount);
        emit AssetsLog(
            counterId,
            msg.sender,
            _m.nftcontract,
            _m.nftTokenId,
            _lender,
            _m.paymentContract,
            _m.loanAmount,
            _m.loanCost,
            _m.payAmountAfterLoan, 
            _m.gist);
    }
  

    // make payment before time expired
    function makePayment(uint256 _counterId, uint256 term_, 
    uint256[] calldata loanTimestampPaymentInterest, uint256 fee_, bytes32[] calldata proof) external nonReentrant {
        
        // _termOf[_counterId] = _termId.current();
        LendingAssets memory _m = _assets[_counterId];
        Receipt memory _nft = _receipt[_counterId];
        require(term_ == _m.termId, "term does not matched");
        require(_verifyTree(_leaf(term_ , loanTimestampPaymentInterest), proof, _m.gist), "Invalid proof");
        require(ownerOf(_nft.borrowerBalances) == msg.sender,"Only NFT owner");
        require(_m.isPaid != true, "is paid already");
        require(_timeExpired(loanTimestampPaymentInterest[0]) >= clockTimeStamp(), "Default");
        uint256 loanPayment = loanTimestampPaymentInterest[1] + loanTimestampPaymentInterest[2];
        require(IERC20(_m.paymentContract).allowance(msg.sender, address(this)) >= loanPayment,"Not enough allowance" );
        require(calculatedInterestFee(loanTimestampPaymentInterest[2]) <= fee_, "fees");
        // interest[_counterId] += loanTimestampLoanPaymentLoanInterest[2];
        _assets[_counterId].paidInterest += loanTimestampPaymentInterest[2];
        _assets[_counterId].termId++;        
        _assets[_counterId].payBackAfterLoan +=  loanPayment ;
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, owner(), fee_);
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, ownerOf(_nft.lenderBalances),  loanPayment);
        LendingAssets memory _after = _assets[_counterId];

        if (_after.payBackAfterLoan >= _after.payAmountAfterLoan ){
            _burn(_nft.borrowerBalances);
            _burn(_nft.lenderBalances);
            _assets[_counterId].isPaid = true;
            IERC721(_m.nftcontract).safeTransferFrom(address(this), msg.sender, _m.nftTokenId);
        }
        emit PayBackLog(_counterId, _m.nftcontract, _m.nftTokenId, msg.sender, ownerOf(_nft.lenderBalances), _m.termId, loanPayment, fee_, proof); 
    }

    function makePrePayment(uint256 _counterId, uint256 term_, 
    uint256[] calldata loanTimesPaymentInterest, uint256[] calldata preloanTimes,uint256 fee_, bytes32 [] calldata proof,bytes32 [] calldata preProof) external nonReentrant {
        
        LendingAssets memory _m = _assets[_counterId];
        Receipt memory _nft = _receipt[_counterId];

        require(_verifyTree(_leaf(0 , preloanTimes), preProof, _m.gist), "Invalid proof");
        require(_verifyTree(_leaf(term_, loanTimesPaymentInterest), proof, _m.gist), "Invalid proof");
        require(preloanTimes[0]>= clockTimeStamp(),"Expired" );
        require(ownerOf(_nft.borrowerBalances) == msg.sender,"Only NFT owner");
        // require(_m.isPaid != true, "is paid already");
        // require(_timeExpired(perloanTimestampLoanPaymentLoanInterest[0]) >= _time, "Expired");
        // uint256 loanPayment = loanTimestampLoanPaymentLoanInterest[1] + loanTimestampLoanPaymentLoanInterest[3];
        // require(IERC20(_m.paymentContract).allowance(msg.sender, address(this)) >= loanTimestampLoanPaymentLoanInterest[4] + loanTimestampLoanPaymentLoanInterest[3],"Not enough allowance" );
        // _assets[_counterId].termId++;
        require(calculatedInterestFee(_m.loanCost - _m.paidInterest) <= fee_, "fees");

        _assets[_counterId].payBackAfterLoan +=  (loanTimesPaymentInterest[4] + loanTimesPaymentInterest[3]) ;
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, owner(), fee_);
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, ownerOf(_nft.lenderBalances),  loanTimesPaymentInterest[4] + loanTimesPaymentInterest[3]);
        _burn(_nft.borrowerBalances);
        _burn(_nft.lenderBalances);
        _assets[_counterId].isPaid = true;
        IERC721(_m.nftcontract).safeTransferFrom(address(this), msg.sender, _m.nftTokenId);
        emit PrePayLog(_counterId, _m.nftcontract, _m.nftTokenId, msg.sender, ownerOf(_nft.lenderBalances), fee_, proof); 
    }
   
    function clockTimeStamp() private view returns(uint256 x){
        x = block.timestamp;
    }

    // default NFT :
    /*
    submit nft id to check  
    */
    function defaultAsset(uint256 _counterId, 
    uint256[] calldata loanTimestampLoanPayment, uint256 fee_, bytes32[] calldata proof) external nonReentrant  {
        
        address contractOwner  = owner();
        uint256 _time = clockTimeStamp();
        LendingAssets memory _m = _assets[_counterId];
        Receipt memory _nft = _receipt[_counterId];

        require(_m.isPaid != true, "is paid already");
        uint256 term_ = _m.termId ;
        require(_verifyTree(_leaf(term_ , loanTimestampLoanPayment), proof, _m.gist), "Invalid proof");
        require(ownerOf(_nft.lenderBalances)== msg.sender,"not a lender");
        require(_timeExpired(loanTimestampLoanPayment[0]) <= _time, "Not default yet");
        require(IERC20(_m.paymentContract).allowance(msg.sender,address(this)) >= fee_,"Not enough allowance" );
        uint256 remaining = _m.loanCost - _m.paidInterest;
        require(fee_ >= calculatedInterestFee(remaining),"fee");
        _burn(_nft.borrowerBalances);
        _burn(_nft.lenderBalances);

        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, contractOwner, fee_);
        IERC721(_m.nftcontract).safeTransferFrom(address(this), msg.sender, _m.nftTokenId);
        emit DefaultLog(_counterId, _m.nftcontract, _m.nftTokenId, msg.sender, fee_);
    }

    // only lender can cancel their offer usin their nonces
    function cancel(uint256 nonce, address _lender) external   {
        require(_lender == msg.sender, "Not a Lender");
        require(identifiedSignature[_lender][nonce] != true, "Not interested");
        identifiedSignature[_lender][nonce] = true;
        emit CancelLog(_lender,nonce, true);
    }

    function isNonceUsed(uint256 nonce, address _lender) external view returns(bool _isNonceUsed){
        _isNonceUsed = identifiedSignature[_lender][nonce];
    }
    
   /* @dev calculatedFee function is called in any payment
    * @param _amount uint256 of calculating the fees
    */
    function calculatedFee(uint256 _amount) public view returns(uint fee) {
        uint _txfee = txfee;
        uint callItFee = _amount * _txfee;
        fee = callItFee / 2e4;
    }

    function calculatedInterestFee(uint256 _amount) public view returns(uint fee) {
        uint _txfee = txInterestfee;
        uint callItFee = _amount * _txfee;
        fee = callItFee / 2e4;
    }



    /*
    * @notice:  borrower needs to submit the lender new proof to extend the time with a new timestamps and payment intereset 
                the offeredTime value has to be not expired with a current time.
    * @param _counterId uint256 Id of the receipt NFT
    * @param cost uint256 new cost
    * @param currentTerm_ uint256 the cuurent term that already paid 
    * @param _offeredTime uint256  it has to be > then current timestamp
    * @param gist bytes32 new root
    * @param signature bytes32 a new sig of the lender 
    */
   function extendTheTime(uint256 _counterId, uint256 cost, uint256 currentTerm_, uint256 _offeredTime, bytes32 gist ,bytes calldata signature) 
   nonReentrant external {
        LendingAssets memory _m = _assets[_counterId];
        Receipt memory _nft = _receipt[_counterId];

        require(_offeredTime >= clockTimeStamp(), "offer expired" );
        require(currentTerm_ == _m.termId,"term does not matched");
        require(ownerOf(_nft.borrowerBalances) == msg.sender,"Only NFT owner");
        require(_verify(ownerOf(_nft.lenderBalances), _hashextend(_m.nftcontract,_m.nftTokenId,
              _offeredTime, cost, gist), signature), "lender signature");
        _assets[_counterId].gist = gist;
        // _assets[_counterId].loanTerm = loanTerm;
        _assets[_counterId].payAmountAfterLoan += cost;
     
        // emit ExtendTimeLog(
        //     _counterId, 
        //     _m.nftcontract,
        //     _m.nftTokenId,
        //    _nft.lenderBalances,
        //     msg.sender,
        //     _m.termId,
        //     _m.loanAmount,
        //     gist);
    }

    /*
    * @notice: to withdraw the fees
    * @param _contract address of the erc20 token
    * @param _to address of the receiver address
    * @param _amount uint256 of amount 
    */
    function withdraw(address _contract, address _to, uint256 _amount) external onlyOwner {
        IERC20(_contract).safeTransfer(_to, _amount);
        emit WithdrawLog(_contract, _to, _amount);
    }


    // // this is only if the nft gets locked or pused contract 
    // function NFTw(address _nftcontract, address _to, uint256 tokenId) external onlyOwner {
    //     IERC721(_nftcontract).safeTransferFrom(address(this), _to, tokenId);
    //     emit PusedTransferLog(_nftcontract, _to, tokenId);
    // }
    /*
    * @notice: burn function is called when all payment made or the nft gets defulted
    * @param tokenId uint256 ID of the token being burned
    */
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    /*
    * @notice: _leaf function is called in makePayment, makePerPayment function to verify each Merkle 
    * @param term uint256 ID of term in the payment 
    * @param an arry of two uint256 values, [0] timestamp [1] payment 
    */
    function _leaf(uint256 term, uint256 [] calldata time)
    private pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(term, time));
    }

    /*
    * @notice: Verifies a Merkle proof proving the existence of a leaf in a Merkle tree
    * @param leaf Leaf of Merkle tree
    * @param proof Merkle proof 
    * @param gist Merkle root
    */
    function _verifyTree(bytes32 leaf, bytes32[] memory proof, bytes32 gist)
    private pure returns (bool)
    {
        return MerkleProof.verify(proof, gist, leaf);
    }

    function onERC721Received(address , address , uint256 , bytes memory) external pure override returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

   
    function setURI(string calldata baseURI_) external  onlyOwner {
        _baseMetadata = baseURI_;
    }

    function baseURI() external view returns (string memory) {
        return _baseMetadata;
    }


    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function totalSupply() public view  returns (uint256) {
        return _IdCounter.current() ;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }




}