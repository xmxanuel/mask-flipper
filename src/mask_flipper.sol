pragma solidity ^0.6.7;

import "../lib/ds-test/src/test.sol";

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
    function transferFrom(address from, address to, uint amount) external;
    function balanceOf(address usr) external returns(uint amount);
}

interface SushiRouter {
    function getAmountsOut(uint256 amount, address[] calldata path) external view returns(uint[] memory);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external returns (uint[] memory amounts);
}

import "ds-test/test.sol";
contract MaskFlipper is DSTest {
    uint constant public ONE = 10**27;
    uint constant public ONE_MASK_TOKEN = 1 ether;
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
    ERC20 public weth;

    // default 100% payout => no fee
    // denominated in RAY (10^27)
    uint public payoutRate = ONE;

    address public owner;

    constructor(address nftx_, address sushiRouter_, address hashmasks_, address maskToken_, address weth_) public {
        owner = msg.sender;
        nftx = NFTX(nftx_);
        sushiRouter = SushiRouter(sushiRouter_);
        hashmasks = ERC721(hashmasks_);
        maskToken = ERC20(maskToken_);
        weth = ERC20(weth_);

        maskToken.approve(address(sushiRouter), uint(-1));
    }

    // returns the current floor price minus the fee in WETH
    function currentFloorPrice() public view returns(uint) {
        return rmul(_currentFloorPrice(), payoutRate);
    }

    function _currentFloorPrice() internal view returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(maskToken);
        path[1] = address(weth);

        return sushiRouter.getAmountsOut(ONE_MASK_TOKEN, path)[1];
    }

    // flip a mask against the current floor price in NFTX
    function flipMask(uint nftID) public {
        require(hashmasks.ownerOf(nftID) == msg.sender, "msg.sender is not nft owner");
        hashmasks.transferFrom(msg.sender, address(this), nftID);

        // move nft into NFTX pool
        hashmasks.approve(address(nftx), nftID);

        uint256[] memory list = new uint256[](1);
        list[0] = nftID;

        nftx.mint(VAULT_ID, list, 0);

        require(maskToken.balanceOf(address(this)) == ONE_MASK_TOKEN, "no mask token received from nftx");

        address[] memory path = new address[](2);
        path[0] = address(maskToken);
        path[1] = address(weth);

        uint wantPrice = _currentFloorPrice();

        uint price = sushiRouter.swapExactTokensForTokens(ONE_MASK_TOKEN, 0, path, address(this), block.timestamp+1)[1];

        require(price >= wantPrice, "received WETH amount from sushi-swap too low");

        weth.transferFrom(address(this), msg.sender, rmul(price, payoutRate));
    }

    function setPayoutRate(uint payoutRate_) public {
        require(msg.sender == owner, "msg.sender not owner");
        payoutRate = payoutRate_;
    }

    function payout() public {
        require(msg.sender == owner);
        weth.transferFrom(address(this), owner, weth.balanceOf(address(this)));
    }
}
