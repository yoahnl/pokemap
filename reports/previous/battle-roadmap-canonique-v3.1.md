# PokeMap — Battle Roadmap Canonique v3.1

## 1. Résumé exécutif honnête

### Verdict net sur l’état réel du moteur

Le moteur battle PokeMap est déjà réel. Il ne manque ni battle loop locale, ni runtime handoff, ni overlay branchée sur une timeline exploitable, ni trainer battles avec réserve, ni wild battles, ni capture minimale, ni write-back minimal, ni ordre priorité/vitesse/Trick Room local, ni PP/accuracy/crit minimal, ni dégâts simples avec STAB/effectiveness/immunités, ni statuts majeurs `par/brn/psn/tox`, ni volatiles bornés, ni `rain/sandstorm/trickRoom`, ni switch volontaire, ni forced replacement joueur, ni auto-switch ennemi, ni `Stealth Rock`, ni `Spikes`.

Le vrai problème n’est plus “il faut enfin un moteur”. Le vrai problème est :

- une causalité encore trop concentrée dans [`packages/map_battle/lib/src/battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:947) ;
- des seams déjà vivants, mais encore trop étroits et asymétriques ;
- une vérité canonique repo/doc/reports encore partiellement décalée ;
- un écart Showdown qui est désormais surtout structurel, pas seulement mécanique.

### Verdict net sur la trajectoire recommandée

La bonne trajectoire n’est pas un “reset canon” ni une reprise H3 immédiate. La bonne trajectoire est :

1. réaligner la vérité canonique à partir du code réel ;
2. durcir le slice déjà ouvert ;
3. consolider le scheduler local existant ;
4. ensuite seulement choisir la bonne branche structurante :
   - `R3` si la prochaine mécanique cible les conditions ;
   - `R4` si la prochaine mécanique cible les requests / replacements / targeting ;
5. rouvrir un **seul** H3 micro-slice après ces prérequis, pas avant.

### Verdict net sur H3

- `H3 large maintenant` : **non**
- `H3 micro-slice maintenant` : **non**
- `H3 micro-slice après R0 + R1 + R2 + branche pertinente` : **oui sous conditions**

Le repo ne justifie pas un refus métaphysique de H3. Il justifie un refus d’un H3 large, opportuniste, ou qui remettrait encore plus de branches spéciales dans `battle_session.dart`.

### Verdict net sur la place de l’IA / difficulté

L’IA / difficulté ne doit **pas** être fusionnée avec le tronc principal de convergence Showdown.

Le bon cadrage est :

- tronc principal battle : vérité, hardening, scheduler, conditions, contracts ;
- piste parallèle produit/gameplay : IA adverse et modulation de difficulté ;
- point d’intégration minimal côté `map_battle` : un seam de policy d’action adverse ;
- point interdit absolu : aucune heuristique de difficulté, aucun arbre de décision “boss”, aucun script trainer ne doit être recodé en dur dans `battle_session.dart`.

## 2. Pré-gates réellement exécutés + résultats

Pré-gates read-only exécutés :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
```

Résultat réellement observé **avant** création de ce report :

- `git status --short --untracked-files=all`
  - aucune sortie
- `git diff --stat`
  - aucune sortie
- `git ls-files --others --exclude-standard`
  - aucune sortie

Interprétation :

- le worktree était propre au début de ce passage v3.1 ;
- il n’y avait ni diff tracked, ni untracked visibles au moment des pré-gates relancés.

## 3. Méthode réellement suivie

### Ce qui a été lu

Battle core :

- [`packages/map_battle/lib/src/battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1)
- [`packages/map_battle/lib/src/battle_state.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:1)
- [`packages/map_battle/lib/src/battle_setup.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart:1)
- [`packages/map_battle/lib/src/battle_decision.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:1)
- [`packages/map_battle/lib/src/battle_queue.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:1)
- [`packages/map_battle/lib/src/battle_condition_engine.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_condition_engine.dart:1)
- [`packages/map_battle/lib/src/battle_field.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:1)
- [`packages/map_battle/lib/src/battle_status.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:1)
- [`packages/map_battle/lib/src/battle_volatile.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:1)
- [`packages/map_battle/lib/src/battle_move.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:1)
- [`packages/map_battle/lib/src/battle_action.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart:1)
- [`packages/map_battle/lib/src/battle_resolution.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart:1)
- [`packages/map_battle/lib/src/battle_type_chart.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:1)
- [`packages/map_battle/lib/src/battle_spikes.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart:1)
- [`packages/map_battle/lib/src/battle_stealth_rock.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart:1)
- [`packages/map_battle/lib/src/battle_topology.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_topology.dart:1)
- [`packages/map_battle/lib/map_battle.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/map_battle.dart:1)

Runtime :

- [`packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3040)
- [`packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:1)
- [`packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:48)
- [`packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:1)
- [`packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:1)
- [`packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:57)
- [`packages/map_runtime/lib/src/application/battle_start_request.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart:1)

Bootstrap / editor :

- [`packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:1)
- [`packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart:1)
- [`packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart:1)

Host / vérité produit :

- [`examples/playable_runtime_host/README.md`](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:1)
- [`examples/playable_runtime_host/golden_battle_slice/README.md`](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/README.md:1)
- [`examples/playable_runtime_host/lib/src/runtime_launch_save.dart`](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_launch_save.dart:1)
- tests host utiles sous `examples/playable_runtime_host/test/`

Historique / docs / reports :

- [`ROADMAP_FANGAME_RECALEE.md`](/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md:1)
- [`plan battle engine/plan-moteur-combat-projet.md`](/Users/karim/Project/pokemonProject/plan%20battle%20engine/plan-moteur-combat-projet.md:1)
- reports battle/runtime/golden-slice directement pertinents :
  - [`reports/phase-h1-stealth-rock-minimal-report.md`](/Users/karim/Project/pokemonProject/reports/phase-h1-stealth-rock-minimal-report.md:1)
  - [`reports/phase-h2-spikes-minimal-report.md`](/Users/karim/Project/pokemonProject/reports/phase-h2-spikes-minimal-report.md:1)
  - [`reports/phase-a-golden-battle-slice-report.md`](/Users/karim/Project/pokemonProject/reports/phase-a-golden-battle-slice-report.md:1)
  - [`reports/phase-battle-be1-bridge-hardening-report.md`](/Users/karim/Project/pokemonProject/reports/phase-battle-be1-bridge-hardening-report.md:1)
  - [`reports/phase-r1-lot-11-wild-battle-end-to-end-report.md`](/Users/karim/Project/pokemonProject/reports/phase-r1-lot-11-wild-battle-end-to-end-report.md:1)
  - [`reports/audit-showdown-parity-battle-engine.md`](/Users/karim/Project/pokemonProject/reports/audit-showdown-parity-battle-engine.md:1)
  - [`reports/battle-state-vs-showdown-audit.md`](/Users/karim/Project/pokemonProject/reports/battle-state-vs-showdown-audit.md:1)
  - [`reports/roadmap-battle-v3-review.md`](/Users/karim/Project/pokemonProject/reports/roadmap-battle-v3-review.md:1)

Référence Showdown locale :

- [`pokemon-showdown-master/sim/battle-queue.ts`](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:1)
- [`pokemon-showdown-master/sim/side.ts`](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:280)
- [`pokemon-showdown-master/sim/field.ts`](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/field.ts:1)
- [`pokemon-showdown-master/data/moves.ts`](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/moves.ts:17555)
- [`pokemon-showdown-master/test/sim/misc/hazards.js`](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:1)

### Ce qui a été relancé

Battle :

- `dart analyze` dans `packages/map_battle`
- `dart test` dans `packages/map_battle`

Runtime ciblé battle :

- `flutter analyze --no-pub` ciblé sur fichiers runtime battle + tests runtime battle utiles
- `flutter test` ciblé sur :
  - `runtime_battle_move_bridge_test.dart`
  - `runtime_battle_setup_mapper_test.dart`
  - `runtime_battle_outcome_apply_test.dart`
  - `runtime_battle_combatant_seed_builder_test.dart`
  - `battle_overlay_component_test.dart`
  - `wild_battle_end_to_end_flow_test.dart`
  - `phase_a_golden_battle_slice_smoke_test.dart`

Editor ciblé bootstrap :

- `flutter analyze --no-pub` ciblé sur seed + use cases bootstrap + test seed
- `flutter test test/pokemon_moves_bootstrap_seed_test.dart`

Host :

- `flutter test` ciblé sur :
  - `project_loader_page_test.dart`
  - `runtime_launch_save_test.dart`
  - `runtime_demo_party_seed_test.dart`
  - `phase_a_golden_slice_launch_test.dart`

### Sub-agents réellement utilisés

- `Laplace` : angle battle-core / architecture
- `Dirac` : angle comparaison Showdown
- `Pasteur` : angle runtime / bootstrap / host
- `Huygens` : reviewer séparé

### Reviewer séparé utilisé

- `Huygens`

### Plugin / skills réellement utilisés

Plugin explicitement demandé :

- `Superpowers`

Skills/fichiers de skill réellement consultés :

- `Superpowers:using-superpowers`
- `Superpowers:dispatching-parallel-agents`
- `Superpowers:verification-before-completion`
- `Superpowers:brainstorming`
- `Superpowers:writing-plans`

Utilisation réelle :

- `dispatching-parallel-agents` pour répartir les audits battle-core / Showdown / runtime-bootstrap ;
- `verification-before-completion` pour relancer les validations avant toute conclusion ;
- `brainstorming` et `writing-plans` ont été utilisés comme garde-fous de structuration, sans suivre leur workflow documentaire par défaut, car l’utilisateur a explicitement demandé un unique report en `reports/`.

## 4. État réel canonique du moteur aujourd’hui

### 4.1. Battle core

#### Ce qui existe déjà réellement

- vraie topologie `BattleSideId` + `BattleSlotRef` singles-bornée dans [`battle_topology.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_topology.dart:1)
- vrai état side-level avec actif + réserves + `hasStealthRock` + `spikesLayers` dans [`battle_state.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:523)
- vrai `BattleSetup` avec réserves joueur et ennemi dans [`battle_setup.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart:41)
- vrai request model `BattleDecisionRequest` avec `turnChoice`, `forcedReplacement`, `continue`, `wait` dans [`battle_decision.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:70)
- vraie queue locale de tour dans [`battle_queue.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:6)
- vrai `BattleConditionEngine` consommé par le moteur dans [`battle_condition_engine.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_condition_engine.dart:15)
- vrai pipeline d’ordre local avec priorité/vitesse/Trick Room dans [`battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1347)
- vrais seams accuracy / PP / crit / damage / STAB / type dans [`battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1700) et [`battle_type_chart.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:199)
- vrais statuts `par/brn/psn/tox` dans [`battle_status.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:16)
- vrais volatiles `protect/recharge/chargeThenStrike` dans [`battle_volatile.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:57)
- vrai field `rain/sandstorm/trickRoom` dans [`battle_field.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:91)
- vraies hazards `Stealth Rock` et `Spikes` dans [`battle_stealth_rock.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart:5) et [`battle_spikes.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart:4)
- vraie timeline ordonnée `BattleTurnResult.timeline` consommable par l’overlay dans [`battle_resolution.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart:110)

#### Ce qui est supporté mais local / borné

- `singles-only`, un slot actif par side, pas de grille multi-slot
- targeting transporté mais non générique
- queue réelle mais bornée aux familles utiles aujourd’hui
- condition engine réel mais borné à statuses/volatiles/field
- hazards réelles mais encore deux slices dédiées, pas une couche side-condition générale
- switch et replacement réels mais pas de vraie famille `selfSwitch/forceSwitch` de moves

#### Ce qui est fragile

- `Struggle` absent dans [`battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:924)
- fallback IA ennemi douteux vers `BattleActionRun()` dans [`battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:928)
- tie-break vitesse égale = joueur avant ennemi, volontairement déterministe, non Showdown-like dans [`battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1430)
- priorité de switch hardcodée localement à `6` dans [`battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1451)
- politique `double KO => victory` conservée par ordre “enemy d’abord” dans [`battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2022)
- ordre hazards `Stealth Rock puis Spikes` divergent de Showdown dans [`battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2284)
- compatibilités legacy dans [`battle_move.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:188) et [`battle_type_chart.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:203)

#### Ce qui est mensonger ou trop ancien dans les docs/reports

- les textes qui parlent encore d’absence de vraie queue, d’absence de vraie topologie ou de runtime battle non branché sont dépassés ;
- [`plan-moteur-combat-projet.md`](/Users/karim/Project/pokemonProject/plan%20battle%20engine/plan-moteur-combat-projet.md:188) décrit encore `_toBattleSetup()` comme placeholder, ce qui est faux ;
- [`phase-battle-be1-bridge-hardening-report.md`](/Users/karim/Project/pokemonProject/reports/phase-battle-be1-bridge-hardening-report.md:20) parle de `priority` et `critRatio` refusés, ce qui est dépassé.

### 4.2. Runtime battle

#### Ce qui existe déjà réellement

- `BattleStartRequest` wild/trainer réel dans [`battle_start_request.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart:35)
- vrai mapping runtime -> `BattleSetup` via [`runtime_battle_setup_mapper.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:48)
- vraie sélection de lineup joueur avec actif + réserves dans [`runtime_battle_setup_mapper.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:175)
- vrai bridge moves vers `BattleMoveData` dans [`runtime_battle_move_bridge.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:1)
- vrai seed builder qui charge species/learnset et filtre les moves non bridgeables dans [`runtime_battle_combatant_seed_builder.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:53)
- vrai write-back runtime sur outcome dans [`runtime_battle_outcome_apply.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:160)
- vrai whiteout-lite runtime dans [`runtime_battle_outcome_apply.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:57)
- vrai overlay piloté par `decisionRequest` et `timeline` dans [`battle_overlay_component.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:15) et [`battle_overlay_component.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:43)
- vraie boucle runtime battle dans [`playable_map_game.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3040)

#### Ce qui est supporté mais local / borné

- `allowCapture` décidé strictement au seam runtime, pas un système d’inventaire global ;
- write-back limité aux PV, au flag trainer defeated, à la capture minimale et au whiteout-lite ;
- le runtime reste volontairement plus strict que le moteur sur les moves supportés.

#### Ce qui est fragile

- hard-fail “no bridgeable move remaining after filtering” dans [`runtime_battle_combatant_seed_builder.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:118)
- runtime README obsolète : il continue à dire que le package ne gère pas wild encounters / combat / saves dans [`packages/map_runtime/README.md`](/Users/karim/Project/pokemonProject/packages/map_runtime/README.md:18)

### 4.3. Host battleable / golden slice

#### Ce qui existe déjà réellement

- host Flutter local qui charge un `project.json` réel dans [`examples/playable_runtime_host/README.md`](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:1)
- versioned golden slice battleable dans [`examples/playable_runtime_host/golden_battle_slice/README.md`](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/README.md:1)
- vraie save de lancement dans [`runtime_launch_save.dart`](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/lib/src/runtime_launch_save.dart:18)
- test host qui prouve la vraie save de lancement versionnée dans [`phase_a_golden_slice_launch_test.dart`](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart:9)
- smoke runtime qui prouve un vrai wild battle et un vrai trainer battle depuis le slice versionné dans [`phase_a_golden_battle_slice_smoke_test.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart:21)

#### Vérité produit correcte

- oui, il existe une vérité produit battleable versionnée ;
- non, cela ne signifie pas que tout projet fraîchement initialisé est génériquement battle-ready ;
- la vérité produit la plus honnête aujourd’hui est : **golden slice battleable versionné + host + save de lancement adjacente**.

### 4.4. Bootstrap / seed

#### Ce qui existe déjà réellement

- seed moves curaté, offline, versionné dans [`pokemon_moves_bootstrap_seed.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:14)
- bootstrap minimal d’un projet local Pokémon via [`initialize_pokemon_project_storage_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart:59)
- demo seed explicite et séparé via [`seed_pokemon_demo_data_use_case.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart:23)

#### Ce qui est honnête

- le seed ne prétend pas être tout Showdown ;
- le scaffold d’initialisation n’essaie pas de rendre tout projet frais immédiatement battle-ready ;
- le seed garde des entrées `catalogOnly` quand le moteur/runtime ne savent pas les exécuter honnêtement.

#### Ce qui reste décalé

- `trick_room` reste seedé `structuredPartial` alors que le bridge runtime accepte déjà son sous-ensemble exact ;
- `stealth_rock` et `spikes` sont encore rangés dans `_catalogOnlySeedMoves`, même si leur support bout à bout est réel.

### 4.5. Conclusion canonique froide

Photographie canonique :

- le repo n’est plus “avant les fondations” ;
- il n’est pas non plus proche d’une convergence Showdown large ;
- il a déjà un vrai slice battle/runtime/host/seed ;
- sa prochaine dette dominante est structurelle, pas la simple absence de mécaniques.

## 5. Matrice de support vs Pokémon Showdown

| Famille | État PokeMap réel | État Showdown utile | Écart réel | Niveau de proximité | Implication roadmap |
|---|---|---|---|---|---|
| request model | requests joueur-only, `slot 0`, `turnChoice/forcedReplacement/continue/wait` dans [`battle_decision.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:70) | state/request side-level plus riche dans [`sim/side.ts`](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:280) | structurel | local honnête mais simplifié | ne pas recréer le seam, le consolider puis l’élargir via `R4` |
| side / slot | deux sides canoniques, un slot actif par side, réserves réelles dans [`battle_state.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:523) | side system plus large, topologies de format variées | structurel mais borné | showdown-like local pour singles utile | la vieille histoire “pas de vraie topologie” est morte |
| targeting | taxonomie minimale `self/opponent/field/opponentSide/unspecified` dans [`battle_move.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:21) | targeting beaucoup plus riche | structurel | loin de Showdown | `R4` doit clarifier/élargir seulement si la mécanique le force |
| queue / scheduling | vraie queue locale de tour dans [`battle_queue.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:6) | queue centrale riche dans [`battle-queue.ts`](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:166) | structurel | local honnête mais simplifié | `R2` = consolidation du scheduler existant, pas création |
| statuses | `par/brn/psn/tox` réels dans [`battle_status.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:16) | système beaucoup plus large | mécanique + structurel | local honnête mais simplifié | `R3` pour élargir le cycle de vie des conditions si besoin |
| volatiles | `protect/recharge/chargeThenStrike` dans [`battle_volatile.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:57) | volatiles beaucoup plus riches | mécanique + structurel | local honnête mais simplifié | ne pas ouvrir de volatile riche avant `R3` |
| field / pseudoWeather | `rain/sandstorm/trickRoom` dans [`battle_field.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:91) | pseudoWeather/field callbacks génériques dans [`sim/field.ts`](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/field.ts:195) | structurel | local honnête mais simplifié | consolider avant d’élargir |
| hazards / side conditions | `Stealth Rock` + `Spikes` réels, ordre SR puis Spikes dans [`battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2284) | side conditions génériques, ordre hazards plus riche dans [`hazards.js`](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:86) | structurel + mécanique | loin de Showdown | ne pas continuer les hazards avant consolidation |
| switch / replacement / forced actions | switch volontaire, replacement forcé joueur, auto-switch ennemi, continuation de tour réelle | Showdown porte plus de formes de switch/forced action | structurel | showdown-like local sur petit scope | H3 forced switch/self-switch seulement après `R2` + `R4` |
| PP / accuracy / crit / damage | réels et testés, bornés | plus riches dans Showdown | surtout mécanique, un peu structurel | local honnête mais simplifié | ne pas les revendre comme “à créer” |
| runtime bridge | réel, strict, rejette explicitement hors scope | Showdown n’a pas ce seam produit local | n/a moteur, fort côté produit | très bon niveau de vérité produit | garder le runtime plus strict que le moteur |
| runtime write-back | réel mais étroit (PV, trainer flag, capture min, whiteout-lite) | pas comparable directement | produit/runtime | honnête mais borné | ne pas sur-vendre, hardening ciblé seulement |
| bootstrap/seed truth | curaté, offline, versionné, un peu sous-déclaré sur Trick Room | data exhaustive Showdown | produit/seed | honnête mais imparfait | `R0/R1` doc + label truth |
| host / product truth | golden slice battleable réel et lancé honnêtement | n/a | produit | très bon pour le scope | le canon produit existe déjà, pas de “reset” |

## 6. Tableau des blockers réels

| Blocker | Classe | Why it matters now | Bloque H3 ? | Bloque seulement H3 large ? | Fichiers principalement concernés |
|---|---|---|---|---|---|
| Causalité trop concentrée dans `battle_session.dart` | architecture | chaque mécanique supplémentaire risque de devenir une branche spéciale de plus | oui | oui | `battle_session.dart`, `battle_queue.dart`, `battle_condition_engine.dart`, `battle_resolution.dart` |
| Queue locale réelle mais trop petite pour des interruptions plus riches | scheduling | le repo a un scheduler, mais pas encore assez expressif pour absorber proprement certains futurs flows Showdown-like | oui pour H3 switch-centric | oui | `battle_queue.dart`, `battle_session.dart`, tests switch/hazards |
| Asymétrie conditions vs side conditions | architecture | statuses/volatiles/field vivent dans un seam dédié ; hazards vivent encore surtout dans la session | oui pour H3 condition-centric | oui | `battle_condition_engine.dart`, `battle_field.dart`, `battle_status.dart`, `battle_volatile.dart`, `battle_spikes.dart`, `battle_stealth_rock.dart`, `battle_session.dart` |
| Contracts request/targeting/replacement trop serrés | contracts | `forced switch`, `self switch`, side-targeting utile ne rentrent pas proprement | oui pour H3 switch-centric | oui | `battle_decision.dart`, `battle_move.dart`, `battle_action.dart`, `battle_resolution.dart`, `battle_topology.dart` |
| `Struggle` absent + fallback IA `Run` | produit | edge-cases honteux visibles, dette explicite mais réelle | non à lui seul | oui | `battle_session.dart`, tests battle session |
| Hard-fail “no bridgeable move” | runtime | contenu authored peut empêcher le démarrage du combat malgré un moteur battle réel | non pour core, oui produit | oui | `runtime_battle_combatant_seed_builder.dart`, `runtime_battle_setup_mapper.dart`, tests runtime |
| Seed/support labels légèrement décalés | bootstrap | crée une vérité support floue si non recadrée | non | oui | `pokemon_moves_bootstrap_seed.dart`, tests seed |
| Docs/reports historiques obsolètes | documentation | entretiennent une fausse photo du repo et peuvent fausser les priorités | non | non | `ROADMAP_FANGAME_RECALEE.md`, `plan-moteur-combat-projet.md`, `packages/map_runtime/README.md`, vieux reports battle |
| Absence de vrai seam IA/difficulté | produit / gameplay | toute montée en difficulté tomberait aujourd’hui dans `_chooseEnemyAction()` si on n’ouvre pas un seam propre | non pour Showdown, oui pour gameplay | oui | `battle_session.dart`, futur `battle_opponent_policy.dart`, `project_trainer.dart`, `runtime_battle_setup_mapper.dart` |

## 7. Roadmap battle canonique v3.1 corrigée

### 7.1. Principes directeurs de v3.1

1. ne jamais raconter comme “à créer” un seam déjà vivant ;
2. ne pas confondre consolidation d’un seam existant et invention d’une nouvelle fondation ;
3. garder le runtime plus strict que le moteur ;
4. garder le bootstrap plus honnête que flatteur ;
5. ne rouvrir H3 qu’après avoir prouvé qu’il tient dans les seams consolidés ;
6. séparer la piste IA/difficulté du tronc principal de convergence Showdown.

### 7.2. R0 — Truth Alignment

- **Statut** : prochaine étape officielle
- **Type** : piste documentation / canon / produit
- **But** : réaligner la vérité battle canonique sur le code, les tests, le runtime et le golden slice réels
- **Pourquoi maintenant** : le repo a dépassé une partie de son propre récit ; tant que le canon documentaire ment, les priorités techniques peuvent partir de travers
- **Ce que cette étape corrige**
  - roadmap/reports qui racontent encore un runtime battle en construction
  - confusion “golden slice battleable” vs “projet frais générique battle-ready”
  - sous-déclaration de certaines capacités réellement vivantes
- **Ce qu’elle ne doit surtout pas faire**
  - pas de nouvelle mécanique
  - pas de refonte battle-core
  - pas de faux “grand reset”
- **Dépendances/prérequis** : aucun
- **Rapprochement Showdown réel**
  - indirect mais important : une roadmap qui ne ment pas évite d’ouvrir de faux chantiers et permet de viser les vrais écarts structurants
- **Ce que ça ne fait pas semblant de rapprocher de Showdown**
  - ce n’est pas une phase d’architecture moteur
  - ce n’est pas une pseudo-progression technique déguisée
- **Critères de sortie**
  - photographie canonique battle/runtime/host/seed alignée sur le repo
  - vieux reports clairement déclassés ou recadrés
  - distinction officielle entre “slice battleable versionné” et “bootstrap projet”
- **Validations attendues**
  - aucune nouvelle validation code obligatoire
  - cohérence documentaire avec tests déjà verts
- **Risques si on la fait mal**
  - rester reset-heavy
  - recoller de vieux termes de phase sur des seams déjà dépassés

### 7.3. R1 — Battleable Slice Hardening

- **Statut** : obligatoire avant toute reprise riche
- **Type** : hardening + vérité produit
- **But** : durcir le slice déjà ouvert, sans l’élargir
- **Pourquoi maintenant** : les dettes visibles (`Struggle`, fallback IA, hard-fail move bridgeable, labels seed/support, doc truth) pollueraient toute mécanique plus riche
- **Ce que cette étape corrige**
  - edge-cases sales du flow actuel
  - points de honte explicites
  - quelques mensonges ou sous-déclarations de vérité produit
- **Ce qu’elle ne doit surtout pas faire**
  - pas de nouvelle famille de mécaniques
  - pas de nouvel hazard
  - pas de forced switch riche
  - pas d’abilities/items
- **Dépendances/prérequis** : R0
- **Rapprochement Showdown réel**
  - améliore l’honnêteté du slice et supprime des comportements trop locaux/honteux
- **Ce que ça ne fait pas semblant de rapprocher de Showdown**
  - ne crée ni queue générique, ni targeting riche, ni conditions générales
- **Critères de sortie**
  - stratégie explicite sur `Struggle` ou sur son absence assumée
  - stratégie explicite sur “no bridgeable move”
  - politique double KO documentée ou corrigée si décidé
  - labels seed/support réalignés là où le repo a changé
- **Validations attendues**
  - `dart analyze` + `dart test` battle
  - tests runtime ciblés
  - tests seed
  - tests host
- **Risques si on la fait mal**
  - transformer R1 en grand nettoyage vague
  - rouvrir déjà H3 sous couvert de hardening

### 7.4. R2 — Scheduler Consolidation

- **Statut** : obligatoire avant tout H3
- **Type** : consolidation d’un seam existant
- **But** : sortir le scheduler local du statut “réel mais trop absorbé par `BattleSession`”
- **Pourquoi maintenant** : le repo a déjà une queue et des interruptions ; le vrai besoin est de mieux séparer action choisie, action planifiée, effets insérés, checks et reprise
- **Ce que cette étape corrige**
  - surcharge de `battle_session.dart`
  - mélange entre calcul d’ordre, construction de queue, exécution de queue, interruptions et tail logic
- **Ce qu’elle ne doit surtout pas faire**
  - pas de clone de `sim/battle-queue.ts`
  - pas de doubles
  - pas d’event framework total
- **Dépendances/prérequis** : R1
- **Rapprochement Showdown réel**
  - rapproche PokeMap de la séparation Showdown entre choix, action résolue et scheduling
- **Ce que ça ne fait pas semblant de rapprocher de Showdown**
  - ne copie pas la taxonomie Showdown entière
  - ne prétend pas résoudre tous les futurs cas
- **Critères de sortie**
  - moins de causalité scheduling dans `battle_session.dart`
  - queue capable de porter plus explicitement les suites déjà réelles du moteur
  - tests hazards/switch/replacement toujours verts, sans heuristiques ajoutées côté overlay/runtime
- **Validations attendues**
  - battle tests ciblant order/queue/switch/hazards
  - runtime smoke golden slice inchangé
- **Risques si on la fait mal**
  - introduire une pseudo-queue abstraite morte
  - déplacer du code sans réduire réellement la densité de `battle_session.dart`

### 7.5. R3 — Condition Lifecycle Consolidation

- **Statut** : branche conditionnelle, requise avant H3 condition-centric
- **Type** : consolidation d’un seam existant
- **But** : traiter l’asymétrie entre `BattleConditionEngine` et les side conditions/hazards
- **Pourquoi maintenant** : statuses/volatiles/field ont déjà un foyer ; side-level mechanics vivent encore trop hors de ce cycle de vie
- **Ce que cette étape corrige**
  - branches ad hoc de conditions dans `battle_session.dart`
  - absence de cycle de vie side-level un peu plus cohérent
- **Ce qu’elle ne doit surtout pas faire**
  - pas de `runEvent` Showdown-like global
  - pas de bus générique
  - pas de framework universel “future proof”
- **Dépendances/prérequis** : R2
- **Rapprochement Showdown réel**
  - rapproche le moteur d’un vrai cycle de vie de conditions, sans copier l’architecture entière de Showdown
- **Ce que ça ne fait pas semblant de rapprocher de Showdown**
  - ne vise pas la parité globale de toutes les conditions Showdown
- **Critères de sortie**
  - side conditions supportées moins exceptionnelles structurellement
  - ajout d’une condition simple plus sain mécaniquement
  - `battle_session.dart` ne centralise plus autant la causalité conditionnelle
- **Validations attendues**
  - tests statuts/volatiles/field/hazards
  - overlay timeline inchangée ou plus honnête
- **Risques si on la fait mal**
  - faire exploser `battle_condition_engine.dart`
  - créer un framework mort de side conditions

### 7.6. R4 — Request / Targeting / Replacement Contract Widening

- **Statut** : branche conditionnelle ; peut remonter avant R3
- **Type** : widening de contrats existants
- **But** : élargir proprement ce qui est trop serré pour des mécaniques switch/forced-action plus Showdown-like
- **Pourquoi maintenant** : la prochaine mécanique utile peut demander des contracts plus riches avant des conditions plus riches
- **Ce que cette étape corrige**
  - targeting trop plat
  - requests trop serrées
  - replacement flows encore trop spécifiques
- **Ce qu’elle ne doit surtout pas faire**
  - pas de widening cosmétique “pour un jour”
  - pas de champs morts
  - pas de géant DTO ingérable
- **Dépendances/prérequis** : R2 minimum ; peut venir avant R3 si H3 visé touche switch/replacement/targeting
- **Rapprochement Showdown réel**
  - rapproche directement les seams utiles de `side`, `requestState`, `action choice` et targeting minimal Showdown
- **Ce que ça ne fait pas semblant de rapprocher de Showdown**
  - ne crée pas d’un coup tout le système d’actions/targets Showdown
- **Critères de sortie**
  - requests plus expressives sans casser le runtime
  - targeting minimal élargi sans devenir mensonger
  - flows `forced replacement` / `future forced switch` mieux modélisés
- **Validations attendues**
  - tests battle requests/targeting/switch/replacement
  - runtime tests de bridge/setup si contrats touchés
- **Risques si on la fait mal**
  - élargir des contrats sans consommation réelle
  - repousser la complexité dans le runtime pour cacher une dette battle-core

### 7.7. H3 — One Showdown-Leaning Micro-Slice

- **Statut** : fermé maintenant ; ouvrable sous conditions
- **Type** : enablement mécanique
- **But** : reprendre une seule mécanique riche, explicitement choisie pour sa valeur de convergence Showdown
- **Pourquoi maintenant** : pas maintenant ; seulement après `R0 + R1 + R2` et la branche structurante pertinente
- **Ce que cette étape corrige**
  - un écart mécanique ciblé devenu atteignable après consolidation
- **Ce qu’elle ne doit surtout pas faire**
  - pas “on rajoute un move cool”
  - pas “encore un hazard”
  - pas “un peu de tout”
- **Dépendances/prérequis**
  - `R0` et `R1` obligatoires
  - `R2` obligatoire
  - `R4` obligatoire si H3 touche forced switch / self switch / phazing
  - `R3` obligatoire si H3 touche status/volatile/side condition riche
- **Rapprochement Showdown réel**
  - oui, mais uniquement si le choix du micro-slice force une amélioration structurelle réelle
- **Ce que ça ne fait pas semblant de rapprocher de Showdown**
  - ne pas confondre “ajout d’un move supporté” et “convergence moteur”
- **Critères de sortie**
  - un seul micro-slice
  - support honnête bout à bout bridge/runtime/overlay/seed
  - pas de dette ad hoc disproportionnée ajoutée dans `battle_session.dart`
- **Validations attendues**
  - tests battle ciblés
  - tests runtime bridge/setup/write-back concernés
  - smoke golden slice si impact produit
- **Risques si on la fait mal**
  - empiler un troisième hazard ou un cas spécial de plus
  - appeler “Showdown-like” un simple bricolage local

## 8. Précision fichier par fichier pour chaque étape

### 8.1. R0 — Truth Alignment

#### Fichiers probablement à modifier

- [`ROADMAP_FANGAME_RECALEE.md`](/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md:1)
- [`packages/map_runtime/README.md`](/Users/karim/Project/pokemonProject/packages/map_runtime/README.md:1)
- [`plan battle engine/plan-moteur-combat-projet.md`](/Users/karim/Project/pokemonProject/plan%20battle%20engine/plan-moteur-combat-projet.md:1)
- reports battle historiques directement contredits par le code

#### Pourquoi ces fichiers

- ils portent encore une photo partiellement fausse du runtime battle, du handoff ou de l’état réel du moteur.

#### Type de modification attendu

- déclassification explicite
- recadrage des claims obsolètes
- documentation canonique de l’état réel

#### Tests à ajouter/adapter

- aucun test code
- éventuellement un check documentaire interne si l’équipe en veut un, mais ce n’est pas requis pour la battle roadmap

#### Fichiers à ne surtout pas toucher à ce stade

- `battle_session.dart`
- `battle_queue.dart`
- `battle_condition_engine.dart`
- runtime bridge code

R0 n’est pas un prétexte de refactor.

### 8.2. R1 — Battleable Slice Hardening

#### Fichiers probablement à modifier

- [`packages/map_battle/lib/src/battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:901)
- [`packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:53)
- [`packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart`](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:602)
- tests battle ciblés sur flow/edge-cases
- tests runtime ciblés setup/seed builder
- tests seed

#### Pourquoi ces fichiers

- `battle_session.dart` porte aujourd’hui `Struggle`, fallback IA et double KO policy
- `runtime_battle_combatant_seed_builder.dart` porte le hard-fail “no bridgeable move”
- `pokemon_moves_bootstrap_seed.dart` porte les labels/support claims décalés

#### Type de modification attendu

- durcir explicitement des règles déjà visibles
- rendre certains choix locaux plus honnêtes ou mieux documentés
- réaligner labels/support truth

#### Tests à ajouter/adapter

- tests battle pour `Struggle` ou absence assumée
- tests runtime pour “aucun move bridgeable”
- tests seed pour `trick_room` et support claims

#### Fichiers à ne surtout pas toucher à ce stade

- `battle_queue.dart`
- `battle_condition_engine.dart`
- `battle_decision.dart`

R1 ne doit pas dériver vers un chantier de fondation.

### 8.3. R2 — Scheduler Consolidation

#### Fichiers probablement à modifier

- [`packages/map_battle/lib/src/battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:932)
- [`packages/map_battle/lib/src/battle_queue.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:1)
- [`packages/map_battle/lib/src/battle_resolution.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart:12)
- potentiellement un nouveau fichier interne du type `packages/map_battle/lib/src/battle_turn_plan.dart` ou `battle_planned_action.dart` **si et seulement si** cela réduit réellement la densité de `battle_session.dart`
- tests :
  - `battle_queue_test.dart`
  - `battle_switch_test.dart`
  - `battle_stealth_rock_test.dart`
  - `battle_spikes_test.dart`

#### Pourquoi ces fichiers

- `battle_session.dart` concentre aujourd’hui construction + exécution + interruption de queue ;
- `battle_queue.dart` existe déjà et doit être consolidée, pas remplacée ;
- `battle_resolution.dart` porte la restitution observable du turn scheduling.

#### Type de modification attendu

- séparer plus clairement :
  - action choisie
  - action planifiée
  - exécution
  - checks post-résolution
  - reprise après interruption

#### Tests à ajouter/adapter

- tests de reprise de queue après forced replacement
- tests de chronologie ordonnée
- tests d’ordre/resolution sans heuristique overlay

#### Fichiers à ne surtout pas toucher à ce stade

- `runtime_battle_move_bridge.dart`
- `runtime_battle_setup_mapper.dart`
- `pokemon_moves_bootstrap_seed.dart`

R2 est battle-core, pas runtime/seed.

### 8.4. R3 — Condition Lifecycle Consolidation

#### Fichiers probablement à modifier

- [`packages/map_battle/lib/src/battle_condition_engine.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_condition_engine.dart:15)
- [`packages/map_battle/lib/src/battle_field.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:1)
- [`packages/map_battle/lib/src/battle_status.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:1)
- [`packages/map_battle/lib/src/battle_volatile.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:1)
- [`packages/map_battle/lib/src/battle_spikes.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart:1)
- [`packages/map_battle/lib/src/battle_stealth_rock.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart:1)
- [`packages/map_battle/lib/src/battle_session.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2284)
- tests de conditions/hazards

#### Pourquoi ces fichiers

- ce sont eux qui portent aujourd’hui les familles de conditions réellement supportées ;
- l’asymétrie la plus visible est entre `BattleConditionEngine` et les hazards side-level.

#### Type de modification attendu

- expliciter un cycle de vie side-level plus propre
- réduire le nombre de branches conditionnelles directes dans `battle_session.dart`
- garder des slices dédiées tant que c’est plus honnête qu’un faux framework

#### Tests à ajouter/adapter

- tests de fin de tour croisée
- tests d’interaction field/status/hazard déjà supportés
- tests de timeline pour événements conditionnels

#### Fichiers à ne surtout pas toucher à ce stade

- `runtime_battle_setup_mapper.dart`
- `runtime_battle_outcome_apply.dart`
- host files

R3 ne doit pas glisser côté runtime/host.

### 8.5. R4 — Request / Targeting / Replacement Contract Widening

#### Fichiers probablement à modifier

- [`packages/map_battle/lib/src/battle_decision.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:70)
- [`packages/map_battle/lib/src/battle_move.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:21)
- [`packages/map_battle/lib/src/battle_action.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_action.dart:136)
- [`packages/map_battle/lib/src/battle_resolution.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart:181)
- [`packages/map_battle/lib/src/battle_topology.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_topology.dart:1)
- [`packages/map_battle/lib/src/battle_state.dart`](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:523)
- impacts runtime possibles si contrats battle élargis :
  - [`runtime_battle_move_bridge.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:1)
  - [`runtime_battle_setup_mapper.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:48)
  - [`battle_overlay_component.dart`](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:31)

#### Pourquoi ces fichiers

- ce sont eux qui portent déjà requests, target semantics, action semantics et restitution observable ;
- si H3 vise forced switch կամ self switch, c’est ici que le vrai plafond se situe.

#### Type de modification attendu

- requests plus riches mais encore vivantes
- targeting side/combatant/field moins ambigu
- actions de replacement/forced action plus explicites
- élargissement du runtime seulement si le battle-core consomme réellement ces nouveaux contrats

#### Tests à ajouter/adapter

- tests requests/choices/illegal choices
- tests targeting observable
- tests runtime bridge si contrats target changent

#### Fichiers à ne surtout pas toucher à ce stade

- `pokemon_moves_bootstrap_seed.dart` sauf si un nouveau claim de support devient honnête
- docs historiques hors besoin direct

### 8.6. H3 — One Showdown-Leaning Micro-Slice

#### Fichiers probablement à modifier selon le candidat

##### Si H3 = forced switch / phazing minimal

- `battle_action.dart`
- `battle_decision.dart`
- `battle_queue.dart`
- `battle_session.dart`
- `battle_resolution.dart`
- `runtime_battle_move_bridge.dart`
- `battle_overlay_component.dart`
- tests switch/replacement/runtime bridge

##### Si H3 = self switch minimal

- `battle_action.dart`
- `battle_queue.dart`
- `battle_session.dart`
- `battle_resolution.dart`
- `runtime_battle_move_bridge.dart`
- tests move bridge + scheduling + write-back mapping

##### Si H3 = status/volatile plus riche

- `battle_condition_engine.dart`
- `battle_status.dart` or `battle_volatile.dart`
- `battle_session.dart`
- `battle_resolution.dart`
- runtime bridge if new supported move effect enters

##### Si H3 = hazard interaction minimale

- **mauvaise idée avant R3**
- ne pas ouvrir tant que side-condition lifecycle reste trop asymétrique

#### Fichiers à ne surtout pas toucher avant que le candidat soit choisi

- tout le runtime/seed/host “au cas où”
- `project_trainer.dart` pour des choses sans lien avec le candidat

## 9. Ordre officiel recommandé

### 9.1. Tronc obligatoire

Ordre officiel recommandé :

1. `R0 — Truth Alignment`
2. `R1 — Battleable Slice Hardening`
3. `R2 — Scheduler Consolidation`

Ce tronc est **obligatoire** avant toute reprise riche.

### 9.2. Branches conditionnelles

Après `R2`, l’ordre n’est **pas** une chaîne rigide `R3 puis R4`.

Il faut choisir la branche selon la mécanique visée.

#### Si la prochaine mécanique visée est switch/replacement-centric

Ordre :

1. `R4`
2. `H3`
3. `R3` plus tard si nécessaire

Cas typiques :

- forced switch / phazing minimal
- self switch minimal
- future replacement contracts plus riches

#### Si la prochaine mécanique visée est condition-centric

Ordre :

1. `R3`
2. `H3`
3. `R4` plus tard si nécessaire

Cas typiques :

- status/volatile plus riche
- side condition plus riche

### 9.3. Réponses nettes aux questions d’ordre

- `R0 puis R1 sont-ils obligatoires avant toute reprise riche ?`
  - **oui**
- `R2 doit-il vraiment passer avant R3 ?`
  - **oui dans la version canonique recommandée**, parce que le scheduler actuel est déjà vivant mais trop absorbé par `BattleSession`
- `R4 peut-il remonter avant R3 ?`
  - **oui**
- `Dans quels cas ?`
  - **si le prochain H3 visé touche forced switch, self switch, phazing, replacement ou targeting**

## 10. Décision explicite sur H3

### H3 large maintenant

- **non**

Raison :

- le repo a déjà assez de réalité pour ne pas bricoler un H3 large sur une base encore trop concentrée ;
- un H3 large aujourd’hui retransformerait `battle_session.dart` en point d’absorption universel.

### H3 micro-slice maintenant

- **non**

Raison :

- le slice actuel doit être durci ;
- le scheduler actuel doit être consolidé avant toute nouvelle mécanique riche ;
- sans `R2`, même un micro-slice “raisonnable” risque de tomber dans de nouveaux cas spéciaux.

### H3 micro-slice après consolidation

- **oui sous conditions**

Conditions minimales :

- `R0` fait
- `R1` fait
- `R2` fait
- branche pertinente faite (`R3` ou `R4`)
- candidat unique et borné
- support honnête runtime/overlay/seed

### Candidats H3 plausibles

#### Candidat recommandé 1 — forced switch / phazing minimal

Pourquoi :

- très bonne valeur de convergence Showdown ;
- force la vérité sur replacement, interruption et planification ;
- ne peut pas être correctement ajouté sans faire apparaître les vrais seams.

Pré-requis :

- `R2` + `R4`

#### Candidat recommandé 2 — self switch minimal

Pourquoi :

- très bon révélateur de scheduling et de write-back lineup ;
- force moins de conditions que certains status riches.

Pré-requis :

- `R2` + `R4`

#### Candidat acceptable mais secondaire — expansion d’un status/volatile plus riche

Pourquoi :

- valable seulement si le vrai objectif suivant est la consolidation conditions.

Pré-requis :

- `R2` + `R3`

### Candidats H3 explicitement déconseillés

- hazard interaction minimale avant `R3`
- nouveau hazard juste parce que H1/H2 existent déjà
- status riche avant consolidation du cycle de vie des conditions
- tout H3 “move cool” sans valeur structurelle

## 11. Piste IA / difficulté des combats

### 11.1. Est-ce que la difficulté IA doit faire partie de la roadmap battle principale ?

- **non**

Elle doit exister comme **piste parallèle produit/gameplay**, avec un petit seam battle-core propre, mais elle ne doit pas devenir un prérequis du tronc Showdown.

### 11.2. À quel moment ouvrir cette piste ?

Moment recommandé :

- après `R1`
- idéalement après `R2`

Pourquoi :

- avant `R1`, le slice actuel a encore trop de dettes de hardening ;
- avant `R2`, injecter une IA plus riche dans `battle_session.dart` aggraverait exactement le mauvais problème.

### 11.3. Quels seams doivent exister pour moduler la difficulté proprement ?

Seam minimal recommandé :

- un contrat battle-core du type `BattleOpponentPolicy` ou `BattleAiPolicy`
- une entrée runtime/product du type `battlePolicyId` ou `difficultyProfileId`
- un mapping runtime qui choisit la policy à injecter selon le trainer / wild context / script override

### 11.4. Où cette future difficulté devrait vivre

#### Battle core

Probable nouveau fichier :

- `packages/map_battle/lib/src/battle_opponent_policy.dart`

Responsabilité :

- transformer un état battle lisible et les actions légales en `BattleAction`
- aucune logique de rendu, aucun accès runtime, aucune lecture de projet

`battle_session.dart` :

- doit seulement appeler ce seam
- ne doit pas contenir la logique de difficulté elle-même

#### Runtime / product

Probables fichiers concernés quand cette piste ouvrira :

- `packages/map_core/lib/src/models/project_trainer.dart`
  - ajout explicite futur d’un identifiant de policy/difficulty
- `packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart`
  - mapping trainer/wild context -> opponent policy config
- `packages/map_runtime/lib/src/application/battle_start_request.dart`
  - **ne pas** y mettre la difficulté par défaut ; n’autoriser un override que pour un vrai cas scripté

### 11.5. Ce qu’il ne faut surtout pas mettre dans `battle_session.dart`

- arbres de décision de difficulté
- scripts de boss
- heuristiques trainer spécifiques
- pondérations produit/content
- logique d’équilibrage

`battle_session.dart` doit rester moteur de résolution, pas cerveau de design produit.

### 11.6. Niveaux de difficulté architecturablement propres

#### Facile

- policy qui choisit une action légale simple
- peu ou pas d’évaluation tactique

#### Normal

- policy heuristique locale
- priorise dégâts simples, KO probables, et évite les moves inutiles quand l’information est disponible

#### Difficile

- policy heuristique plus riche
- tient compte de la vitesse, des dégâts probables, des switches conservateurs, de l’état du terrain/hazards supportés

#### Boss / trainer scripté

- séquences ou priorités contrôlées par une policy spéciale ou un script externe
- toujours via une policy qui retourne des `BattleAction` légales
- jamais via des branches en dur dans `battle_session.dart`

## 12. Critique explicite du prompt et de la roadmap

### Ce qui est juste dans ton cadrage

- tu imposes la bonne hiérarchie de vérité ;
- tu interdis les faux supports ;
- tu obliges à regarder runtime, bootstrap, host et golden slice ;
- tu interdis de raconter comme “à construire” des seams déjà vivants ;
- tu sépares correctement l’idée de convergence Showdown et l’idée de vérité produit.

### Ce qui est discutable

- le mot “roadmap battle” peut pousser à sur-centrer `map_battle` alors qu’une partie de la vérité la plus utile vit dans runtime/host/seed ;
- la tentation “v3.1 corrigée = ordre fixe parfait” est discutable : après `R2`, l’ordre dépend vraiment de la mécanique visée ;
- le cadrage sur l’IA/difficulté peut pousser à vouloir la faire rentrer dans le tronc battle principal alors que ce serait une erreur.

### Ce qui est déjà dépassé par le repo

- tout récit qui sous-estime la battleabilité réelle du golden slice ;
- tout récit qui parle encore du runtime handoff comme d’un placeholder ;
- tout récit qui nie l’existence d’une vraie queue locale ou d’un vrai condition engine.

### Ce qui pourrait pousser vers une mauvaise roadmap si suivi aveuglément

- croire qu’il faut “resetter le canon” au lieu de réaligner la vérité ;
- croire que `R2`, `R3`, `R4` doivent former une chaîne rigide ;
- croire qu’un H3 micro-slice est interdit par principe, au lieu d’être conditionné par les seams ;
- croire que l’IA/difficulté doit être branchée dans `battle_session.dart`.

## 13. Retour des sub-agents

### Laplace — battle-core / architecture

Ce qu’il a dit :

- requests, queue, continuation de tour, condition engine, topologie et hazards existent déjà réellement ;
- la vraie dette est la concentration dans `battle_session.dart` ;
- l’IA/difficulty doit sortir vers une policy dédiée ;
- `R1` puis consolidation scheduler puis conditions puis contracts est la bonne logique globale.

Ce que je retiens :

- le battle-core n’a plus besoin d’une histoire “pré-fondations” ;
- `battle_session.dart` est le vrai centre de dette ;
- futur seam IA doit être externe.

Ce que je nuance :

- l’ordre `conditions puis contracts` n’est pas toujours vrai ; il dépend du H3 visé.

### Dirac — comparaison Showdown

Ce qu’il a dit :

- le repo a déjà une queue locale et un condition engine réels ;
- `R2` et `R3` sont des consolidations, pas des créations ;
- `R4` est le levier le plus Showdown-convergent si la prochaine mécanique est switch/replacement-centric ;
- la chaîne rigide `R2 -> R3 -> R4` est le plus gros défaut de la v3 précédente.

Ce que je retiens :

- l’ordre après `R2` doit être piloté par la mécanique cible ;
- `R4` peut remonter avant `R3`.

### Pasteur — runtime / bootstrap / host

Ce qu’il a dit :

- le runtime handoff, l’overlay, le write-back, le golden slice et la vérité host sont déjà réels ;
- la vraie dette côté runtime/seed n’est pas “plomberie manquante”, mais honnêteté au seam et startability ;
- `plan-moteur-combat-projet.md` et des portions de `ROADMAP_FANGAME_RECALEE.md` sont obsolètes.

Ce que je retiens :

- R0 doit être un réalignement de vérité, pas un reset ;
- la distinction “golden slice battleable” vs “projet frais générique” doit être officielle.

### Désaccords utiles entre sub-agents

- aucun désaccord de fond sur l’existence des seams ;
- principal désaccord utile : degré de rigidité du refus de H3.

Ma synthèse :

- large H3 maintenant : non
- micro-H3 après consolidation : oui sous conditions

## 14. Retour du reviewer séparé

Reviewer :

- `Huygens`

### Findings concrets

1. toute formulation `reset-heavy` du type “canon reset” part d’une base fausse, car le repo a déjà un canon battleable versionné ;
2. toute roadmap qui prétend encore “créer” scheduler, conditions ou contracts contredit le code réel ;
3. l’ordre fixe `scheduler -> conditions -> contracts` est suspect et trop théorique ;
4. le refus absolu de H3 est excessif ; seul un refus de H3 large est solidement justifié ;
5. l’IA/difficulty est une piste séparée produit/policy, pas une fondation requise du moteur.

### Objections retenues

- rejet de toute formulation `reset-heavy`
- rejet de toute narration “on va enfin créer la queue / le condition engine / les contracts”
- rejet d’un `H3 no-now` absolu

### Ce qui a été écarté

- l’idée qu’un micro-H3 pourrait rouvrir dès maintenant

Pourquoi :

- même si ce n’est pas métaphysiquement impossible, la recommandation canonique la plus saine reste `R0 + R1 + R2` avant de rouvrir quoi que ce soit.

## 15. Autocritique finale

Ce que je n’ai pas pu vérifier complètement :

- je n’ai pas fait de harness automatisé de comparaison comportementale battle-by-battle avec Showdown ;
- je n’ai pas analysé tous les tests non battle du monorepo, seulement les surfaces utiles au sujet.

Ce qui reste inféré :

- la forme exacte d’un futur seam `BattleOpponentPolicy` ;
- le détail du meilleur candidat H3 final entre forced switch et self switch dépendra du coût réel de `R4`.

Ce qui pourrait encore être faux dans mon jugement :

- la priorité relative fine entre `R3` et `R4` peut bouger si une contrainte produit forte impose un H3 très précis ;
- une partie de la stratégie IA/difficulty dépendra du niveau de scriptabilité que l’équipe voudra réellement côté trainers/boss.

## 16. Commandes réellement lancées

Pré-gates :

```bash
git status --short --untracked-files=all
git diff --stat
git ls-files --others --exclude-standard
git status --short --untracked-files=all | cat -vet
git ls-files --others --exclude-standard | cat -vet
```

Validations :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart analyze
cd /Users/karim/Project/pokemonProject/packages/map_battle && dart test

cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze --no-pub \
  lib/src/presentation/flame/playable_map_game.dart \
  lib/src/presentation/flame/battle_overlay_component.dart \
  lib/src/application/runtime_battle_setup_mapper.dart \
  lib/src/application/runtime_battle_move_bridge.dart \
  lib/src/application/runtime_battle_combatant_seed_builder.dart \
  lib/src/application/runtime_battle_outcome_apply.dart \
  lib/src/application/battle_start_request.dart \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub \
  lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart \
  lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart \
  lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart \
  test/pokemon_moves_bootstrap_seed_test.dart

cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test \
  test/pokemon_moves_bootstrap_seed_test.dart

cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host && flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

Inspection read-only ciblée :

```bash
rg --files -g 'ROADMAP*' -g 'reports/**' -g 'docs/**' -g 'plan*'
rg -n ...
nl -ba ... | sed -n ...
ls reports | rg 'battle|roadmap'
```

Sub-agents / reviewer :

- dispatch parallèle via messages aux agents `Laplace`, `Dirac`, `Pasteur`, `Huygens`

## 17. Résultats réellement obtenus

### Pré-gates initiaux

- `git status --short --untracked-files=all`
  - aucune sortie
- `git diff --stat`
  - aucune sortie
- `git ls-files --others --exclude-standard`
  - aucune sortie

### Battle

- `dart analyze`
  - `Analyzing map_battle...`
  - `No issues found!`
- `dart test`
  - `+160: All tests passed!`

### Runtime ciblé battle

- `flutter analyze --no-pub ...`
  - `Analyzing 14 items...`
  - `No issues found!`
- `flutter test ...`
  - `All tests passed!`

### Editor ciblé bootstrap

- `flutter analyze --no-pub ...`
  - `Analyzing 4 items...`
  - `No issues found!`
- `flutter test test/pokemon_moves_bootstrap_seed_test.dart`
  - `All tests passed!`

### Host

- `flutter test ...`
  - `All tests passed!`

### Bruit observé mais non bloquant

- plusieurs commandes Flutter ont brièvement affiché `Waiting for another flutter command to release the startup lock...`
- une bannière `A new version of Flutter is available!` est apparue

Ces deux signaux sont de l’outillage, pas des problèmes du repo.

## 18. État git final utile

Après création de ce report :

- nouveau fichier créé :
  - `reports/battle-roadmap-canonique-v3.1.md`
- aucun fichier source battle/runtime/editor/host modifié
- aucune écriture Git effectuée

## 19. Checklist finale

- ai-je utilisé le code réel comme source de vérité principale ? oui
- ai-je relancé réellement les validations utiles ? oui
- ai-je intégré runtime battle, host, golden slice et bootstrap ? oui
- ai-je refusé de raconter comme “à construire” des seams déjà vivants ? oui
- ai-je séparé écarts structurels et écarts mécaniques vis-à-vis de Showdown ? oui
- ai-je distingué tronc obligatoire et branches conditionnelles ? oui
- ai-je pris une position nette sur H3 ? oui
- ai-je pris une position nette sur l’IA/difficulté ? oui
- ai-je utilisé des sub-agents ? oui
- ai-je fait une review séparée ? oui
- ai-je gardé le code source strictement read-only ? oui
- ai-je limité l’écriture à un seul report markdown ? oui

## 20. Décision finale nette

### Décision

**adoptable telle quelle**

Cette décision vaut pour **la v3.1 proposée dans ce report**, pas pour la v3 précédente.

### Version v3.1 finale recommandée

La v3.1 finale recommandée est :

1. `R0 — Truth Alignment`
2. `R1 — Battleable Slice Hardening`
3. `R2 — Scheduler Consolidation`
4. puis branche conditionnelle :
   - `R4` avant `H3` si H3 est switch/replacement-centric
   - `R3` avant `H3` si H3 est condition-centric
5. `H3 — One Showdown-Leaning Micro-Slice`

Piste parallèle séparée :

- `AI/Difficulty Track` après `R1`, idéalement après `R2`, via seam de policy externe

### Prochaine vraie étape officielle

**R0 — Truth Alignment**

Raison :

- c’est la seule étape qui permet de nettoyer immédiatement la dette de représentation sans réécrire l’histoire ni ouvrir un faux chantier technique ;
- elle évite que la suite parte d’une photo erronée du repo ;
- elle prépare proprement `R1`, qui est la première vraie étape technique obligatoire.
