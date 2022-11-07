// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./IXEN.sol";

interface ITraits {
    function tokenURI(
        uint256 tokenId,
        uint256 peroidIndex,
        uint256 burnedAmount
    ) external  view returns (string memory);
}