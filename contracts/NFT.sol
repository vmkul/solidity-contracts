pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Timers.sol";

contract MyNFT is ERC721 {
    using Counters for Counters.Counter;
    using Timers for Timers.Timestamp;
    Counters.Counter private _tokenIds;
    IERC20 TokenContract;
    address admin;
    
    struct TokenForSale {
        address originalOwner;
        uint price;
    }
    
    mapping(uint => TokenForSale) tokensOnSale;
    mapping(address => uint) balances;
    mapping(uint => Timers.Timestamp) tokenTimelocks;

    constructor(address _ERC20Token) ERC721("SomeNFT", "NFT") {
        TokenContract = IERC20(_ERC20Token);
        admin = msg.sender;
    }
    
    modifier requireAdmin() {
        require(msg.sender == admin);
        _;
    }

    function mintAmount(uint amount) internal {
        for (uint i = 0; i < amount; i++) {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            
            tokenTimelocks[newItemId] = Timers.Timestamp(0);
            tokenTimelocks[newItemId].setDeadline(uint64(block.timestamp + 5 minutes));

            _mint(msg.sender, newItemId);
        }
    }

    function mint(uint amount) external payable returns (bool) {
        require(amount >= 1 && amount <= 20);
        require(msg.value == 1 ether * amount);

        mintAmount(amount);
        return true;
    }

    function mintERC20(uint amount) external returns (bool) {
        require(amount >= 1 && amount <= 20);
        bool result = TokenContract.transferFrom(msg.sender, address(this), amount * 10 ** 18);
        if (!result) revert();

        mintAmount(amount);
        return true;
    }
    
    function setOnSale(uint tokenId, uint price) external payable returns (bool) {
        if (price == 0) {
            require(tokensOnSale[tokenId].originalOwner == msg.sender);
            delete tokensOnSale[tokenId];
            _transfer(address(this), msg.sender, tokenId);
            return true;
        }
        
        require(ownerOf(tokenId) == msg.sender);
        require(tokensOnSale[tokenId].price == 0, "Token already on sale!");
        
        _transfer(msg.sender, address(this), tokenId);
        
        TokenForSale memory token = TokenForSale(msg.sender, price);
        tokensOnSale[tokenId] = token;
        return true;
    }
    
    function calculateRoyalty(uint price) internal pure returns (uint) {
        return price / 20;
    }
    
    function buyToken(uint tokenId) external payable returns (bool) {
        TokenForSale memory token = tokensOnSale[tokenId];
        
        require(token.price != 0);
        require(msg.value == calculateRoyalty(token.price) + token.price);
        
        _transfer(address(this), msg.sender, tokenId);
        
        balances[token.originalOwner] += token.price;
        delete tokensOnSale[tokenId];
        return true;
    }
    
    function withdrawFromSale() external returns (bool) {
        uint balance = balances[msg.sender];
        require(balance > 0);
        
        address payable sender = payable(msg.sender);
        sender.transfer(balance);
        delete balances[msg.sender];
        return true;
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal virtual override
    {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from != address(0) && to != address(0)) {
            require(tokenTimelocks[tokenId].isExpired(), "Token locked for 5 minutes after minting!");
        }
        
    }
    
    function setPrice(uint tokenId, uint newPrice) external returns (bool) {
        require(tokensOnSale[tokenId].price > 0, "Token not on sale");
        require(newPrice > 0, "Price should be greater than 0");
        require(msg.sender == tokensOnSale[tokenId].originalOwner, "You're not token's owner!");
        
        tokensOnSale[tokenId].price = newPrice;
        return true;
    }
}
