# PokeMap — Suivi rapide des mécaniques Pokémon, cible Génération V

## 1. Rôle de ce document

Ce fichier est un **tableau de bord produit**, pas un plan d'implémentation.

Il sert à répondre rapidement à trois questions :

1. qu'est-ce qui fonctionne déjà au moins partiellement ?
2. qu'est-ce qui manque encore pour obtenir un fangame jouable de type Génération V ?
3. qu'est-ce qui a volontairement été repoussé ou exclu ?

Il ne contient volontairement ni lots, ni estimations, ni détails de code.

**Dernière mise à jour :** 2 août 2026  
**Périmètre :** moteur PokeMap générique, sans dépendance à un fangame particulier  
**Objectif actuel :** aventure Pokémon classique et structurée, inspirée de la
Génération V, avec un moteur de combat et un catalogue couvrant les Générations I à IX

Pour les preuves et l'analyse détaillée, consulter :

- [l'audit exhaustif des mécaniques](../reports/gameplay/audit_exhaustif_mecaniques_pokemon_pokemap_2026-08-02.md) ;
- [la roadmap mécanique technique](../../pokemap_roadmap_mecaniques_fangame.md) ;
- [la roadmap runtime, médias, audio et temps](road_map_runtime_media_cinematics_audio_time.md).

---

## 2. Légende

| Statut | Signification |
|---|---|
| `✅ PRÊT` | Fonctionnel et suffisamment prouvé pour la cible actuelle |
| `🟡 PARTIEL` | Une base existe, mais la boucle est incomplète ou insuffisamment fidèle |
| `🟠 À REVALIDER` | Une implémentation existe, mais la preuve runtime actuelle est bloquée ou périmée |
| `⬜ À FAIRE` | Élément nécessaire qui manque encore réellement |
| `⏳ PLUS TARD` | Intéressant après la stabilisation du cœur Génération V singles |
| `⏸ MIS DE CÔTÉ` | Volontairement absent de la roadmap active |
| `🚫 EXCLU` | Ne correspond pas à la direction du produit |

Un statut `✅ PRÊT` ne doit être utilisé que si la mécanique est :

- configurable sans modifier manuellement du JSON ;
- jouable dans la runtime ;
- correctement sauvegardée si elle modifie la partie ;
- couverte par des vérifications fraîches ;
- présente dans le jeu exporté lorsque cela s'applique.

---

## 3. Cible produit actuelle

La structure de la première aventure n'est pas « toutes les générations ». Elle reste
volontairement classique et mesurable. Le moteur de combat et le catalogue constituent
cependant une exception : ils doivent être aussi complets et extensibles que possible.

- une aventure linéaire ou semi-linéaire avec routes, villes et donjons ;
- des rencontres sauvages aléatoires et des rencontres statiques scénarisées ;
- une première interface joueur centrée sur les combats **simples** au tour par tour ;
- toutes les espèces de Pokémon des Générations I à IX, utilisables en combat ;
- les formes standards, types, statistiques, moves, talents et objets de combat
  nécessaires à ces Pokémon jusqu'à la Génération IX ;
- un moteur de combat data-driven qui ne soit pas artificiellement limité à la
  Génération V ;
- le split physique/spécial par attaque ;
- des TM réutilisables comme en Génération V, sans crafting ;
- une équipe de six Pokémon, un sac, des boîtes PC et un Pokédex ;
- des dresseurs, badges, Arènes, Ligue, argent et progression narrative ;
- des capacités de terrain classiques, ou une abstraction équivalente liée à l'équipe ;
- une sauvegarde manuelle ;
- une création entièrement no-code dans PokeMap ;
- un test rapide dans la runtime puis un export jouable.

Le moteur doit gérer les **18 types standards**, Fairy compris. Stellar et les formes
qui dépendent exclusivement de la Téracristallisation restent au parking avec cette
mécanique.

Cette cible distingue deux notions :

- **disponible en combat** : Pokémon, forme standard, move, talent ou objet utilisable
  par le moteur ;
- **obtenable par sa méthode canonique** : rencontre, évolution, échange ou autre
  système permettant de l'obtenir dans l'aventure.

Tous les Pokémon I–IX doivent être disponibles en combat. Reproduire immédiatement
toutes leurs méthodes d'obtention postérieures à la Génération V n'est pas un prérequis
pour la première aventure jouable.

---

## 4. Vue d'ensemble

| Domaine | État actuel | Lecture rapide |
|---|---|---|
| Runtime et playtest | `🟠 À REVALIDER` | La runtime est riche, mais sa compilation et ses parcours joueur doivent être recertifiés |
| Nouvelle partie et sauvegarde | `🟡 PARTIEL` | Plusieurs contrats existent ; le parcours complet New Game → starter → sauvegarde → reprise reste à prouver |
| Exploration | `🟡 PARTIEL` | Cartes, collisions, interactions, warps et PNJ existent ; certaines actions de terrain restent incomplètes |
| Événements et narration | `🟡 PARTIEL` | Dialogues, choix, faits et conditions existent ; il manque encore des commandes générales et des parcours entièrement prouvés |
| Données Pokémon I–IX | `🟡 PARTIEL` | Espèces, formes, moves, talents et objets sont largement modélisés, mais couverture et contrats restent à certifier |
| Rencontres et capture | `🟡 PARTIEL` | Les fondations sont présentes ; les règles Génération V et la boucle runtime complète doivent être fermées |
| Moteur de combat I–IX | `🟡 PARTIEL` | Le moteur est avancé ; couverture des contenus, effets et règles doit être certifiée sans réactiver les gimmicks garées |
| Progression Pokémon | `🟡 PARTIEL` | XP, niveaux, apprentissage et évolution existent partiellement ; plusieurs règles I–V manquent |
| Équipe, PC, sac et Pokédex | `🟡 PARTIEL` | Les surfaces principales existent, mais leurs opérations et leur identité persistante sont incomplètes |
| Monde, services et progression | `🟡 PARTIEL` | Centres, boutiques, argent, badges et monde vivant existent à des niveaux variables |
| Authoring no-code | `🟡 PARTIEL` | Beaucoup de données sont éditables ; les parcours guidés et la parité des transports restent incomplets |
| Export et partie de référence | `🟠 À REVALIDER` | La chaîne existe, mais aucun parcours Génération V complet n'est actuellement certifié de bout en bout |

**État global : `🟡 EN CONSTRUCTION`.** PokeMap possède une base importante, mais ne
peut pas encore être présenté comme un moteur de fangame classique avec combat I–IX
complet et certifié.

---

## 5. Chemin critique vers un fangame Génération V jouable

Ces objectifs sont rangés dans l'ordre le plus utile. Ils ne représentent pas des lots.

| Ordre | Objectif observable | Statut |
|---:|---|---|
| 1 | Séparer et versionner le profil d'aventure classique et le moteur de combat I–IX | `⬜ À FAIRE` |
| 2 | Rétablir une runtime compilable et recertifier les parcours joueur existants | `🟠 À REVALIDER` |
| 3 | Jouer New Game → choix du starter → arrivée sur la première carte | `🟡 PARTIEL` |
| 4 | Sauvegarder manuellement, quitter et reprendre exactement le même état | `🟡 PARTIEL` |
| 5 | Stabiliser l'identité persistante de chaque Pokémon et les catalogues partagés | `🟡 PARTIEL` |
| 6 | Explorer, dialoguer, déclencher des événements et progresser sans commande de développement | `🟡 PARTIEL` |
| 7 | Déclencher une rencontre sauvage, générer le Pokémon et terminer la capture | `🟡 PARTIEL` |
| 8 | Certifier le moteur de combat singles et les contenus nécessaires aux Pokémon I–IX | `🟡 PARTIEL` |
| 9 | Fermer XP, EV, niveaux, apprentissage, amitié, obéissance et évolutions I–V | `🟡 PARTIEL` |
| 10 | Finaliser les boucles équipe, sac, objets tenus, PC et Pokédex | `🟡 PARTIEL` |
| 11 | Finaliser dresseurs, récompenses, badges, Arènes, Ligue et défaite | `🟡 PARTIEL` |
| 12 | Finaliser les capacités de terrain nécessaires à l'aventure classique | `🟡 PARTIEL` |
| 13 | Rendre toutes ces mécaniques authorables et validables sans code | `🟡 PARTIEL` |
| 14 | Tester la carte courante directement depuis PokeMap | `⬜ À FAIRE` |
| 15 | Certifier une petite aventure complète puis son export jouable | `🟠 À REVALIDER` |

---

## 6. Suivi détaillé

### 6.1 Démarrage, joueur et sauvegarde

| Mécanique | Statut | Ce qu'il reste principalement à obtenir |
|---|---|---|
| Écran titre, New Game et Continue | `🟡 PARTIEL` | Prouver le parcours joueur complet |
| Choix du nom et identité du joueur | `🟡 PARTIEL` | Unifier les données et leur persistance |
| Choix du starter | `🟡 PARTIEL` | Parcours runtime et destination party/PC sans perte |
| Sauvegarde manuelle | `🟡 PARTIEL` | Recertifier les transactions et tous les états importants |
| Chargement et reprise | `🟡 PARTIEL` | Prouver une reprise fidèle depuis le produit exporté |
| Menu pause | `🟡 PARTIEL` | Relier proprement toutes les surfaces joueur |
| Options de jeu essentielles | `🟡 PARTIEL` | Texte, vitesse, audio et contrôles à harmoniser |

### 6.2 Exploration, événements et narration

| Mécanique | Statut | Ce qu'il reste principalement à obtenir |
|---|---|---|
| Cartes, collisions et déplacement | `🟡 PARTIEL` | Recertifier la runtime et les cas limites |
| Warps et changements de carte | `🟡 PARTIEL` | Prouver les transitions, retours et sauvegardes |
| PNJ et interactions | `🟡 PARTIEL` | Compléter les comportements et parcours no-code |
| Dialogues et choix | `🟡 PARTIEL` | Généraliser les conséquences et leur reprise après sauvegarde |
| Flags, variables et conditions | `🟡 PARTIEL` | Ajouter les opérations générales manquantes et les validations |
| Objets au sol et objets cachés | `🟡 PARTIEL` | Garantir ramassage unique, feedback et persistance |
| Scènes et contrôle du joueur | `🟡 PARTIEL` | Compléter les commandes de mise en scène réutilisables |
| Obstacles et dangers de carte | `🟡 PARTIEL` | Relier dommages, recul, respawn et événements |
| Course | `⬜ À FAIRE` | Définir comportement, animation et authoring |
| Vélo ou déplacement rapide classique | `⬜ À FAIRE` | Définir le besoin exact sans basculer vers un système Ride |

### 6.3 Pokémon, équipe, PC et Pokédex

| Mécanique | Statut | Ce qu'il reste principalement à obtenir |
|---|---|---|
| Catalogue des espèces et formes I–IX | `🟡 PARTIEL` | Unifier propriétaire, validation et contenu réellement distribué |
| Catalogue des moves I–IX | `🟡 PARTIEL` | Fermer effets, learnsets et parité du contenu |
| Catalogue des talents I–IX | `🟡 PARTIEL` | Fermer triggers, ordre et authoring |
| Catalogue des objets de combat I–IX | `🟡 PARTIEL` | Unifier métadonnées, effets et distribution |
| Identité individuelle d'un Pokémon | `🟡 PARTIEL` | ID stable, forme, OT, IDs, langue, provenance et migration |
| Nature, IV et EV | `🟡 PARTIEL` | Fermer calculs, gains, caps et présentation joueur |
| Shiny | `🟡 PARTIEL` | Identité, génération, locks, rendu et persistance |
| Équipe de six | `🟡 PARTIEL` | Finaliser toutes les opérations et cas limites |
| Résumé d'un Pokémon | `🟡 PARTIEL` | Présenter toutes les données utiles de manière cohérente |
| Boîtes PC | `🟡 PARTIEL` | Release, organisation, recherche, œufs et objets tenus |
| Pokédex vu/capturé | `🟡 PARTIEL` | Espèces et formes standards I–IX, Dex régional/national, recherche et complétion |

### 6.4 Rencontres et capture

| Mécanique | Statut | Ce qu'il reste principalement à obtenir |
|---|---|---|
| Rencontres en marchant | `🟠 À REVALIDER` | Reprouver l'intégration runtime |
| Rencontres en surfant | `🟠 À REVALIDER` | Reprouver conditions, tables et intégration runtime |
| Pêche | `🟡 PARTIEL` | Boucle joueur, cannes, tables et feedback |
| Headbutt et autres rencontres I–V | `🟡 PARTIEL` | Conditions, runtime et authoring |
| Rencontres statiques | `🟡 PARTIEL` | Garantir état vaincu/capturé et idempotence |
| Cadeaux et fossiles | `🟡 PARTIEL` | Politique party/PC, provenance et cas de stockage plein |
| Roamers et swarms | `🟡 PARTIEL` | État mondial, temps et persistance |
| Repel | `🟡 PARTIEL` | Règles Génération V et choix du Pokémon de référence |
| Génération du Pokémon sauvage | `🟡 PARTIEL` | Nature, IV, talent, sexe, shiny, objet tenu et forme |
| Formule de capture | `🟡 PARTIEL` | Parité Génération V, shakes et effets des Balls |
| Balls spécialisées I–V | `🟡 PARTIEL` | Couvrir les conditions et multiplicateurs manquants |
| Capture critique | `⬜ À FAIRE` | Implémenter la règle introduite en Génération V |
| Destination équipe puis boîte | `🟡 PARTIEL` | Recertifier l'atomicité, le stockage plein et le Pokédex |

### 6.5 Combat singles

| Mécanique | Statut | Ce qu'il reste principalement à obtenir |
|---|---|---|
| Boucle de combat simple | `🟡 PARTIEL` | Certifier tous les chemins joueur et IA |
| Profil des 18 types standards | `🟡 PARTIEL` | Inclure Fairy et garantir une table cohérente dans toutes les surfaces |
| Dégâts et arrondis versionnés | `🟡 PARTIEL` | Définir la cible moderne du moteur et prouver les cas limites |
| Ordre des tours et égalités de Vitesse | `🟡 PARTIEL` | RNG seedée, règles explicites et tests reproductibles |
| Catégories physique/spécial/statut | `🟡 PARTIEL` | Fermer les exceptions de moves |
| Statuts majeurs et volatiles | `🟡 PARTIEL` | Fermer durée, immunités, ordre et persistance |
| Changements de statistiques | `🟡 PARTIEL` | Fermer caps, reset et effets secondaires |
| Talents I–IX | `🟡 PARTIEL` | Fermer ordre des triggers et couverture du catalogue |
| Objets tenus et baies I–IX | `🟡 PARTIEL` | Effets, équipement, consommation et write-back |
| Météo, terrains et hazards I–IX | `🟡 PARTIEL` | Fermer ordre, durée et interactions |
| Switch, K.O. et remplacement | `🟡 PARTIEL` | Fermer tous les enchaînements et fins de tour |
| Objets utilisés en combat | `🟡 PARTIEL` | Unifier effets, validation et consommation |
| Fuite | `🟡 PARTIEL` | Fermer formule, interdictions et feedback |
| Combat de dresseur | `🟡 PARTIEL` | Défaite persistante, récompenses et rematch |
| Intelligence artificielle | `🟡 PARTIEL` | Profils simples, avancés et boss scénarisés |
| Interface de combat joueur | `🟠 À REVALIDER` | Recompiler et rejouer tous les parcours |
| Récompenses et retour au monde | `🟡 PARTIEL` | XP, argent, évolutions et sauvegarde sans duplication |

### 6.6 Progression Pokémon et progression du joueur

| Mécanique | Statut | Ce qu'il reste principalement à obtenir |
|---|---|---|
| XP et montée de niveau | `🟡 PARTIEL` | Formule, participants, bonus et profils Génération V |
| Gains d'EV | `🟡 PARTIEL` | Yields, caps et répartition |
| Apprentissage avec quatre moves | `🟡 PARTIEL` | Tous les choix, refus et reprises après combat |
| Move Reminder, Deleter et Tutors | `🟡 PARTIEL` | Services, coûts et authoring |
| TM réutilisables Génération V | `🟡 PARTIEL` | Catalogue, compatibilité et expérience joueur |
| HM et capacités de terrain | `🟡 PARTIEL` | Relier progression, équipe, monde et oubli des moves |
| Évolutions I–V | `🟡 PARTIEL` | Échange, temps, lieu, genre, objet tenu, équipe, stats et cas spéciaux |
| Annulation et reprise d'évolution | `🟡 PARTIEL` | Comportement fiable dans tous les contextes |
| Amitié | `🟡 PARTIEL` | Gains, pertes, seuils, moves et évolutions |
| Obéissance | `⬜ À FAIRE` | OT, outsider, badges, seuils et actions de désobéissance |
| Argent | `🟡 PARTIEL` | Gains, pertes, achats, ventes et caps |
| Badges | `🟡 PARTIEL` | Attribution, effets, présentation et persistance |
| Arènes et Ligue | `🟡 PARTIEL` | Modèles réutilisables, progression et Hall of Fame |
| Défaite et retour au Centre | `🟡 PARTIEL` | Politique fiable et personnalisable |

### 6.7 Sac, objets et services

| Mécanique | Statut | Ce qu'il reste principalement à obtenir |
|---|---|---|
| Sac et poches | `🟡 PARTIEL` | Tri, limite, objet favori, jeter et descriptions |
| Soins HP, statut et PP | `🟡 PARTIEL` | Unifier les effets terrain/combat |
| Revive | `🟡 PARTIEL` | Tous les contextes, validations et feedback |
| Objets de statistiques et vitamines | `🟡 PARTIEL` | Effets, caps et authoring |
| Objets clés | `🟡 PARTIEL` | Unicité, usage scénarisé et persistance |
| Boutiques | `🟠 À REVALIDER` | Reprouver achat, vente, stock et argent dans la runtime |
| Centres Pokémon | `🟡 PARTIEL` | Boucle joueur, soin, checkpoint et reprise |
| Services spécialisés | `🟡 PARTIEL` | Name Rater, Move services, fossiles et autres services I–V |
| Plusieurs devises | `⬜ À FAIRE` | BP, coins et règles propres aux services concernés |

### 6.8 Monde et capacités de terrain

| Mécanique | Statut | Ce qu'il reste principalement à obtenir |
|---|---|---|
| Surf | `🟡 PARTIEL` | Recertifier la boucle complète et son authoring |
| Cut | `⬜ À FAIRE` | Obstacle, animation, progression et persistance |
| Strength | `⬜ À FAIRE` | Déplacement de rochers et état de puzzle |
| Rock Smash | `⬜ À FAIRE` | Obstacle, rencontre éventuelle et persistance |
| Flash | `⬜ À FAIRE` | Éclairage de zone et état de progression |
| Waterfall | `⬜ À FAIRE` | Déplacement, contraintes et transitions |
| Fly | `⬜ À FAIRE` | Carte des destinations, déblocage et voyage |
| Temps de jeu et horloge mondiale | `🟡 PARTIEL` | Définir la source du temps et la persistance |
| Cycle jour-nuit | `🟡 PARTIEL` | Relier visuel, rencontres, événements et audio |
| Météo du monde | `🟡 PARTIEL` | Relier carte, combat, rencontres et scènes |
| Jours de la semaine et calendrier | `⏳ PLUS TARD` | À traiter après le cycle fondamental |
| Baies, respawns et événements quotidiens | `⏳ PLUS TARD` | Dépend du temps mondial fiable |

### 6.9 Éditeur, validation, runtime et distribution

| Mécanique | Statut | Ce qu'il reste principalement à obtenir |
|---|---|---|
| Authoring no-code des mécaniques | `🟡 PARTIEL` | Pickers, libellés, previews et diagnostics partout |
| Validation avant playtest | `🟡 PARTIEL` | Détecter les références, états et boucles impossibles |
| Parité API, JSONL, éditeur et MCP | `🟡 PARTIEL` | Exposer chaque sémantique, pas uniquement la sauvegarde JSON |
| Playtest d'une carte dans PokeMap | `⬜ À FAIRE` | Lancer et arrêter rapidement une carte courante |
| Playtest du jeu complet dans PokeMap | `⬜ À FAIRE` | Démarrer depuis New Game avec la vraie sauvegarde |
| Runtime compilable et stable | `🟠 À REVALIDER` | Résoudre puis recertifier les blocages actuels |
| Export autonome | `🟠 À REVALIDER` | Prouver assets, données et parcours complet |
| Petite aventure de référence | `🟠 À REVALIDER` | Certifier le parcours de bout en bout avec preuves fraîches |

---

## 7. Après le cœur Génération V singles

Ces éléments restent compatibles avec la direction générale, mais ne doivent pas
retarder la première aventure complète et stable.

| Mécanique | Décision actuelle |
|---|---|
| Combats doubles | `⏳ PLUS TARD` — seulement après certification des singles |
| Combats Triple et Rotation | `⏳ PLUS TARD` — non nécessaires à la première cible |
| Échanges en jeu avec des PNJ | `⏳ PLUS TARD` |
| Échange entre joueurs | `⏳ PLUS TARD` — commencer éventuellement en local avant l'online |
| Battle Subway et autres facilities | `⏳ PLUS TARD` |
| Concours et contenus secondaires I–V | `⏳ PLUS TARD` |
| Rubans I–V | `⏳ PLUS TARD` |
| Roamers et systèmes mondiaux avancés | `⏳ PLUS TARD` si non indispensables au jeu de référence |

---

## 8. Parking explicite

Les éléments suivants ne participent pas à l'évaluation de la cible actuelle.
Leur absence ne doit donc pas être comptée comme un retard.

| Mécanique | Statut | Explication courte |
|---|---|---|
| Reproduction, Pension, œufs et hérédité | `⏸ MIS DE CÔTÉ` | Système très transversal ; aucune obligation pour la première cible |
| Saisons | `⏸ MIS DE CÔTÉ` | Variation saisonnière du monde introduite en Génération V |
| Dive | `⏸ MIS DE CÔTÉ` | Exploration sous-marine et transitions entre cartes dédiées |
| Mega Evolution | `⏸ MIS DE CÔTÉ` | Gimmick de Génération VI |
| Z-Moves | `⏸ MIS DE CÔTÉ` | Gimmick de Génération VII |
| SOS | `⏸ MIS DE CÔTÉ` | Renforts sauvages de Génération VII |
| Ride remplaçant les HM | `⏸ MIS DE CÔTÉ` | Les capacités de terrain classiques restent la direction actuelle |
| Dynamax et Gigamax | `⏸ MIS DE CÔTÉ` | Gimmicks de Génération VIII |
| Raids | `⏸ MIS DE CÔTÉ` | Combats de boss coopératifs modernes |
| Spawns visibles | `⏸ MIS DE CÔTÉ` | Pokémon sauvages visibles et mobiles sur la carte avant le combat |
| Autosave | `⏸ MIS DE CÔTÉ` | La cible actuelle utilise la sauvegarde manuelle |
| Mints | `⏸ MIS DE CÔTÉ` | Objets modifiant l'effet statistique d'une nature |
| Téracristallisation | `⏸ MIS DE CÔTÉ` | Gimmick de Génération IX |
| Open world | `⏸ MIS DE CÔTÉ` | La cible reste une aventure structurée |
| Auto-battle | `⏸ MIS DE CÔTÉ` | Combat automatique dans l'overworld |
| Pique-nique | `⏸ MIS DE CÔTÉ` | Système moderne d'interactions, repas et œufs |
| Crafting de TM | `⏸ MIS DE CÔTÉ` | Les TM Génération V sont réutilisables sans fabrication |
| Online et coopération | `⏸ MIS DE CÔTÉ` | Hors du besoin de la première aventure locale |
| Gameplay de type `Pokémon Legends` | `🚫 EXCLU` | Pas de furtivité, capture en temps réel, dégâts au joueur ou action speed |

Le parking peut être réévalué plus tard, mais ne doit pas produire de travail actif
tant que la cible Génération V singles n'est pas stable.

---

## 9. Comment tenir ce fichier à jour

Après chaque évolution importante :

1. modifier uniquement les lignes réellement concernées ;
2. conserver `🟡 PARTIEL` si une seule surface fonctionne mais pas toute la boucle ;
3. utiliser `🟠 À REVALIDER` si le code existe sans preuve fraîche ;
4. passer à `✅ PRÊT` seulement avec authoring, runtime, sauvegarde et vérifications ;
5. ne pas transformer un élément du parking en objectif actif sans décision explicite ;
6. reporter les preuves détaillées dans l'audit ou les rapports techniques, pas ici.

La question de pilotage à se poser reste simple :

> Peut-on créer cette mécanique sans code, la jouer dans la runtime, sauvegarder son
> résultat et la retrouver intacte dans un export ?

Si la réponse n'est pas entièrement oui, la mécanique n'est pas encore `✅ PRÊT`.
