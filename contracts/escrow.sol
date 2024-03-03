// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// This contract allows peer-to-peer funds transfer via a 3rd-party escrow arbiter.
// The beneficiary and arbiter address are defined upon construction.
contract Escrow {
    address public depositor;
    address public beneficiary;
    address public arbiter;

    event Approved(uint256);

    // Optimize memory (and gas) using custom errors
    error ArbiterOnly();
    error EscrowTransferFailed();

    constructor(address _arbiter, address _beneficiary) payable {
        arbiter = _arbiter;
        beneficiary = _beneficiary;
        depositor = msg.sender;
    }

    function approve () external {
        // Only allow the arbiter's address to approve transfer of escrowed funds.
        if (msg.sender != arbiter) {
            revert ArbiterOnly();
        }

        uint256 balance = address(this).balance;

        // Message call - sending this contract's balance with no calldata
        (bool success, ) = beneficiary.call{ value: address(this).balance }("");

        if (!success) {
            revert EscrowTransferFailed();
        }

        emit Approved(balance);
    }
}