// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

error NotRegistered();

interface IVoteFactory {
    function owner() external view returns (address);
    function registered(address voter) external view returns (bool);
    function ownedGlifPool(address voter) external view returns (address);
    function ownedMiners(address voter) external view returns (uint64[] calldata);
    function voterRBP(uint64 minerId, address minerOwner) external view returns (uint256);
}