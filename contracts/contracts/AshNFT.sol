// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AshNFT is ERC721, ERC721URIStorage, Ownable {
    // 事件定义
    event NFTMinted(
        address indexed to,
        uint256 indexed tokenId,
        string ipfsHash
    );
    event NFTBurned(uint256 indexed tokenId);
    event NFTListed(uint256 indexed tokenId, uint256 price);
    event NFTDelisted(uint256 indexed tokenId);
    event NFTSold(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    // 合约常量
    string public constant NAME = "AshNFT";
    string public constant SYMBOL = "ASHNFT";

    // Token ID 计数器
    uint256 private _tokenIdCounter;

    // 映射关系：tokenId -> IPFS哈希
    mapping(uint256 => string) private _tokenURIs;

    // 映射关系：地址 -> 持有的所有tokenId数组
    mapping(address => uint256[]) private _ownedTokens;

    // 映射关系：tokenId -> 在_ownedTokens数组中的索引
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // 映射关系：tokenId -> 创建者
    mapping(uint256 => address) private _creators;
    
    // 映射关系：地址 -> 创建的所有tokenId数组
    mapping(address => uint256[]) private _createdTokens;

    // 映射关系：tokenId -> 是否上架
    mapping(uint256 => bool) private _isListed;

    // 映射关系：tokenId -> 价格
    mapping(uint256 => uint256) private _prices;

    // NFT交易记录结构
    struct TradeRecord {
        uint256 tokenId;
        address seller;
        address buyer;
        uint256 price;
        uint256 timestamp;
    }

    // tokenId -> 交易记录数组
    mapping(uint256 => TradeRecord[]) private _tradeRecords;

    // 总供应量
    uint256 public totalSupply;

    // 最大供应量（可选，设置为0表示无限制）
    uint256 public maxSupply;

    constructor(
        address initialOwner,
        uint256 _maxSupply
    ) ERC721(NAME, SYMBOL) Ownable(initialOwner) {
        maxSupply = _maxSupply;
    }

    /**
     * @dev 铸造NFT
     * @param to 接收者地址
     * @param ipfsHash IPFS哈希值
     * @return id 新铸造的tokenId
     */
    function mint(
        address to,
        string memory ipfsHash
    ) public returns (uint256 id) {
        require(
            bytes(ipfsHash).length > 0,
            "AshNFT: IPFS hash cannot be empty"
        );
        require(
            maxSupply == 0 || totalSupply < maxSupply,
            "AshNFT: Maximum supply reached"
        );

        id = ++_tokenIdCounter;

        _mint(to, id);
        _setTokenURI(id, ipfsHash);
        _tokenURIs[id] = ipfsHash;

        // 设置创建者
        _creators[id] = msg.sender;
        
        // 添加到创作者的作品列表中
        _createdTokens[msg.sender].push(id);

        // 默认上架状态
        _isListed[id] = true;
        // 设置默认价格为0，需要通过listNFT函数设置实际价格
        _prices[id] = 0;

        // 更新持有者映射
        _addTokenToOwnerEnumeration(to, id);

        totalSupply++;

        emit NFTMinted(to, id, ipfsHash);
        return id;
    }

    /**
     * @dev 批量铸造NFT
     * @param to 接收者地址
     * @param ipfsHashes IPFS哈希值数组
     * @return ids 新铸造的tokenId数组
     */
    function mintBatch(
        address to,
        string[] memory ipfsHashes
    ) public returns (uint256[] memory ids) {
        require(ipfsHashes.length > 0, "AshNFT: Hash array cannot be empty");
        require(
            maxSupply == 0 || totalSupply + ipfsHashes.length <= maxSupply,
            "AshNFT: Will exceed maximum supply"
        );

        ids = new uint256[](ipfsHashes.length);

        for (uint256 i = 0; i < ipfsHashes.length; i++) {
            require(
                bytes(ipfsHashes[i]).length > 0,
                "AshNFT: IPFS hash cannot be empty"
            );

            uint256 id = ++_tokenIdCounter;

            _mint(to, id);
            _setTokenURI(id, ipfsHashes[i]);
            _tokenURIs[id] = ipfsHashes[i];

            // 设置创建者
            _creators[id] = msg.sender;
            
            // 添加到创作者的作品列表中
            _createdTokens[msg.sender].push(id);

            // 默认上架状态
            _isListed[id] = true;

            // 更新持有者映射
            _addTokenToOwnerEnumeration(to, id);

            ids[i] = id;
            totalSupply++;

            emit NFTMinted(to, id, ipfsHashes[i]);
        }

        return ids;
    }

    /**
     * @dev 销毁NFT
     * @param tokenId 要销毁的tokenId
     */
    function burn(uint256 tokenId) public {
        require(
            _ownerOf(tokenId) != address(0),
            "AshNFT: Token does not exist"
        );
        require(
            ownerOf(tokenId) == msg.sender || msg.sender == owner(),
            "AshNFT: Not authorized to burn this token"
        );

        address tokenOwner = ownerOf(tokenId);

        // 直接调用内部函数销毁代币
        _burn(tokenId);

        // 从持有者映射中移除
        _removeTokenFromOwnerEnumeration(tokenOwner, tokenId);

        // 清理IPFS哈希映射
        delete _tokenURIs[tokenId];

        // 清理创建者映射
        delete _creators[tokenId];

        // 清理上架状态
        delete _isListed[tokenId];

        // 清理价格
        delete _prices[tokenId];

        totalSupply--;

        emit NFTBurned(tokenId);
    }

    /**
     * @dev 上架NFT进行出售
     * @notice 调用此函数将NFT放入市场进行出售
     * @param tokenId 要上架的tokenId
     * @param price NFT的出售价格（以wei为单位）
     *
     * Requirements:
     * - tokenId必须存在且有效
     * - 调用者必须是tokenId的所有者
     * - 价格必须大于0
     *
     * Effects:
     * - 将tokenId标记为上架状态
     * - 设置NFT的出售价格
     * - 触发NFTListed事件记录上架信息
     *
     * Emits a {NFTListed} event.
     */
    function listNFT(uint256 tokenId, uint256 price) public {
        require(_exists(tokenId), "AshNFT: Token does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "AshNFT: Not the owner of this token"
        );
        require(price > 0, "AshNFT: Price must be greater than 0");

        _isListed[tokenId] = true;
        _prices[tokenId] = price;

        emit NFTListed(tokenId, price);
    }

    /**
     * @dev 下架NFT
     * @param tokenId 要下架的tokenId
     */
    function delistNFT(uint256 tokenId) public {
        require(_exists(tokenId), "AshNFT: Token does not exist");
        require(
            ownerOf(tokenId) == msg.sender,
            "AshNFT: Not the owner of this token"
        );

        _isListed[tokenId] = false;

        emit NFTDelisted(tokenId);
    }

    /**
     * @dev 购买NFT
     * @param tokenId 要购买的tokenId
     */
    function buyNFT(uint256 tokenId) public payable {
        // 检查代币是否存在
        require(_exists(tokenId), "AshNFT: Token does not exist");
        // 检查代币是否正在销售
        require(_isListed[tokenId], "AshNFT: Token is not listed for sale");
        // 检查购买者不是所有者
        require(
            ownerOf(tokenId) != msg.sender,
            "AshNFT: Cannot buy your own token"
        );
        // 检查支付金额是否足够
        require(msg.value >= _prices[tokenId], "AshNFT: Insufficient funds");

        address seller = ownerOf(tokenId);
        address buyer = msg.sender;
        uint256 price = _prices[tokenId];

        // 直接转移所有权，绕过ERC721的授权检查
        // 这是市场合约的特殊权限
        _transfer(seller, buyer, tokenId);

        // 更新持有者映射
        _removeTokenFromOwnerEnumeration(seller, tokenId);
        _addTokenToOwnerEnumeration(buyer, tokenId);

        // 转移资金
        payable(seller).transfer(price);

        // 下架NFT
        _isListed[tokenId] = false;

        // 添加交易记录
        _tradeRecords[tokenId].push(
            TradeRecord({
                tokenId: tokenId,
                seller: seller,
                buyer: buyer,
                price: price,
                timestamp: block.timestamp
            })
        );

        emit NFTSold(tokenId, seller, buyer, price);
    }

    /**
     * @dev 查询特定地址持有的所有NFT
     * @param owner 持有者地址
     * @return ids 持有的tokenId数组
     */
    function tokensOfOwner(
        address owner
    ) public view returns (uint256[] memory ids) {
        require(owner != address(0), "AshNFT: Query for zero address");

        return _ownedTokens[owner];
    }
    
    /**
     * @dev 查询特定地址创建的所有NFT
     * @param creator 创作者地址
     * @return ids 创建的tokenId数组
     */
    function tokensOfCreator(
        address creator
    ) public view returns (uint256[] memory ids) {
        require(creator != address(0), "AshNFT: Query for zero address");
        return _createdTokens[creator];
    }

    /**
     * @dev 获取tokenId对应的IPFS哈希
     * @param tokenId 代币ID
     * @return hash IPFS哈希值
     */
    function getTokenIPFSHash(
        uint256 tokenId
    ) public view returns (string memory hash) {
        require(_exists(tokenId), "AshNFT: Token does not exist");
        return _tokenURIs[tokenId];
    }

    /**
     * @dev 获取NFT创建者
     * @param tokenId 代币ID
     * @return creatorAddress 创建者地址
     */
    function getCreator(
        uint256 tokenId
    ) public view returns (address creatorAddress) {
        require(_exists(tokenId), "AshNFT: Token does not exist");
        return _creators[tokenId];
    }

    /**
     * @dev 检查NFT是否上架
     * @param tokenId 代币ID
     * @return listed 是否上架
     */
    function isListed(uint256 tokenId) public view returns (bool listed) {
        require(_exists(tokenId), "AshNFT: Token does not exist");
        return _isListed[tokenId];
    }

    /**
     * @dev 获取NFT价格
     * @param tokenId 代币ID
     * @return tokenPrice 价格
     */
    function getPrice(
        uint256 tokenId
    ) public view returns (uint256 tokenPrice) {
        require(_exists(tokenId), "AshNFT: Token does not exist");
        return _prices[tokenId];
    }

    /**
     * @dev 获取NFT交易记录
     * @param tokenId 代币ID
     * @return tradeRecords 交易记录数组
     */
    function getTradeRecords(
        uint256 tokenId
    ) public view returns (TradeRecord[] memory tradeRecords) {
        require(_exists(tokenId), "AshNFT: Token does not exist");
        return _tradeRecords[tokenId];
    }

    /**
     * @dev 检查tokenId是否存在
     * @param tokenId 代币ID
     * @return bool tokenId是否存在
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev 设置最大供应量
     * @param _maxSupply 新的最大供应量
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(
            _maxSupply >= totalSupply,
            "AshNFT: Max supply cannot be less than current supply"
        );
        maxSupply = _maxSupply;
    }

    /**
     * @dev 重写ERC721的transferFrom函数，确保转移时更新映射关系
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        super.transferFrom(from, to, tokenId);

        // 更新持有者映射
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev 重写ERC721的safeTransferFrom函数，确保转移时更新映射关系
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) {
        super.safeTransferFrom(from, to, tokenId, data);

        // 更新持有者映射
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev 重写ERC721的_safeTransfer函数，确保转移时更新映射关系
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal override {
        super._safeTransfer(from, to, tokenId, data);

        // 更新持有者映射
        _removeTokenFromOwnerEnumeration(from, tokenId);
        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev 重写ERC721的tokenURI函数
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        require(_exists(tokenId), "AshNFT: Token does not exist");
        return super.tokenURI(tokenId);
    }

    /**
     * @dev 重写ERC721的supportsInterface函数
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev 将tokenId添加到持有者的枚举中
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokens[to].push(tokenId);
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length - 1;
    }

    /**
     * @dev 从持有者的枚举中移除tokenId
     */
    function _removeTokenFromOwnerEnumeration(
        address from,
        uint256 tokenId
    ) private {
        uint256 lastTokenIndex = _ownedTokens[from].length - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;
            _ownedTokensIndex[lastTokenId] = tokenIndex;
        }

        delete _ownedTokensIndex[tokenId];
        _ownedTokens[from].pop();
    }

    /**
     * @dev 获取总供应量
     * @return getTotalSupply 总供应量
     */
    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    // 接收ETH函数
    receive() external payable {}
}