// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "./interfaces/IXEN.sol";
import "./interfaces/IBurnRedeemable.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

contract XProxy is IBurnRedeemable, IERC165 {
    IXEN public xen;
    address public owner;
    bool public isBase;
    uint256 public mintedAmount;

    constructor() {
        isBase = true;
    }
    
    function initialize(address _owner, address _xen, uint256 term, address spreader) external payable {
        require(!isBase, "!initialized.");
        require(owner == address(0), "initialized");
        owner = _owner;
        xen = IXEN(_xen);
        xen.claimRank{value: msg.value}(term, spreader);
    }

    function claimMintReward() external {
        uint256 beforeAmount = xen.balanceOf(address(this));
        xen.claimMintReward();
        mintedAmount = xen.balanceOf(address(this)) - beforeAmount;
    }

    function withdraw(address to, uint256 amount) external {
        require(msg.sender == owner, "!owner");
        uint256 balance = xen.balanceOf(address(this));
        require(balance >= amount, "Not enough.");
        xen.transfer(to, amount);
    }

    function burn() external returns(uint256) {
        require(msg.sender == owner, "!owner");

        MintInfo memory mintInfo = xen.getUserMint();
        require(mintInfo.term == 0, "Not Claimed!");

        uint256 balance = xen.balanceOf(address(this));
        require(balance > 0, "balance = 0");
        uint256 burnedAmount = balance > mintedAmount ? mintedAmount: balance;
        xen.approve(address(this), type(uint256).max);
        xen.burn(address(this), burnedAmount);
        return burnedAmount;
    }

    function getUserMint() external view returns (MintInfo memory) {
        return xen.getUserMint();
    }

    function onTokenBurned(address user, uint256 amount) external {
        
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return true;
    }
}