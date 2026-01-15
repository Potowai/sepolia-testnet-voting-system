// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VotingNFT is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor() ERC721("VotingBadge", "VOTE") Ownable(msg.sender) {}

    // Fonction pour mint un NFT (seul le proprietaire peut l'appeler)
    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
}
