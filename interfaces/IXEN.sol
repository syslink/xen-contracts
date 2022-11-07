// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// INTERNAL TYPE TO DESCRIBE A XEN MINT INFO
struct MintInfo {
    address user;
    uint256 term;
    uint256 maturityTs;
    uint256 rank;
    uint256 amplifier;
    uint256 eaaRate;
}

// INTERNAL TYPE TO DESCRIBE A XEN STAKE
struct StakeInfo {
    uint256 term;
    uint256 maturityTs;
    uint256 amount;
    uint256 apy;
}

interface IXEN is IERC20 {
    function symbol() external view returns (string memory);
    function SECONDS_IN_DAY() external view returns(uint256);
    function WITHDRAWAL_WINDOW_DAYS() external view returns(uint256);
    function MAX_PENALTY_PCT() external view returns(uint256);
    function globalRank() external view returns(uint256);
    function userBurns(address user) external view returns(uint256);
    function MintFee() external view returns(uint256);
    /**
     * @dev returns User Mint object associated with User account address
     */
    function getUserMint() external view returns (MintInfo memory);

    /**
     * @dev returns XEN Stake object associated with User account address
     */
    function getUserStake() external view returns (StakeInfo memory);

    /**
     * @dev returns current AMP
     */
    function getCurrentAMP() external view returns (uint256);

    /**
     * @dev returns current EAA Rate
     */
    function getCurrentEAAR() external view returns (uint256);

    /**
     * @dev returns current APY
     */
    function getCurrentAPY() external view returns (uint256);

    /**
     * @dev returns current MaxTerm
     */
    function getCurrentMaxTerm() external view returns (uint256);
    /**
     * @dev accepts User cRank claim provided all checks pass (incl. no current claim exists)
     */
    function claimRank(uint256 term, address spreader) external payable;

    /**
     * @dev ends minting upon maturity (and within permitted Withdrawal Time Window), gets minted XEN
     */
    function claimMintReward() external;

    /**
     * @dev  ends minting upon maturity (and within permitted Withdrawal time Window)
     *       mints XEN coins and splits them between User and designated other address
     */
    function claimMintRewardAndShare(address other, uint256 pct) external;

    /**
     * @dev  ends minting upon maturity (and within permitted Withdrawal time Window)
     *       mints XEN coins and stakes 'pct' of it for 'term'
     */
    function claimMintRewardAndStake(uint256 pct, uint256 term) external;

    /**
     * @dev initiates XEN Stake in amount for a term (days)
     */
    function stake(uint256 amount, uint256 term) external;

    /**
     * @dev ends XEN Stake and gets reward if the Stake is mature
     */
    function withdraw() external;

    /**
     * @dev burns XEN tokens and creates Proof-Of-Burn record to be used by connected DeFi services
     */
    function burn(address user, uint256 amount) external;

    /**
     * @dev calculates gross Mint Reward  log(rankDelta)*APML*DAYS*EAA/1000
     */
    function getGrossReward(
        uint256 rankDelta,
        uint256 amplifier,
        uint256 term,
        uint256 eaa
    ) external pure returns (uint256);
}