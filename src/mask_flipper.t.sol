pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./mask_flipper.sol";

interface SushiRouterLike {
    function swapExactETHForTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
}

interface NFTXLike {
    function swapExactETHForTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function redeem(uint vaultId, uint256 amount) external;
}

interface ERC721Like {
    function tokenOfOwnerByIndex(address owner, uint idx) external returns(uint);
}

interface ERC20Like {
    function balanceOf(address usr) external returns(uint);
}

interface WETHLike {
    function deposit() external payable;
}

// RPC Test for Mainnet
contract MaskFlipperTest is DSTest {
    // math
    uint constant public ONE = 10**27;
    function rmul(uint x, uint y) public pure returns (uint z) {
        z = safeMul(x, y) / ONE;
    }
    function safeMul(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "safe-mul-failed");
    }
    function rdiv(uint x, uint y) public pure returns (uint z) {
        require(y > 0, "division by zero");
        z = safeAdd(safeMul(x, ONE), y / 2) / y;
    }
    function safeAdd(uint x, uint y) public pure returns (uint z) {
        require((z = x + y) >= x, "safe-add-failed");
    }

    function safeSub(uint x, uint y) public pure returns (uint z) {
        require((z = x - y) <= x, "safe-sub-failed");
    }
    function rdivup(uint x, uint y) internal pure returns (uint z) {
        require(y > 0, "division by zero");
        // always rounds up
        z = safeAdd(safeMul(x, ONE), safeSub(y, 1)) / y;
    }


    MaskFlipper flipper;
    // mainnet contracts
    address constant MASK_TOKEN = 0x0fe629d1E84E171f8fF0C1Ded2Cc2221Caa48a3f;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant NFTX = 0xAf93fCce0548D3124A5fC3045adAf1ddE4e8Bf7e;

    address constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant ERC721_HASHMASKS = 0xC2C747E0F7004F9E8817Db2ca4997657a7746928;

    function setUp() public {
        flipper = new MaskFlipper(NFTX, SUSHI_ROUTER, ERC721_HASHMASKS, MASK_TOKEN, WETH);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return 0x150b7a02;
    }

    function setUpHashMask() public returns(uint) {
        address[] memory path = new address[](2);
        path[0] = address(WETH);
        path[1] = address(MASK_TOKEN);
        SushiRouterLike(SUSHI_ROUTER).swapExactETHForTokens{value:1 ether}(1, path, address(this), now + 1);

        ERC20(MASK_TOKEN).approve(NFTX, flipper.ONE_MASK_TOKEN());

        // redeem NFT
        NFTXLike(NFTX).redeem(flipper.VAULT_ID(), 1);

        return ERC721Like(ERC721_HASHMASKS).tokenOfOwnerByIndex(address(this), 0);
    }

    function setUpWETH() public {
        uint wethIn = 2 ether;
        WETHLike(WETH).deposit.value(wethIn)();
    }

    function testCurrentFloorPrice() public {
        uint price = flipper.currentFloor();
        assertTrue(price > 0.2 ether);
        assertTrue(price < 2 ether);
    }

    function flipMask() public returns(uint balance) {
        uint expectedMinBalance = flipper.currentFloor();
        uint nftID = setUpHashMask();
        // test contract should own a mask
        assertEq(ERC721(flipper.hashmasks()).ownerOf(nftID), address(this));

        ERC721(flipper.hashmasks()).approve(address(flipper), nftID);

        flipper.flipMask(nftID);

        uint balance = ERC20Like(WETH).balanceOf(address(this));

        assertTrue(balance >= expectedMinBalance);
        return balance;
    }

    function testFlipMask() public {
        flipMask();
    }

    function testflipMaskRate() public {
        uint flipMaskRate = 0.995 * 10**27;
        flipper.file("flipMaskRate", flipMaskRate);
        uint balance = flipMask();

        uint fees = safeSub(rmul(rdivup(balance, flipMaskRate), ONE), balance);

        assertEq(ERC20Like(WETH).balanceOf(address(flipper)), fees);

        uint preBalance = ERC20Like(WETH).balanceOf(address(this));

        flipper.redeem();
        assertEq(ERC20Like(WETH).balanceOf(address(this)), safeAdd(preBalance, fees));
    }

    function getRandomMask() public {
        setUpWETH();
        ERC20(WETH).approve(address(flipper), uint(-1));
        uint nftID = flipper.getRandomMask();
        assertEq(ERC721(ERC721_HASHMASKS).ownerOf(nftID), address(this));
    }

    function testGetMask() public {
        getRandomMask();
    }

    function testGetMaskWithRate() public {
        uint getMaskRate = 1.005 * 10**27;
        flipper.file("getMaskRate", getMaskRate);
        uint currentBuyPrice = flipper.currentBuyPrice();
        uint fees = safeSub(currentBuyPrice, rmul(rdivup(currentBuyPrice, getMaskRate), ONE));
        getRandomMask();

        uint preBalance = ERC20Like(WETH).balanceOf(address(this));

        flipper.redeem();
        assertEq(ERC20Like(WETH).balanceOf(address(this)), safeAdd(preBalance, fees));
    }
}
