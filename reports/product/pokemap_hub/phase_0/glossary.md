# Glossaire normatif

Les verbes **DOIT**, **NE DOIT PAS**, **DEVRAIT** et **PEUT** ont leur sens
normatif habituel.

| Terme | Définition |
|---|---|
| Hub | Application publique `apps/pokemap_hub`, propriétaire de la bibliothèque, des installations, des saves, des préférences et du lifecycle. |
| Host | `examples/playable_runtime_host`, harness interne pour workspace, maps, seeds, debug, FPS et évaluations. Il n’est pas un produit distribué. |
| Player session | Exécution isolée d’une version installée d’un jeu pour un profil/slot donnés. |
| Shell joueur | Titre, pause, équipe, sac, Pokédex, carte, options, crédits et surfaces accessibles autour du runtime. |
| `gameId` | Identité logique stable et immuable du jeu, choisie par l’auteur, indépendante de son titre, chemin et numéro de version. |
| `packageFormat` | Version entière de la structure `.pokemapgame`; une valeur future inconnue est rejetée. |
| `gameVersion` | Version SemVer publiée du contenu d’un `gameId`. |
| `runtimeApi` | Contrat SemVer des capacités et événements attendus du runtime. |
| `projectFormat` | Token sérialisé du projet PokeMap (`v1`, `v2`), identique à `ProjectVersion`. |
| `schemaVersion` | Version entière de la structure de `SaveEnvelope`. |
| `saveFormat` | Version entière de l’état métier transporté dans l’enveloppe. |
| `compatibilityId` | Identifiant déclaré par le jeu pour la famille d’états métier qu’il sait relire. Il ne remplace aucune version. |
| Capability | Fonction nommée et versionnée que le package exige du Hub/runtime. Toute capability requise inconnue est bloquante. |
| Profil | Identité locale d’un joueur à l’intérieur d’un `gameId`. |
| Slot | Emplacement de partie nommé dans un profil. |
| Save | Snapshot métier enveloppé, vérifié et atomiquement stocké pour un triplet game/profile/slot. |
| Save complétée | Save valide marquée `completed`, conservée et chargeable selon la politique du jeu. |
| Install receipt | Preuve locale immuable de l’installation : manifest/tree hash, version, dates, policy et résultat de validation. |
| Staging | Racine temporaire dédiée où l’intégralité du package est validée avant exposition à la bibliothèque. |
| Promotion atomique | Publication d’un staging validé vers une version finale sans modifier la version courante tant que l’opération n’a pas réussi. |
| Version courante | Version pointée par `current.json`; les autres versions installées restent côte à côte. |
| Repair | Revalidation d’une version installée contre son receipt et restauration depuis le package/cache, sans toucher aux saves. |
| Rollback | Changement atomique de `current.json` vers une version déjà validée et compatible. |
| Uninstall | Suppression des versions et receipts ciblés ; les saves sont préservées par défaut. |
| Smoke de chargement | Ouverture bornée du projet, de ses index et de sa map de démarrage sans démarrer une partie persistante. |
| Crash marker | Enregistrement créé avant lancement et supprimé après teardown propre ; sa présence au redémarrage signale une session interrompue. |
| Session jetable | Graphe runtime entièrement créé pour une session et entièrement déchargé avant toute autre session. |
| Runtime projection | Copie nettoyée et minimale du workspace auteur destinée à la distribution ; elle exclut secrets, caches, saves et données éditeur. |
| Data-only | Contenu interprété comme données par des codecs/capacités connus, jamais exécuté comme code arbitraire. |
| Tree hash | SHA-256 canonique de l’inventaire complet du payload, indépendant de l’ordre et des métadonnées du ZIP. |
