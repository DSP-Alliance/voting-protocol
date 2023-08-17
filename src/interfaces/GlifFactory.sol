// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface GlifFactory {
    function isAgent(address) external view returns (bool);
}