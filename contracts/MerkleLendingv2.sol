// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Merkle is ERC721 {

using Counters for Counters.Counter;
Counters.Counter private _tokenIdCounter;

struct Root {
    bytes32 root;
    address brower;

}
mapping (uint256 => Root) private _root;

mapping (uint256 => mapping (uint256 => bool)) private isPaid;
mapping (uint256 => uint256) private counterPayment;

constructor(string memory name, string memory symbol)
ERC721(name, symbol)
{
 
}

function setRoot(bytes32 root_) public {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _root[tokenId].root = root_;
    _root[tokenId].brower = msg.sender;
}



function safeMint(address to) private  {
    uint256 tokenId = _tokenIdCounter.current();
    _tokenIdCounter.increment();
    _safeMint(to, tokenId);
}

function redeem(address account, uint256 time_,  bytes32[] calldata proof)
    external
    {
        require(counterPayment[1] == _tokenIdCounter.current());
        require(time_ > block.timestamp);
        // uint256 _IdCounter = _tokenIdCounter.current();
        counterPayment[1] = _tokenIdCounter.current();
        require(_verify(_leaf(account, time_),counterPayment[1], proof), "Invalid merkle proof");
        require(account==msg.sender,"not owner" );
        _tokenIdCounter.increment();
        safeMint(account);
    }

    function _leaf(address account, uint256 time_)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(time_, account));
    }

    function _verify(bytes32 leaf, uint256 _IdCounter, bytes32[] memory proof)
    internal view returns (bool)
    {
        bytes32 root = _root[_IdCounter].root;
        return MerkleProof.verify(proof, root, leaf);
    }
}