pragma solidity ^0.8.10;

interface IDPool {
    function dividendPeriod() external view returns(uint256);
    function addDividend() external payable;
    function getCurrentPeriodIndex() external view returns(uint256);
}