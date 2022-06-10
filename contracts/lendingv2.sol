// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MerkleExample is ERC721 {

using Counters for Counters.Counter;
Counters.Counter private _tokenIdCounter;

struct Root {
    bytes32 root;
    uint256 paymentLenigh;

}
mapping (uint256 => Root) private _root;

mapping (address => bool) private isMinted;

constructor(string memory name, string memory symbol)
ERC721(name, symbol)
{
 
}

function setRoot(bytes32 root_, uint256 paymentLenght_) public {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _root[_tokenIdCounter].root = root_;
    _root[_tokenIdCounter].paymentLenght = paymentLenght_;
}

function airdrop(address account, bytes32[] calldata proof) external
{
    require(account==msg.sender,"not owner" );
    // you can have some requirement by checking how many mint per address
    // or map address -> true/false something like isMinted:
    require(!isMinted[account]);
    require(_verify(_leaf(account), proof), "Invalid merkle proof");
    isMinted[account] = true;
    safeMint(account);
}

function safeMint(address to) private  {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
}

function _leaf(address account)
public pure returns (bytes32)
{
    return keccak256(abi.encodePacked(account));
}

function _verify(bytes32 leaf, bytes32[] memory proof)
public view returns (bool)
{
    return MerkleProof.verify(proof, root, leaf);
}
}

