// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract U20 is ERC20 {
    constructor() ERC20("U20", "U20") {}

    function mint() public  {
        _mint(msg.sender, 200 * 10 ** decimals());
    }
}