// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract AddBlock  {
    uint256 public i;

    constructor() {
        i = block.number;
    }
    function addBlock() external returns(uint256) {
        return i++;
    }

    function blockNumber() external  view returns(uint256) {
        return block.number;
    }

    function blockTime() external  view returns(uint256) {
        return block.timestamp;
    }
}