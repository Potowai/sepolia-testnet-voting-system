// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./VotingNFT.sol";

contract SimpleVotingSystem is AccessControl {
    bytes32 public constant FOUNDER_ROLE = keccak256("FOUNDER_ROLE");
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    enum WorkflowStatus {
        REGISTER_CANDIDATES,
        FOUND_CANDIDATES,
        VOTE,
        COMPLETED
    }

    struct Candidate {
        string name;
        address candidateAddress;
        uint256 voteCount;
    }

    WorkflowStatus public workflowStatus;
    uint256 public voteStartTime;
    VotingNFT public votingNft;
    Candidate[] public candidates;

    constructor(address _votingNftAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        votingNft = VotingNFT(_votingNftAddress);
        workflowStatus = WorkflowStatus.REGISTER_CANDIDATES;
    }

    modifier atStatus(WorkflowStatus _status) {
        require(workflowStatus == _status, "Statut du workflow invite");
        _;
    }

    function setWorkflowStatus(WorkflowStatus _newStatus) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // Enregistre l'heure de debut si on passe au vote
        if (_newStatus == WorkflowStatus.VOTE && workflowStatus != WorkflowStatus.VOTE) {
            voteStartTime = block.timestamp;
        }
        workflowStatus = _newStatus;
    }

    function registerCandidate(string memory _name, address _candidateAddress)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        atStatus(WorkflowStatus.REGISTER_CANDIDATES)
    {
        candidates.push(Candidate({name: _name, candidateAddress: _candidateAddress, voteCount: 0}));
    }

    // Role FOUNDER : Envoyer des fonds aux candidats
    function fundCandidates() external payable onlyRole(FOUNDER_ROLE) atStatus(WorkflowStatus.FOUND_CANDIDATES) {
        require(candidates.length > 0, "Aucun candidat a financer");
        require(msg.value > 0, "Aucun fonds envoye");

        uint256 share = msg.value / candidates.length;
        for (uint256 i = 0; i < candidates.length; i++) {
            (bool success,) = candidates[i].candidateAddress.call{value: share}("");
            require(success, "Echec du transfert");
        }
    }

    function vote(uint256 _candidateIndex) external atStatus(WorkflowStatus.VOTE) {
        require(block.timestamp >= voteStartTime + 1 hours, "Le vote n'a pas encore commence (delai 1h)");
        require(votingNft.balanceOf(msg.sender) == 0, "Vous avez deja vote");
        require(_candidateIndex < candidates.length, "Index candidat invalide");

        candidates[_candidateIndex].voteCount++;
        votingNft.safeMint(msg.sender);
    }

    function getWinner() external view returns (string memory winnerName, uint256 winnerVoteCount) {
        require(workflowStatus == WorkflowStatus.COMPLETED, "Vote non termine");

        uint256 winningVoteCount = 0;
        uint256 winningIndex = 0;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winningIndex = i;
            }
        }

        if (candidates.length > 0) {
            return (candidates[winningIndex].name, candidates[winningIndex].voteCount);
        } else {
            return ("", 0);
        }
    }

    // Role WITHDRAWER : Retirer les fonds restants
    function withdraw() external onlyRole(WITHDRAWER_ROLE) atStatus(WorkflowStatus.COMPLETED) {
        uint256 balance = address(this).balance;
        require(balance > 0, "Aucun fonds a retirer");

        (bool success,) = msg.sender.call{value: balance}("");
        require(success, "Echec du retrait");
    }

    function getCandidate(uint256 _index) public view returns (string memory, uint256, address) {
        require(_index < candidates.length, "Index invalide");
        return (candidates[_index].name, candidates[_index].voteCount, candidates[_index].candidateAddress);
    }
}
