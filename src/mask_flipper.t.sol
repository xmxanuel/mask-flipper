pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./mask_flipper.sol";

contract MaskFlipperTest is DSTest {
    MaskFlipper flipper;
    address constant MASK_TOKEN = 0x0fe629d1E84E171f8fF0C1Ded2Cc2221Caa48a3f;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant NFTX = 0xAf93fCce0548D3124A5fC3045adAf1ddE4e8Bf7e;

    address constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address constant ERC721_HASHMASKS = 0xC2C747E0F7004F9E8817Db2ca4997657a7746928;

    function setUp() public {
        flipper = new MaskFlipper(NFTX, SUSHI_ROUTER, ERC721_HASHMASKS, MASK_TOKEN, WETH);
    }

    function testCurrentFloorPrice() public {
        uint price = flipper.currentFloorPrice();
        assertTrue(price > 0.2 ether);
        assertTrue(price < 2 ether);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
