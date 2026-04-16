# Audit de parité Pokémon Showdown vs moteur battle PokeMap

## 1. Résumé exécutif honnête

### Verdict global

Le moteur battle local de PokeMap n'est **pas proche d'une vraie parité Showdown** au sens architectural ou comportemental large.

En revanche, il n'est **pas non plus un faux moteur cosmétique** :

- il exécute réellement un sous-ensemble singles 1v1 ;
- il a un handoff runtime -> battle honnête sur ce sous-ensemble ;
- il a un write-back runtime réel ;
- il a une chronologie de tour locale honnête via `BattleTurnResult.timeline`.

La bonne lecture est donc :

- **moteur local crédible et propre sur un sous-ensemble étroit** ;
- **très loin du moteur Showdown complet** ;
- **quelques fondations actuelles peuvent encore porter 2-3 lots singles bornés** ;
- **mais une vraie convergence vers la parité Showdown singles exigera une reprise plus profonde du modèle `state/request/event`, et pas juste une addition de features**.

### Niveau actuel de proximité avec Showdown

Appréciation franche :

- singles 1v1 local honnête sur un sous-ensemble : **oui**
- proximité avec l'architecture Showdown : **faible**
- proximité avec la richesse comportementale Showdown : **très faible**
- robustesse du runtime handoff local pour le sous-ensemble actuel : **bonne**
- capacité à atteindre Showdown par simple croissance incrémentale du design actuel : **non**

### Ce qui est déjà solide

- ordre d'action minimal cohérent (`priority`, `speed`, `Trick Room`) ;
- PP / accuracy / crits / dégâts / STAB / effectiveness / immunités réellement consommés ;
- statuts majeurs `par`, `brn`, `psn`, `tox` réellement exécutés ;
- volatiles utiles BE8 réellement exécutés ;
- field state BE9 réellement exécuté (`rain`, `sandstorm`, `trickRoom`) ;
- switch pipeline singles minimal BE10 réellement exécuté ;
- chronologie d'affichage honnête via `timeline` ;
- bridge runtime explicite, refus honnêtes, filtrage local des moves non bridgeables ;
- mapping lineup -> party et write-back runtime déjà disciplinés pour le périmètre BE10A.

### Ce qui est encore très loin

- moteur d'événements / callbacks Showdown ;
- vraie action queue Showdown ;
- `Side` / `slotConditions` / `sideConditions` ;
- request model riche (`move` / `switch` / `wait` / `teampreview`) ;
- abilities ;
- items ;
- side conditions / hazards ;
- terrains ;
- targeting riche ;
- self-switch / force-switch / phazing ;
- secondaries et hooks move-level riches ;
- modèles de move / pokemon / field beaucoup trop étroits ;
- write-back runtime bien trop pauvre pour persister un combat Showdown-like large.

### Principaux blockers structurels

1. absence de moteur d'événements / callbacks comparable à `runEvent` / `singleEvent` / `eachEvent`
2. absence de vrai modèle `Side` / `slot` / `request`
3. absence de vraie queue d'actions généralisée
4. modèle `BattleMove` trop petit pour approcher la sémantique Showdown
5. modèle `BattleFieldState` trop fermé
6. modèle `BattleVolatileState` trop fermé
7. write-back runtime trop étroit si le moteur devient réellement riche
8. bridge/runtime conçus pour un sous-ensemble honnête, pas pour la richesse de Showdown

## 2. Pré-gates exécutés + résultats

### Pré-gates git read-only

Commandes exécutées :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

Résultat :

- les trois commandes n'ont renvoyé aucune ligne avant création du report ;
- cela confirme un état de travail localement propre **au moment du pré-gate** ;
- ce n'est pas une preuve historique absolue de propreté éternelle, seulement le résultat réellement observé.

### Validation battle exécutée

Commandes exécutées :

```bash
cd packages/map_battle && /opt/homebrew/bin/dart analyze
cd packages/map_battle && /opt/homebrew/bin/dart test
```

Résultat observé :

- `dart analyze` : `No issues found!`
- `dart test` : `All tests passed!` après 111 tests

### Validation runtime exécutée

Commandes exécutées :

```bash
cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/application/runtime_battle_outcome_apply.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/battle_overlay_component_test.dart

cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/battle_overlay_component_test.dart
```

Résultat observé :

- `flutter analyze --no-pub` : `No issues found! (ran in 2.8s)`
- `flutter test ...` : `All tests passed!` après 89 tests

### Classification honnête des preuves

- **confirmé par lecture de code** : cartographie architecture locale et Showdown, contrats, gaps structurels
- **confirmé par exécution/tests existants** : le sous-ensemble local actuellement supporté fonctionne et les suites ciblées battle/runtime passent
- **inférence raisonnable** : coût d'évolution vers la parité large, ordre de chantiers recommandé
- **point incertain** : aucun benchmark d'exhaustivité n'a été exécuté move-by-move contre tout le dex Showdown ; ce n'était pas l'objet ni le scope réaliste de cet audit

## 3. Méthode réelle utilisée

### Côté local : lecture réelle

Fichiers relus côté battle/runtime local :

- `packages/map_battle/lib/map_battle.dart`
- `packages/map_battle/lib/src/battle_action.dart`
- `packages/map_battle/lib/src/battle_move.dart`
- `packages/map_battle/lib/src/battle_setup.dart`
- `packages/map_battle/lib/src/battle_state.dart`
- `packages/map_battle/lib/src/battle_resolution.dart`
- `packages/map_battle/lib/src/battle_session.dart`
- `packages/map_battle/lib/src/battle_status.dart`
- `packages/map_battle/lib/src/battle_volatile.dart`
- `packages/map_battle/lib/src/battle_field.dart`
- `packages/map_battle/lib/src/battle_switch.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
- `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`
- tests battle/runtime liés via `rg` + validation ciblée
- reports contextuels BE9 / BE10 / BE10A / post-BE10A

### Côté Showdown : lecture réelle

Le repo officiel a été cloné en lecture seule hors du dépôt utilisateur :

- `/tmp/pokemon-showdown-audit`

Commande exécutée :

```bash
git clone --depth 1 https://github.com/smogon/pokemon-showdown.git /tmp/pokemon-showdown-audit
```

Fichiers Showdown réellement lus :

- `/tmp/pokemon-showdown-audit/sim/README.md`
- `/tmp/pokemon-showdown-audit/sim/battle.ts`
- `/tmp/pokemon-showdown-audit/sim/battle-actions.ts`
- `/tmp/pokemon-showdown-audit/sim/battle-queue.ts`
- `/tmp/pokemon-showdown-audit/sim/side.ts`
- `/tmp/pokemon-showdown-audit/sim/field.ts`
- `/tmp/pokemon-showdown-audit/sim/pokemon.ts`
- `/tmp/pokemon-showdown-audit/sim/state.ts`
- `/tmp/pokemon-showdown-audit/sim/dex-moves.ts`
- `/tmp/pokemon-showdown-audit/data/conditions.ts`
- `/tmp/pokemon-showdown-audit/data/moves.ts`

### Recherches ciblées réellement exécutées

Commandes de cartographie locale :

```bash
rg -n "BattleTurnResult\(|currentTurn|\.executions\b|\.statusEvents\b|\.volatileEvents\b|\.fieldEvents\b|\.switchEvents\b|\.timeline\b" packages

rg -n "playerPartySlotIndicesByLineupIndex|playerPartyIndex|RuntimeActiveBattleContext|applyRuntimeBattleOutcomeToGameState|timeline|buildBattleTurnLinesForOverlay" packages/map_runtime packages/map_battle
```

Commandes de cartographie Showdown :

```bash
rg -n "runEvent\(|singleEvent\(|eachEvent\(|makeRequest\(|getRequests\(|faintQueue|requestState|activeRequest|forceSwitch|switchFlag|selfSwitch|sideConditions|slotConditions|pseudoWeather|terrain|weatherState|beforeTurn|residual" \
  /tmp/pokemon-showdown-audit/sim/battle.ts \
  /tmp/pokemon-showdown-audit/sim/battle-actions.ts \
  /tmp/pokemon-showdown-audit/sim/battle-queue.ts \
  /tmp/pokemon-showdown-audit/sim/side.ts \
  /tmp/pokemon-showdown-audit/sim/field.ts \
  /tmp/pokemon-showdown-audit/sim/pokemon.ts

rg -n "teleport|trickroom|protect|feint|hyperbeam|mustrecharge|solarbeam|selfSwitch|forceSwitch|sideCondition|slotCondition|terrain|pseudoWeather|weather" \
  /tmp/pokemon-showdown-audit/data/moves.ts \
  /tmp/pokemon-showdown-audit/data/conditions.ts \
  /tmp/pokemon-showdown-audit/sim/battle-actions.ts \
  /tmp/pokemon-showdown-audit/sim/battle.ts \
  /tmp/pokemon-showdown-audit/sim/side.ts \
  /tmp/pokemon-showdown-audit/sim/field.ts \
  /tmp/pokemon-showdown-audit/sim/pokemon.ts
```

### Ce qui a été exécuté

- pré-gates git read-only
- analyze/test battle
- analyze/test runtime ciblés
- recherches `rg`
- lecture de code local
- lecture de code Showdown
- sub-agent d'audit/design
- reviewer séparé

### Ce que je n'ai pas pu vérifier ou ce que je n'ai volontairement pas fait

- aucun diff comportemental automatisé move-by-move entre le moteur local et Showdown
- aucune exécution du moteur Showdown sur scénarios miroir
- aucune lecture exhaustive de l'intégralité du dex ou de tous les scripts Showdown
- aucune modification de code locale
- aucun test ajouté
- aucun refactor

## 4. Cartographie du code local

### Battle : modules réellement pertinents

| Fichier local | Rôle réel | Source de vérité locale |
| --- | --- | --- |
| `packages/map_battle/lib/src/battle_session.dart` | cœur de résolution du combat, ordre du tour, move execution, résiduels, switches, timeline | **source de vérité principale** |
| `packages/map_battle/lib/src/battle_state.dart` | état immutable du combat, combattants, réserves, champ, currentTurn, outcome | source de vérité de l'état |
| `packages/map_battle/lib/src/battle_resolution.dart` | contrat observable du tour (`BattleTurnResult`, buckets, `timeline`) | source de vérité de la restitution de tour |
| `packages/map_battle/lib/src/battle_action.dart` | contrats de choix joueur et actions internes | source de vérité du request model local minimal |
| `packages/map_battle/lib/src/battle_move.dart` | contrat move battle minimal | source de vérité du move model local |
| `packages/map_battle/lib/src/battle_setup.dart` | contrat d'initialisation du combat | source de vérité du setup battle |
| `packages/map_battle/lib/src/battle_status.dart` | statuts majeurs BE7 et événements associés | source de vérité du statut majeur local |
| `packages/map_battle/lib/src/battle_volatile.dart` | volatiles BE8 et événements associés | source de vérité du volatile local |
| `packages/map_battle/lib/src/battle_field.dart` | field state BE9 et événements associés | source de vérité du champ local |
| `packages/map_battle/lib/src/battle_switch.dart` | événements de switch/remplacement | source de vérité des traces roster locales |
| `packages/map_battle/lib/src/battle_rng.dart` | seam RNG local | source de vérité du RNG local |
| `packages/map_battle/lib/src/battle_typing.dart` / `battle_type_chart.dart` | typing minimal et chart supportée | source de vérité type locale |

### Runtime : modules réellement pertinents

| Fichier local | Rôle réel | Source de vérité locale |
| --- | --- | --- |
| `packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart` | projection canonique -> `BattleMoveData`, refus explicites | source de vérité du support bridgeable |
| `packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart` | dérive species/learnset/moves et construit les seeds battle | source de vérité de l'assemblage seed |
| `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart` | orchestre actif/réserves et construit `BattleSetup` | source de vérité du handoff runtime -> battle |
| `packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart` | write-back post-combat vers `GameState` | source de vérité du write-back runtime |
| `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` | orchestration runtime battle + contexte actif | source de vérité des call sites runtime principaux |
| `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` | restitution UI du tour à partir de `timeline` | source de vérité UI de la chronologie locale |

### Tests réellement pertinents

| Zone | Tests clés |
| --- | --- |
| battle | `battle_move_effects_test.dart`, `battle_field_test.dart`, `battle_volatiles_test.dart`, `battle_switch_test.dart`, `battle_rng_test.dart`, `battle_session_test.dart`, `battle_flow_integration_test.dart`, `battle_session_flow_test.dart` |
| runtime | `runtime_battle_move_bridge_test.dart`, `runtime_battle_combatant_seed_builder_test.dart`, `runtime_battle_setup_mapper_test.dart`, `runtime_battle_outcome_apply_test.dart`, `battle_overlay_component_test.dart`, `wild_battle_end_to_end_flow_test.dart`, `playable_map_game_whiteout_lite_test.dart` |

## 5. Cartographie du code Showdown pertinent

### Modules Showdown réellement centraux pour la comparaison

| Fichier Showdown | Sujet | Pourquoi pertinent ici |
| --- | --- | --- |
| `sim/battle.ts` | noyau battle, `runEvent`, `requestState`, faint queue, turn loop | point de comparaison principal |
| `sim/battle-actions.ts` | switch, runMove, useMove, damage, hit pipeline | compare move execution et switch lifecycle |
| `sim/battle-queue.ts` | queue d'actions, tri, taxonomie d'actions | compare scheduler et action model |
| `sim/side.ts` | `Side`, request payloads, `choice`, side/slot conditions | compare request model et state partitioning |
| `sim/field.ts` | weather, terrain, pseudoWeather | compare field state |
| `sim/pokemon.ts` | `Pokemon`, volatiles, boosts, status, move slots, flags | compare combattant et état riche |
| `sim/state.ts` | sérialisation du state battle Showdown | utile pour mesurer la richesse structurelle |
| `sim/dex-moves.ts` | contrat move riche (targeting, callbacks, side/slot/field effects) | compare move model |
| `data/conditions.ts` | conditions, volatiles, statuts, weathers | compare la mécanique conditionnelle |
| `data/moves.ts` | moves concrets, callbacks, effets | compare la réalité du dex Showdown |

### Synthèse Showdown pertinente sans bruit

Showdown n'est pas juste “plus complet”.

Ce qui le distingue structurellement est :

- un **modèle d'état partitionné** (`Battle`, `Side`, `Pokemon`, `Field`) ;
- une **queue d'actions généralisée** ;
- un **modèle de request riche** ;
- un **moteur d'événements/callbacks** ;
- des **conditions/moves riches pilotées par données + callbacks** ;
- une **gestion du faint/switch/request** bien plus structurée ;
- une **richesse de move model** sans commune mesure.

## 6. Consommateurs de `BattleTurnResult` identifiés

### Cartographie réelle des consommateurs locaux

| Fichier | Usage | Classification |
| --- | --- | --- |
| `packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart` | narration/restauration chronologique du tour | **chronologique légitime via `timeline`** |
| `packages/map_runtime/test/battle_overlay_component_test.dart` | vérifie que l'overlay consomme `timeline` et refuse bucket-only | **test légitime** |
| `packages/map_battle/test/*` | assertions ciblées sur `executions`, `statusEvents`, `volatileEvents`, `fieldEvents`, `switchEvents` | **catégoriel légitime** |
| `packages/map_runtime/test/runtime_battle_setup_mapper_test.dart` | assertions ciblées sur exécutions / events | **catégoriel légitime** |
| `packages/map_runtime/test/runtime_battle_outcome_apply_test.dart` | ne reconstruit pas la chronologie, vérifie l'issue/finalState | **légitime** |

### Conclusion post-BE10A

Après lecture exhaustive via `rg` :

- **je n'ai pas trouvé d'autre consommateur de prod qui raconte l'ordre d'un tour via les buckets historiques**
- le seul consommateur narratif de prod identifié est l'overlay runtime
- cet overlay consomme bien `timeline` et jette explicitement si `timeline` est absente alors que des buckets sont présents

Conclusion :

- **pas de bug de chronologie supplémentaire confirmé après BE10A**
- les buckets restants sont aujourd'hui surtout :
  - des contrats de compatibilité locale
  - des points d'observation catégoriels pour les tests

## 7. Matrice de parité détaillée

Statuts utilisés :

- `équivalent` : comparable et suffisamment riche
- `partiel` : présent mais plus étroit
- `très simplifié` : présent mais loin d'une vraie équivalence
- `absent` : non présent
- `structurellement incompatible` : la forme actuelle bloque une parité crédible par simple ajout de branches
- `hors scope immédiat` : important Showdown, mais pas premier périmètre singles minimal

### A. Modèle d'état battle

| Sous-système | Local | Showdown | Statut | Fichiers locaux | Fichiers Showdown | Criticité | Niveau de preuve |
| --- | --- | --- | --- | --- | --- | --- | --- |
| état global battle | `BattleState` minimal | `Battle` riche | très simplifié | `battle_state.dart` | `sim/battle.ts` | haute | confirmé code |
| combattant actif | `BattleCombatant` | `Pokemon` | très simplifié | `battle_state.dart` | `sim/pokemon.ts` | haute | confirmé code |
| identité stable | `lineupIndex` | identité `Pokemon` + position + side | partiel | `battle_setup.dart`, `battle_state.dart` | `sim/pokemon.ts`, `sim/side.ts` | moyenne | confirmé code |
| réserves | actif + réserves singles | team + active + reserves riches | partiel | `battle_setup.dart`, `battle_state.dart`, `battle_session.dart` | `sim/side.ts` | moyenne | confirmé code + tests |
| `Side` | absent | central | absent / structurellement incompatible | local N/A | `sim/side.ts` | haute | confirmé code |
| `slotConditions` | absent | présent | absent | local N/A | `sim/side.ts` | haute | confirmé code |
| `sideConditions` | absent | présent | absent | local N/A | `sim/side.ts` | haute | confirmé code |
| field state | 1 weather + 1 pseudoWeather | weather + terrain + pseudoWeather map | très simplifié / structurellement incompatible | `battle_field.dart` | `sim/field.ts` | haute | confirmé code |
| major status | `par/brn/psn/tox` uniquement | tous statuts + interactions riches | très simplifié | `battle_status.dart` | `data/conditions.ts`, `sim/pokemon.ts` | haute | confirmé code |
| volatiles | `protect/mustRecharge/pendingCharge` | map général de volatiles | très simplifié / structurellement incompatible | `battle_volatile.dart` | `sim/pokemon.ts`, `data/conditions.ts` | haute | confirmé code |
| faint queue | post-KO local hardcodé | `faintQueue` explicite | absent / partiel | `battle_session.dart` | `sim/battle.ts` | haute | confirmé code |
| request state | `BattlePhase` minimal | `requestState` + `activeRequest` par side | structurellement incompatible | `battle_state.dart`, `battle_action.dart` | `sim/battle.ts`, `sim/side.ts` | haute | confirmé code |

### B. Pipeline de tour

| Sous-système | Local | Showdown | Statut | Fichiers locaux | Fichiers Showdown | Criticité | Preuve |
| --- | --- | --- | --- | --- | --- | --- | --- |
| choix joueur | `getAvailableChoices()` minimal | requests riches et validation side-level | très simplifié | `battle_session.dart`, `battle_action.dart` | `sim/side.ts`, `sim/battle.ts` | haute | confirmé code |
| choix ennemi | déterministe/locale selon runtime | même système requests/choices | très simplifié | `battle_session.dart`, runtime | `sim/side.ts`, `sim/battle.ts` | moyenne | confirmé code + inférence |
| action queue | pas de vraie queue généralisée | `BattleQueue` centrale | structurellement incompatible | `battle_session.dart` | `sim/battle-queue.ts` | haute | confirmé code |
| priorité / vitesse | oui, singles minimal | oui, plus riche | partiel | `battle_session.dart` | `sim/battle.ts`, `sim/battle-queue.ts` | moyenne | confirmé code + tests |
| tie handling | deterministic player tie-break | randomized/taxonomic queue order | très simplifié | `battle_session.dart` | `sim/battle-queue.ts` | moyenne | confirmé code |
| interruptions mid-turn | très limitées | riches via queue + events | absent / structurellement incompatible | `battle_session.dart` | `sim/battle-queue.ts`, `sim/battle.ts` | haute | confirmé code |
| tours forcés | `Continue`, recharge, charge | système beaucoup plus large | partiel | `battle_action.dart`, `battle_session.dart` | `sim/battle-actions.ts`, `data/conditions.ts` | moyenne | confirmé code + tests |
| switch volontaire | oui, singles minimal | oui, plus riche | partiel | `battle_action.dart`, `battle_session.dart`, `battle_switch.dart` | `sim/battle-actions.ts`, `sim/side.ts` | moyenne | confirmé code + tests |
| switch forcé / phazing | absent | présent | absent | local refus bridge | `sim/battle-actions.ts`, `sim/battle.ts`, `sim/pokemon.ts` | haute | confirmé code |
| selfSwitch | absent | présent | absent | bridge refuse | `sim/battle-actions.ts`, `data/moves.ts` | haute | confirmé code |
| faint handling | post-turn local + remplacements | faint queue + win checks + switch requests | très simplifié | `battle_session.dart` | `sim/battle.ts` | haute | confirmé code |
| end-of-turn | structuré localement | queue + residual events + event engine | partiel mais très simplifié | `battle_session.dart` | `sim/battle.ts`, `data/conditions.ts` | haute | confirmé code |
| timeline / restitution | honnête localement via `timeline` | Showdown log/protocol, pas même seam | hors analogue direct mais localement solide | `battle_resolution.dart`, `battle_overlay_component.dart` | `sim/battle.ts` | faible | confirmé code + tests |

### C. Exécution des moves

| Sous-système | Local | Showdown | Statut | Fichiers locaux | Fichiers Showdown | Criticité | Preuve |
| --- | --- | --- | --- | --- | --- | --- | --- |
| accuracy simple | oui | oui + modifiers/events riches | partiel | `battle_move.dart`, `battle_session.dart` | `sim/battle-actions.ts` | moyenne | confirmé code + tests |
| crits | oui, minimal | oui, très riche | très simplifié | `battle_move.dart`, `battle_session.dart` | `sim/battle-actions.ts` | moyenne | confirmé code + tests |
| dégâts standards | oui, simplifiés | oui, riches | très simplifié | `battle_session.dart` | `sim/battle-actions.ts` | haute | confirmé code + tests |
| STAB / type effectiveness / immunités | oui, subset | oui, riche | partiel | `battle_session.dart`, `battle_typing.dart`, `battle_type_chart.dart` | `sim/battle-actions.ts`, `sim/pokemon.ts` | moyenne | confirmé code + tests |
| secondaries | absent | très présents | absent | local N/A | `sim/dex-moves.ts`, `data/moves.ts`, `sim/battle-actions.ts` | haute | confirmé code |
| callbacks move-level | absent | centraux | absent / structurellement incompatible | local N/A | `sim/dex-moves.ts`, `sim/battle-actions.ts`, `sim/battle.ts` | haute | confirmé code |
| stat stages | petit sous-ensemble | complet et event-driven | partiel / très simplifié | `battle_move.dart`, `battle_state.dart`, `battle_session.dart` | `sim/pokemon.ts`, `sim/battle.ts` | moyenne | confirmé code + tests |
| apply major status | oui, subset | oui, riche | très simplifié | `battle_status.dart`, `battle_session.dart`, bridge | `data/conditions.ts`, `sim/pokemon.ts`, `sim/battle-actions.ts` | moyenne | confirmé code + tests |
| Protect / breakProtect | oui, minimal | oui, avec stall logic etc. | très simplifié | `battle_volatile.dart`, `battle_session.dart` | `data/conditions.ts`, `sim/battle-actions.ts`, `data/moves.ts` | moyenne | confirmé code + tests |
| chargeThenStrike / requireRecharge | oui, minimal | oui, beaucoup plus large | très simplifié | `battle_volatile.dart`, `battle_session.dart` | `data/conditions.ts`, `data/moves.ts`, `sim/battle-actions.ts` | moyenne | confirmé code + tests |
| weather setters / pseudoWeather setters | oui, subset | oui, riche | très simplifié | bridge + `battle_field.dart` + `battle_session.dart` | `sim/field.ts`, `sim/battle-actions.ts`, `data/moves.ts` | moyenne | confirmé code + tests |
| moves partiellement supportés | refus + filtrage runtime | non pertinent côté Showdown (moteur complet) | localement honnête mais non comparable | `runtime_battle_move_bridge.dart`, `runtime_battle_combatant_seed_builder.dart` | N/A | faible | confirmé code + tests |

### D. Mécaniques Showdown majeures absentes ou incomplètes

| Sous-système | Statut local | Référence Showdown | Criticité | Preuve |
| --- | --- | --- | --- | --- |
| abilities | absent | `sim/pokemon.ts`, `sim/battle.ts`, `data/conditions.ts`, `data/moves.ts` | très haute | confirmé code |
| items | absent | `sim/pokemon.ts`, `sim/battle.ts`, `data/conditions.ts`, `data/moves.ts` | très haute | confirmé code |
| side conditions / hazards | absent | `sim/side.ts`, `data/moves.ts`, `sim/battle.ts` | très haute | confirmé code |
| terrains | absent | `sim/field.ts`, `data/moves.ts` | haute | confirmé code |
| weather complet | très simplifié | `sim/field.ts`, `data/conditions.ts` | haute | confirmé code |
| pseudoWeather multiple | absent | `sim/field.ts` | haute | confirmé code |
| multi-hit | refus explicite | `sim/dex-moves.ts`, `data/moves.ts`, `sim/battle-actions.ts` | haute | confirmé code |
| spread moves / doubles targeting | absent | `sim/dex-moves.ts`, `sim/side.ts`, `sim/battle-queue.ts` | très haute | confirmé code |
| doubles / triples | absent | `sim/side.ts`, `sim/battle.ts` | très haute | confirmé code |
| disabled / encore / taunt / lock / trap riches | absent | `sim/side.ts`, `sim/pokemon.ts`, `data/conditions.ts` | haute | confirmé code |
| struggle réel | non confirmé comme support riche | `sim/battle-actions.ts` | moyenne | confirmé code côté Showdown, incertain local détaillé |
| transformation / formes / tera / dynamax | absent | multiples modules Showdown | haute | confirmé code |

### E. Runtime / intégration locale

| Sous-système | Local | Showdown analogue | Statut | Criticité | Preuve |
| --- | --- | --- | --- | --- | --- |
| source data moves/species/learnsets | loaders runtime locaux | dex Showdown intégré | hors analogue direct | faible | confirmé code |
| bridge runtime -> battle | sous-ensemble explicite | pas de seam équivalent direct | force locale, non analogue | faible | confirmé code + tests |
| seed builder | oui | pas d'équivalent direct | force locale utile | faible | confirmé code + tests |
| setup mapper | oui | pas d'équivalent direct | force locale utile | faible | confirmé code + tests |
| outcome apply | HP/write-back minimal | pas d'équivalent direct | partiel et deviendra blocker | haute | confirmé code + tests |
| whiteout-lite | oui, minimal | hors scope Showdown | force locale, non analogue | faible | confirmé code + tests |
| overlay chronologique | `timeline` honnête | pas un analogue direct du protocole Showdown | force locale | faible | confirmé code + tests |
| erreurs runtime trompeuses | plusieurs durcissements déjà faits | N/A | nettement amélioré sur sous-ensemble | faible | confirmé code + tests |

### F. Tests

| Sujet | État | Lecture honnête |
| --- | --- | --- |
| tests battle du sous-ensemble | assez riches | bonne sécurité locale pour le périmètre actuel |
| tests runtime handoff/write-back | bons pour le périmètre local | utiles et honnêtes |
| illusion de sécurité globale | oui, possible si mal lue | passer 200 tests locaux ne prouve en rien une parité Showdown |
| tests requis avant nouvelles features | beaucoup resteront nécessaires | notamment request model, side/slot state, event-driven conditions |

## 8. Faux positifs dangereux

1. **“On a déjà le field state, donc on est proche de Showdown field.”**  
   Faux. Local : un seul weather et un seul pseudoWeather dans `battle_field.dart`. Showdown : weather, terrain, pseudoWeather map, callbacks et durées riches dans `sim/field.ts`.

2. **“On a des volatiles, donc le système volatile est lancé.”**  
   Faux. Local : `protectActive`, `mustRecharge`, `pendingCharge` seulement. Showdown : map général de volatiles sur `Pokemon`, beaucoup de conditions pilotées par events.

3. **“On a le switch pipeline, donc on est quasi au niveau Showdown sur le roster.”**  
   Faux. Le local a un vrai singles minimal, mais pas `Side`, pas `switchFlag`, pas `forceSwitchFlag`, pas request model riche, pas side/slot conditions, pas faint queue équivalente.

4. **“On a Trick Room, donc le scheduler est proche.”**  
   Faux. Le local a un ordre singles minimal cohérent. Showdown a une queue d'actions généralisée avec plus de types d'actions et des insertions mid-turn.

5. **“On a un bridge runtime strict, donc la simulation se rapproche de Showdown.”**  
   Faux ami. C'est une **force d'intégration locale**, pas un équivalent structurel du simulateur Showdown.

6. **“Le champ et les statuts sont présents, donc il manque surtout abilities/items.”**  
   Faux. Les modèles locaux `field`, `volatile`, `request`, `move`, `side` ne sont pas encore de la bonne forme pour absorber proprement beaucoup de mécaniques Showdown, même avant d'arriver aux abilities/items.

7. **“Les tests sont nombreux, donc on est assez proche.”**  
   Faux. Ils verrouillent bien le sous-ensemble local, pas une parité Showdown.

## 9. Problèmes confirmés / non confirmés

### Confirmés

- le moteur local est **délibérément étroit**
- il n'a **pas** d'équivalent au moteur d'événements Showdown
- il n'a **pas** de vrai `Side` / `slotConditions` / `sideConditions`
- il n'a **pas** de request model riche
- il n'a **pas** de vraie `BattleQueue`
- ses modèles `field` et `volatile` sont déjà trop fermés pour beaucoup de mécaniques Showdown
- son bridge runtime est honnête, mais conçu pour une fenêtre de support étroite
- son write-back runtime est encore trop pauvre pour une montée réelle de la richesse de combat

### Non confirmés / à nuancer

- “il faut forcément une vraie queue avant toute progression singles” : **non confirmé tel quel**
  - confirmé : la queue généralisée est un blocker de vraie parité Showdown large
  - non confirmé : elle serait nécessaire avant tout prochain lot singles borné

- “il faut forcément un `Side` complet avant toute nouvelle mécanique utile” : **non confirmé tel quel**
  - confirmé : `Side`/`slot`/`request` deviennent nécessaires pour hazards/screens/healing wish/forced switch riche
  - non confirmé : toute amélioration singles utile restante serait impossible avant cela

- “l'overlay/runtime sont des retards de parité Showdown” : **non**
  - ce sont des couches locales d'intégration sans analogue Showdown direct

## 10. Cause racine réelle

La cause racine n'est pas “on n'a pas encore ajouté assez de mécaniques”.

La cause racine est :

- le moteur local a été conçu comme un **micro-moteur singles explicite, lisible et borné** ;
- Showdown est un **simulateur généraliste fondé sur un state model riche, une queue d'actions, un request model et surtout un moteur d'événements/callbacks** ;
- on ne peut pas passer honnêtement de l'un à l'autre uniquement en ajoutant des branches dans `battle_session.dart`.

Autrement dit :

- certains gaps sont de simples absences de feature ;
- mais les plus gros gaps sont des **gaps de forme du moteur**.

## 11. Décisions retenues / rejetées

### Retenues

- comparer au vrai code Showdown, pas à une image mentale
- conserver une séparation nette entre :
  - moteur battle
  - runtime handoff/write-back
  - couches locales sans analogue direct
- classer les écarts en :
  - `partiel`
  - `très simplifié`
  - `absent`
  - `structurellement incompatible`
- être plus sévère sur `field`, `volatile` et `request/choice` que sur une simple liste de features manquantes

### Rejetées

- audit cosmétique “Showdown est plus complet”
- assimilation du bridge runtime local à un “manque Showdown”
- recommandation “continuer à ajouter des features et on verra”
- refonte suggérée totale et immédiate sans lots intermédiaires

## 12. Critique explicite du prompt

### Ce qui était juste

- centrer l'audit sur le vrai moteur battle + runtime handoff utile
- exiger une comparaison au vrai code Showdown
- exclure les couches serveur/chat/ladder/UI web globale
- exiger un regard système, pas une liste vague de features

### Ce qui était discutable

- “savoir précisément ce qu'il nous manque pour atteindre une vraie parité moteur de combat Showdown” peut laisser croire qu'une parité quasi totale serait un horizon proche par lots incrémentaux. La lecture du code montre plutôt qu'il faudra d'abord recadrer les fondations.

### Ce qui aurait été dangereux si suivi aveuglément

- juger certains seams runtime locaux comme des “retards Showdown” alors qu'ils répondent à des besoins propres à PokeMap
- confondre “beaucoup de mécaniques manquantes” avec “moteur essentiellement similaire mais incomplet”

### Recadrage retenu

- je traite la comparaison comme une comparaison de **moteur de simulation** et de **surfaces locales d'intégration**
- je n'assimile pas automatiquement les seams runtime locaux à des écarts de simulateur
- je distingue bien :
  - ce qui relève de la simulation pure
  - ce qui relève de l'handoff/write-back/overlay local

## 13. Périmètre inclus / exclu

### Inclus

- `packages/map_battle`
- `packages/map_runtime`
- tests battle/runtime liés
- reports récents de contexte
- Showdown `sim/*`, `data/moves.ts`, `data/conditions.ts`

### Exclus

- `packages/map_core` (sauf mention indirecte de data flow)
- `packages/map_editor` (hors lecture indirecte si nécessaire, non requise ici)
- chat/server/login/rooms/ladder/UI client web Showdown globale
- refactors locaux
- corrections code

## 14. Blockers structurels majeurs

### 14.1. Pas de moteur d'événements/callbacks

Local :

- la logique vit principalement dans `battle_session.dart`
- les effets supportés sont explicitement codés en dur

Showdown :

- `runEvent`
- `singleEvent`
- `eachEvent`
- distribution des callbacks depuis `moves.ts`, `conditions.ts`, abilities, items, field, side, pokemon

Pourquoi c'est un blocker :

- abilities/items/conditions/secondaries/terrains/hazards/locks/protect-like riches ne se greffent pas proprement sans cette forme

### 14.2. Pas de vrai modèle `Side` / `slot`

Local :

- `player`
- `playerReserve`
- `enemy`
- `enemyReserve`

Showdown :

- `Side`
- `active`
- `pokemon`
- `sideConditions`
- `slotConditions`
- `choice`
- `activeRequest`

Pourquoi c'est un blocker :

- hazards
- screens
- tailwind
- wish / healing wish / revival blessing
- forced switches riches
- request legality riches

### 14.3. Modèle de request/choice trop étroit

Local :

- `BattlePhase`
- `getAvailableChoices()`
- `PlayerBattleChoice*`

Showdown :

- `MoveRequest`
- `SwitchRequest`
- `TeamPreviewRequest`
- `WaitRequest`
- légalité riche côté `Side`

Pourquoi c'est un blocker :

- trapped
- disabled moves
- encore / taunt / lock
- forced switches
- passes
- previews

### 14.4. Pas de vraie queue d'actions généralisée

Local :

- résolveur singles borné

Showdown :

- `BattleQueue`
- `beforeTurn`
- `residual`
- `runSwitch`
- `priorityChargeMove`
- `beforeTurnMove`
- multiples actions non-move

Pourquoi c'est un blocker :

- mid-turn insertions
- interruptions riches
- force/self switch
- callbacks de timing riches
- gestion précise de beaucoup d'effets conditionnels

### 14.5. `BattleFieldState` trop fermé

Local :

- un seul weather
- un seul pseudoWeather
- pas de terrain

Showdown :

- weather
- terrain
- pseudoWeather map

Pourquoi c'est un blocker :

- la vraie croissance du field state n'est pas additive dans la forme actuelle

### 14.6. `BattleVolatileState` trop fermé

Local :

- `protectActive`
- `mustRecharge`
- `pendingCharge`

Showdown :

- map de volatiles générale par Pokémon

Pourquoi c'est un blocker :

- confusion
- flinch
- encore
- taunt
- disable
- lockedmove
- twoturnmove
- partially trapped
- substitute
- future states multiples

### 14.7. Contrat `BattleMove` trop étroit

Local :

- move DTO battle minimal

Showdown :

- targeting riche
- flags
- secondaries
- self effects
- selfSwitch / forceSwitch
- side/slot/field setters
- callbacks très nombreux

Pourquoi c'est un blocker :

- beaucoup de mécaniques Showdown ne sont pas “juste absentes” ; le move model n'a pas la place de les porter proprement

### 14.8. Write-back runtime trop pauvre

Local :

- write-back honnête sur HP et quelques seams stricts de contexte

Manque pour une vraie montée :

- PP
- statuts hors périmètre
- modifications riches
- side/slot state
- item/ability interactions persistantes
- states multi-combattants plus riches

## 15. Ce qu’il manque pour une vraie parité Showdown sur le périmètre singles

Par ordre de priorité métier/architecture.

### 15.1. Un vrai modèle de request/decision singles

Il manque :

- distinction explicite des requests de type `move`, `switch`, `wait`, potentiellement `teampreview`
- légalité de choix plus riche
- contrat runtime moins implicite

### 15.2. Un modèle `Side` / `slot` minimal mais réel

Il manque :

- `Side`
- `sideConditions`
- `slotConditions`
- requests attachées au side

### 15.3. Un moteur de conditions/événements minimal mais réel

Il manque :

- callbacks de condition
- phases/event points explicites
- capacité à faire vivre statuts/volatiles/field/side sans tout coder à la main dans `battle_session.dart`

### 15.4. Une queue d'actions réellement extensible

Il manque :

- taxonomie d'actions plus riche
- insertions mid-turn propres
- résiduals et transitions pilotées par queue plutôt que seulement par pipeline figé

### 15.5. Un move model plus riche

Il manque :

- secondaries
- self effects riches
- selfSwitch / forceSwitch
- side/slot/terrain setters
- plus de callbacks structurés

### 15.6. Un write-back runtime plus riche

Il manque :

- persistance plus large de l'état battle si l'on ouvre un moteur plus complet

## 16. Ce qu’il manque pour aller au-delà

Hors périmètre singles minimal prioritaire :

- doubles / triples
- spread moves
- targeting complet
- terrains complets
- hazards complets
- abilities
- items
- forme changes / transformation / tera / dynamax
- phazing riche
- request model multi-side plus complet
- callbacks format-level riches
- protocole/log client Showdown-like

## 17. Roadmap proposée

### Lot 1 — BR1 : Request model singles réel

- **Objectif** : remplacer `BattlePhase + getAvailableChoices()` par un request model singles plus riche et explicite
- **Pourquoi maintenant** : c'est le trou de fondation le plus immédiatement bloquant pour disabled/trap/forced switch/hazards futurs
- **Dépendances** : aucune
- **Risques** : retouche battle/runtime/overlay
- **Critères d'acceptation** :
  - request type explicite
  - choices validées contre request
  - forced switch / wait / move request distingués
- **Fichiers probables** :
  - `battle_state.dart`
  - `battle_action.dart`
  - `battle_session.dart`
  - `battle_overlay_component.dart`
  - runtime setup/flow autour des choix
- **Nature** : nécessaire à la parité Showdown singles

### Lot 2 — BR2 : `Side` / `slot` state singles minimal

- **Objectif** : introduire un vrai `Side` local et des `sideConditions` / `slotConditions`
- **Pourquoi maintenant** : sans cela, hazards/screens/wish/revival/forced switch riche resteront tordus
- **Dépendances** : BR1 recommandé
- **Risques** : migration large de l'état battle
- **Critères d'acceptation** :
  - `Side` local lisible
  - side/slot conditions réelles
  - remplacements/request flow cohérents
- **Fichiers probables** :
  - nouveau `battle_side.dart`
  - `battle_state.dart`
  - `battle_session.dart`
  - `battle_resolution.dart`
- **Nature** : nécessaire à la parité Showdown singles

### Lot 3 — BR3 : Event/condition engine singles minimal

- **Objectif** : sortir des gros blocs hardcodés pour statuts/volatiles/field/side
- **Pourquoi maintenant** : sans ce lot, chaque nouvelle mécanique coûte exponentiellement plus cher
- **Dépendances** : BR1, BR2
- **Risques** : design délicat, danger de sur-architecture
- **Critères d'acceptation** :
  - quelques event points explicites
  - conditions locales pilotées par callbacks
  - plus besoin de tout ajouter par `if` dans `battle_session.dart`
- **Fichiers probables** :
  - `battle_session.dart`
  - nouveaux fichiers de conditions/events
  - `battle_status.dart`
  - `battle_volatile.dart`
  - `battle_field.dart`
- **Nature** : nécessaire à la parité Showdown singles

### Lot 4 — BR4 : Move model expansion v2

- **Objectif** : élargir `BattleMove` / bridge pour porter secondaries, self effects et hooks utiles
- **Pourquoi maintenant** : seulement après BR3
- **Dépendances** : BR3
- **Risques** : bridge/runtime explosion si fait trop tôt
- **Critères d'acceptation** :
  - move contract élargi sans clone total de Showdown
  - secondaries et self effects supportables honnêtement
- **Fichiers probables** :
  - `battle_move.dart`
  - `runtime_battle_move_bridge.dart`
  - `battle_session.dart`
- **Nature** : nécessaire à la parité Showdown singles

### Lot 5 — BR5 : Hazards / side conditions singles

- **Objectif** : ouvrir Stealth Rock / Spikes / screens / Tailwind-like selon périmètre choisi
- **Pourquoi maintenant** : une fois `Side` + event engine présents
- **Dépendances** : BR2, BR3, BR4
- **Risques** : switch/request/order/faint interactions
- **Critères d'acceptation** :
  - vraie side condition lifecycle
  - impact réel au switch
- **Fichiers probables** :
  - `battle_session.dart`
  - `battle_side.dart`
  - conditions/events
  - bridge runtime
- **Nature** : nécessaire à la parité Showdown singles

### Lot 6 — BR6 : Force switch / self switch / phazing

- **Objectif** : ouvrir `selfSwitch`, `forceSwitch`, drag/phazing, requests associées
- **Pourquoi maintenant** : dépend d'un vrai modèle de request + side + queue/events
- **Dépendances** : BR1 à BR5
- **Risques** : gros effets croisés sur scheduler/request/faint handling
- **Critères d'acceptation** :
  - move-triggered switching réel
  - forced requests réelles
- **Nature** : nécessaire à la parité Showdown singles

### Lot 7 — BR7 : Abilities/items backbone

- **Objectif** : commencer une couche ability/item réellement exécutable
- **Pourquoi maintenant** : après event engine et state model suffisants
- **Dépendances** : BR3 minimum
- **Risques** : énorme
- **Critères d'acceptation** :
  - quelques abilities/items pilotes réellement consommés
- **Nature** : nécessaire à la vraie parité, mais plus tard

### Lot 8 — BR8 : Runtime write-back v2

- **Objectif** : enrichir le write-back pour ne pas trahir un moteur plus riche
- **Pourquoi maintenant** : au fur et à mesure des expansions structurelles
- **Dépendances** : ce qui ouvre réellement de nouveaux états persistables
- **Risques** : couplage runtime/save data
- **Critères d'acceptation** :
  - write-back cohérent avec le nouveau moteur
- **Nature** : nécessaire à la cohérence locale, pas “Showdown” en soi

## 18. Quick wins vs gros chantiers

### Quick wins relatifs

- request model singles plus propre
- clarifier encore la surface bridge/refus et ses analogues Showdown
- enrichir la cartographie de tests contre les faux positifs de parité

### Gros chantiers à ne pas sous-estimer

- event/callback engine
- `Side` / `slot` state
- vraie queue d'actions
- abilities/items
- persistance runtime d'un moteur réellement plus riche

### Ce qu'il ne faut surtout pas sous-estimer

- le coût de migration depuis un `battle_session.dart` très centralisé vers un moteur plus distribué
- le risque de créer un faux “mini-Showdown” abstrait et pire que l'état actuel
- le coût runtime de tout ce qui devra être écrit/relu côté bridge/write-back/overlay

## 19. Recommandation finale franche

### Faut-il continuer à faire grossir le moteur actuel ?

**Oui, mais seulement si l'objectif est recadré.**

Le moteur actuel peut encore absorber **quelques lots ciblés** si ces lots servent explicitement à préparer une **parité Showdown singles ciblée**, et non à empiler des mécaniques isolées au hasard.

### Faut-il pivoter certaines couches ?

**Oui.**

Les couches qui doivent être revues avant une vraie convergence :

- request/choice
- state partitioning (`Side` / `slot`)
- event/condition engine
- action queue

### Faut-il viser la parité Showdown totale ?

**Non, pas comme objectif de court/moyen terme.**

L'objectif réaliste et défendable est :

- **parité Showdown ciblée sur le périmètre singles utile au projet**
- avec adoption progressive de certaines fondations Showdown-like
- sans cloner tout Showdown

### Réponse franche

**Non, une vraie parité moteur Showdown ne viendra pas par simple croissance additive du moteur actuel ; certaines fondations doivent être revues.**

Nuance importante :

**Oui, la base actuelle peut encore converger vers une parité Showdown ciblée en singles si cette révision de fondations est faite en lots explicites et disciplinés.**

## 20. Retour du sub-agent

### Sub-agents d'audit/design utilisés

- `Jason` (`019d9815-ee41-7963-82e1-6da5daebfa42`)
- `Hypatia` (`019d9810-aaeb-7422-b89b-80c21e4adca1`)

### Ce qu'ils ont trouvé

Constats convergents :

- pas de moteur d'événements/callbacks
- pas de vraie queue d'actions généralisée
- pas de vrai modèle `Side` / `request` / `choice`
- contrat `BattleMove` trop petit
- `BattleFieldState` et `BattleVolatileState` déjà trop fermés pour une vraie croissance Showdown-like
- write-back runtime trop étroit pour une montée réelle vers la parité

Différences de focalisation :

- `Jason` a surtout insisté sur les 6 blockers structurels majeurs et sur les forces locales à créditer
- `Hypatia` a particulièrement insisté sur :
  - la pauvreté de `BattleCombatant` par rapport à `Pokemon`
  - le fait que `timeline` est une bonne restitution locale, mais pas un équivalent du moteur causal Showdown
  - le fait que le bridge runtime est un filtre honnête vers un mini-contrat, pas un signe de compatibilité Showdown large

### Ce que j'ai retenu

- le cadrage des blockers structurels communs
- la montée de criticité de `field` / `volatile`
- l'idée que `timeline`, le bridge runtime et le setup mapper doivent être crédités comme **forces locales**, pas lus comme des “retards simulateur”
- la formulation franche suivante, retenue dans le verdict : la base peut encore converger vers une parité Showdown **ciblée** en singles, mais pas vers une vraie parité Showdown par simple empilement

### Ce que j'ai rejeté ou nuancé

- aucun finding majeur rejeté
- j'ai fusionné les deux retours avec celui du reviewer séparé pour nuancer la place exacte de la queue :
  - oui, c'est un gros blocker structurel
  - non, cela ne prouve pas qu'aucun prochain lot singles borné n'est possible avant elle

## 21. Retour du reviewer séparé

### Reviewer utilisé

- `McClintock` (`019d9810-b21c-7ed2-83fc-5dc92e6389b8`)

### Objections / critiques utiles

1. être plus dur sur `BattleFieldState` et `BattleVolatileState`
2. ne pas sous-estimer le request/choice model comme blocker de fondation
3. nuancer le discours sur l'absence de queue :
   - blocker pour la vraie parité large
   - pas forcément blocker avant tout prochain lot singles borné
4. mieux créditer les seams déjà solides du local :
   - switch/réserves
   - timeline honnête
   - bridge/runtime explicite

### Ce que j'ai intégré

- le rapport est plus sévère sur `field` et `volatile`
- le request model monte dans les blockers majeurs
- la section “problèmes confirmés / non confirmés” nuance explicitement la queue
- les forces locales sont davantage créditées

### Ce que je n'ai pas retenu tel quel

- aucune objection majeure rejetée

## 22. Corrections appliquées après review

Comme il s'agit d'un audit-only, les “corrections” sont des corrections de lecture et de formulation du rapport :

- montée de la criticité de `field`/`volatile`
- montée de la criticité du request/choice model
- nuance sur la queue comme blocker immédiat vs blocker structurel large
- séparation plus nette entre :
  - gaps simulateur Showdown
  - forces d'intégration locale PokeMap

## 23. Incidents rencontrés

- le premier sub-agent d'audit/design (`Hypatia`) n'a pas renvoyé de payload exploitable dans les délais
- aucun incident réseau bloquant : le clone Showdown a fonctionné
- aucune suite locale rouge pendant cet audit
- aucun fichier de code n'a été modifié

## 24. Liste exacte des fichiers modifiés / créés / supprimés

### Créés

- `reports/audit-showdown-parity-battle-engine.md`

### Modifiés

- aucun fichier de code

### Supprimés

- aucun

## 25. Justification fichier par fichier

| Fichier | Pourquoi |
| --- | --- |
| `reports/audit-showdown-parity-battle-engine.md` | livrable unique d'audit-only demandé par l'utilisateur |

## 26. Commandes réellement exécutées

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard

cd packages/map_battle && /opt/homebrew/bin/dart analyze
cd packages/map_battle && /opt/homebrew/bin/dart test

cd packages/map_runtime && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/application/runtime_battle_outcome_apply.dart \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/battle_overlay_component_test.dart

cd packages/map_runtime && /opt/homebrew/bin/flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/playable_map_game_whiteout_lite_test.dart \
  test/battle_overlay_component_test.dart

git clone --depth 1 https://github.com/smogon/pokemon-showdown.git /tmp/pokemon-showdown-audit

rg -n "BattleTurnResult\(|currentTurn|\.executions\b|\.statusEvents\b|\.volatileEvents\b|\.fieldEvents\b|\.switchEvents\b|\.timeline\b" packages

rg -n "playerPartySlotIndicesByLineupIndex|playerPartyIndex|RuntimeActiveBattleContext|applyRuntimeBattleOutcomeToGameState|timeline|buildBattleTurnLinesForOverlay" packages/map_runtime packages/map_battle

rg -n "runEvent\(|singleEvent\(|eachEvent\(|makeRequest\(|getRequests\(|faintQueue|requestState|activeRequest|forceSwitch|switchFlag|selfSwitch|sideConditions|slotConditions|pseudoWeather|terrain|weatherState|beforeTurn|residual" \
  /tmp/pokemon-showdown-audit/sim/battle.ts \
  /tmp/pokemon-showdown-audit/sim/battle-actions.ts \
  /tmp/pokemon-showdown-audit/sim/battle-queue.ts \
  /tmp/pokemon-showdown-audit/sim/side.ts \
  /tmp/pokemon-showdown-audit/sim/field.ts \
  /tmp/pokemon-showdown-audit/sim/pokemon.ts

rg -n "teleport|trickroom|protect|feint|hyperbeam|mustrecharge|solarbeam|selfSwitch|forceSwitch|sideCondition|slotCondition|terrain|pseudoWeather|weather" \
  /tmp/pokemon-showdown-audit/data/moves.ts \
  /tmp/pokemon-showdown-audit/data/conditions.ts \
  /tmp/pokemon-showdown-audit/sim/battle-actions.ts \
  /tmp/pokemon-showdown-audit/sim/battle.ts \
  /tmp/pokemon-showdown-audit/sim/side.ts \
  /tmp/pokemon-showdown-audit/sim/field.ts \
  /tmp/pokemon-showdown-audit/sim/pokemon.ts
```

## 27. Résultats réels de format / analyze / tests

### Format

- aucun `format` exécuté
- raison : audit-only, aucun fichier de code modifié

### Analyze

- `packages/map_battle`: vert
- `packages/map_runtime` ciblé : vert

### Tests

- `packages/map_battle`: vert (111 tests)
- `packages/map_runtime` ciblé : vert (89 tests)

## 28. État git utile final

Commandes réellement relancées après création du report :

```bash
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

Résultat observé :

```text
git status --short
?? reports/audit-showdown-parity-battle-engine.md

git diff --stat
[aucune sortie]

git ls-files --others --exclude-standard
reports/audit-showdown-parity-battle-engine.md
```

Lecture honnête :

- seul le report d'audit apparaît comme nouveau fichier non suivi ;
- aucun diff tracked n'a été produit sur du code ;
- cela est cohérent avec un lot strictement audit-only.

## 29. Checklist finale

- [x] j’ai audité le code réel avant de conclure
- [x] j’ai comparé au vrai code source Pokémon Showdown
- [x] j’ai distingué lecture de code / exécution / inférence
- [x] je n’ai modifié aucun fichier de code produit
- [x] je n’ai ajouté aucun test
- [x] je n’ai ouvert aucune feature hors scope
- [x] j’ai identifié les consommateurs significatifs de `BattleTurnResult`
- [x] j’ai distingué usages catégoriels légitimes et usages chronologiques
- [x] j’ai audité les seams runtime post-combat / lineup mapping
- [x] j’ai gardé une séparation claire entre moteur battle et runtime local
- [x] j’ai utilisé au moins un sub-agent d’audit/design exploitable
- [x] j’ai utilisé un reviewer séparé exploitable
- [x] j’ai intégré les remarques valides
- [x] je n’ai fait aucune écriture Git interdite
- [x] le report est audit-only
- [x] le report porte un regard critique sur le prompt
- [x] le report est franc sur les blockers structurels

## 30. Autocritique finale

Les limites principales de cet audit sont :

1. **Pas de diff comportemental automatisé contre Showdown.**  
   J'ai comparé du code et des tests, pas exécuté une batterie de scénarios miroir moteur contre moteur.

2. **Le périmètre Showdown lu est ciblé, pas exhaustif à 100%.**  
   J'ai lu les modules structurants et les fichiers de données les plus pertinents, pas la totalité du repo.

3. **La roadmap reste une proposition argumentée, pas une preuve.**  
   Elle est robuste au vu du code, mais reste une recommandation d'architecture.

4. **Je peux encore sous-estimer certains coûts de migration.**  
   En particulier le coût exact de passage d'un `battle_session.dart` centralisé à un modèle plus distribué.

5. **Je peux aussi sous-estimer certains progrès encore possibles sans refonte totale.**  
   Le reviewer a raison de rappeler que l'absence de queue ne bloque pas forcément chaque prochain lot singles borné.

## 31. Regard critique sur le prompt lui-même

Le prompt était globalement bien cadré, mais deux points méritent une correction de lecture :

1. Il risque de pousser vers une question trop absolue : “parité Showdown” peut faire oublier qu'il existe plusieurs niveaux de parité.
2. Il peut laisser croire que tout écart doit être lu comme un manque de simulateur, alors qu'une partie de la surface runtime locale n'a tout simplement pas d'analogue direct chez Showdown.

Le recadrage retenu dans ce report est :

- comparer très sérieusement le moteur battle et le handoff utile ;
- mais ne pas appeler “retard Showdown” une couche locale qui répond à un besoin d'intégration propre à PokeMap.

## 32. Contenu complet de tous les fichiers modifiés / créés / supprimés
