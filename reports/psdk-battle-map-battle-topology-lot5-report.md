# PSDK Battle Migration - Lot 5 Map Battle Topology

## Nom exact du lot

Lot 5 - Battlers, banks, parties et topology PSDK.

## Résumé exécutif

Le lot 5 introduit dans `map_battle` un modèle PSDK additif basé sur
`bank`, `position`, `party`, `slot actif`, `réserves` et `battler` mutable.

Le legacy `BattleState` et son `BattleSlotRef(side, slotIndex)` restent
inchangés. Pour éviter une collision API, le nouveau repère PSDK s'appelle
`BattlePositionRef(bank, position)`.

## Scope confirmé

Inclus :

- domain clean PSDK : `BattleBattler`, `BattleBank`, `BattleParty`,
  `BattleSlot`, `BattleTopology`, `BattleComputedStats`, `BattleTypes`,
  `BattleMoveInstance`, `BattleStatStageSet`;
- exposition publique bornée via `map_battle.dart`;
- `BattlePublicState.topology` comme snapshot topology dérivé de l'état PSDK;
- tests de topology, battler state, invariants, immutabilité et non-collision
  avec le legacy.

Hors scope :

- aucun branchement runtime;
- aucun remplacement du legacy `BattleState`;
- aucun switch complet dans le runner;
- aucun support réel doubles/multi dans la résolution des actions;
- aucun port des handlers/effects PSDK complets.

## Audit initial

Fichiers inspectés :

- `packages/map_battle/lib/src/battle_topology.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/domain/battle/battle_context.dart`
- `packages/map_battle/lib/src/domain/battle/battle_setup.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_slots.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart`
- `packages/map_battle/test/battle_state_topology_test.dart`
- `reports/psdk-battle-engine-migration-worklots.md`

Constats :

- le legacy exporte déjà `BattleSlotRef` avec `side` et `slotIndex`;
- la lane PSDK exporte déjà `PsdkBattleSlotRef` avec `bank` et `position`;
- le lot devait donc être adapté pour éviter un nouveau `BattleSlotRef`
  incompatible;
- le runner Lot 4 reste singles-only et s'appuie encore sur `PsdkBattleState`.

Décision :

- créer `BattlePositionRef` pour la topology PSDK propre;
- ne pas modifier `packages/map_battle/lib/src/battle_state.dart`;
- ne pas modifier `packages/map_battle/lib/src/battle_topology.dart`;
- exposer la topology comme snapshot dérivé depuis `BattlePublicState`.

## État git initial

Le workspace contenait déjà les changements cumulés Lots 1 à 4, plus un fichier
IDE non lié :

- `.idea/libraries/Dart_Packages.xml`;
- `map_core` Lot 1;
- `map_editor` Lots 2 et 3;
- `map_battle` fondation PSDK + Lot 4.

## Fichiers créés

- `packages/map_battle/lib/src/domain/battle/battle_battler.dart`
- `packages/map_battle/lib/src/domain/battle/battle_bank.dart`
- `packages/map_battle/lib/src/domain/battle/battle_party.dart`
- `packages/map_battle/lib/src/domain/battle/battle_slot.dart`
- `packages/map_battle/lib/src/domain/battle/battle_stats.dart`
- `packages/map_battle/lib/src/domain/battle/battle_topology.dart`
- `packages/map_battle/test/psdk_battle_topology_test.dart`
- `packages/map_battle/test/psdk_battler_state_test.dart`

## Fichiers modifiés

### `packages/map_battle/lib/map_battle.dart`

Zones modifiées :

- exports `show` pour les nouveaux types Lot 5.

Raison :

- rendre le modèle PSDK consommable sans exposer de helpers internes;
- conserver la coexistence avec le legacy.

Impact :

- nouveaux types publics : `BattlePositionRef`, `BattleSlot`,
  `BattleBattler`, `BattleBank`, `BattleParty`, `BattleTopology`,
  `BattleComputedStats`, `BattleTypes`, `BattleMoveInstance`,
  `BattleStatStageSet`, `BattleStat`.

### `packages/map_battle/lib/src/domain/battle/battle_context.dart`

Zones modifiées :

- ajout de `BattlePublicState.topology`.

Raison :

- donner au runtime/aux tests une vue PSDK bank/position du snapshot courant
  sans rendre le `BattleContext` mutable public.

Impact :

- `BattleEngine.snapshot().topology` reflète les PV et slots actifs courants;
- la topology est dérivée de `PsdkBattleState` et reste détachée du moteur.

## Logique créée

### Battler state

- `BattleBattler` porte `bank`, `position`, `partyId`, `partyIndex`,
  `hp/maxHp`, stats, types, moves, ability/item optionnels, effects et history.
- `position == -1` sert de sentinelle pour un battler de réserve.
- HP est clampé entre `0` et `maxHp`.
- `applyDamage` et `heal` restent bornés.
- `BattleMoveInstance` possède ses propres PP et refuse les PP invalides.
- `BattleStatStageSet` borne les stages entre `-6` et `+6`.

### Banks / parties / slots

- `BattleBank` vérifie les indexes de bank, les positions de slots, les party
  ids dupliqués et les battlers actifs assignés au mauvais bank/position.
- `BattleParty` vérifie les `partyIndex` et `instanceId` dupliqués.
- `BattleSlot` connaît sa bank une fois attaché à un `BattleBank` et expose un
  `BattlePositionRef`.

### Topology

- `BattleTopology.fromPsdkSetup` construit la topology singles initiale.
- `BattleTopology.fromPsdkState` groupe correctement plusieurs positions
  actives par bank.
- `alliesOf`, `foesOf`, `adjacentFoesOf`, `emptySlots`,
  `replacementsFor`, `battlerAt` et `placeBattler` sont disponibles.
- Les réserves ne sont pas des slots actifs targetables.
- `replacementsFor` refuse maintenant de proposer des candidats pour un slot
  inexistant.
- Les stages refusent un montant négatif sur `raise` et `lower`, au lieu de
  transformer implicitement une hausse en baisse ou inversement.

## Corrections après revue sub-agent

La critique finale a fait remonter deux vrais risques P1 :

- `placeBattler` permettait une mutation non atomique : un battler déjà actif
  pouvait être placé ailleurs sans switch explicite, et un slot occupé pouvait
  perdre son occupant.
- `BattleBank` acceptait des parties/battlers incohérents avec son propre
  index de bank.

Actions prises :

- `BattleBank.placeBattler` refuse désormais un déplacement d'actif vers une
  autre position et refuse de remplacer un occupant différent.
- `BattleBank` vérifie que chaque `BattleParty.id` correspond à l'index de
  bank et que tous les battlers de ses parties appartiennent à cette bank.
- Les tests couvrent ces cas, ainsi que les deux durcissements P2 retenus :
  slot inexistant pour les remplacements et montant négatif de stat stage.

## Tests créés

### `packages/map_battle/test/psdk_battler_state_test.dart`

Couverture :

- clamp HP;
- helpers `isAlive` / `isKo`;
- ownership de la liste de moves;
- effects et history;
- stages bornés `-6..+6`;
- PP non négatifs et plafonnés;
- invariants invalides sur battler et move.

### `packages/map_battle/test/psdk_battle_topology_test.dart`

Couverture :

- construction depuis setup singles;
- groupement de plusieurs positions actives depuis un `PsdkBattleState`;
- allies/foes/adjacent foes;
- slots vides et remplacements possibles;
- `partyIndex` stable après placement;
- doublons bank/slot/party/instance rejetés;
- mauvais bank/position rejetés;
- réserves non targetables comme actifs;
- collections publiques immuables;
- non-shadowing `BattleSlotRef` legacy vs `BattlePositionRef` PSDK;
- `BattlePublicState.topology` suit l'état après un tour.

## Commandes de test lancées

Depuis `packages/map_battle` :

```bash
dart test test/psdk_battle_topology_test.dart test/psdk_battler_state_test.dart
```

Résultat exact :

```text
00:00 +17: All tests passed!
```

```bash
dart test test/psdk_battle_topology_test.dart test/psdk_battler_state_test.dart test/battle_engine_clean_architecture_test.dart test/psdk_engine_smoke_test.dart test/battle_state_topology_test.dart
```

Résultat exact :

```text
00:00 +44: All tests passed!
```

```bash
dart test
```

Résultat exact :

```text
00:00 +246: All tests passed!
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

## Smoke CLI comportemental

Depuis `packages/map_battle` :

```bash
dart run bin/psdk_battle_cli.dart --format json
```

Résultat exact :

```json
{"outcome":"victory","turns":1,"playerHp":44,"opponentHp":0,"events":[{"kind":"turn_started","turn":1},{"kind":"move_declared","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","moveName":"Scratch"},{"kind":"animation_cue","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch"},{"kind":"damage","user":{"bank":0,"position":0},"target":{"bank":1,"position":0},"moveId":"scratch","damage":18,"remainingHp":0},{"kind":"battle_ended","outcome":"victory"}]}
```

Ce smoke prouve que le CLI traverse bien le moteur PSDK/clean, produit une
timeline bank/position cohérente, applique les dégâts et termine le combat.

## Autres validations

Depuis la racine :

```bash
git diff --check
```

Résultat exact :

```text
<no output>
```

## Sub-agents

### Sub-agent Audit / Architecture

Verdict :

- ne pas introduire un nouveau `BattleSlotRef`;
- utiliser `BattlePositionRef`;
- ne pas toucher au legacy `BattleState` / `battle_topology.dart`;
- exposer les nouveaux types via `show`;
- surveiller la divergence `PsdkBattleState` / `BattleTopology`.

Actions prises :

- nom `BattlePositionRef` retenu;
- pas de modification du legacy;
- topology exposée comme snapshot dérivé.

### Sub-agent Tests

Verdict :

- deux tests dédiés recommandés : `psdk_battle_topology_test.dart` et
  `psdk_battler_state_test.dart`;
- ajouter invariants, immutabilité, non-shadowing et réserves non targetables.

Actions prises :

- tous ces tests ont été ajoutés.

### Sub-agent Implémentation

Implémentation réalisée localement :

- création des six fichiers domain;
- ajout des exports publics bornés;
- ajout de `BattlePublicState.topology`.

### Sub-agent Build / Validation

Validation réalisée localement :

- tests ciblés Lot 5;
- garde de régression Lot 4/PSDK/legacy topology;
- analyse statique;
- compilation CLI;
- suite complète `map_battle`.

### Sub-agent CLI comportemental

Validation demandée après le retour d'Averroes : utiliser le CLI comme banc de
fumée comportemental, avec sub-agent dédié.

Verdict :

- `dart run bin/psdk_battle_cli.dart --format json` sort bien un combat
  déterministe en victoire;
- deux exécutions JSON consécutives sont identiques;
- `--format text` sort `outcome=victory turns=1 playerHp=44 opponentHp=0`;
- `--format xml` et un argument inconnu échouent avec exit code `64`;
- le smoke CLI est bon pour vérifier la chaîne engine/timeline, mais ne
  remplace pas les tests unitaires détaillés.

### Sub-agent Critique finale

Verdict :

- P1 `placeBattler` corrigé;
- P1 cohérence party/bank corrigé;
- P2 surface publique mutable acceptée temporairement comme surface de
  migration, à réduire quand les handlers PSDK seront branchés dans le moteur;
- P2 slot inexistant et montant négatif de stages corrigés localement.

## État git final

Le workspace reste dirty car les lots sont cumulés.

Changements Lot 5 :

- nouveaux fichiers sous `packages/map_battle/lib/src/domain/battle`;
- modification de `packages/map_battle/lib/src/domain/battle/battle_context.dart`;
- modification de `packages/map_battle/lib/map_battle.dart`;
- nouveaux tests `psdk_battle_topology_test.dart` et
  `psdk_battler_state_test.dart`;
- présent rapport.

## Limites conservées

- La résolution du runner reste singles-only.
- Les switches complets ne sont pas encore branchés dans `BattleTurnRunner`.
- Les parties de réserve existent au niveau topology, mais le setup public
  clean ne transporte pas encore des réserves riches.
- Le modèle actuel suppose une party principale par bank (`party.id == bank`)
  pour éviter les incohérences pendant cette première extraction.
- `BattlePublicState.topology` est un snapshot dérivé, pas une référence live
  vers une topology mutable interne.
- Les nouveaux types domain restent exportés pour permettre l'intégration des
  lots suivants; cette surface n'est pas encore l'API stable finale.
- Les handlers/effects PSDK réels restent à porter dans les lots suivants.

## Auto-critique finale

Points solides :

- collision `BattleSlotRef` évitée;
- legacy non modifié;
- invariants topology/battler testés;
- collections publiques protégées;
- suite complète `map_battle` verte.

Risques restants :

- modèle topology plus riche que le runner actuel;
- duplication temporaire entre `PsdkBattleState` et la projection
  `BattleTopology`;
- `BattleSlot` est mutable pour préparer les switches, donc il doit rester
  manipulé avec prudence hors engine.

## Prochaines étapes proposées

- Lot 6 : extraire les RNG streams clean et enrichir la timeline typée.
- Ajouter des actions PSDK explicites avant de brancher les switches dans le
  runner.
- Faire évoluer `BattleEngineSetup` pour transporter de vraies réserves clean.
