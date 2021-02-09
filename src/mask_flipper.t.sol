pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./mask_flipper.sol";

contract MaskFlipperTest is DSTest {
    MaskFlipper flipper;

    function setUp() public {
        //flipper = new MaskFlipper(address(0), address(0), address(0));
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
