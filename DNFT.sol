// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./ERC3525.sol";
import "./interfaces/IXEN.sol";
import "./interfaces/IXProxy.sol";
import "./interfaces/ITraits.sol";
import "./interfaces/IDPool.sol";
import "./interfaces/IBurnRedeemable.sol";

// BSC-T: 0x77dfB189A25514b4087D499fe9BCaaDABD87b5D4
/*
通过代理燃烧XEN: 0.005e + 2次gas fee(一次mint，一次burn) + XEN burned (number is not comfirmed)
二级市场购买XEN进行燃烧：买入费 + 0.005E + 2次gas费（一次swap，一次burn）+ XEN burned
假设需要burn 1M XEN，哪种方式更划算？
1：预估N天才能mint出，然后才能burn抵押，需要评估burn时的分红收益
2：0.013E = 1M XEN
*/
contract DNFT is IBurnRedeemable, ERC3525 {
    mapping(address => address[]) public userXProxies;
    mapping(address => address) public xProxyOwner;
    address public owner;
    ITraits public traits;
    IXEN public xen;  
    uint256 immutable public MintFee;
    uint256 immutable public startTime;
    uint256 lastPeriodIndex = 1;
    uint256 public id = 1;
    address public xProxyImp;
    IDPool public dPool;


    event NewXProxy(address indexed user, address indexed xProxyAddr, uint256 term);

    // xen: bsc-t: 0xa525366969F79b223a5d16900e8F0754c64C3EDa, eth: 0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8, bsc: 0x2AB0e9e4eE70FFf1fB9D67031E44F6410170d00e, polygon:  
    // traits: bsc-t: 0x2166E30b9D1380b36A30605de32E3796Faec8Bb1, eth: , bsc: , polygon:  
    // xProxy: bsc-t: 0x2147c8A7fEd1dd17E50b29F665682651a7f76982, eth: , bsc: , polygon:  
    constructor(IXEN _xen, ITraits _traits, address _xProxyImp) ERC3525("XEN Dividend NFT", "DNFT", 0) {
        owner = msg.sender;
        xen = _xen;
        traits = _traits;
        xProxyImp = _xProxyImp;
        startTime = block.timestamp;
        MintFee = xen.MintFee();
    }

    function setTraits(ITraits _traits) external {
        require(owner == msg.sender, "!owner");
        traits = _traits;
    }

    function setDividendPool(IDPool _dPool) external {
        require(owner == msg.sender, "!owner");
        dPool = _dPool;
    }

    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    function batchCreateProxy(uint256 times, uint256 term, address spreader) external payable {
        require(msg.sender == tx.origin, "only EOA");
        require(msg.value == times * MintFee, "msg.value ERROR");
        
        for (uint i = 0; i < times; i++) {
            IXProxy xProxy = IXProxy(clone(xProxyImp));
            xProxy.initialize{value: MintFee}(address(this), address(xen), term, spreader);
            userXProxies[msg.sender].push(address(xProxy));
            xProxyOwner[address(xProxy)] = msg.sender;
            emit NewXProxy(msg.sender, address(xProxy), term);
        }
    }

    function burnXenInXProxy(address proxyAddr) external {
        require(xProxyOwner[proxyAddr] == msg.sender, "!owner");
        IXProxy xProxy = IXProxy(proxyAddr);
        MintInfo memory mintInfo = xProxy.getUserMint();
        require(mintInfo.maturityTs <= block.timestamp, "DNFT can only be minted out after the time of maturityTs.");
        
        uint256 burnedAmount = xProxy.burn();
        
        uint256 periodIndex = dPool.getCurrentPeriodIndex();
        _mintValue(msg.sender, id++, periodIndex, burnedAmount);
    }

    // user should approve to this contract firstly
    function burnXen(uint256 burnedAmount) external {
        xen.burn(msg.sender, burnedAmount);

        uint256 periodIndex = dPool.getCurrentPeriodIndex();
        _mintValue(msg.sender, id++, periodIndex, burnedAmount);
    }

    function split(uint256 tokenId, uint256[] memory newTokenValues) external {
        require(ownerOf(tokenId) == msg.sender, "Not owner of NFT");
        for (uint256 i; i < newTokenValues.length; i++) {
            transferFrom(tokenId, msg.sender, newTokenValues[i]);
        }
        if (_values[tokenId] == 0) {
            _burn(tokenId);
        }
    }

    function merge(uint256[] memory fromTokenIds, uint256[] memory fromTokenValues, uint256 toTokenId) external {
        for (uint256 i; i < fromTokenIds.length; i++) {
            require(ownerOf(fromTokenIds[i]) == msg.sender, "Not owner");
            transferFrom(fromTokenIds[i], toTokenId, fromTokenValues[i]);
            if (_values[fromTokenIds[i]] == 0) {
                _burn(fromTokenIds[i]);
            }
        }
    } 

    function withdrawXEN(address xProxyAddr, uint256 amount) external {
        require(xProxyOwner[xProxyAddr] == msg.sender, "!owner");
        IXProxy xProxy = IXProxy(xProxyAddr);
        xProxy.withdraw(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        uint256 xenAmount = _values[tokenId];
        uint256 peroidId = _slots[tokenId];

        return traits.tokenURI(tokenId, peroidId, xenAmount);
    }

    function getProxies(address user) public view returns(address[] memory) {
        return userXProxies[user];
    }

    function _getNewTokenId() internal virtual override returns (uint256) {
        return id++;
    }

    function onTokenBurned(address user, uint256 amount) external  {
        
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        if (type(IBurnRedeemable).interfaceId == interfaceId) {
            return true;
        }
        return super.supportsInterface(interfaceId);
    }
}