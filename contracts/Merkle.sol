// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Merkle is ERC721 {

using Counters for Counters.Counter;
Counters.Counter public _tokenIdCounter;
Counters.Counter public _tokenIdCounterMint;

struct Root {
    bytes32 root;
    address brower;

}

bytes32 root;
mapping (uint256 => Root) private _root;

mapping (uint256 => mapping (uint256 => bool)) private isPaid;
// mapping (uint256 => uint256) private counterPayment;

constructor(string memory name, string memory symbol)
ERC721(name, symbol)
{
 
}

function setRoot(bytes32 root_) public {
    // root has to be signed by the lender
    // uint256 tokenId = _tokenIdCounter.current();
    // _tokenIdCounter.increment();
    // _root[tokenId].root = root_;
    // _root[tokenId].brower = msg.sender;
    root = root_;
}



function safeMint(address to) private  {
    uint256 tokenId = _tokenIdCounterMint.current();
    _tokenIdCounterMint.increment();
    _safeMint(to, tokenId);
}

function redeem(address account, uint256 term, uint256 [] calldata time_,  bytes32[] calldata proof)
    external
    {
        // require(account==_root[1].brower,"not owner" );
        // require(counterPayment[1] == _tokenIdCounter.current());
        require(time_[0] > block.timestamp, "expired");
        // uint256 counterPayment = _tokenIdCounter.current();
        require(_verify(_leaf(term , time_), proof), "Invalid merkle proof");
        // _tokenIdCounter.increment();
        safeMint(account);
    }

    function _leaf( uint256 counter, uint256 [] calldata time)
    public pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(counter, time));
    }

    function _verify(bytes32 leaf,  bytes32[] memory proof)
    internal view returns (bool)
    {
        // bytes32 root = _root[_IdCounter].root;
        return MerkleProof.verify(proof, root, leaf);
    }
}