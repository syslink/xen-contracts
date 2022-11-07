// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./IXEN.sol";

interface IXProxy {
    function initialize(address _owner, address _xen, uint256 term, address spreader) external payable;
    function withdraw(address to, uint256 amount) external;
    function getUserMint() external view returns (MintInfo memory);
    function burn() external returns(uint256);
    function mintedAmount() external view returns (uint256);
    function claimMintReward() external;
}