// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This contract was built using tutorial videos from the Learn Solidity course @ Alchemy University.
// It is a simple voting contract which uses many data types, events, and concepts.
// This contract allows a set of whitelisted addresses to vote on proposals to execute contracts.
// Voters may only vote once, but are able to change their vote at will.
// Once a pre-determined threshold of yes votes is reached, a contract is executed.
// Contracts can only be executed once.
contract Voting {
    uint256 constant VOTE_THRESHOLD = 10;

    struct Proposal {
        address target;
        bytes data;
        uint256 yesCount;
        uint256 noCount;
    }

    struct UserVote {
        bool voted;
        bool vote;
    }

    Proposal[] public proposals;

    mapping(address => UserVote) userVotes;
    mapping(address => bool) voterWhitelist;
    mapping(address => bool) executedContracts;

    event ProposalCreated(uint256 proposalId);
    event VoteCast(uint256 proposalId, address voterAddress);
    event ContractExecuted(address contractAddress);

    constructor(address[] memory addressWhitelist) {
        // Contract deployer can vote and create proposals
        voterWhitelist[msg.sender] = true;

        // Provided addresses can vote and create proposals
        for (uint256 i = 0; i < addressWhitelist.length; i++) {
            voterWhitelist[addressWhitelist[i]] = true;
        }
    }

    function isAllowedAddress(address voterAddress) private view returns(bool) {
        return voterWhitelist[voterAddress];
    }

    function newProposal(address targetAddress, bytes memory targetData) external {
        require(isAllowedAddress(msg.sender));

        proposals.push(Proposal ({
            target: targetAddress,
            data: targetData,
            yesCount: 0,
            noCount: 0
        }));

        emit ProposalCreated(proposals.length - 1);
    }

    function castVote(uint256 proposalId, bool vote) external {
        require(isAllowedAddress(msg.sender));

        // If this address has already voted, only allow changing of vote
        bool hasVoted = userVotes[msg.sender].voted;

        if (hasVoted) {
            require(vote != userVotes[msg.sender].vote);
        }

        if (vote) {
            if (hasVoted) {
                proposals[proposalId].noCount--;
            }

            proposals[proposalId].yesCount++;
            userVotes[msg.sender].voted = true;
            userVotes[msg.sender].vote = vote;
        } else {
            if (hasVoted) {
                proposals[proposalId].yesCount--;
            }

            proposals[proposalId].noCount++;
            userVotes[msg.sender].voted = true;
            userVotes[msg.sender].vote = vote;
        }

        if (proposals[proposalId].yesCount >= VOTE_THRESHOLD) {
            executeProposal(proposalId);
        }

        emit VoteCast(proposalId, msg.sender);

    }

    function executeProposal(uint256 proposalId) private {
        //Make sure this contract has not yet been executed!
        require(!executedContracts[proposals[proposalId].target]);

        proposals[proposalId].target.call(proposals[proposalId].data);
        executedContracts[proposals[proposalId].target] = true;
        emit ContractExecuted(proposals[proposalId].target);
    }
}