// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SupDeVinci_USD is ERC20, Ownable {
    // Le constructeur initialise le nom et le symbole [cite: 1277]
    constructor(address initialOwner) ERC20("SupDeVinci_USD", "SUSD") Ownable(initialOwner) {
        // 1. Définir la Supply Totale à 1 million (1,000,000)
        // Note: On multiplie par 10^decimals() pour avoir la valeur correcte en wei/unités
        uint256 totalToMint = 1000000 * (10 ** decimals());

        // On mint la totalité à l'owner (deployer) pour commencer
        _mint(msg.sender, totalToMint);
    }

    // 2. Surcharge pour mettre 6 décimales
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    // Fonction utilitaire pour mint des tokens supplémentaires si besoin (réservé à l'owner)
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
