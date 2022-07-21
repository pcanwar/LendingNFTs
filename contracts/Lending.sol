
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./iSwopXLending.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";


contract LendingAPI is ERC20, ERC20Burnable, Pausable, Ownable {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    address private immutable swopXLending = 0x7fE9a07F48bcde7E0ee7D31CbAF24c7e8934b383;
    uint256 startRew = 3;
    uint256 contRew = 1;


    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;


    constructor() ERC20("SwopXLendingAPI", "SwopxAPIvo") {}

    function _sign(address to, uint256 tokenId) public {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }



    function receipt(uint256 counterId) 
    external view returns( uint256 borrowerToken, uint256 lenderToken){
        (borrowerToken, lenderToken) =  iSwopXLending(swopXLending).receipt(counterId) ;

    
    }


    function owners(uint256 counterId) 
    external view returns( uint256 borrowerToken,address borrowerAddress, uint256 lenderToken,address lenderAddress){
        (borrowerToken, lenderToken) =  iSwopXLending(swopXLending).receipt(counterId) ;
        borrowerAddress = iSwopXLending(swopXLending).ownerOf(borrowerToken);
        lenderAddress = iSwopXLending(swopXLending).ownerOf(lenderToken);
    }


    function transferAssset(address from, address to, uint256 token) 
    external {
        iSwopXLending(swopXLending).approve(to, token) ;
        iSwopXLending(swopXLending).transferFrom(from, to, token) ;
    
    }

    function startLoan(
        uint256 [2] calldata nonces , 
        address _paymentAddress, address _lender, 
        address _nftcontract, 
        uint256 _nftTokenId,
        uint256 [3] calldata _loanAmounLoanCost,
        uint256 _offeredTime, bytes32 _gist, 
        bytes [2] calldata signature, uint256 id)
            external  {
                iSwopXLending(swopXLending).submit(nonces,
                    _paymentAddress, _lender, 
                    _nftcontract, 
                    _nftTokenId,
                    _loanAmounLoanCost,
                    _offeredTime, _gist, signature[0],signature[1]);
            address to  = ownerOf(id);
            _mint(to, startRew);
        
    }

    function seqPayment(uint256 _counterId, uint256 term_, uint256[] calldata loanTimestampPaymentInterest, uint256 fee_,
    bytes32[] calldata proof, uint256 id)
            external  {
            iSwopXLending(swopXLending).makePayment( _counterId, term_, 
            loanTimestampPaymentInterest, fee_, proof);
            address to  = ownerOf(id);
            _mint(to, contRew);

    }

    function prePayment(uint256 _counterId, uint256 term_, 
    uint256[] calldata loanTimesPaymentInterest, 
    uint256[] calldata preLoanTimes,uint256 fee_, 
    bytes32 [] calldata proof,bytes32 [] calldata preProof, uint256 id)
        external  {
            iSwopXLending(swopXLending).makePrePayment(_counterId,
             term_, loanTimesPaymentInterest, 
             preLoanTimes, fee_, proof, preProof) ;
             address to  = ownerOf(id);
            _mint(to, contRew);
    }


    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balance(address owner) public view  returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view  returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Invalid token ID");
        return owner;
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }




}
