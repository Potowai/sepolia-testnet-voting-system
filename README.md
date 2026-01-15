# Projet Evaluation Blockchain - Système de Vote

Ce projet implémente un système de vote simple mais sécurisé sur Ethereum, utilisant des rôles, un workflow strict et des NFT pour valider le vote.

## Fonctionnalités
- **Rôles** : Admin, Founder, Withdrawer.
- **Workflow** : REGISTER -> FOUND -> VOTE -> COMPLETED.
- **NFT** : Un NFT est minté pour chaque votant pour empêcher le double vote.
- **Délai** : Le vote ne peut commencer qu'une heure après l'ouverture de la session.

## Déploiement (Sepolia)
Déployé via Foundry sur le testnet Sepolia.

- **Contrat VotingNFT** : `0x00A9CB62F1a1332d15dcB02B77Fa008444F3bEb5`
- **Contrat VotingSystem** : `0xddb46ef53eEB95b755CC1F43558e78AeC308C117`

### Transactions
Voici les hash de transactions sur Sepolia :

- **Déploiement (NFT)** : [`0x14ad407345d6dc04d3c3c9d77f4b7676970ad2760c348914afa7309b3c31ab6b`](https://sepolia.etherscan.io/tx/0x14ad407345d6dc04d3c3c9d77f4b7676970ad2760c348914afa7309b3c31ab6b)
- **Déploiement (Système)** : [`0xd25ac5574b81d2ef08a67e1ebc06829b68da579f3165f944936aa699868d25b5`](https://sepolia.etherscan.io/tx/0xd25ac5574b81d2ef08a67e1ebc06829b68da579f3165f944936aa699868d25b5)
- **Configuration (Transfert Ownership)** : [`0x9ccd1effff4ecbbbb072442bb8b0a6c117f414b03ac9d5975341e7b917159a78`](https://sepolia.etherscan.io/tx/0x9ccd1effff4ecbbbb072442bb8b0a6c117f414b03ac9d5975341e7b917159a78)

### Tests
Pour lancer les tests unitaires :
```bash
forge test
```
