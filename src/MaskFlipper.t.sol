pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./MaskFlipper.sol";

contract MaskFlipperTest is DSTest {
    MaskFlipper flipper;

    function setUp() public {
        flipper = new MaskFlipper();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
