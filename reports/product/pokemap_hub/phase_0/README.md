# PokeMap Hub — Phase 0 Decision Pack

Statut : **Accepted**

Date de ratification : **2026-07-25**

Source de vérité : [`../../pokemap_hub_player_application_audit_2026-07-24.md`](../../pokemap_hub_player_application_audit_2026-07-24.md)

## Objet

Ce dossier ferme la Phase 0 du produit **PokeMap Hub**. Il fixe les contrats
nécessaires avant toute implémentation du package de distribution, des
sauvegardes multijeux, de l’installateur, du shell joueur ou du Hub visuel.

Le produit cible est générique. Il n’est ni une nouvelle version de Selbrume,
ni une promotion de `examples/playable_runtime_host` en application publique.

## Décisions structurantes

- `apps/pokemap_hub` sera la racine de composition du produit joueur.
- `examples/playable_runtime_host` reste un harness interne de développement.
- `packages/map_distribution` sera un package Dart pur.
- `packages/map_player_ui` sera un package Flutter sans dépendance vers
  `map_editor`.
- `map_runtime` ne dépendra jamais de `map_player_ui` ni de
  `map_distribution`.
- `.pokemapgame` v1 est une archive ZIP déterministe, data-only et inventoriée.
- `gameId` est stable, immuable et indépendant du titre ou du dossier.
- les sauvegardes sont isolées par jeu, profil et slot, avec écriture atomique.
- mobile/V0 utilise une session jetable dans le même processus ; le desktop
  public lance un processus enfant du même binaire via `--player-session`.
- le parcours normatif est Hub → détail → titre → session → fin → crédits →
  titre ou Hub.

## Lots Phase 0

| Lot | Objectif | Artefacts normatifs | Validation documentaire | DONE |
|---|---|---|---|---|
| HUB-000 | Frontières, ownership et isolation | ADR, graphe de dépendances, port de session | aucune dépendance inversée ou responsabilité orpheline | ADR Accepted et protocole sans ambiguïté |
| HUB-001 | Format `.pokemapgame` v1 | spécification, schéma, exemples, vecteurs | parsing JSON, cohérence inventaire et hashes reproductibles | format et identité entièrement définis |
| HUB-002 | Sécurité et confiance | threat model, quotas, corpus hostile | chaque menace a une règle et un résultat attendu | aucune extraction avant validation structurelle |
| HUB-003 | Compatibilité et saves | politique, matrice, enveloppe et lifecycle | accept/reject/migrate/warn, checksum et recovery | update, downgrade, migration et isolation définis |
| HUB-004 | Parcours joueur | IA, états, actions, journeys, fin de jeu | happy paths, erreurs et recovery couverts | aucun état terminal ou action ambiguë |
| HUB-005 | Sessions et lifecycle | ADR isolation, port, matrice d’échec | crash, timeout, teardown et reprise couverts | stratégie explicite par plateforme |

Chaque lot documente son objectif, son périmètre, les futurs fichiers de code,
les tests à créer, ses critères de DONE, ses risques et ses dépendances. Les
artefacts JSON présents ici deviennent les fixtures contractuelles de départ
des phases suivantes.

## Ordre d’implémentation autorisé

1. Phase 1 : `map_distribution`, schémas, canonicalisation et validateur.
2. Phase 2 : `GameIdentity`, `SaveEnvelope`, repository atomique et lifecycle.
3. Phase 3 : installation, bibliothèque, update, rollback, repair, uninstall.
4. Phase 4 : shell joueur, session, titre et `GameCompleted`.
5. Phases 5+ : Hub visuel et UI joueur, puis combat/dialogue et certification.

L’accueil peut être maquetté, mais aucun écran isolé ne doit précéder les
contrats dont il dépend.

## Non-objectifs

- réécrire `map_battle` ;
- distribuer du Dart, des scripts, des plugins ou des binaires dans un jeu ;
- exposer les seeds, FPS, collisions ou outils d’évaluation dans le Hub ;
- définir la place de marché publique ou la rotation complète des clés ;
- garantir que le dépôt entier est vert sans nouvelle exécution globale.

## Gate de sortie

La Phase 0 est fermée seulement si :

1. les décisions `P0-D01` à `P0-D15` sont `Accepted` ;
2. tous les fichiers listés dans [`phase-0-exit-gate.md`](phase-0-exit-gate.md)
   existent et se valident ;
3. les exemples valides passent les schémas et chaque fixture invalide échoue ;
4. les hashes canoniques sont recalculables ;
5. aucune modification de code produit n’a été introduite ;
6. les risques résiduels et les tests futurs sont explicites.

## Dépendances et risques

La Phase 0 dépend des contrats actuels de `map_core` et des snapshots publics
de `map_runtime`, sans leur imposer encore de changement. Les risques majeurs
sont la divergence entre JSON Schema et codec Dart, les limites de ZIP selon
les plateformes, les faux positifs du secret scanning, et les crashs natifs en
session même processus. Ils sont couverts par les lots et gates correspondants.
