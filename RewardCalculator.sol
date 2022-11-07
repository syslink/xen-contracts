// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./interfaces/IXEN.sol";
import "abdk-libraries-solidity/ABDKMath64x64.sol";


contract RewardCalculator {
    using ABDKMath64x64 for int128;
    using ABDKMath64x64 for uint256;

    IXEN public xen;

    uint256 public SECONDS_IN_DAY; 
    uint256 public WITHDRAWAL_WINDOW_DAYS;
    uint256 public MAX_PENALTY_PCT;

    uint256 public constant SECONDS_IN_HOUR = 3_600;
    uint256 public constant SECONDS_IN_MINUTE = 60;

    constructor(IXEN _xen) {
        xen = _xen;
        SECONDS_IN_DAY = xen.SECONDS_IN_DAY();
        WITHDRAWAL_WINDOW_DAYS = xen.WITHDRAWAL_WINDOW_DAYS();
        MAX_PENALTY_PCT = xen.MAX_PENALTY_PCT();
    }


    function getLeftTimeToMint(uint256 mintableTime, uint256 timeNow) external view returns (bool, uint256, uint256, uint256, uint256) {        
        bool positive = true;
        if (timeNow > mintableTime) {
            positive = false;
            uint256 tmpTime = mintableTime;
            mintableTime = timeNow;
            timeNow = tmpTime;
        }
        uint256 spanTime = mintableTime - timeNow;
        uint256 leftDays = spanTime / SECONDS_IN_DAY;
        uint256 leftHours = (spanTime % SECONDS_IN_DAY) / SECONDS_IN_HOUR;
        uint256 leftMinutes = ((spanTime % SECONDS_IN_DAY) % SECONDS_IN_HOUR) / SECONDS_IN_MINUTE;
        uint256 leftSeconds = spanTime % SECONDS_IN_MINUTE;
        return (positive, leftDays, leftHours, leftMinutes, leftSeconds);
    }

    function _penalty(uint256 secsLate) public view returns (uint256) {
        uint256 daysLate = secsLate / SECONDS_IN_DAY;
        if (daysLate > WITHDRAWAL_WINDOW_DAYS - 1) return MAX_PENALTY_PCT;
        uint256 penalty = (uint256(1) << (daysLate + 3)) / WITHDRAWAL_WINDOW_DAYS - 1;
        return (penalty > MAX_PENALTY_PCT) ? MAX_PENALTY_PCT : penalty;
    }

    function getGrossReward(
        uint256 rankDelta,
        uint256 amplifier,
        uint256 term,
        uint256 eaa
    ) public pure returns (uint256) {
        int128 log128 = rankDelta.fromUInt().log_2();
        int128 reward128 = log128.mul(amplifier.fromUInt()).mul(term.fromUInt()).mul(eaa.fromUInt());
        return reward128.div(uint256(1_000).fromUInt()).toUInt();
    }
struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }
    function calculateMintReward(
        uint256 cRank,
        uint256 term,
        uint256 maturityTs,
        uint256 amplifier,
        uint256 eaaRate
    ) public view returns (uint256) {
        uint256 secsLate = block.timestamp >= maturityTs ? block.timestamp - maturityTs : 0; 
        uint256 penalty = _penalty(secsLate); 
        uint256 rankDelta = (xen.globalRank() - cRank > 2) ? xen.globalRank() - cRank : 2;
        uint256 EAA = (1_000 + eaaRate);
        uint256 reward = getGrossReward(rankDelta, amplifier, term, EAA);
        return (reward * (100 - penalty)) / 100;
    }
}