pragma solidity ^0.6.7;

interface NFTX  {
    function mint(uint256 vaultId, uint256[] calldata nftIds, uint256 d2Amount) external;
}
interface ERC721 {
    function transferFrom(address from, address to, uint nftID) external;
    function ownerOf(uint nftID) external returns (address);
    function approve(address usr, uint amount) external;
}

interface ERC20 {
    function approve(address usr, uint amount)  external;
}

interface SushiRouter {
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function getAmountsOut(uint256 amount, address[] calldata path) external view returns(uint);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}
contract MaskFlipper {

    uint constant public ONE = 10**27;
    uint constant public ONE_MASK_TOKEN = 10**18;
    // Hashmasks vault id
    uint constant public VAULT_ID = 20;

    //math
    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }
    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }


    NFTX public nftx;
    SushiRouter public sushiRouter;
    ERC721 public hashmasks;
    ERC20 public maskToken;
    address public weth;

    uint public fee = ONE;

    address public owner;


    constructor(address nftx_, address sushiRouter_, address hashmasks_, address maskToken_, address weth_) public {
        owner = msg.sender;
        nftx = NFTX(nftx_);
        sushiRouter = SushiRouter(sushiRouter_);
        hashmasks = ERC721(hashmasks_);
        maskToken = ERC20(maskToken_);
        weth = weth_;

        maskToken.approve(address(nftx), uint(-1));
    }

    // returns the current amount of ETH in exchange for a mask
    function currentFloorPrice() public view returns(uint) {
        address[] memory path = new address[](2);
        path[0] = address(maskToken);
        path[1] = address(weth);

        return sushiRouter.getAmountsOut(ONE_MASK_TOKEN, path);
    }

    function flipMask(uint nftID) public {
        require(hashmasks.ownerOf(nftID) == msg.sender, "msg.sender is not nft owner");
        hashmasks.transferFrom(msg.sender, address(this), nftID);


        // move nft into NFTX pool
        hashmasks.approve(address(nftx), nftID);

        uint256[] memory list = new uint256[](1);
        list[0] = nftID;

        nftx.mint(VAULT_ID,list, 0);

        address[] memory path = new address[](2);
        path[0] = address(maskToken);
        path[1] = weth;

        uint minPrice = currentFloorPrice();

        sushiRouter.swapTokensForExactTokens(ONE_MASK_TOKEN, minPrice, path, address(this), block.timestamp+1);

    }
}
