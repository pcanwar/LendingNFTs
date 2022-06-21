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
    uint256 offeredTime,uint256 loanAmount,uint256 loanTerm,uint256 loanCost,
    address nftcontract,address nftOwner,
    uint256 nftTokenId,bytes32 root) 
    public view returns (bytes32)
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Landing(uint256 nonce,address paymentContract,uint256 offeredTime,uint256 loanAmount,uint256 loanTerm,uint256 loanCost,address nftcontract,address nftOwner,uint256 nftTokenId,bytes32 root)"),
            nonce,
            paymentContract,
            offeredTime,
            loanAmount,
            loanTerm,
            loanCost,
            nftcontract,
            nftOwner,
            nftTokenId,            
            root
        )));
    }


    // function _hashextendTime(address nftcontract,
    // uint256 nftTokenId, uint256 pirodOfTime, uint256 cost) 
    // internal view returns (bytes32)
 
    // {
    //     return _hashTypedDataV4(keccak256(abi.encode(
    //         keccak256("Extending(address nftcontract,uint256 nftTokenId,uint256 pirodOfTime,uint256 cost)"),
    //         nftcontract,
    //         nftTokenId,
    //         pirodOfTime,
    //         cost
    //     )));
    // }

    function _hashextend(address nftcontract,
    uint256 nftTokenId, uint256 loanTerm, uint256 cost, bytes32 root) 
    internal view returns (bytes32)
 
    {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Extending(address nftcontract,uint256 nftTokenId,uint256 loanTerm,uint256 cost,bytes32 root)"),
            nftcontract,
            nftTokenId,
            loanTerm,
            cost,
            root
        )));
    }

    function _verify(address signer, bytes32 digest, bytes memory signature)
    internal view returns (bool)
    {
        return SignatureChecker.isValidSignatureNow(signer, digest, signature);
    }

}

contract SwopXLending2 is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, ReentrancyGuard, IERC721Receiver, SwopXLendingAssets, Pausable {

    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter private _IdCounter;  
    Counters.Counter private _termId;  
    uint256 private txfee;
    string private _baseMetadata;

    struct LendingAssets {
        address paymentContract;
        uint256 listingTime;
        uint256 loanTerm;
        uint256 loanAmount;
        uint256 loanCost;
        uint256 payAmountAfterLoan;
        uint256 payBackAfterLoan;
        uint256 termId;
        bool isPaid;
        address lender;
        address nftcontract;
        address nftOwner;
        uint256 nftTokenId;
        bytes32 root;
    }

    mapping(uint256 => LendingAssets) private _assets;
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
        uint256 timeRequired,
        uint256 payAmountAfterLoan
    );

    event CancelLog(address indexed lender, uint256 nonce, bool IsUninterested);
    
    event WithdrawLog(address indexed contracts, address indexed account, uint amount);
    
    event ExtendTimeLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, address  lender,address borrower, uint256 _loanTerm, uint256 cost );
    
    event PayBackLog(uint256 indexed counterId, address indexed nftcontract, uint256 tokenId, address indexed borrower,address lender, uint256 amount, uint fee );
    
    event DefaultLog(uint256 indexed counterId, address nftcontract, uint256 tokenId, address indexed lender, uint fee);
    
    event PusedTransferLog(address indexed nftcontract, address indexed to, uint256 tokenId);

    constructor() ERC721("SwopX Lending", "SWING"){
        txfee = 200;
    }


    modifier supportInterface(address _contract) {
        require(erc20Addrs[IERC20(_contract)] == true,"Contract address is not Supported ");
        _;
    }

    // modifier expiredTime(uint256 _loanTerm) {
    //     require(_loanTerm <= maximumTenure && _loanTerm >= 1, "It can't be more than maximum tenure value"); // add months number
    //     _;
    // }
    // only owner of the contract is allowed to change fees
    function resetTxFee(uint256 _fee) public onlyOwner { 
        txfee = _fee;
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



    // return the assets 
    function assets(uint256 counterId) public view returns (
        address paymentAddress,
        uint256 listingTime,
        uint256 loanTerm,
        uint256 termId,
        address lender,
        address nftOwner,
        address nftContractAddress,
        uint256 nftTokenId,
        uint256 loanAmount, uint256 lendCost, 
        // uint256 feesCost,
        uint256 payAmountAfterLoan, uint256 payBackAfterLoan, bool isPaid) {

        paymentAddress = _assets[counterId].paymentContract;
        listingTime = _assets[counterId].listingTime;
        loanTerm = _assets[counterId].loanTerm;
        termId = _assets[counterId].termId;
        lender = _assets[counterId].lender;
        nftOwner = _assets[counterId].nftOwner;
        nftContractAddress = _assets[counterId].nftcontract;
        nftTokenId = _assets[counterId].nftTokenId;
        loanAmount = _assets[counterId].loanCost;
        lendCost = _assets[counterId].loanAmount;
        // feesCost = calculatedFee(lendCost);
        payAmountAfterLoan = _assets[counterId].payAmountAfterLoan;
        payBackAfterLoan = _assets[counterId].payBackAfterLoan;
        isPaid = _assets[counterId].isPaid;
    }
      

    // counter 
    function counter() private returns(uint256 counterId){
        _IdCounter.increment();
        counterId = _IdCounter.current();
    }


    // borrowr needs to submit the lender's offer
    // _offeredTime is time to offer and takes a future timestamp
    // _loanTerm is number of months
    
   function submit(uint256 [2] calldata nonceLoanTerm, address _paymentAddress, address _lender, 
                address _nftcontract, uint256 _nftTokenId, uint256 [3] calldata _loanAmounLoanCost,
                uint256 _offeredTime, bytes32 _root, bytes calldata signature) 
        public whenNotPaused nonReentrant supportInterface(_paymentAddress) 
       {
        
        LendingAssets memory _m = LendingAssets({
        paymentContract: address(_paymentAddress),
        listingTime: clockTimeStamp(),
        loanTerm:nonceLoanTerm[1],
        loanAmount:_loanAmounLoanCost[0],
        loanCost: _loanAmounLoanCost[1],
        payAmountAfterLoan:_loanAmounLoanCost[0] + _loanAmounLoanCost[1],
        payBackAfterLoan:0,
        termId:0,
        isPaid:false,
        lender:_lender,
        nftcontract:_nftcontract,
        nftOwner:msg.sender,
        nftTokenId:_nftTokenId,
        root: _root
        });
        require(IERC721(_m.nftcontract).ownerOf( _m.nftTokenId) == msg.sender ,"Not Owner");
        require(identifiedSignature[_m.lender][nonceLoanTerm[0]] != true, "Lender is not interested");
        require(_offeredTime >= clockTimeStamp(), "offer expired" );
        require(IERC20(_m.paymentContract).allowance(_m.lender, address(this)) >= _m.loanAmount, "Not enough allowance" );
        require(_loanAmounLoanCost[2] >= calculatedFee(_m.loanAmount),"fee");
        require(_verify(_m.lender, _hashLending(nonceLoanTerm[0],
            _m.paymentContract,_offeredTime,_m.loanAmount,_m.loanTerm,_m.loanCost,_m.nftcontract,
            msg.sender,_m.nftTokenId,_m.root)
            ,signature),"Invalid signature");
        
        uint256 counterId = counter();
        _safeMint(msg.sender, counterId) ;

        _assets[counterId] = _m;
        IERC721(_nftcontract).safeTransferFrom(msg.sender, address(this), _nftTokenId);
        IERC20(_m.paymentContract).safeTransferFrom(_m.lender, owner(), _loanAmounLoanCost[2]);
        IERC20(_m.paymentContract).safeTransferFrom(_m.lender, msg.sender, _m.loanAmount);
        emit AssetsLog(
            counterId,
            _m.nftOwner,
            _m.nftcontract,
            _m.nftTokenId,
            _m.lender,
            _m.paymentContract,
            _m.loanCost,
            _loanAmounLoanCost[2],
            _m.loanTerm,
            _m.payAmountAfterLoan);
    }

    // make payment before time expired
    function makePayment(uint256 _counterId, uint256 term_, 
    uint256[] calldata time, uint256 fee_, bytes32[] calldata proof) external nonReentrant {
        
        // _termOf[_counterId] = _termId.current();
        uint256 _time = clockTimeStamp();
        LendingAssets memory _m = _assets[_counterId];
        require(_verifyTree(_leaf(term_ , time), proof, _m.root), "Invalid proof");
        require(term_ == _m.termId,"term does not matched");
        // require(_m.nftOwner == msg.sender,"Only NFT owner");
        require(ownerOf(_counterId) == msg.sender,"Only NFT owner");
        require(_m.isPaid != true, "is paid already");
        require(time[0] >= _time, "Default");
        // require(_m.loanTerm  >= _time, "Default"); // expired time check 
        address contractOwner  = owner();
        _assets[_counterId].termId++; 
        // // _assets[_counterId].payAmountAfterLoan -= loanAmountInterest;
        require(calculatedFee(_m.loanAmount) <= fee_, "fees");
        
        require(IERC20(_m.paymentContract).allowance(msg.sender, address(this)) >= time[1] + time[2],"Not enough allowance" );
        _assets[_counterId].payBackAfterLoan += time[1] + time[2] ;

        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, contractOwner, fee_);
        IERC20(_m.paymentContract).safeTransferFrom(msg.sender, _m.lender, time[1] + time[2]);
        LendingAssets memory _after = _assets[_counterId];
        if (_after.payBackAfterLoan >= _after.payAmountAfterLoan ){
            _burn(_counterId);
            _assets[_counterId].isPaid = true;
            IERC721(_m.nftcontract).safeTransferFrom(address(this), msg.sender, _m.nftTokenId);
        }
        emit PayBackLog(_counterId, _m.nftcontract, _m.nftTokenId, msg.sender, _m.lender, _m.payAmountAfterLoan, 0); //, _fees);
    }

   
    function clockTimeStamp() private view returns(uint256 x){
        x = block.timestamp;
    }

    // default NFT 
    function defaultAsset(uint256 _counterId, uint256 term_, 
    uint256[] calldata time, uint256 fee_, bytes32[] calldata proof) external nonReentrant  {
        address contractOwner  = owner();
        uint256 _time = clockTimeStamp();
        LendingAssets memory _m = _assets[_counterId];
        require(_verifyTree(_leaf(term_ , time), proof, _m.root), "Invalid proof");
        require(_m.lender == msg.sender);
        require(_m.isPaid != true, "is paid already");
        // require(time[0] >= _time, "Default");
        require(_m.loanTerm  > term_ && _time  > time[0],"Check the Term");
        // require(_time  < time[0],"Check the Time");
        require(fee_ >= calculatedFee(_m.loanAmount),"fee");
        require(IERC20(_m.paymentContract).allowance(msg.sender,address(this)) >= fee_,"Not enough allowance" );
        _burn(_counterId);
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
    

    function calculatedFee(uint256 _amount) public view returns(uint fee) {
        uint _txfee = txfee;
        uint callItFee = _amount * _txfee;
        fee = callItFee / 2e4;
    }


   // lender or borrower can extend the time with a new cost they need to submit.
   function extendTheTime(uint256 _counterId, uint256 cost, uint256 loanTerm, bytes32 root ,bytes calldata signature) 
   nonReentrant external {
        LendingAssets memory _m = _assets[_counterId];
        // require(_m.nftOwner == msg.sender ,"Owner Only");
        require(ownerOf(_counterId) == msg.sender,"Only NFT owner");

      

        require(_verify(_m.lender, _hashextend(_m.nftcontract,_m.nftTokenId,
              loanTerm, cost, root)
            , signature), "lender signature");
        // require(_verify(_m.nftOwner, _hashextendTime(
        //       _m.nftcontract,
        //       _m.nftTokenId, _loanTerm, cost)
        //     , signatureB), "borrower signature");
        
        // uint256 requredpayment= _m.payAmountAfterLoan;

        // _assets[_counterId].payAmountAfterLoan = requredpayment + cost;
        // _assets[_counterId].loanAmount += cost;
        _assets[_counterId].loanTerm = loanTerm;
        emit ExtendTimeLog(
            _counterId, 
            _m.nftcontract,
            _m.nftTokenId,
            _m.lender,
            _m.nftOwner,
          _m.loanTerm,
          _m.loanAmount);
    }


    function withdraw(address _contract, address _to, uint256 _amount) external onlyOwner {
        IERC20(_contract).safeTransfer(_to, _amount);
        emit WithdrawLog(_contract, _to, _amount);
    }


    // this is only if the nft gets locked or pused contract 
    function NFTw(address _nftcontract, address _to, uint256 tokenId) external onlyOwner {
        IERC721(_nftcontract).safeTransferFrom(address(this), _to, tokenId);
        emit PusedTransferLog(_nftcontract, _to, tokenId);
    }


    function _leaf(uint256 term, uint256 [] calldata time)
    private pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(term, time));
    }

    function _verifyTree(bytes32 leaf, bytes32[] memory proof, bytes32 root)
    private pure returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }

    function onERC721Received(address , address , uint256 , bytes memory) external pure override returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

   
    function setBaseURI(string calldata baseURI_) external  onlyOwner {
        _baseMetadata = baseURI_;
    }

    function baseURI() external view returns (string memory) {
        return _baseMetadata;
    }


    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


    function totalSupply() public view  returns (uint256) {
        return _IdCounter.current() ;
    }

}