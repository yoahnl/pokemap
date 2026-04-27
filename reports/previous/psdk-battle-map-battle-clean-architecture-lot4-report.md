# PSDK Battle Migration - Lot 4 Map Battle Clean Architecture Skeleton

## Nom exact du lot

Lot 4 - Squelette clean architecture de `map_battle`.

## Résumé exécutif

Le lot 4 pose une nouvelle entrée publique `BattleEngine` pour la migration
Pokemon SDK, sans supprimer ni remplacer le moteur legacy `BattleSession`.

Le moteur clean utilise une couche applicative interne mutable, un état public
immutabilisé, une décision dédiée `BattleDecision`, une timeline ordonnée, et
un adaptateur de coexistence pour l'ancienne façade PSDK `PsdkBattleEngine`.

## Scope confirmé

Inclus :

- création des couches `application`, `domain/battle`, `domain/decision` et
  `domain/timeline` dans `packages/map_battle`;
- exposition publique bornée depuis `map_battle.dart`;
- délégation de `PsdkBattleEngine` vers le nouveau `BattleEngine`;
- tests TDD couvrant le comportement positif, les cas négatifs, l'atomicité et
  la non-régression legacy.

Hors scope :

- aucun branchement runtime;
- aucune suppression de `BattleSession`;
- aucun port complet des handlers/effects PSDK;
- aucune topologie multi-bank/multi-slot au-delà du singles PSDK déjà présent;
- aucune migration des animations.

## Audit initial

Fichiers et contrats existants inspectés :

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_decision.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/psdk/**`
- `packages/map_battle/test/psdk_engine_smoke_test.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`

Constats :

- `BattleSetup`, `BattleTurnResult`, `BattleOutcome` et
  `BattleDecisionRequest` sont déjà des contrats publics legacy.
- La lane PSDK existante expose déjà `PsdkBattleEngine`, `PsdkBattleSetup`,
  `PsdkBattleState`, `PsdkBattleTimeline` et les DTOs de moves.
- Le runtime n'est pas encore branché sur la lane PSDK; le lot doit donc être
  additif.
- `BattleContext` doit rester interne, car mutable.

Décision d'architecture :

- ne pas créer un second `BattleSetup` public;
- créer `BattleEngineSetup`, `BattleEngineTurnResult`,
  `BattleEngineOutcome` et `BattleEngineDecisionRequest`;
- garder les anciens types publics intacts;
- exporter les nouveaux types via `show` pour ne pas publier le contexte mutable.

## État git initial

Le repo était déjà dirty à cause des lots précédents et d'un fichier IDE non
lié :

- `.idea/libraries/Dart_Packages.xml` modifié avant ce lot;
- changements Lot 1 dans `packages/map_core`;
- changements Lots 2 et 3 dans `packages/map_editor`;
- fondation PSDK précédente sous `packages/map_battle/lib/src/psdk`,
  `packages/map_battle/bin` et tests associés;
- rapports précédents non suivis.

## Fichiers créés

- `packages/map_battle/lib/src/application/battle_engine.dart`
- `packages/map_battle/lib/src/application/battle_turn_runner.dart`
- `packages/map_battle/lib/src/application/battle_session_facade.dart`
- `packages/map_battle/lib/src/domain/battle/battle_context.dart`
- `packages/map_battle/lib/src/domain/battle/battle_setup.dart`
- `packages/map_battle/lib/src/domain/battle/battle_outcome.dart`
- `packages/map_battle/lib/src/domain/decision/battle_decision.dart`
- `packages/map_battle/lib/src/domain/timeline/battle_timeline.dart`
- `packages/map_battle/test/battle_engine_clean_architecture_test.dart`

## Fichiers modifiés

### `packages/map_battle/lib/map_battle.dart`

Zones modifiées :

- ajout d'exports publics bornés pour la nouvelle architecture.

Raison :

- rendre `BattleEngine` consommable depuis le package sans exposer
  accidentellement les détails mutables.

Impact :

- nouveaux types publics accessibles : `BattleEngine`, `BattleEngineSetup`,
  `BattleDecision`, `BattleEngineDecisionRequest`, `BattleEngineTurnResult`,
  `BattleEngineOutcome`, `BattleTimeline`, `BattlePublicState`,
  `BattleSessionFacade`;
- `BattleContext` et `BattleTurnRunner` ne sont pas exportés publiquement.

### `packages/map_battle/lib/src/psdk/application/psdk_battle_engine.dart`

Zones modifiées :

- remplacement de la résolution locale par une délégation à
  `BattleEngine.fromPsdk`;
- conservation de la sortie historique `PsdkBattleTurnResult`.

Raison :

- éviter deux moteurs PSDK parallèles;
- faire du nouveau `BattleEngine` le point d'entrée applicatif tout en gardant
  la CLI et les tests PSDK existants compatibles.

Impact :

- `PsdkBattleEngine` reste utilisable;
- les tests `psdk_engine_smoke_test.dart` continuent de passer;
- les erreurs `UnsupportedPsdkBattleMoveBehavior` remontent toujours.

## Logique mise en place

- `BattleEngine` possède un `BattleContext` mutable privé.
- `BattlePublicState` expose un snapshot immuable.
- `BattleEngineDecisionRequest` expose les choix fight disponibles côté joueur.
- `BattleTurnRunner` résout un tour singles PSDK avec priorité, vitesse et
  tie-break déterministe.
- `BattleTimeline` transporte l'ordre causal pour runtime/CLI.
- Une soumission qui échoue en cours de résolution restaure état, RNG et numéro
  de tour.
- `BattleSessionFacade` fournit un objet de transition vers la nouvelle API
  sans toucher au legacy.

## Tests créés

`packages/map_battle/test/battle_engine_clean_architecture_test.dart`

Couverture :

- requête joueur et snapshot public immuable;
- résolution d'un tour par `BattleEngine.submit`;
- timeline ordonnée;
- outcome terminal sans `nextRequest`;
- second submit après fin de combat sans événements inventés;
- slot fight invalide sans mutation;
- `battleEngineMethod` PSDK inconnue qui remonte et rollback l'état;
- `battleEngineMethod` adverse inconnue après une action joueur déjà résolue,
  pour prouver le rollback d'un tour partiellement muté;
- non-shadowing des contrats publics legacy;
- non-régression de `createBattleSession`.

## Commandes de test lancées

Depuis `packages/map_battle` :

```bash
dart test test/battle_engine_clean_architecture_test.dart
```

Résultat exact :

```text
00:00 +8: All tests passed!
```

```bash
dart test test/battle_engine_clean_architecture_test.dart test/psdk_engine_smoke_test.dart test/psdk_battle_cli_test.dart
```

Résultat exact :

```text
00:00 +25: All tests passed!
```

```bash
dart test
```

Résultat exact :

```text
00:00 +231: All tests passed!
```

## Commandes d'analyse lancées

Depuis `packages/map_battle` :

```bash
dart analyze
```

Résultat exact :

```text
Analyzing map_battle...
No issues found!
```

## Commande de build lancée

Depuis `packages/map_battle` :

```bash
dart compile exe bin/psdk_battle_cli.dart -o /tmp/pokemon_project_psdk_battle_cli
```

Résultat exact :

```text
Generated: /tmp/pokemon_project_psdk_battle_cli
```

## Sub-agents

### Sub-agent Audit / Architecture

Verdict :

- noms `BattleEngineSetup`, `BattleEngineTurnResult`,
  `BattleEngineOutcome` validés pour éviter le shadowing legacy;
- correction demandée : ne pas exporter `BattleContext` ni le runner concret;
- correction appliquée avec des exports `show` dans `map_battle.dart`.

### Sub-agent Tests

Verdict :

- le test rouge `battle_engine_clean_architecture_test.dart` couvrait le bon
  noyau;
- recommandations intégrées : bubbling des méthodes PSDK inconnues, garde-fou
  sur les contrats legacy.

### Sub-agent Implémentation

Implémentation réalisée localement :

- création des couches;
- adaptation de `PsdkBattleEngine`;
- rollback atomique sur exception de résolution.

### Sub-agent Build / Validation

Validation réalisée localement :

- tests ciblés;
- suite complète `map_battle`;
- analyse statique;
- compilation CLI.

### Sub-agent Critique finale

Verdict :

- aucun bloquant détecté;
- pas de fuite directe du `BattleContext` mutable;
- exports clean correctement bornés;
- non-shadowing legacy confirmé;
- demande non bloquante : ajouter un test d'atomicité après mutation partielle.

Action prise :

- ajout du test `second action failure restores a partially resolved turn`;
- vérification que l'état joueur, l'état adverse et `turnNumber` reviennent à
  leur valeur initiale après l'exception.

## État git final

Le repo reste dirty car les lots 1 à 4 sont cumulés dans le même workspace.

Changements Lot 4 :

- nouveaux fichiers sous `packages/map_battle/lib/src/application`;
- nouveaux fichiers sous `packages/map_battle/lib/src/domain`;
- nouveau test `packages/map_battle/test/battle_engine_clean_architecture_test.dart`;
- modification de `packages/map_battle/lib/map_battle.dart`;
- modification de
  `packages/map_battle/lib/src/psdk/application/psdk_battle_engine.dart`.

Changements hors Lot 4 toujours présents :

- `.idea/libraries/Dart_Packages.xml`;
- fichiers `map_core` Lot 1;
- fichiers `map_editor` Lots 2 et 3;
- rapports précédents.

## Limites explicitement conservées

- Le moteur clean ne supporte encore que le singles PSDK déjà prouvé.
- L'adversaire choisit encore son premier move.
- Les actions PSDK ne sont pas encore des classes domain dédiées.
- Les handlers de fin de tour PSDK ne sont pas portés.
- Les banks/parties/réserves PSDK complètes appartiennent au Lot 5.
- Le runtime continue à utiliser le legacy `BattleSession`.

## Auto-critique finale

Points solides :

- l'API est additive;
- le legacy est prouvé par test;
- la CLI PSDK compile encore;
- le contexte mutable n'est plus exporté depuis le barrel public;
- une erreur de handler PSDK ne laisse pas un tour à moitié committé.

Risques restants :

- `BattlePublicState` expose encore `psdkState` comme bridge temporaire;
- `BattleEngineDecisionRequest` dépend encore directement des DTOs PSDK;
- le runner est encore simple et devra être remplacé progressivement par les
  actions/handlers PSDK des lots suivants.

## Prochaines étapes proposées

- Lot 5 : introduire banks, parties, slots actifs et battlers PSDK.
- Déplacer progressivement la construction d'actions hors du runner.
- Ajouter des décisions de switch dès que la topology PSDK existe.
