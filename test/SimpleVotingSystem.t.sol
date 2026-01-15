// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Test.sol";
import "../src/SimpleVotingSystem.sol";
import "../src/VotingNFT.sol";

contract SimpleVotingSystemTest is Test {
    SimpleVotingSystem votingSystem;
    VotingNFT votingNft;

    // Adresses de test
    address admin = address(this);
    address founder = address(0x1);
    address withdrawer = address(0x2);
    address voter1 = address(0x3);
    address voter2 = address(0x4);
    address candidate1 = address(0x5);
    address candidate2 = address(0x6);

    function setUp() public {
        // 1. Deploiement des contrats
        votingNft = new VotingNFT();
        votingSystem = new SimpleVotingSystem(address(votingNft));
        
        // 2. Transfert de l'ownership du NFT vers le systeme de vote
        votingNft.transferOwnership(address(votingSystem));

        // 3. Attribution des roles
        votingSystem.grantRole(votingSystem.FOUNDER_ROLE(), founder);
        votingSystem.grantRole(votingSystem.WITHDRAWER_ROLE(), withdrawer);
    }

    function testInitialState() public view {
        assertEq(uint256(votingSystem.workflowStatus()), uint256(SimpleVotingSystem.WorkflowStatus.REGISTER_CANDIDATES));
        assertEq(votingNft.owner(), address(votingSystem));
    }

    function testRegisterCandidate() public {
        // Test ajout candidat par Admin
        votingSystem.registerCandidate("Alice", candidate1);
        (string memory name,, address addr) = votingSystem.getCandidate(0);
        assertEq(name, "Alice");
        assertEq(addr, candidate1);
    }

    function testRevertRegisterCandidateNonAdmin() public {
        // Verifie que seul l'admin peut ajouter
        vm.prank(voter1);
        vm.expectRevert(); 
        votingSystem.registerCandidate("Bob", candidate2);
    }

    function testWorkflowTransition() public {
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);
        assertEq(uint256(votingSystem.workflowStatus()), uint256(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES));
    }

    function testFundCandidates() public {
        votingSystem.registerCandidate("Alice", candidate1);
        votingSystem.registerCandidate("Bob", candidate2);
        
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.FOUND_CANDIDATES);

        vm.deal(founder, 10 ether);
        vm.prank(founder);
        // Le founder envoie 10 ETH, donc 5 ETH chacun
        votingSystem.fundCandidates{value: 10 ether}();

        assertEq(candidate1.balance, 5 ether);
        assertEq(candidate2.balance, 5 ether);
    }

    function testRevertVoteTooEarly() public {
        votingSystem.registerCandidate("Alice", candidate1);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE); 

        vm.prank(voter1);
        vm.expectRevert("Le vote n'a pas encore commence (delai 1h)");
        votingSystem.vote(0);
    }

    function testVoteAfterDelay() public {
        votingSystem.registerCandidate("Alice", candidate1);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE); 

        // On avance le temps d'une heure
        vm.warp(block.timestamp + 3601);

        vm.startPrank(voter1);
        votingSystem.vote(0);
        vm.stopPrank();

        (, uint256 count,) = votingSystem.getCandidate(0);
        assertEq(count, 1);
        
        // Verifie que le votant a recu son NFT
        assertEq(votingNft.balanceOf(voter1), 1);
    }

    function testRevertDoubleVote() public {
        votingSystem.registerCandidate("Alice", candidate1);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 3601);

        vm.startPrank(voter1);
        votingSystem.vote(0);
        
        // Tentative de second vote
        vm.expectRevert("Vous avez deja vote");
        votingSystem.vote(0);
        vm.stopPrank();
    }

    function testWinnerAndWithdraw() public {
        votingSystem.registerCandidate("Alice", candidate1);
        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.VOTE);
        vm.warp(block.timestamp + 3601);

        vm.prank(voter1);
        votingSystem.vote(0);

        votingSystem.setWorkflowStatus(SimpleVotingSystem.WorkflowStatus.COMPLETED);

        (string memory winnerName, uint256 winnerCount) = votingSystem.getWinner();
        assertEq(winnerName, "Alice");
        assertEq(winnerCount, 1);

        // Test du retrait par le Withdrawer
        vm.deal(address(votingSystem), 1 ether); 
        
        vm.prank(withdrawer);
        uint256 preBalance = withdrawer.balance;
        votingSystem.withdraw();
        assertEq(withdrawer.balance, preBalance + 1 ether);
    }
}
