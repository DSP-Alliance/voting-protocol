// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface ERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint8);
}