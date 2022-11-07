// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";      
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";  
import "./interfaces/IERC3525.sol";

interface IDNFT is IERC3525, IERC721 {

}

contract DPool is Ownable {
    using EnumerableSet for EnumerableSet.UintSet;

    // Info of each user.
    struct UserInfo {
        uint256 weight;     // How many NFT weight of the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // dividendPerSecond=0, lastDividendTime=N, endBlock = N + 100, mintedOutDividend = 0
    // Info of each pool.
    struct PoolInfo {
        uint256 endTime;                // end time of this pool
        uint256 dividendPerSecond;      // dividend per second
        uint256 lastDividendTime;       // last timestamp calculate the dividend
        uint256 mintedOutDividend;      // 
        uint256 totalDividend;          //  
        uint256 accDividendPerShare;    // dividend per share
        uint256 totalWeightOfNFT;       // weight of nft = burned xen in this nft
        uint256 toMintDividend;         // dividend haven't been minted out
    }

    IDNFT public dNftToken;           // Address of LP token contract.
    
    uint256 public totalFee = 0;
    uint256 constant public numerator = 500;
    uint256 constant public denominator = 10000;
    uint256 constant public dividendPeriod = 3_600 * 24 * 3; 
    uint256 public startTime;

    // Info of each pool.
    mapping(uint256 => PoolInfo) public poolList;
    // Info of each user that stakes NFT tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Staked NFTs of each user 
    mapping (address => mapping(uint256 => EnumerableSet.UintSet)) private userNFTIds;

    event Deposit(address indexed user, uint256 indexed pid, uint256[] nftIds);
    event ClaimDividend(address indexed user, uint256 indexed pid, uint256 amount);
    event Redeem(address indexed user, uint256 indexed pid, uint256[] nftIds);

    constructor() {
    }

    function setDNFT(IDNFT _dNftToken) external onlyOwner {
        dNftToken = _dNftToken;
    }
    
    function getCurrentPeriodIndex() public view returns(uint256) {
        return (block.timestamp - startTime) / dividendPeriod;
    }
   
    function addDividend() external payable {
        if (startTime == 0) {
            startTime = block.timestamp;
        }

        uint256 poolIndex = getCurrentPeriodIndex();
        PoolInfo storage curPool = poolList[poolIndex];
        if (curPool.endTime == 0) {
            curPool.endTime = startTime + (poolIndex + 1) * dividendPeriod;
            uint256 restDividendFromLastPool = address(this).balance - totalFee - msg.value;
            curPool.totalDividend = restDividendFromLastPool;
            curPool.toMintDividend = restDividendFromLastPool;
        }

        uint256 deltaMintedOutDividend = curPool.dividendPerSecond * (block.timestamp - curPool.lastDividendTime);
        curPool.mintedOutDividend = curPool.mintedOutDividend + deltaMintedOutDividend;
        curPool.lastDividendTime = block.timestamp;
        curPool.totalDividend += msg.value;
        if (curPool.totalWeightOfNFT > 0) {
            curPool.dividendPerSecond = curPool.dividendPerSecond + msg.value / (curPool.endTime - block.timestamp);        
            curPool.accDividendPerShare = curPool.accDividendPerShare + deltaMintedOutDividend * 1e12 / curPool.totalWeightOfNFT;
        } else {
            curPool.toMintDividend += msg.value;
        }
    }

    // View function to see pending ETHs on frontend.
    function pendingDividend(uint256 poolIndex, address user) external view returns (uint256) {
        PoolInfo memory pool = poolList[poolIndex];
        UserInfo memory user = userInfo[poolIndex][user];
        if (user.weight == 0) return 0;

        uint256 time = pool.endTime < block.timestamp ? pool.endTime : block.timestamp;
        uint256 totalWeight = pool.totalWeightOfNFT;
        uint256 deltaMintedOutDividend = pool.dividendPerSecond * (time - pool.lastDividendTime);
        uint256 accDividendPerShare = pool.accDividendPerShare + deltaMintedOutDividend * 1e12 / totalWeight;
        return user.weight * accDividendPerShare / 1e12 - user.rewardDebt;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 poolIndex) public {
        require(poolIndex <= getCurrentPeriodIndex(), "Out of index");
        PoolInfo storage pool = poolList[poolIndex];
        if (block.timestamp <= pool.lastDividendTime) {
            return;
        }
        uint256 time = pool.endTime < block.timestamp ? pool.endTime : block.timestamp;

        uint256 totalWeight = pool.totalWeightOfNFT;
        if (totalWeight == 0) {
            pool.lastDividendTime = time;
            return;
        }
        uint256 deltaMintedOutDividend = pool.dividendPerSecond * (time - pool.lastDividendTime);
        if (deltaMintedOutDividend > 0) {
            pool.accDividendPerShare = pool.accDividendPerShare + deltaMintedOutDividend * 1e12 / totalWeight;
            pool.mintedOutDividend = pool.mintedOutDividend + deltaMintedOutDividend;
        }
        pool.lastDividendTime = time;
    }

    // Deposit NFT to get the dividend.
    function deposit(uint256[] memory _nftIds) public {
        uint256 poolIndex = getCurrentPeriodIndex();
        PoolInfo storage pool = poolList[poolIndex];
        UserInfo storage user = userInfo[poolIndex][msg.sender];
        updatePool(poolIndex);
        if (user.weight > 0) {
            uint256 pending = user.weight * pool.accDividendPerShare / 1e12 - user.rewardDebt;
            if(pending > 0) {
                safeTransferDividend(msg.sender, pending);
            }
        }
        if (_nftIds.length > 0) {
            for (uint256 i = 0; i < _nftIds.length; i++) {
                dNftToken.transferFrom(address(msg.sender), address(this), _nftIds[i]);

                uint256 slotId = dNftToken.slotOf(_nftIds[i]);
                require(slotId == poolIndex, "SlotId != poolIndex.");
                
                uint256 nftWeight = dNftToken.balanceOf(_nftIds[i]);
                user.weight = user.weight + nftWeight;
                pool.totalWeightOfNFT = pool.totalWeightOfNFT + nftWeight;
                userNFTIds[msg.sender][poolIndex].add(_nftIds[i]);
            }
        }

        if (pool.toMintDividend > 0 && pool.totalWeightOfNFT > 0) {
            pool.dividendPerSecond = pool.dividendPerSecond + pool.toMintDividend / (pool.endTime - block.timestamp);  
            pool.toMintDividend = 0;
        }
        user.rewardDebt = user.weight * pool.accDividendPerShare / 1e12;
        emit Deposit(msg.sender, 0, _nftIds);
    }

    function claimDividend(uint256 poolIndex) public {
        require(poolIndex <= getCurrentPeriodIndex(), "claimDividend: out of index");
        PoolInfo storage pool = poolList[poolIndex];
        UserInfo storage user = userInfo[poolIndex][msg.sender];
        updatePool(poolIndex);
        
        uint256 pendingAmount;
        if (user.weight > 0) {
            pendingAmount = user.weight * pool.accDividendPerShare / 1e12 - user.rewardDebt;
            if(pendingAmount > 0) {
                safeTransferDividend(msg.sender, pendingAmount);
            }
        }
        user.rewardDebt = user.weight * pool.accDividendPerShare / 1e12;
        emit ClaimDividend(msg.sender, poolIndex, pendingAmount);
    }

    function redeem(uint256[] memory _nftIds, uint256 poolIndex) public {
        require(poolIndex <= getCurrentPeriodIndex(), "redeem: index out of range.");
        EnumerableSet.UintSet storage nftIds = userNFTIds[msg.sender][poolIndex];
        require(nftIds.length() >= _nftIds.length, "The number of redeemed nfts is too much!");
        
        PoolInfo storage pool = poolList[poolIndex];
        UserInfo storage user = userInfo[poolIndex][msg.sender];
        updatePool(poolIndex);
        uint256 pending = user.weight * pool.accDividendPerShare / 1e12 - user.rewardDebt;
        if (pending > 0) {
            safeTransferDividend(msg.sender, pending);
        }
        for (uint256 i = 0; i < _nftIds.length; i++) {
            require(nftIds.contains(_nftIds[i]), "redeem: NFT id is NOT contained in user's list.");
            nftIds.remove(_nftIds[i]);
            uint256 nftWeight = dNftToken.balanceOf(_nftIds[i]);
            user.weight = user.weight - nftWeight;
            pool.totalWeightOfNFT = pool.totalWeightOfNFT - nftWeight;
            dNftToken.transferFrom(address(this), address(msg.sender), _nftIds[i]);
        }
        user.rewardDebt = user.weight * pool.accDividendPerShare / 1e12;
        
        emit Redeem(msg.sender, poolIndex, _nftIds);
    }

    function redeemAll(uint256 poolIndex) public {        
        uint256[] memory nftIds = userNFTIds[msg.sender][poolIndex].values();
        if (nftIds.length > 0) {
            redeem(nftIds, poolIndex);
        }
    }

    function safeTransferDividend(address _to, uint256 _amount) internal {
        if (_amount > address(this).balance) {
            _amount = address(this).balance;
        }
        uint256 fee = _amount * numerator / denominator;
        payable(_to).transfer(_amount - fee);
        totalFee += fee;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(totalFee);
        totalFee = 0;
    }

    function getUserNFTNumber(address user, uint256 poolIndex) view public returns(uint256) {
        return userNFTIds[user][poolIndex].length();
    }

    function getUserNFTIds(address user, uint256 poolIndex, uint256 _fromIndex, uint256 _toIndex) view public returns(uint256[] memory nftIds) {
        uint256 length = userNFTIds[user][poolIndex].length();
        if (_toIndex > length) _toIndex = length;
        require(_fromIndex < _toIndex, "Index is out of range.");
        nftIds = new uint256[](_toIndex - _fromIndex);
        for (uint256 i = _fromIndex; i < _toIndex; i++) {
            nftIds[i - _fromIndex] = userNFTIds[user][poolIndex].at(i);
        }
    }
}