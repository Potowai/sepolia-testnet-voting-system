// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/SupDeVinci_USD.sol";

contract DeploySUSD is Script {
    function run() external {
        // Récupération de la clé privée depuis le fichier .env [cite: 888]
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Déploiement du contrat (l'owner est celui qui déploie)
        SupDeVinci_USD susd = new SupDeVinci_USD(vm.addr(deployerPrivateKey));

        // Consigne : Mint/Envoyer 10k tokens à un wallet au choix
        address walletAuChoix = address(0x1234567890123456789012345678901234567890);
        uint256 amountToSend = 10000 * (10 ** susd.decimals());

        // Comme le deployer a reçu toute la supply dans le constructeur, il transfère 10k
        susd.transfer(walletAuChoix, amountToSend);

        vm.stopBroadcast();
    }
}
