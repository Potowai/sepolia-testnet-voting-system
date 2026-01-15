// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "forge-std/Script.sol";
import "../src/SimpleVotingSystem.sol";
import "../src/VotingNFT.sol";

contract DeployVotingScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploiement du NFT
        VotingNFT votingNft = new VotingNFT();
        console.log("VotingNFT deployed at:", address(votingNft));

        // 2. Deploiement du Systeme de Vote
        SimpleVotingSystem votingSystem = new SimpleVotingSystem(address(votingNft));
        console.log("SimpleVotingSystem deployed at:", address(votingSystem));

        // 3. Transfert de l'ownership vers le contrat de vote
        votingNft.transferOwnership(address(votingSystem));
        console.log("NFT ownership transferred to Voting System");

        vm.stopBroadcast();
    }
}
