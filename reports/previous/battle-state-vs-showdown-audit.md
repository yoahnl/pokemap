# Battle State vs Showdown Audit

Date de l'audit: 2026-04-18

Périmètre audité:
- dépôt local `/Users/karim/Project/pokemonProject`
- battle core: `packages/map_battle/**`
- runtime battle handoff / overlay / write-back: `packages/map_runtime/**`
- bootstrap seed utile: `packages/map_editor/**`
- host de référence: `examples/playable_runtime_host/**`
- clone local Showdown: `/Users/karim/Project/pokemonProject/pokemon-showdown-master`

Règle de vérité suivie pendant tout l'audit:
1. code réel
2. tests réellement exécutés et verts
3. runtime réellement branché et smoke-testé
4. bootstrap/seed réellement versionné
5. reports / roadmap historiques

## 1. Résumé exécutif honnête

Le moteur battle PokeMap n'est plus un prototype vide ni un faux seam de combat. Le dépôt exécute aujourd'hui un vrai sous-ensemble battle `singles-only`, avec un seul slot actif par side mais avec réserves réelles, trainer battles multi-Pokémon, vraie résolution de tour, vrai runtime handoff, vraie overlay, vraie capture minimale, vrai write-back minimal, et une golden slice réellement lançable.

En revanche, ce moteur reste loin de Pokémon Showdown au sens moteur. Il n'est pas simplement "un peu incomplet"; il manque encore les couches structurantes qui font la profondeur Showdown-like:
- request model multi-side riche
- scheduler / queue générique
- conditions génériques side / slot / field / volatile
- targeting plus riche que `self/opponent/field/opponentSide`
- familles de mécaniques largement au-delà du sous-ensemble actuellement ouvert

Le support réel aujourd'hui est honnête sur un slice étroit:
- ordre priorité / vitesse / Trick Room
- PP / accuracy / crit minimaux
- dégâts simples + STAB + type chart + immunités
- statuts majeurs `par/brn/psn/tox`
- volatiles `protect`, recharge, charge puis frappe
- weather `rain/sandstorm`
- pseudoWeather `trickRoom`
- switch volontaire
- remplacement forcé joueur
- auto-switch ennemi
- hazards `Stealth Rock` et `Spikes`
- timeline observable
- `Run` et `Capture` en wild
- bridge runtime
- bootstrap curaté battleable

La vérité produit actuelle est globalement bonne sur la tranche ouverte. Le runtime live ne promet pas plus que le moteur sur les moves supportés; au contraire, il refuse explicitement beaucoup de choses hors scope dans [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:816). Les mensonges restants sont surtout documentaires, de classement seed, ou des reports historiques désormais dépassés par le code.

La roadmap actuelle ne colle plus proprement au repo pour la battle loop minimale. `ROADMAP_FANGAME_RECALEE.md` parle encore de bridge runtime -> battle, combat sauvage réel, capture minimale et whiteout-lite comme de futures étapes, alors que ces slices existent déjà dans le repo et sont testées. Elle reste utile comme vision, mais elle n'est plus une photo canonique de l'état battle/runtime.

Décision nette: `H3 maintenant = non`.

Raison:
- oui, un micro-lot supplémentaire pourrait théoriquement encore rentrer dans les seams actuels;
- non, ce n'est pas la bonne décision canonique à ce stade;
- l'état réel du repo appelle d'abord une consolidation: canon documentaire, vérité bootstrap, clarification de la trajectoire battle, stabilisation des seams avant d'ajouter une nouvelle mécanique.

## 2. Verdict global

### 2.1. Etat réel du moteur battle

Etat réel:
- moteur `singles-only`
- un slot actif par side
- réserves réelles des deux côtés
- trainer battles multi-Pokémon supportées via lineup active + reserve
- vraie résolution de tour locale
- vraie chaîne runtime -> battle -> runtime

Ce que le moteur est réellement:
- un slice battle local honnête, testable, jouable, intégré au produit
- un moteur encore très centralisé, avec une dette de généralisation claire

Ce qu'il n'est pas:
- un moteur proche de la profondeur structurelle de Showdown
- un moteur générique de conditions / events / scheduling
- un moteur prêt à absorber sans friction une nouvelle famille riche de mécaniques

### 2.2. Proximité réelle avec Showdown sur le périmètre utile

Proximité utile:
- suffisante pour parler d'un sous-ensemble "Showdown-like" local sur quelques familles concrètes
- insuffisante pour parler de convergence Showdown forte

Le delta avec Showdown n'est pas "quelques moves manquants". Le delta majeur est architectural:
- Showdown a un vrai modèle `Side` riche, des `request` riches, une vraie `BattleQueue`, des `sideConditions` et `pseudoWeather` génériques, et un modèle d'actions / callbacks beaucoup plus large dans [sim/battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:1), [sim/side.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:280) et [sim/field.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/field.ts:186)
- PokeMap a des contrats honnêtes mais étroits, et un `battle_session.dart` qui porte encore une grande partie de la causalité

### 2.3. Qualité réelle de la vérité produit

Etat:
- bonne sur la tranche ouverte
- pas parfaite

Points honnêtes:
- golden slice réellement lançable et battleable
- runtime bridge strict
- capture minimale réelle
- write-back HP réel
- overlay fondée sur la vraie `timeline`

Points encore trompeurs ou décalés:
- roadmap globale en retard sur le repo battle/runtime
- vieux reports battle devenus partiellement faux
- bootstrap seed structurellement un peu trompeur sur l'organisation des entrées

### 2.4. Décision sur la suite

Décision recommandée:
- pas de H3 maintenant
- consolidation d'abord

## 3. Pré-gates exécutés + résultats

Pré-gates requis exécutés au début de l'audit initial, puis rerun ce tour avant écriture du seul fichier de report:

Commande:

```bash
git status --short --untracked-files=all
```

Résultat observé avant écriture du report:

```text
[aucune sortie]
```

Commande:

```bash
git diff --stat
```

Résultat observé avant écriture du report:

```text
[aucune sortie]
```

Commande:

```bash
git ls-files --others --exclude-standard
```

Résultat observé avant écriture du report:

```text
[aucune sortie]
```

Conclusion pré-gates:
- worktree propre au début de l'audit
- aucun bruit git local avant ce report
- aucun fichier non suivi avant ce report

## 4. Méthode réelle utilisée

### 4.1. Ce qui a été lu

Code battle lu directement:
- [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:30)
- [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:50)
- [battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:44)
- [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:62)
- [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:6)
- [battle_condition_engine.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_condition_engine.dart:1)
- [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:1)
- [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:1)
- [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:1)
- [battle_switch.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_switch.dart:1)
- [battle_stealth_rock.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart:1)
- [battle_spikes.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart:1)
- [battle_topology.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_topology.dart:1)
- [battle_type_chart.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:1)
- [battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart:1)
- [battle_resolution.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart:1)

Code runtime lu directement:
- [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:1)
- [runtime_battle_combatant_seed_builder.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:1)
- [runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:1)
- [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:1)
- [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:1)
- [playable_map_game.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3040)
- [battle_start_request.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart:1)

Bootstrap / editor lu directement:
- [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:1)
- [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:1)
- [initialize_pokemon_project_storage_use_case.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart:59)
- [seed_pokemon_demo_data_use_case.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart:23)

Host / produit:
- [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:1)
- [golden_battle_slice/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/README.md:1)

Roadmap / reports historiques lus comme hypothèses:
- [ROADMAP_FANGAME_RECALEE.md](/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md:1)
- [docs/combat/moves-battle-engine-master-roadmap.md](/Users/karim/Project/pokemonProject/docs/combat/moves-battle-engine-master-roadmap.md:1)
- [phase-battle-post-m8-audit-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-post-m8-audit-report.md:1)
- [phase-battle-be1-bridge-hardening-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be1-bridge-hardening-report.md:1)
- [phase-h1-stealth-rock-minimal-report.md](/Users/karim/Project/pokemonProject/reports/phase-h1-stealth-rock-minimal-report.md:1)
- [phase-h2-spikes-minimal-report.md](/Users/karim/Project/pokemonProject/reports/phase-h2-spikes-minimal-report.md:1)
- [phase-r1-lot-11-wild-battle-end-to-end-report.md](/Users/karim/Project/pokemonProject/reports/phase-r1-lot-11-wild-battle-end-to-end-report.md:1)
- [audit-showdown-parity-battle-engine.md](/Users/karim/Project/pokemonProject/reports/audit-showdown-parity-battle-engine.md:1)

Showdown local lu directement:
- [sim/battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:1)
- [sim/side.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:280)
- [sim/field.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/field.ts:186)
- [data/moves.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/moves.ts:19808)
- [test/sim/misc/hazards.js](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:1)

### 4.2. Ce qui a été relancé

Battle:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart analyze
dart test
```

Résultat:
- `dart analyze`: vert
- `dart test`: vert

Runtime ciblé battle:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze --no-pub [fichiers battle/runtime ciblés]
flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
```

Résultat:
- analyze ciblé: vert
- tests ciblés: verts

Editor seed:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze --no-pub lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart test/pokemon_moves_bootstrap_seed_test.dart
flutter test test/pokemon_moves_bootstrap_seed_test.dart
```

Résultat:
- analyze ciblé: vert
- test seed: vert

Host d'exemple:

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

Résultat:# Battle State vs Showdown Audit

Date de l'audit: 2026-04-18

Périmètre audité:
- dépôt local `/Users/karim/Project/pokemonProject`
- battle core: `packages/map_battle/**`
- runtime battle handoff / overlay / write-back: `packages/map_runtime/**`
- bootstrap seed utile: `packages/map_editor/**`
- host de référence: `examples/playable_runtime_host/**`
- clone local Showdown: `/Users/karim/Project/pokemonProject/pokemon-showdown-master`

Règle de vérité suivie pendant tout l'audit:
1. code réel
2. tests réellement exécutés et verts
3. runtime réellement branché et smoke-testé
4. bootstrap/seed réellement versionné
5. reports / roadmap historiques

## 1. Résumé exécutif honnête

Le moteur battle PokeMap n'est plus un prototype vide ni un faux seam de combat. Le dépôt exécute aujourd'hui un vrai sous-ensemble battle `singles-only`, avec un seul slot actif par side mais avec réserves réelles, trainer battles multi-Pokémon, vraie résolution de tour, vrai runtime handoff, vraie overlay, vraie capture minimale, vrai write-back minimal, et une golden slice réellement lançable.

En revanche, ce moteur reste loin de Pokémon Showdown au sens moteur. Il n'est pas simplement "un peu incomplet"; il manque encore les couches structurantes qui font la profondeur Showdown-like:
- request model multi-side riche
- scheduler / queue générique
- conditions génériques side / slot / field / volatile
- targeting plus riche que `self/opponent/field/opponentSide`
- familles de mécaniques largement au-delà du sous-ensemble actuellement ouvert

Le support réel aujourd'hui est honnête sur un slice étroit:
- ordre priorité / vitesse / Trick Room
- PP / accuracy / crit minimaux
- dégâts simples + STAB + type chart + immunités
- statuts majeurs `par/brn/psn/tox`
- volatiles `protect`, recharge, charge puis frappe
- weather `rain/sandstorm`
- pseudoWeather `trickRoom`
- switch volontaire
- remplacement forcé joueur
- auto-switch ennemi
- hazards `Stealth Rock` et `Spikes`
- timeline observable
- `Run` et `Capture` en wild
- bridge runtime
- bootstrap curaté battleable

La vérité produit actuelle est globalement bonne sur la tranche ouverte. Le runtime live ne promet pas plus que le moteur sur les moves supportés; au contraire, il refuse explicitement beaucoup de choses hors scope dans [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:816). Les mensonges restants sont surtout documentaires, de classement seed, ou des reports historiques désormais dépassés par le code.

La roadmap actuelle ne colle plus proprement au repo pour la battle loop minimale. `ROADMAP_FANGAME_RECALEE.md` parle encore de bridge runtime -> battle, combat sauvage réel, capture minimale et whiteout-lite comme de futures étapes, alors que ces slices existent déjà dans le repo et sont testées. Elle reste utile comme vision, mais elle n'est plus une photo canonique de l'état battle/runtime.

Décision nette: `H3 maintenant = non`.

Raison:
- oui, un micro-lot supplémentaire pourrait théoriquement encore rentrer dans les seams actuels;
- non, ce n'est pas la bonne décision canonique à ce stade;
- l'état réel du repo appelle d'abord une consolidation: canon documentaire, vérité bootstrap, clarification de la trajectoire battle, stabilisation des seams avant d'ajouter une nouvelle mécanique.

## 2. Verdict global

### 2.1. Etat réel du moteur battle

Etat réel:
- moteur `singles-only`
- un slot actif par side
- réserves réelles des deux côtés
- trainer battles multi-Pokémon supportées via lineup active + reserve
- vraie résolution de tour locale
- vraie chaîne runtime -> battle -> runtime

Ce que le moteur est réellement:
- un slice battle local honnête, testable, jouable, intégré au produit
- un moteur encore très centralisé, avec une dette de généralisation claire

Ce qu'il n'est pas:
- un moteur proche de la profondeur structurelle de Showdown
- un moteur générique de conditions / events / scheduling
- un moteur prêt à absorber sans friction une nouvelle famille riche de mécaniques

### 2.2. Proximité réelle avec Showdown sur le périmètre utile

Proximité utile:
- suffisante pour parler d'un sous-ensemble "Showdown-like" local sur quelques familles concrètes
- insuffisante pour parler de convergence Showdown forte

Le delta avec Showdown n'est pas "quelques moves manquants". Le delta majeur est architectural:
- Showdown a un vrai modèle `Side` riche, des `request` riches, une vraie `BattleQueue`, des `sideConditions` et `pseudoWeather` génériques, et un modèle d'actions / callbacks beaucoup plus large dans [sim/battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:1), [sim/side.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:280) et [sim/field.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/field.ts:186)
- PokeMap a des contrats honnêtes mais étroits, et un `battle_session.dart` qui porte encore une grande partie de la causalité

### 2.3. Qualité réelle de la vérité produit

Etat:
- bonne sur la tranche ouverte
- pas parfaite

Points honnêtes:
- golden slice réellement lançable et battleable
- runtime bridge strict
- capture minimale réelle
- write-back HP réel
- overlay fondée sur la vraie `timeline`

Points encore trompeurs ou décalés:
- roadmap globale en retard sur le repo battle/runtime
- vieux reports battle devenus partiellement faux
- bootstrap seed structurellement un peu trompeur sur l'organisation des entrées

### 2.4. Décision sur la suite

Décision recommandée:
- pas de H3 maintenant
- consolidation d'abord

## 3. Pré-gates exécutés + résultats

Pré-gates requis exécutés au début de l'audit initial, puis rerun ce tour avant écriture du seul fichier de report:

Commande:

```bash
git status --short --untracked-files=all
```

Résultat observé avant écriture du report:

```text
[aucune sortie]
```

Commande:

```bash
git diff --stat
```

Résultat observé avant écriture du report:

```text
[aucune sortie]
```

Commande:

```bash
git ls-files --others --exclude-standard
```

Résultat observé avant écriture du report:

```text
[aucune sortie]
```

Conclusion pré-gates:
- worktree propre au début de l'audit
- aucun bruit git local avant ce report
- aucun fichier non suivi avant ce report

## 4. Méthode réelle utilisée

### 4.1. Ce qui a été lu

Code battle lu directement:
- [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:30)
- [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:50)
- [battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:44)
- [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:62)
- [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:6)
- [battle_condition_engine.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_condition_engine.dart:1)
- [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:1)
- [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:1)
- [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:1)
- [battle_switch.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_switch.dart:1)
- [battle_stealth_rock.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart:1)
- [battle_spikes.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart:1)
- [battle_topology.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_topology.dart:1)
- [battle_type_chart.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:1)
- [battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart:1)
- [battle_resolution.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart:1)

Code runtime lu directement:
- [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:1)
- [runtime_battle_combatant_seed_builder.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:1)
- [runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:1)
- [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:1)
- [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:1)
- [playable_map_game.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:3040)
- [battle_start_request.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/battle_start_request.dart:1)

Bootstrap / editor lu directement:
- [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:1)
- [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:1)
- [initialize_pokemon_project_storage_use_case.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart:59)
- [seed_pokemon_demo_data_use_case.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/seed_pokemon_demo_data_use_case.dart:23)

Host / produit:
- [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:1)
- [golden_battle_slice/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/README.md:1)

Roadmap / reports historiques lus comme hypothèses:
- [ROADMAP_FANGAME_RECALEE.md](/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md:1)
- [docs/combat/moves-battle-engine-master-roadmap.md](/Users/karim/Project/pokemonProject/docs/combat/moves-battle-engine-master-roadmap.md:1)
- [phase-battle-post-m8-audit-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-post-m8-audit-report.md:1)
- [phase-battle-be1-bridge-hardening-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be1-bridge-hardening-report.md:1)
- [phase-h1-stealth-rock-minimal-report.md](/Users/karim/Project/pokemonProject/reports/phase-h1-stealth-rock-minimal-report.md:1)
- [phase-h2-spikes-minimal-report.md](/Users/karim/Project/pokemonProject/reports/phase-h2-spikes-minimal-report.md:1)
- [phase-r1-lot-11-wild-battle-end-to-end-report.md](/Users/karim/Project/pokemonProject/reports/phase-r1-lot-11-wild-battle-end-to-end-report.md:1)
- [audit-showdown-parity-battle-engine.md](/Users/karim/Project/pokemonProject/reports/audit-showdown-parity-battle-engine.md:1)

Showdown local lu directement:
- [sim/battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:1)
- [sim/side.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:280)
- [sim/field.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/field.ts:186)
- [data/moves.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/moves.ts:19808)
- [test/sim/misc/hazards.js](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:1)

### 4.2. Ce qui a été relancé

Battle:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_battle
dart analyze
dart test
```

Résultat:
- `dart analyze`: vert
- `dart test`: vert

Runtime ciblé battle:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze --no-pub [fichiers battle/runtime ciblés]
flutter test \
  test/runtime_battle_move_bridge_test.dart \
  test/runtime_battle_setup_mapper_test.dart \
  test/runtime_battle_outcome_apply_test.dart \
  test/runtime_battle_combatant_seed_builder_test.dart \
  test/battle_overlay_component_test.dart \
  test/wild_battle_end_to_end_flow_test.dart \
  test/phase_a_golden_battle_slice_smoke_test.dart
```

Résultat:
- analyze ciblé: vert
- tests ciblés: verts

Editor seed:

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze --no-pub lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart test/pokemon_moves_bootstrap_seed_test.dart
flutter test test/pokemon_moves_bootstrap_seed_test.dart
```

Résultat:
- analyze ciblé: vert
- test seed: vert

Host d'exemple:

```bash
cd /Users/karim/Project/pokemonProject/examples/playable_runtime_host
flutter test \
  test/project_loader_page_test.dart \
  test/runtime_launch_save_test.dart \
  test/runtime_demo_party_seed_test.dart \
  test/phase_a_golden_slice_launch_test.dart
```

Résultat:
- vert

### 4.3. Ce qui a été comparé

Comparaison primaire:
- PokeMap local vs clone local Showdown
- battle core vs runtime vs bootstrap vs host produit
- code actuel vs reports historiques
- code actuel vs roadmap globale

### 4.4. Sub-agents utilisés

Sous-agents obligatoires utilisés:
- `Laplace`: battle-core / architecture
- `Dirac`: showdown comparison
- `Pasteur`: runtime / bootstrap truth

Reviewer(s) séparé(s) utilisé(s):
- `Huygens`: reviewer séparé principal
- `Carson`: reviewer séparé de recadrage / contradiction documentaire

### 4.5. Ordre réel de travail

Ordre réellement suivi:
1. lecture de `AGENTS.md`
2. pré-gates git read-only
3. cartographie battle/runtime/editor/reports
4. lancement des validations ciblées
5. délégation battle-core / Showdown / runtime-bootstrap
6. lecture du clone Showdown local
7. confrontation reports/roadmap vs code actuel
8. reviewer séparé
9. correction de la synthèse initiale
10. rédaction du report canonique

### 4.6. Plugins / skills

Plugin explicitement nommé et réellement utilisé:
- `Superpowers`, via lecture de `using-superpowers` puis `verification-before-completion`

Plugin explicitement nommé mais non retenu comme capacité active:
- `Game Studio`
- raison: aucune compétence `browser-game`, `frontend HUD`, `playtest` ou `browser QA` n'était nécessaire pour cet audit de code battle/runtime/bootstrap

## 5. Audit réel avant conclusion

### 5.1. Forces réelles du moteur actuel

#### 5.1.1. Le moteur n'est plus un fake seam battle

Le point important le plus facilement sous-estimé est celui-ci: le repo possède déjà une vraie boucle battle verticale.

Preuves:
- le runtime construit un vrai `BattleSetup` via [RuntimeBattleSetupMapper](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:39)
- le moteur battle reçoit une vraie lineup joueur + réserve et une vraie lineup adverse + réserve via [BattleSetup](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart:27)
- l'overlay lit la vraie `BattleDecisionRequest` et la vraie `BattleTurnResult.timeline` via [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:15) et [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:43)
- le write-back runtime réécrit réellement les PV, le flag trainer battu et la capture minimale via [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:174)

Ce n'est pas une simple maquette:
- wild battle réel
- trainer battle réel
- retour overworld réel
- smoke tests et host tests réellement verts

#### 5.1.2. Le moteur a déjà un vrai petit request model

[BattleDecisionRequest](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:70) n'est pas un faux wrapper vide:
- `turnChoice`
- `forcedReplacement`
- `forcedContinue`
- `wait`

Cela reste local et joueur-only, mais ce n'est plus une "liste plate" naïve.

#### 5.1.3. Le moteur a déjà un vrai état side-level minimal

[BattleSideState](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:523) porte aujourd'hui:
- identité de side
- slot actif `0`
- réserve ordonnée
- `hasStealthRock`
- `spikesLayers`

Ce n'est pas encore un système générique de side conditions, mais c'est déjà un vrai état battle utile et consommé.

#### 5.1.4. Les seams BE8/BE9/BE10/H1/H2 sont réellement vivants

Le moteur sait déjà exécuter:
- PP réels
- accuracy minimale
- crit minimal
- statuts majeurs limités
- volatiles limités
- weather / Trick Room
- switch pipeline
- hazards d'entrée

Ce ne sont pas des noms d'étapes décoratifs:
- ils sont testés
- ils sont réellement consommés par le runtime
- ils sont visibles dans la timeline

### 5.2. Limites réelles et structurantes

#### 5.2.1. `battle_session.dart` reste le centre de gravité du moteur

C'est la limite structurelle la plus importante.

[battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:947) porte encore, en pratique:
- choix de l'action adverse
- résolution du tour
- ordre d'action
- hit check
- dégâts
- statuts
- volatiles
- field
- hazards
- continuation de tour
- replacement / auto-switch
- outcome
- timeline

Conséquence:
- tant que le moteur reste dans des mécaniques locales simples, c'est défendable
- dès qu'une nouvelle mécanique exige une causalité plus générique, le coût marginal monte vite

#### 5.2.2. La queue actuelle est honnête, mais trop petite pour parler de convergence Showdown

[BattleTurnQueue](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:20) est une vraie queue de tour.

Mais elle sait explicitement seulement:
- `Fight`
- `Switch`
- `Recharge`
- fin de tour
- checks post-tour
- auto-switch
- replacement required

Elle ne couvre pas:
- request richness Showdown
- scheduling plus large des effets
- callbacks / side conditions / slot conditions / action classes riches
- les variantes d'actions que Showdown gère nativement dans [sim/battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:24)

#### 5.2.3. Le condition engine est encore honnête, mais très mince

[battle_condition_engine.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_condition_engine.dart:1) fonctionne encore comme un mini moteur de conditions locales, pas comme une couche générique de résolution.

Il reste honnête tant que:
- le périmètre reste petit
- les familles ouvertes restent explicitement bornées

Il deviendrait trop pauvre si on voulait y pousser trop vite:
- side conditions riches
- terrains
- conditions conditionnelles plus larges
- statuts / volatiles plus nombreux et interactifs

### 5.3. Zones honnêtes mais simplifiées

#### 5.3.1. Ordre d'action

Ordre actuel dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1347):
- priorité
- vitesse effective
- inversion Trick Room à priorité égale
- tie-break déterministe joueur avant ennemi

Ce n'est pas mensonger.
Ce n'est pas Showdown.
C'est une simplification locale honnête.

#### 5.3.2. `Trick Room`

Le moteur et le bridge savent réellement exécuter un petit `Trick Room`:
- pseudoWeather réel
- durée réelle
- ordre de vitesse inversé à priorité égale

Preuves:
- [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:15)
- [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1401)
- [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:816)

Mais ce n'est pas la richesse Showdown de [moves.ts trickroom](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/moves.ts:20007):
- pas de `onFieldRestart` générique
- pas de couche condition générique
- pas de couverture plus large que l'ordre local

#### 5.3.3. Hazards

`Stealth Rock` et `Spikes` sont vraiment ouverts.
Mais ils restent volontairement étroits.

Preuves:
- [battle_stealth_rock.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart:1)
- [battle_spikes.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart:1)
- [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2284)

Simplifications explicites:
- pas de framework générique de hazards
- pas de Toxic Spikes
- pas de Sticky Web
- pas de retrait de hazards
- groundedness H2 locale seulement

### 5.4. Zones fragiles

#### 5.4.1. Pas de Struggle

[battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:924) échoue explicitement si l'adversaire n'a plus aucun move utilisable:

```text
Struggle est hors scope.
```

Cette dette est visible et honnête.
Mais elle reste une fragilité réelle si le contenu supporté s'élargit.

#### 5.4.2. Fallback `BattleActionRun` côté ennemi

Si aucune attaque n'existe du tout, `_chooseEnemyAction()` retourne `BattleActionRun()` dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:928).

Ce n'est pas un chemin gameplay Showdown-like.
C'est un edge-case de secours fragile.

#### 5.4.3. Double K.O. biaisé vers la victoire

[battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2032) documente explicitement la politique actuelle:
- si l'adversaire est K.O., victoire immédiate
- si double K.O. sans réserve des deux côtés, la vérification `enemy d'abord` produit une victoire

Ce comportement est stable et documenté.
Mais il diverge d'une lecture plus neutre / plus canonique d'un double K.O.

#### 5.4.4. Hard-fail runtime "aucun move bridgeable"

[resolveBattleMovesForSeed](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:63) échoue explicitement si un combattant n'a plus aucun move bridgeable après filtrage:

```text
Le combat ne peut pas démarrer car "... n'a aucun move bridgeable restant après filtrage."
```

C'est honnête.
Mais c'est un vrai blocker produit/contenu si le catalogue supporté et le contenu projet dérivent.

### 5.5. Zones trompeuses ou structurellement ambiguës

#### 5.5.1. Roadmap globale

[ROADMAP_FANGAME_RECALEE.md](/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md:573) raconte encore:
- bridge runtime -> battle réel à construire
- combat sauvage réel à construire
- capture minimale à construire
- heal / whiteout-lite à construire

Le code réel et les tests montrent que ces slices existent déjà.

Conclusion:
- la roadmap reste utile comme vision
- elle n'est plus canonique comme état battle/runtime

#### 5.5.2. Reports historiques

Certains reports battle sont désormais partiellement faux s'ils sont lus comme vérité actuelle:
- [phase-battle-be1-bridge-hardening-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be1-bridge-hardening-report.md:12)
- [phase-r1-lot-11-wild-battle-end-to-end-report.md](/Users/karim/Project/pokemonProject/reports/phase-r1-lot-11-wild-battle-end-to-end-report.md:1)
- [phase-battle-post-m8-audit-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-post-m8-audit-report.md:1)

Le code gagne sur ces documents.

#### 5.5.3. Bootstrap seed: vérité correcte, structure de fichier moins bonne

[pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:67) sépare:
- `_structuredSupportedSeedMoves`
- `_catalogOnlySeedMoves`

Mais cette structure contient aujourd'hui `stealth_rock` et `spikes` dans `_catalogOnlySeedMoves` à [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:607), alors que leurs labels métier attendus sont supportés de bout en bout et testés comme tels dans [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:49).

Ce n'est pas un mensonge de champ.
C'est une ambiguïté structurelle de lecture.

## 6. Matrice de support détaillée

| area | mechanic | status | showdown_alignment | runtime_truth | bootstrap_truth | main_limit | evidence |
|---|---|---|---|---|---|---|---|
| battle core | singles engine with one active slot per side | supported | close_enough_for_current_scope | honnête | n/a | pas de doubles / multi-slot | [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:515) |
| battle core | reserves on both sides | supported | close_enough_for_current_scope | honnête | honnête via host slice | singles only, pas de side grid riche | [battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart:41), [runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:71) |
| decision / request model | typed turn request | supported_bounded_slice | locally_honest_but_simplified | overlay aligné | n/a | joueur seulement | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:153) |
| decision / request model | forced replacement request | supported_bounded_slice | locally_honest_but_simplified | overlay aligné | n/a | pas de `forceSwitch` arrays Showdown | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:204) |
| decision / request model | continue / wait requests | supported_bounded_slice | locally_honest_but_simplified | overlay aligné | n/a | très local au flow PokeMap | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:221) |
| topology | side identity + slot refs | supported_bounded_slice | locally_honest_but_simplified | honnête | n/a | slot `0` seulement | [battle_topology.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_topology.dart:1), [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:92) |
| order / scheduling | turn order by priority then speed | supported_bounded_slice | locally_honest_but_simplified | honnête | certaines moves seedées en profitent | pas de scheduler riche | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1375) |
| order / scheduling | Trick Room inversion at equal priority | supported_bounded_slice | locally_honest_but_simplified | honnête | sous-déclaré dans le seed | petit sous-ensemble seulement | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1401), [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:863) |
| order / scheduling | deterministic player-first speed tie | fragile | far_from_showdown | honnête | n/a | pas de PRNG / pas de Fischer-Yates | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1430), [battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:18) |
| queue | local queue with action / endOfTurn / postChecks / autoSwitch / replacementRequired | partial | far_from_showdown | honnête pour slice ouvert | n/a | hors de portée pour demandes plus riches | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:61) |
| queue | `Run` and `Capture` outside queue | fragile | far_from_showdown | honnête | n/a | limite la généralisation | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:78) |
| hit pipeline | PP consumption | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | pas de Struggle | [battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:44), [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:912) |
| hit pipeline | accuracy percent / alwaysHits | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | pas d'accuracy/evasion stages | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1692), [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:49) |
| hit pipeline | crit minimal with critRatio | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête pour moves concernés | pas d'interactions items/abilities | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1919) |
| damage | standard damage formula | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête sur seed supporté | pas de multihit / drain / recoil / heal | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1787) |
| typing | STAB | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | fixe a 1.5, pas de tera / abilities | [battle_type_chart.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:255) |
| typing | type effectiveness / immunities | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | limité au chart local sans couches annexes | [battle_type_chart.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:199) |
| statuses | `par` | supported_bounded_slice | far_from_showdown | honnête | honnête | pas de système complet | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:16) |
| statuses | `brn` | supported_bounded_slice | far_from_showdown | honnête | honnête | interactions réduites | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:39) |
| statuses | `psn` | supported_bounded_slice | far_from_showdown | honnête | honnête | pas de poison steel/ability logic | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:43) |
| statuses | `tox` | supported_bounded_slice | far_from_showdown | honnête | honnête | compteur local simple seulement | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:47) |
| statuses | sleep / freeze / confusion | unsupported | far_from_showdown | runtime les refuse | seed les laisse hors support | absents du moteur | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:11), [data/conditions.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/conditions.ts:162) |
| volatiles | Protect | supported_bounded_slice | far_from_showdown | honnête | honnête | volatile subset très petit | [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:3) |
| volatiles | recharge turn | supported_bounded_slice | far_from_showdown | honnête | honnête | pas de système générique d'actions forcées | [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:48) |
| volatiles | charge-then-strike | supported_bounded_slice | far_from_showdown | honnête | honnête | pas de raccourcis meteo / power herb | [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:15), [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:763) |
| field | rain | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | subset weather tres petit | [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:10), [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:799) |
| field | sandstorm | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | pas de famille weather large | [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:10), [runtime_battle_move_bridge_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart:774) |
| field | Trick Room pseudoWeather | supported_bounded_slice | locally_honest_but_simplified | honnête | partial | pas de `onFieldRestart` générique | [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:15), [runtime_battle_move_bridge_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart:805) |
| field | terrain | unsupported | far_from_showdown | explicitement refusé | catalogOnly | hors subset bridge/moteur | [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:675) |
| switch | voluntary switch | supported_bounded_slice | close_enough_for_current_scope | honnête | n/a | pas de trapped logic / self-switch | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:153), [battle_switch.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_switch.dart:24) |
| switch | forced replacement player | supported_bounded_slice | locally_honest_but_simplified | honnête | n/a | réalisé via prochaine requête, pas via actions Showdown-like | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:204) |
| switch | enemy auto-switch after KO | supported_bounded_slice | locally_honest_but_simplified | honnête | n/a | IA et flow étroits | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:171), [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1207) |
| switch | forceSwitch / selfSwitch moves | unsupported | far_from_showdown | bridge les refuse | seed les garde hors support | pas de seams correspondants | [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:852), [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:17) |
| hazards | Stealth Rock set + entry damage | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | pas de removal / Boots / ability interactions | [battle_stealth_rock.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart:5) |
| hazards | Spikes layers + entry damage | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête mais structure seed confuse | groundedness locale très étroite | [battle_spikes.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart:59) |
| hazards | hazard order on entry | supported_bounded_slice | far_from_showdown | honnête localement | n/a | PokeMap impose `Stealth Rock` puis `Spikes`, Showdown teste autre ordre global | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2284), [hazards.js](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:70) |
| targeting | `opponent`, `self`, `field`, `opponentSide` | partial | far_from_showdown | honnête pour slice ouvert | honnête pour seed supporté | pas de targeting plus riche | [battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:1), [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1723) |
| outcomes | victory / defeat | supported | close_enough_for_current_scope | honnête | n/a | double KO policy locale | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2036) |
| outcomes | runaway | supported_bounded_slice | not_applicable_yet | honnête pour wild | n/a | hors scheduler normal | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:80), [phase-r1-lot-11-wild-battle-end-to-end-report.md](/Users/karim/Project/pokemonProject/reports/phase-r1-lot-11-wild-battle-end-to-end-report.md:1) |
| outcomes | captured | supported_bounded_slice | not_applicable_yet | honnête pour wild | host slice le prouve | capture formule minimale non-canonique | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:186) |
| timeline | ordered turn timeline | supported_bounded_slice | close_enough_for_current_scope | overlay en dépend | n/a | log textuel simple, pas journal Showdown complet | [battle_resolution.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart:110), [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:43) |
| runtime bridge | move bridge strict | supported_bounded_slice | not_applicable_yet | très honnête | seed aligné sur subset | beaucoup de rejets explicites, pas de sur-promesse | [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:863) |
| runtime setup | player + trainer lineup mapping | supported | close_enough_for_current_scope | honnête | host slice réel | seulement singles one-active-slot | [runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:48) |
| runtime setup | hard failure when no bridgeable move remains | fragile | not_applicable_yet | honnête mais bloquant | n/a | blocker contenu / bootstrap potentiel | [runtime_battle_combatant_seed_builder.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:118) |
| runtime write-back | HP write-back | supported_bounded_slice | not_applicable_yet | honnête | n/a | PV seulement | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:319) |
| runtime write-back | trainer defeated flag | supported_bounded_slice | not_applicable_yet | honnête | n/a | rien au-delà du flag minimal | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:225) |
| runtime write-back | capture minimal write-back | supported_bounded_slice | not_applicable_yet | honnête | honnête via golden slice | pas de boxes / catch formula canonique | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:205) |
| runtime write-back | PP/status post-battle persistence | unsupported | not_applicable_yet | le code ne le prétend pas | n/a | seam inexistant hors HP | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:329) |
| bootstrap | fresh battleable seed exists | supported_bounded_slice | not_applicable_yet | host/tests le prouvent | honnête | curaté et minimal, pas un dex large | [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:6), [phase_a_golden_slice_launch_test.dart](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart:9) |
| bootstrap | `trick_room` classified `structuredPartial` | partial | locally_honest_but_simplified | moteur/bridge en savent plus | sous-déclare légèrement | catalog ageing vs moteur | [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:804), [runtime_battle_move_bridge_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart:805) |
| bootstrap | unsupported seams catalogOnly (`absorb`, `double_slap`, `u_turn`, `whirlwind`) | supported | not_applicable_yet | runtime ne ment pas | honnête | no bridge / no mechanics | [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:17) |
| docs/product | host golden slice claims battleability | supported | not_applicable_yet | honnête | honnête | limité au slice versionné | [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:6), [golden_battle_slice/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/README.md:3) |
| docs/product | `packages/map_runtime/README.md` package README | supported_bounded_slice | not_applicable_yet | scope package, pas vérité produit globale | n/a | document de package, pas de host | [packages/map_runtime/README.md](/Users/karim/Project/pokemonProject/packages/map_runtime/README.md:18) |

## 7. Tableau des blockers

| blocker | type | severity | why_it_matters_now | blocks_H3? | evidence |
|---|---|---|---|---|---|
| `battle_session.dart` concentre encore la majorité des responsabilités moteur | architecture | high | toute nouvelle mécanique riche accroît directement le couplage | yes | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:947) |
| queue locale trop petite pour des familles Showdown-like plus riches | scheduling | high | pas de modèle d'actions / interruptions / effets comparable à Showdown | yes | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:61), [battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:133) |
| contrats targeting / side / slot encore trop serrés | contracts | high | bloque toute extension demandant plus que `slot 0`, `opponent/self/field/opponentSide` | yes | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:92), [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:523) |
| absence de système générique de conditions side / field / volatile | contracts | high | les prochains slices risquent sinon d'être des cas spéciaux accumulés | yes | [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:97), [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:5) |
| hard-fail runtime si aucun move bridgeable ne reste | runtime | medium | vrai blocker produit / contenu si on élargit le contenu sans élargir le moteur | no for consolidation, yes for content-expanding H3 | [runtime_battle_combatant_seed_builder.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:118) |
| write-back post-battle reste étroit | runtime | medium | si H3 ouvre des états post-battle plus riches, le runtime ne sait pas les persister honnêtement | yes | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:329) |
| roadmap battle/runtime n'est plus la photo canonique du repo | product | medium | pousse à de mauvaises priorités si on la prend comme source de vérité | yes | [ROADMAP_FANGAME_RECALEE.md](/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md:573) |
| reports historiques partiellement dépassés | product | medium | entretient des diagnostics obsolètes si relus sans confrontation au code | yes | [phase-battle-be1-bridge-hardening-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be1-bridge-hardening-report.md:12), [phase-r1-lot-11-wild-battle-end-to-end-report.md](/Users/karim/Project/pokemonProject/reports/phase-r1-lot-11-wild-battle-end-to-end-report.md:1) |
| bootstrap seed sous-déclare légèrement certains cas et structure la liste de façon ambiguë | bootstrap | medium | peut dégrader la vérité canonique d'un projet frais | yes | [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:67), [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:607) |
| pas de Struggle | product | medium | dette visible si un contenu plus large atteint une case "0 PP partout" | no for consolidation, yes for broader H3/content | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:924) |
| edge-case adverse `BattleActionRun()` si aucun move n'existe | product | medium | fallback peu défendable si le moteur s'élargit | no for consolidation, yes for broader H3 | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:928) |
| la suite de tests reste honnête sur le slice, mais ne prouve aucune quasi-parité Showdown | tests | medium | évite tout faux discours "presque Showdown" | no directly, but yes against false scope expansion | [phase_a_golden_battle_slice_smoke_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart:21), [hazards.js](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:70) |

## 8. Comparaison roadmap vs réalité

### 8.1. Verdict sur la roadmap battle historique

Verdict:
- comme vision: encore cohérente sur l'idée générale "battle depth progressive"
- comme état canonique du repo battle/runtime: partiellement obsolète
- comme source de vérité d'avancement: non fiable

### 8.2. Tableau

| roadmap_claim | actual_repo_state | compatible? | comment |
|---|---|---|---|
| bridge runtime -> battle réel reste à construire | le mapper runtime -> `BattleSetup` est déjà réel et testé | non | [runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:48) contredit la roadmap |
| combat sauvage réel reste à construire | wild battle réel existe, smoke-testé, host battleable | non | [phase_a_golden_battle_slice_smoke_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart:21), [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:6) |
| capture minimale reste à construire | capture minimale réelle existe | non | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:186) |
| whiteout-lite / heal minimal restent à construire | whiteout-lite minimal existe | non | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:57) |
| M3 handoff combat réel futur | gate largement atteint | non | milestone en retard documentaire |
| M8 "Combat crédible v2" futur | une partie notable existe déjà mais reste bornée | partiellement | bonne vision de direction, mauvaise photo de départ |
| battle depth stage 1 puis stage 2 plus tardifs | certains éléments de stage 1 sont déjà live | partiellement | il faudrait réaligner le texte sur l'état déjà acquis |
| phase H globale = tooling / docs / UX runtime | les reports battle H1/H2 utilisent aussi `H` comme séquence battle | partiellement | collision de nomenclature, source de confusion réelle |
| reports H1/H2 restent canoniques si lus seuls | ils restent globalement cohérents, mais seulement sur leur slice local | partiellement | H1/H2 eux-mêmes ne sont pas le problème; la roadmap globale l'est plus |
| report post-M8 peut encore servir d'état actuel | il est dépassé sur queue, field, statuses, switch, hazards | non | le code actuel a dépassé son diagnostic |

Conclusion roadmap:
- la roadmap battle historique n'est pas totalement morte
- elle est partiellement obsolète
- sur plusieurs points battle/runtime déjà livrés, elle est franchement dépassée par le repo actuel

## 9. Vérité produit / bootstrap / runtime

### 9.1. Le bootstrap reflète-t-il honnêtement le moteur ?

Réponse:
- oui globalement
- non parfaitement

Oui, parce que:
- le seed est explicitement curaté, pas vendu comme "tout Showdown" dans [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:30)
- les tests verrouillent explicitement les seams non supportés en `catalogOnly` dans [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:17)
- un projet frais battleable existe réellement via la golden slice du host dans [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:6)

Non parfaitement, parce que:
- `trick_room` reste `structuredPartial` dans le seed alors que le moteur/bridge savent désormais exécuter un vrai petit sous-ensemble
- `stealth_rock` et `spikes` vivent encore dans la liste `_catalogOnlySeedMoves`, ce qui n'est plus bien aligné avec leur support réel

Verdict bootstrap:
- pas mensonger
- un peu en retard sur le moteur
- encore défendable comme seed curaté minimal

### 9.2. Le runtime promet-il plus que le moteur ?

Réponse: non, pas sur le seam live audité.

Pourquoi:
- [RuntimeBattleMoveBridge](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:863) refuse explicitement beaucoup de formes hors subset
- le runtime ne projette pas silencieusement des effets qu'il ne sait pas porter honnêtement
- l'overlay refuse même une restitution mensongère sans `timeline` dans [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:43)

Le vrai risque runtime n'est pas la sur-promesse. Le vrai risque est:
- le hard-fail si le contenu n'a plus de move bridgeable

### 9.3. Le moteur sait-il plus que le bootstrap ?

Réponse: oui, légèrement.

Cas les plus nets:
- `Trick Room`: moteur + bridge savent porter un petit subset réel, seed encore `structuredPartial`
- la battle loop réelle du host et de la golden slice va plus loin que ce que beaucoup de vieux reports ou textes bootstrap racontent encore

### 9.4. Ou sont les mensonges restants ?

Mensonges restants ou quasi-mensonges:
- roadmap battle/runtime en retard sur le code
- reports historiques encore lisibles comme si leur état était actuel
- seed structuré de façon un peu trompeuse

Ce qui n'est pas un mensonge:
- le README de package `map_runtime` n'est pas la source de vérité produit globale; il documente un package, pas tout le host de référence

### 9.5. Ou sont les zones honnêtes ?

Zones honnêtes:
- bridge runtime -> battle
- overlay timeline
- capture minimale
- host golden slice battleable
- rejects explicites hors scope
- `catalogOnly` sur plusieurs seams réellement non supportés

## 10. Comparaison Showdown ciblée

Repo Showdown local utilisé:
- `/Users/karim/Project/pokemonProject/pokemon-showdown-master`

### 10.1. Décision / request model

PokeMap:
- [BattleDecisionRequest](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:70) expose un request model joueur, singles, slot `0`
- `BattleTurnChoiceRequest`, `BattleForcedReplacementRequest`, `BattleContinueRequest`, `BattleWaitRequest`

Showdown:
- `Side.requestState`, `activeRequest`, `getRequestData()` dans [sim/side.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:280)
- move/switch/teamPreview/wait, plus la richesse interne de `choice.actions`

Verdict:
- PokeMap: honnête mais simplifié
- Showdown: beaucoup plus riche

### 10.2. Side / slot

PokeMap:
- un side explicite avec actif + réserve dans [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:515)
- `slotIndex == 0` imposé en singles dans [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:535)

Showdown:
- `Side` et `active[]` plus riches dans [sim/side.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:340)

Verdict:
- pour le scope courant, PokeMap est suffisamment honnête
- ce n'est pas une topologie comparable à Showdown au-delà de ce scope

### 10.3. Ordre d'action

PokeMap:
- ordre local dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1347)

Showdown:
- `order`, `priority`, `fractionalPriority`, `speed`, plus types d'action riches dans [sim/battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:24)

Verdict:
- PokeMap: slice local honnête
- Showdown: vrai système de scheduling

### 10.4. Speed / priority / Trick Room

PokeMap:
- priorité puis vitesse effective puis inversion Trick Room puis tie-break stable
- switch priorisé via constante locale `6` dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1451)

Showdown:
- priorité plus large, ordres d'action plus riches, `Trick Room` avec `pseudoWeather`, callbacks et intégration plus profonde dans [data/moves.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/moves.ts:20007)

Verdict:
- PokeMap: localement honnête mais simplifié
- loin d'une convergence Showdown forte

### 10.5. Accuracy / PP / crit

PokeMap:
- accuracy et PP réels
- crit minimal
- pas d'accuracy/evasion stages
- pas de Struggle

Showdown:
- modèle beaucoup plus complet, intégré au moteur global et à la data move

Verdict:
- petit slice local honnête, pas parité Showdown

### 10.6. Dégâts simples

PokeMap:
- vraie formule simple dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1787)

Showdown:
- pipeline de dégâts plus riche, avec conditions, items, abilities, hooks et cas spéciaux

Verdict:
- PokeMap défendable comme "simplified Pokemon-like damage"
- pas Showdown-like au sens fort

### 10.7. STAB / type effectiveness / immunités

PokeMap:
- chart local et immunités dans [battle_type_chart.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:199)

Showdown:
- richesse de résolution bien plus large et plus de dépendances contextuelles

Verdict:
- assez proche pour le petit scope actuel
- pas plus

### 10.8. Statuts majeurs

PokeMap:
- seulement `par`, `brn`, `psn`, `tox` dans [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:3)

Showdown:
- conditions beaucoup plus riches dans [data/conditions.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/conditions.ts:162)

Verdict:
- loin de Showdown

### 10.9. Volatiles

PokeMap:
- `protect`, recharge, charge seulement dans [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:48)

Showdown:
- large universe de volatiles, interactions et callbacks

Verdict:
- loin de Showdown

### 10.10. Field / weather / pseudoWeather

PokeMap:
- `rain`, `sandstorm`, `trickRoom` uniquement dans [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:91)

Showdown:
- `pseudoWeather` map générique avec add/remove/restart dans [sim/field.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/field.ts:186)

Verdict:
- PokeMap honnête mais très réduit

### 10.11. Switch volontaire

PokeMap:
- vraiment supporté dans le request model et la résolution

Showdown:
- support beaucoup plus riche avec transitions et actions liées

Verdict:
- proche du minimum utile pour le scope courant

### 10.12. Forced replacement

PokeMap:
- supporté, mais réalisé via prochaine requête explicite

Showdown:
- force switch plus intégré et plus riche

Verdict:
- slice local honnête, pas convergence

### 10.13. Auto-switch ennemi

PokeMap:
- oui, supporté après KO via queue / reserve selection

Showdown:
- oui, mais dans un scheduler plus riche

Verdict:
- localement honnête

### 10.14. Timeline observable

PokeMap:
- vraie `timeline`
- l'overlay en dépend explicitement

Showdown:
- battle log plus riche, plus profond, plus stable dans ses sémantiques

Verdict:
- bon seam produit local
- pas une équivalence de log battle

### 10.15. Queue / scheduling

PokeMap:
- petite queue locale

Showdown:
- vraie action queue centrale

Verdict:
- zone la plus éloignée de Showdown avec le request model et les conditions

### 10.16. Hazards / side-level mechanics

PokeMap:
- `Stealth Rock` et `Spikes` seulement
- groundedness simplifiée
- ordre `Stealth Rock` puis `Spikes` dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2284)

Showdown:
- side conditions génériques et ordering plus large dans [test/sim/misc/hazards.js](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:70)

Verdict:
- slice local honnête
- trop pauvre pour parler de vraie convergence hazard system

### 10.17. Runtime bridge

PokeMap:
- bridge strict et honnête
- pas d'équivalent direct Showdown, car il s'agit d'un seam produit PokeMap

Verdict:
- `not_applicable_yet` côté alignement Showdown fort
- très bon seam de vérité produit

### 10.18. Bootstrap truth

PokeMap:
- seed battleable curaté, vrai host de référence

Showdown:
- pas de rôle équivalent direct

Verdict:
- `not_applicable_yet` pour la parité Showdown
- bon outil de vérité produit locale

### 10.19. Conclusion comparative ciblée

Conclusion Showdown ciblée:
- PokeMap n'est pas "près de Showdown"
- PokeMap a un slice local honnête, branché au produit, qui touche plusieurs familles réelles
- la zone la plus comparable à Showdown aujourd'hui est la petite logique locale de tour / damage / hazards / field
- la zone la moins comparable est la couche request / queue / conditions / targeting

## 11. Incidents rencontrés

Incidents réellement rencontrés pendant l'audit:
- un `rg README.md` a échoué parce qu'il n'existe pas de `README.md` racine à ce chemin. Bruit de commande, pas problème repo.
- deux commandes Flutter ont affiché brièvement `Waiting for another flutter command to release the startup lock...`. Bruit outil, pas problème battle/runtime.
- le reviewer séparé `Huygens` a nécessité un recadrage avant de rendre un retour exploitable.
- un second reviewer `Carson` a été lancé pour trancher une contradiction documentaire / de wording.
- aucune commande de validation ciblée battle/runtime/editor/host n'a échoué.

Limites de comparaison:
- l'audit n'a pas construit de test de parité automatisé PokeMap vs Showdown, move par move
- la comparaison Showdown est fondée sur lecture de sources primaires et tests Showdown consultés, pas sur exécution croisée du même scénario dans les deux moteurs

## 12. Décisions retenues / rejetées

### 12.1. Réellement acquis

Considéré comme réellement acquis:
- true battle loop locale
- player + enemy reserves
- trainer battle multi-Pokémon en singles
- typed request model
- priority / speed / Trick Room local
- PP / accuracy / crit minimal
- simple damage + STAB + type chart
- statuses `par/brn/psn/tox`
- volatiles subset
- weather subset
- SR + Spikes
- true runtime bridge
- true host golden slice
- true capture minimale / write-back minimal

### 12.2. Refusé comme "acquis"

Refusé comme acquis:
- parité Showdown globale
- request model Showdown-like
- generic scheduling layer
- generic side conditions
- generic field condition system
- targeting riche
- broader hazard system
- post-battle persistence riche
- honest support of all seeded or imported move families

### 12.3. Considéré comme fragile

Considéré comme fragile:
- no Struggle
- enemy `Run` fallback edge-case
- double KO victory bias
- hard-fail no-bridgeable-move
- bootstrap structure drift
- roadmap / reports canoniques en retard

### 12.4. Considéré comme trompeur

Considéré comme trompeur:
- lire la roadmap globale comme si elle décrivait encore l'état réel battle/runtime
- lire les reports BE1 / lot11 / post-M8 comme vérité actuelle
- appeler "presque Showdown" le moteur actuel parce qu'il sait SR / Spikes / Trick Room / switch

## 13. Retour des sub-agents

### 13.1. Sub-agent battle-core / architecture: Laplace

Apport:
- a confirmé que le moteur est réellement `singles-only`, avec request model réel, ordre de tour réel, statuts/volatiles/field/hazards réellement vivants
- a mis le doigt sur `battle_session.dart` comme monolithe restant
- a jugé que partir sur H3 était prématuré

Retenu:
- diagnostic structurel sur `battle_session.dart`
- verdict que la tranche actuelle est réelle mais encore étroite
- mise en garde sur le modèle de target plus large que le resolver réel

Rejeté ou nuancé:
- son "pas prêt pour H3" a été gardé comme recommandation finale, mais j'ai nuancé qu'un micro-slice pourrait techniquement encore rentrer; ce n'est simplement pas la décision recommandée

### 13.2. Sub-agent showdown comparison: Dirac

Apport:
- a confirmé la présence d'un clone local Showdown
- a comparé chaque famille importante avec fichiers Showdown précis
- a conclu que le moteur local est Showdown-like seulement sur un slice borné

Retenu:
- request model / queue / conditions bien trop loin de Showdown
- hazards / field / order comme simplifications locales honnêtes
- pas de `not_applicable_yet` généreux sur les familles déjà ouvertes

Rejeté ou nuancé:
- rien de substantiel rejeté; sa lecture a été reprise presque telle quelle

### 13.3. Sub-agent runtime/bootstrap truth: Pasteur

Apport:
- a confirmé que le seam runtime -> battle -> overlay -> write-back est live et honnête
- a identifié des contradictions entre vieux reports et code actuel
- a jugé le bootstrap globalement honnête

Retenu:
- runtime live honnête
- capture / write-back / whiteout-lite réels
- reports BE1 et lot11 dépassés par le code

Rejeté ou nuancé:
- j'ai ensuite précisé avec le reviewer que le `write-back runtime` ne doit pas être sur-vendu: il est réel, mais étroit

## 14. Retour du reviewer séparé

### 14.1. Reviewer principal: Huygens

Findings concrets:
- mon draft sur-vendait un peu le `write-back runtime`; il faut le décrire comme un seam étroit, pas comme une persistance battle large
- le hard-fail `no bridgeable move` doit être traité comme un blocker produit réel
- le bootstrap est globalement honnête, mais sous-déclare légèrement le moteur actuel sur `trick_room`

Ce qu'il a challengé:
- la présentation trop large du write-back
- la décision "non" trop absolue sur H3

Ce que j'en ai retenu:
- correction de wording sur le write-back
- ajout explicite du blocker `no bridgeable move`

Ce que je n'ai pas retenu comme verdict final:
- son `yes under conditions` pour H3
- je l'ai jugé techniquement défendable comme possibilité, mais pas comme recommandation canonique

### 14.2. Reviewer de recadrage: Carson

Findings concrets:
- la bonne formulation n'est pas "duel 1v1 plat", mais moteur `singles-only` avec réserves réelles
- le README de `packages/map_runtime` n'est pas la meilleure source de contradiction produit; le vrai récit produit battleable vit surtout dans le host et la golden slice
- verdict H3: `no`

Ce qu'il a challengé:
- mon ancien wording "1v1" trop étroit
- mon pointage trop lourd sur le README de package runtime

Ce que j'en ai retenu:
- correction du wording vers `singles-only avec réserves`
- recentrage des preuves produit sur le host et la golden slice
- confirmation du verdict final `non`

Doutes restants après review:
- aucun finding structurel nouveau n'a invalidé le diagnostic principal
- le seul vrai désaccord résiduel concernait la recommandation H3; j'ai arbitré contre H3

## 15. Critique explicite du prompt

Ce que le prompt demande correctement:
- source de vérité centrée sur le code réel
- refus explicite des faux "supports"
- obligation de regarder runtime et bootstrap
- obligation de confronter roadmap / reports / code
- exigence utile de comparaison Showdown ciblée, pas globale
- exigence utile de sub-agents et review séparée

Ce qui est discutable:
- le prompt tend à supposer qu'il existe probablement encore un mensonge runtime important; ce n'est plus vraiment le cas sur le seam battle live
- il pousse à parler en `singles 1v1`; le wording exact du repo est un peu plus riche, puisqu'il y a réserves et trainer battles multi-membres dans un cadre `singles-only`
- il sur-indexe parfois le fichier `map_runtime/README.md` comme vérité produit possible, alors que le host de référence et la golden slice sont des preuves plus directes

Ce qui est déjà dépassé par le repo:
- l'idée que handoff réel, combat sauvage réel, capture minimale, whiteout-lite seraient encore simplement des cibles futures
- plusieurs soupçons historiques sur `priority`, `critRatio`, ou l'absence complète de champ / hazards / switch pipeline

Ce qui pourrait pousser vers un faux diagnostic si suivi aveuglément:
- conclure trop vite "il faut H3" juste parce que H1/H2 existent
- conclure trop vite "le runtime ment encore" sans relire le host et les tests actuels
- conclure trop vite "presque Showdown" parce que quelques mécaniques nommées existent

## 16. Autocritique finale

Limites réelles de l'audit:
- je n'ai pas exécuté un harness de comparaison automatique PokeMap vs Showdown
- je n'ai pas relancé l'intégralité de tous les tests de tous les packages du monorepo; j'ai ciblé battle/runtime/bootstrap/host, ce qui est cohérent avec le scope
- je n'ai pas ouvert chaque report historique battle existant; j'ai lu les reports directement pertinents et les plus susceptibles de contredire l'état actuel

Points où je pourrais encore me tromper:
- sur l'importance exacte d'un futur H3 ultra-minimal si le repo voulait volontairement rester longtemps dans des seams très bornés
- sur certaines divergences fines de résolution vis-a-vis de Showdown qui demanderaient des scénarios pas seulement une lecture de code

Zones insuffisamment vérifiées:
- comportement exact de certains cas edge-case non explicitement couverts par les tests ciblés lus pendant l'audit
- impact exact d'éventuels call sites battle directs hors runtime principal

Points qui restent des inférences plutôt que des certitudes:
- le seuil précis a partir duquel un futur slice basculerait de "encore acceptable localement" a "architecture devenue trop pauvre"
- la quantité exacte de consolidation documentaire nécessaire avant d'ouvrir la suite

Mais les points centraux de ce rapport ne sont pas des inférences faibles:
- l'état battle/runtime/host réellement branché
- l'écart structurant avec Showdown
- l'obsolescence partielle de la roadmap et de certains reports
- la centralité encore problématique de `battle_session.dart`

## 17. Décision nette sur la suite

Décision finale

- État réel du moteur par rapport à Showdown : vrai slice `singles-only` avec réserves, trainer battles multi-membres, runtime handoff et write-back minimal réels, mais encore loin de la profondeur structurelle et de la flexibilité de Showdown.
- Niveau de vérité produit actuel : globalement honnête sur la tranche ouverte; les écarts restants sont surtout documentaires, historiques ou de classement bootstrap, pas des promesses live majeures non tenues.
- Roadmap actuelle encore fiable ou non : utile comme vision générale, non fiable comme photo canonique de l'état battle/runtime actuel, et partiellement obsolète sur les slices déjà livrés.
- H3 maintenant : non
- Raison principale : le repo a déjà assez de mécanique réelle pour nécessiter d'abord une consolidation du canon technique et documentaire; ouvrir un H3 maintenant risquerait surtout d'ajouter une nouvelle exception locale sur une architecture encore trop centralisée et des contrats encore trop serrés.
- Prochaine marche recommandée : consolidation d'abord: réaligner roadmap / reports / seed bootstrap / vérité produit, formaliser le canon du slice battle actuel, puis seulement réévaluer le prochain slice battle sur base stabilisée.

## 18. Checklist finale

- ai-je utilisé le code réel comme source de vérité principale ? oui
- ai-je distingué support honnête vs support partiel vs support mensonger ? oui
- ai-je comparé le moteur à Showdown sur le bon périmètre ? oui
- ai-je évalué runtime et bootstrap, pas seulement `map_battle` ? oui
- ai-je signalé les contradictions roadmap / repo ? oui
- ai-je évité tout faux "c'est presque bon" ? oui
- ai-je décidé clairement si H3 est cohérent maintenant ou non ? oui
- ai-je justifié cette décision avec preuves ? oui
- ai-je gardé le travail strictement read-only ? oui, hors création du présent report demandée explicitement
- ai-je utilisé des sub-agents ? oui
- ai-je fait une review séparée ? oui
- ai-je inclus une autocritique finale ? oui

- vert

### 4.3. Ce qui a été comparé

Comparaison primaire:
- PokeMap local vs clone local Showdown
- battle core vs runtime vs bootstrap vs host produit
- code actuel vs reports historiques
- code actuel vs roadmap globale

### 4.4. Sub-agents utilisés

Sous-agents obligatoires utilisés:
- `Laplace`: battle-core / architecture
- `Dirac`: showdown comparison
- `Pasteur`: runtime / bootstrap truth

Reviewer(s) séparé(s) utilisé(s):
- `Huygens`: reviewer séparé principal
- `Carson`: reviewer séparé de recadrage / contradiction documentaire

### 4.5. Ordre réel de travail

Ordre réellement suivi:
1. lecture de `AGENTS.md`
2. pré-gates git read-only
3. cartographie battle/runtime/editor/reports
4. lancement des validations ciblées
5. délégation battle-core / Showdown / runtime-bootstrap
6. lecture du clone Showdown local
7. confrontation reports/roadmap vs code actuel
8. reviewer séparé
9. correction de la synthèse initiale
10. rédaction du report canonique

### 4.6. Plugins / skills

Plugin explicitement nommé et réellement utilisé:
- `Superpowers`, via lecture de `using-superpowers` puis `verification-before-completion`

Plugin explicitement nommé mais non retenu comme capacité active:
- `Game Studio`
- raison: aucune compétence `browser-game`, `frontend HUD`, `playtest` ou `browser QA` n'était nécessaire pour cet audit de code battle/runtime/bootstrap

## 5. Audit réel avant conclusion

### 5.1. Forces réelles du moteur actuel

#### 5.1.1. Le moteur n'est plus un fake seam battle

Le point important le plus facilement sous-estimé est celui-ci: le repo possède déjà une vraie boucle battle verticale.

Preuves:
- le runtime construit un vrai `BattleSetup` via [RuntimeBattleSetupMapper](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:39)
- le moteur battle reçoit une vraie lineup joueur + réserve et une vraie lineup adverse + réserve via [BattleSetup](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart:27)
- l'overlay lit la vraie `BattleDecisionRequest` et la vraie `BattleTurnResult.timeline` via [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:15) et [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:43)
- le write-back runtime réécrit réellement les PV, le flag trainer battu et la capture minimale via [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:174)

Ce n'est pas une simple maquette:
- wild battle réel
- trainer battle réel
- retour overworld réel
- smoke tests et host tests réellement verts

#### 5.1.2. Le moteur a déjà un vrai petit request model

[BattleDecisionRequest](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:70) n'est pas un faux wrapper vide:
- `turnChoice`
- `forcedReplacement`
- `forcedContinue`
- `wait`

Cela reste local et joueur-only, mais ce n'est plus une "liste plate" naïve.

#### 5.1.3. Le moteur a déjà un vrai état side-level minimal

[BattleSideState](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:523) porte aujourd'hui:
- identité de side
- slot actif `0`
- réserve ordonnée
- `hasStealthRock`
- `spikesLayers`

Ce n'est pas encore un système générique de side conditions, mais c'est déjà un vrai état battle utile et consommé.

#### 5.1.4. Les seams BE8/BE9/BE10/H1/H2 sont réellement vivants

Le moteur sait déjà exécuter:
- PP réels
- accuracy minimale
- crit minimal
- statuts majeurs limités
- volatiles limités
- weather / Trick Room
- switch pipeline
- hazards d'entrée

Ce ne sont pas des noms d'étapes décoratifs:
- ils sont testés
- ils sont réellement consommés par le runtime
- ils sont visibles dans la timeline

### 5.2. Limites réelles et structurantes

#### 5.2.1. `battle_session.dart` reste le centre de gravité du moteur

C'est la limite structurelle la plus importante.

[battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:947) porte encore, en pratique:
- choix de l'action adverse
- résolution du tour
- ordre d'action
- hit check
- dégâts
- statuts
- volatiles
- field
- hazards
- continuation de tour
- replacement / auto-switch
- outcome
- timeline

Conséquence:
- tant que le moteur reste dans des mécaniques locales simples, c'est défendable
- dès qu'une nouvelle mécanique exige une causalité plus générique, le coût marginal monte vite

#### 5.2.2. La queue actuelle est honnête, mais trop petite pour parler de convergence Showdown

[BattleTurnQueue](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:20) est une vraie queue de tour.

Mais elle sait explicitement seulement:
- `Fight`
- `Switch`
- `Recharge`
- fin de tour
- checks post-tour
- auto-switch
- replacement required

Elle ne couvre pas:
- request richness Showdown
- scheduling plus large des effets
- callbacks / side conditions / slot conditions / action classes riches
- les variantes d'actions que Showdown gère nativement dans [sim/battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:24)

#### 5.2.3. Le condition engine est encore honnête, mais très mince

[battle_condition_engine.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_condition_engine.dart:1) fonctionne encore comme un mini moteur de conditions locales, pas comme une couche générique de résolution.

Il reste honnête tant que:
- le périmètre reste petit
- les familles ouvertes restent explicitement bornées

Il deviendrait trop pauvre si on voulait y pousser trop vite:
- side conditions riches
- terrains
- conditions conditionnelles plus larges
- statuts / volatiles plus nombreux et interactifs

### 5.3. Zones honnêtes mais simplifiées

#### 5.3.1. Ordre d'action

Ordre actuel dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1347):
- priorité
- vitesse effective
- inversion Trick Room à priorité égale
- tie-break déterministe joueur avant ennemi

Ce n'est pas mensonger.
Ce n'est pas Showdown.
C'est une simplification locale honnête.

#### 5.3.2. `Trick Room`

Le moteur et le bridge savent réellement exécuter un petit `Trick Room`:
- pseudoWeather réel
- durée réelle
- ordre de vitesse inversé à priorité égale

Preuves:
- [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:15)
- [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1401)
- [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:816)

Mais ce n'est pas la richesse Showdown de [moves.ts trickroom](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/moves.ts:20007):
- pas de `onFieldRestart` générique
- pas de couche condition générique
- pas de couverture plus large que l'ordre local

#### 5.3.3. Hazards

`Stealth Rock` et `Spikes` sont vraiment ouverts.
Mais ils restent volontairement étroits.

Preuves:
- [battle_stealth_rock.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart:1)
- [battle_spikes.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart:1)
- [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2284)

Simplifications explicites:
- pas de framework générique de hazards
- pas de Toxic Spikes
- pas de Sticky Web
- pas de retrait de hazards
- groundedness H2 locale seulement

### 5.4. Zones fragiles

#### 5.4.1. Pas de Struggle

[battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:924) échoue explicitement si l'adversaire n'a plus aucun move utilisable:

```text
Struggle est hors scope.
```

Cette dette est visible et honnête.
Mais elle reste une fragilité réelle si le contenu supporté s'élargit.

#### 5.4.2. Fallback `BattleActionRun` côté ennemi

Si aucune attaque n'existe du tout, `_chooseEnemyAction()` retourne `BattleActionRun()` dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:928).

Ce n'est pas un chemin gameplay Showdown-like.
C'est un edge-case de secours fragile.

#### 5.4.3. Double K.O. biaisé vers la victoire

[battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2032) documente explicitement la politique actuelle:
- si l'adversaire est K.O., victoire immédiate
- si double K.O. sans réserve des deux côtés, la vérification `enemy d'abord` produit une victoire

Ce comportement est stable et documenté.
Mais il diverge d'une lecture plus neutre / plus canonique d'un double K.O.

#### 5.4.4. Hard-fail runtime "aucun move bridgeable"

[resolveBattleMovesForSeed](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:63) échoue explicitement si un combattant n'a plus aucun move bridgeable après filtrage:

```text
Le combat ne peut pas démarrer car "... n'a aucun move bridgeable restant après filtrage."
```

C'est honnête.
Mais c'est un vrai blocker produit/contenu si le catalogue supporté et le contenu projet dérivent.

### 5.5. Zones trompeuses ou structurellement ambiguës

#### 5.5.1. Roadmap globale

[ROADMAP_FANGAME_RECALEE.md](/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md:573) raconte encore:
- bridge runtime -> battle réel à construire
- combat sauvage réel à construire
- capture minimale à construire
- heal / whiteout-lite à construire

Le code réel et les tests montrent que ces slices existent déjà.

Conclusion:
- la roadmap reste utile comme vision
- elle n'est plus canonique comme état battle/runtime

#### 5.5.2. Reports historiques

Certains reports battle sont désormais partiellement faux s'ils sont lus comme vérité actuelle:
- [phase-battle-be1-bridge-hardening-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be1-bridge-hardening-report.md:12)
- [phase-r1-lot-11-wild-battle-end-to-end-report.md](/Users/karim/Project/pokemonProject/reports/phase-r1-lot-11-wild-battle-end-to-end-report.md:1)
- [phase-battle-post-m8-audit-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-post-m8-audit-report.md:1)

Le code gagne sur ces documents.

#### 5.5.3. Bootstrap seed: vérité correcte, structure de fichier moins bonne

[pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:67) sépare:
- `_structuredSupportedSeedMoves`
- `_catalogOnlySeedMoves`

Mais cette structure contient aujourd'hui `stealth_rock` et `spikes` dans `_catalogOnlySeedMoves` à [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:607), alors que leurs labels métier attendus sont supportés de bout en bout et testés comme tels dans [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:49).

Ce n'est pas un mensonge de champ.
C'est une ambiguïté structurelle de lecture.

## 6. Matrice de support détaillée

| area | mechanic | status | showdown_alignment | runtime_truth | bootstrap_truth | main_limit | evidence |
|---|---|---|---|---|---|---|---|
| battle core | singles engine with one active slot per side | supported | close_enough_for_current_scope | honnête | n/a | pas de doubles / multi-slot | [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:515) |
| battle core | reserves on both sides | supported | close_enough_for_current_scope | honnête | honnête via host slice | singles only, pas de side grid riche | [battle_setup.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_setup.dart:41), [runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:71) |
| decision / request model | typed turn request | supported_bounded_slice | locally_honest_but_simplified | overlay aligné | n/a | joueur seulement | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:153) |
| decision / request model | forced replacement request | supported_bounded_slice | locally_honest_but_simplified | overlay aligné | n/a | pas de `forceSwitch` arrays Showdown | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:204) |
| decision / request model | continue / wait requests | supported_bounded_slice | locally_honest_but_simplified | overlay aligné | n/a | très local au flow PokeMap | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:221) |
| topology | side identity + slot refs | supported_bounded_slice | locally_honest_but_simplified | honnête | n/a | slot `0` seulement | [battle_topology.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_topology.dart:1), [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:92) |
| order / scheduling | turn order by priority then speed | supported_bounded_slice | locally_honest_but_simplified | honnête | certaines moves seedées en profitent | pas de scheduler riche | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1375) |
| order / scheduling | Trick Room inversion at equal priority | supported_bounded_slice | locally_honest_but_simplified | honnête | sous-déclaré dans le seed | petit sous-ensemble seulement | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1401), [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:863) |
| order / scheduling | deterministic player-first speed tie | fragile | far_from_showdown | honnête | n/a | pas de PRNG / pas de Fischer-Yates | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1430), [battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:18) |
| queue | local queue with action / endOfTurn / postChecks / autoSwitch / replacementRequired | partial | far_from_showdown | honnête pour slice ouvert | n/a | hors de portée pour demandes plus riches | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:61) |
| queue | `Run` and `Capture` outside queue | fragile | far_from_showdown | honnête | n/a | limite la généralisation | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:78) |
| hit pipeline | PP consumption | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | pas de Struggle | [battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:44), [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:912) |
| hit pipeline | accuracy percent / alwaysHits | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | pas d'accuracy/evasion stages | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1692), [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:49) |
| hit pipeline | crit minimal with critRatio | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête pour moves concernés | pas d'interactions items/abilities | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1919) |
| damage | standard damage formula | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête sur seed supporté | pas de multihit / drain / recoil / heal | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1787) |
| typing | STAB | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | fixe a 1.5, pas de tera / abilities | [battle_type_chart.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:255) |
| typing | type effectiveness / immunities | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | limité au chart local sans couches annexes | [battle_type_chart.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:199) |
| statuses | `par` | supported_bounded_slice | far_from_showdown | honnête | honnête | pas de système complet | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:16) |
| statuses | `brn` | supported_bounded_slice | far_from_showdown | honnête | honnête | interactions réduites | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:39) |
| statuses | `psn` | supported_bounded_slice | far_from_showdown | honnête | honnête | pas de poison steel/ability logic | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:43) |
| statuses | `tox` | supported_bounded_slice | far_from_showdown | honnête | honnête | compteur local simple seulement | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:47) |
| statuses | sleep / freeze / confusion | unsupported | far_from_showdown | runtime les refuse | seed les laisse hors support | absents du moteur | [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:11), [data/conditions.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/conditions.ts:162) |
| volatiles | Protect | supported_bounded_slice | far_from_showdown | honnête | honnête | volatile subset très petit | [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:3) |
| volatiles | recharge turn | supported_bounded_slice | far_from_showdown | honnête | honnête | pas de système générique d'actions forcées | [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:48) |
| volatiles | charge-then-strike | supported_bounded_slice | far_from_showdown | honnête | honnête | pas de raccourcis meteo / power herb | [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:15), [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:763) |
| field | rain | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | subset weather tres petit | [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:10), [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:799) |
| field | sandstorm | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | pas de famille weather large | [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:10), [runtime_battle_move_bridge_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart:774) |
| field | Trick Room pseudoWeather | supported_bounded_slice | locally_honest_but_simplified | honnête | partial | pas de `onFieldRestart` générique | [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:15), [runtime_battle_move_bridge_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart:805) |
| field | terrain | unsupported | far_from_showdown | explicitement refusé | catalogOnly | hors subset bridge/moteur | [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:675) |
| switch | voluntary switch | supported_bounded_slice | close_enough_for_current_scope | honnête | n/a | pas de trapped logic / self-switch | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:153), [battle_switch.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_switch.dart:24) |
| switch | forced replacement player | supported_bounded_slice | locally_honest_but_simplified | honnête | n/a | réalisé via prochaine requête, pas via actions Showdown-like | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:204) |
| switch | enemy auto-switch after KO | supported_bounded_slice | locally_honest_but_simplified | honnête | n/a | IA et flow étroits | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:171), [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1207) |
| switch | forceSwitch / selfSwitch moves | unsupported | far_from_showdown | bridge les refuse | seed les garde hors support | pas de seams correspondants | [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:852), [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:17) |
| hazards | Stealth Rock set + entry damage | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête | pas de removal / Boots / ability interactions | [battle_stealth_rock.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_stealth_rock.dart:5) |
| hazards | Spikes layers + entry damage | supported_bounded_slice | locally_honest_but_simplified | honnête | honnête mais structure seed confuse | groundedness locale très étroite | [battle_spikes.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_spikes.dart:59) |
| hazards | hazard order on entry | supported_bounded_slice | far_from_showdown | honnête localement | n/a | PokeMap impose `Stealth Rock` puis `Spikes`, Showdown teste autre ordre global | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2284), [hazards.js](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:70) |
| targeting | `opponent`, `self`, `field`, `opponentSide` | partial | far_from_showdown | honnête pour slice ouvert | honnête pour seed supporté | pas de targeting plus riche | [battle_move.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_move.dart:1), [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1723) |
| outcomes | victory / defeat | supported | close_enough_for_current_scope | honnête | n/a | double KO policy locale | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2036) |
| outcomes | runaway | supported_bounded_slice | not_applicable_yet | honnête pour wild | n/a | hors scheduler normal | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:80), [phase-r1-lot-11-wild-battle-end-to-end-report.md](/Users/karim/Project/pokemonProject/reports/phase-r1-lot-11-wild-battle-end-to-end-report.md:1) |
| outcomes | captured | supported_bounded_slice | not_applicable_yet | honnête pour wild | host slice le prouve | capture formule minimale non-canonique | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:186) |
| timeline | ordered turn timeline | supported_bounded_slice | close_enough_for_current_scope | overlay en dépend | n/a | log textuel simple, pas journal Showdown complet | [battle_resolution.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_resolution.dart:110), [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:43) |
| runtime bridge | move bridge strict | supported_bounded_slice | not_applicable_yet | très honnête | seed aligné sur subset | beaucoup de rejets explicites, pas de sur-promesse | [runtime_battle_move_bridge.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:863) |
| runtime setup | player + trainer lineup mapping | supported | close_enough_for_current_scope | honnête | host slice réel | seulement singles one-active-slot | [runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:48) |
| runtime setup | hard failure when no bridgeable move remains | fragile | not_applicable_yet | honnête mais bloquant | n/a | blocker contenu / bootstrap potentiel | [runtime_battle_combatant_seed_builder.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:118) |
| runtime write-back | HP write-back | supported_bounded_slice | not_applicable_yet | honnête | n/a | PV seulement | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:319) |
| runtime write-back | trainer defeated flag | supported_bounded_slice | not_applicable_yet | honnête | n/a | rien au-delà du flag minimal | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:225) |
| runtime write-back | capture minimal write-back | supported_bounded_slice | not_applicable_yet | honnête | honnête via golden slice | pas de boxes / catch formula canonique | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:205) |
| runtime write-back | PP/status post-battle persistence | unsupported | not_applicable_yet | le code ne le prétend pas | n/a | seam inexistant hors HP | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:329) |
| bootstrap | fresh battleable seed exists | supported_bounded_slice | not_applicable_yet | host/tests le prouvent | honnête | curaté et minimal, pas un dex large | [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:6), [phase_a_golden_slice_launch_test.dart](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/test/phase_a_golden_slice_launch_test.dart:9) |
| bootstrap | `trick_room` classified `structuredPartial` | partial | locally_honest_but_simplified | moteur/bridge en savent plus | sous-déclare légèrement | catalog ageing vs moteur | [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:804), [runtime_battle_move_bridge_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/runtime_battle_move_bridge_test.dart:805) |
| bootstrap | unsupported seams catalogOnly (`absorb`, `double_slap`, `u_turn`, `whirlwind`) | supported | not_applicable_yet | runtime ne ment pas | honnête | no bridge / no mechanics | [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:17) |
| docs/product | host golden slice claims battleability | supported | not_applicable_yet | honnête | honnête | limité au slice versionné | [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:6), [golden_battle_slice/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/golden_battle_slice/README.md:3) |
| docs/product | `packages/map_runtime/README.md` package README | supported_bounded_slice | not_applicable_yet | scope package, pas vérité produit globale | n/a | document de package, pas de host | [packages/map_runtime/README.md](/Users/karim/Project/pokemonProject/packages/map_runtime/README.md:18) |

## 7. Tableau des blockers

| blocker | type | severity | why_it_matters_now | blocks_H3? | evidence |
|---|---|---|---|---|---|
| `battle_session.dart` concentre encore la majorité des responsabilités moteur | architecture | high | toute nouvelle mécanique riche accroît directement le couplage | yes | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:947) |
| queue locale trop petite pour des familles Showdown-like plus riches | scheduling | high | pas de modèle d'actions / interruptions / effets comparable à Showdown | yes | [battle_queue.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_queue.dart:61), [battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:133) |
| contrats targeting / side / slot encore trop serrés | contracts | high | bloque toute extension demandant plus que `slot 0`, `opponent/self/field/opponentSide` | yes | [battle_decision.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:92), [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:523) |
| absence de système générique de conditions side / field / volatile | contracts | high | les prochains slices risquent sinon d'être des cas spéciaux accumulés | yes | [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:97), [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:5) |
| hard-fail runtime si aucun move bridgeable ne reste | runtime | medium | vrai blocker produit / contenu si on élargit le contenu sans élargir le moteur | no for consolidation, yes for content-expanding H3 | [runtime_battle_combatant_seed_builder.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_combatant_seed_builder.dart:118) |
| write-back post-battle reste étroit | runtime | medium | si H3 ouvre des états post-battle plus riches, le runtime ne sait pas les persister honnêtement | yes | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:329) |
| roadmap battle/runtime n'est plus la photo canonique du repo | product | medium | pousse à de mauvaises priorités si on la prend comme source de vérité | yes | [ROADMAP_FANGAME_RECALEE.md](/Users/karim/Project/pokemonProject/ROADMAP_FANGAME_RECALEE.md:573) |
| reports historiques partiellement dépassés | product | medium | entretient des diagnostics obsolètes si relus sans confrontation au code | yes | [phase-battle-be1-bridge-hardening-report.md](/Users/karim/Project/pokemonProject/reports/phase-battle-be1-bridge-hardening-report.md:12), [phase-r1-lot-11-wild-battle-end-to-end-report.md](/Users/karim/Project/pokemonProject/reports/phase-r1-lot-11-wild-battle-end-to-end-report.md:1) |
| bootstrap seed sous-déclare légèrement certains cas et structure la liste de façon ambiguë | bootstrap | medium | peut dégrader la vérité canonique d'un projet frais | yes | [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:67), [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:607) |
| pas de Struggle | product | medium | dette visible si un contenu plus large atteint une case "0 PP partout" | no for consolidation, yes for broader H3/content | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:924) |
| edge-case adverse `BattleActionRun()` si aucun move n'existe | product | medium | fallback peu défendable si le moteur s'élargit | no for consolidation, yes for broader H3 | [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:928) |
| la suite de tests reste honnête sur le slice, mais ne prouve aucune quasi-parité Showdown | tests | medium | évite tout faux discours "presque Showdown" | no directly, but yes against false scope expansion | [phase_a_golden_battle_slice_smoke_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart:21), [hazards.js](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:70) |

## 8. Comparaison roadmap vs réalité

### 8.1. Verdict sur la roadmap battle historique

Verdict:
- comme vision: encore cohérente sur l'idée générale "battle depth progressive"
- comme état canonique du repo battle/runtime: partiellement obsolète
- comme source de vérité d'avancement: non fiable

### 8.2. Tableau

| roadmap_claim | actual_repo_state | compatible? | comment |
|---|---|---|---|
| bridge runtime -> battle réel reste à construire | le mapper runtime -> `BattleSetup` est déjà réel et testé | non | [runtime_battle_setup_mapper.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_setup_mapper.dart:48) contredit la roadmap |
| combat sauvage réel reste à construire | wild battle réel existe, smoke-testé, host battleable | non | [phase_a_golden_battle_slice_smoke_test.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/test/phase_a_golden_battle_slice_smoke_test.dart:21), [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:6) |
| capture minimale reste à construire | capture minimale réelle existe | non | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:186) |
| whiteout-lite / heal minimal restent à construire | whiteout-lite minimal existe | non | [runtime_battle_outcome_apply.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_outcome_apply.dart:57) |
| M3 handoff combat réel futur | gate largement atteint | non | milestone en retard documentaire |
| M8 "Combat crédible v2" futur | une partie notable existe déjà mais reste bornée | partiellement | bonne vision de direction, mauvaise photo de départ |
| battle depth stage 1 puis stage 2 plus tardifs | certains éléments de stage 1 sont déjà live | partiellement | il faudrait réaligner le texte sur l'état déjà acquis |
| phase H globale = tooling / docs / UX runtime | les reports battle H1/H2 utilisent aussi `H` comme séquence battle | partiellement | collision de nomenclature, source de confusion réelle |
| reports H1/H2 restent canoniques si lus seuls | ils restent globalement cohérents, mais seulement sur leur slice local | partiellement | H1/H2 eux-mêmes ne sont pas le problème; la roadmap globale l'est plus |
| report post-M8 peut encore servir d'état actuel | il est dépassé sur queue, field, statuses, switch, hazards | non | le code actuel a dépassé son diagnostic |

Conclusion roadmap:
- la roadmap battle historique n'est pas totalement morte
- elle est partiellement obsolète
- sur plusieurs points battle/runtime déjà livrés, elle est franchement dépassée par le repo actuel

## 9. Vérité produit / bootstrap / runtime

### 9.1. Le bootstrap reflète-t-il honnêtement le moteur ?

Réponse:
- oui globalement
- non parfaitement

Oui, parce que:
- le seed est explicitement curaté, pas vendu comme "tout Showdown" dans [pokemon_moves_bootstrap_seed.dart](/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/seeds/pokemon_moves_bootstrap_seed.dart:30)
- les tests verrouillent explicitement les seams non supportés en `catalogOnly` dans [pokemon_moves_bootstrap_seed_test.dart](/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_moves_bootstrap_seed_test.dart:17)
- un projet frais battleable existe réellement via la golden slice du host dans [examples/playable_runtime_host/README.md](/Users/karim/Project/pokemonProject/examples/playable_runtime_host/README.md:6)

Non parfaitement, parce que:
- `trick_room` reste `structuredPartial` dans le seed alors que le moteur/bridge savent désormais exécuter un vrai petit sous-ensemble
- `stealth_rock` et `spikes` vivent encore dans la liste `_catalogOnlySeedMoves`, ce qui n'est plus bien aligné avec leur support réel

Verdict bootstrap:
- pas mensonger
- un peu en retard sur le moteur
- encore défendable comme seed curaté minimal

### 9.2. Le runtime promet-il plus que le moteur ?

Réponse: non, pas sur le seam live audité.

Pourquoi:
- [RuntimeBattleMoveBridge](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/application/runtime_battle_move_bridge.dart:863) refuse explicitement beaucoup de formes hors subset
- le runtime ne projette pas silencieusement des effets qu'il ne sait pas porter honnêtement
- l'overlay refuse même une restitution mensongère sans `timeline` dans [battle_overlay_component.dart](/Users/karim/Project/pokemonProject/packages/map_runtime/lib/src/presentation/flame/battle_overlay_component.dart:43)

Le vrai risque runtime n'est pas la sur-promesse. Le vrai risque est:
- le hard-fail si le contenu n'a plus de move bridgeable

### 9.3. Le moteur sait-il plus que le bootstrap ?

Réponse: oui, légèrement.

Cas les plus nets:
- `Trick Room`: moteur + bridge savent porter un petit subset réel, seed encore `structuredPartial`
- la battle loop réelle du host et de la golden slice va plus loin que ce que beaucoup de vieux reports ou textes bootstrap racontent encore

### 9.4. Ou sont les mensonges restants ?

Mensonges restants ou quasi-mensonges:
- roadmap battle/runtime en retard sur le code
- reports historiques encore lisibles comme si leur état était actuel
- seed structuré de façon un peu trompeuse

Ce qui n'est pas un mensonge:
- le README de package `map_runtime` n'est pas la source de vérité produit globale; il documente un package, pas tout le host de référence

### 9.5. Ou sont les zones honnêtes ?

Zones honnêtes:
- bridge runtime -> battle
- overlay timeline
- capture minimale
- host golden slice battleable
- rejects explicites hors scope
- `catalogOnly` sur plusieurs seams réellement non supportés

## 10. Comparaison Showdown ciblée

Repo Showdown local utilisé:
- `/Users/karim/Project/pokemonProject/pokemon-showdown-master`

### 10.1. Décision / request model

PokeMap:
- [BattleDecisionRequest](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_decision.dart:70) expose un request model joueur, singles, slot `0`
- `BattleTurnChoiceRequest`, `BattleForcedReplacementRequest`, `BattleContinueRequest`, `BattleWaitRequest`

Showdown:
- `Side.requestState`, `activeRequest`, `getRequestData()` dans [sim/side.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:280)
- move/switch/teamPreview/wait, plus la richesse interne de `choice.actions`

Verdict:
- PokeMap: honnête mais simplifié
- Showdown: beaucoup plus riche

### 10.2. Side / slot

PokeMap:
- un side explicite avec actif + réserve dans [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:515)
- `slotIndex == 0` imposé en singles dans [battle_state.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_state.dart:535)

Showdown:
- `Side` et `active[]` plus riches dans [sim/side.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/side.ts:340)

Verdict:
- pour le scope courant, PokeMap est suffisamment honnête
- ce n'est pas une topologie comparable à Showdown au-delà de ce scope

### 10.3. Ordre d'action

PokeMap:
- ordre local dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1347)

Showdown:
- `order`, `priority`, `fractionalPriority`, `speed`, plus types d'action riches dans [sim/battle-queue.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/battle-queue.ts:24)

Verdict:
- PokeMap: slice local honnête
- Showdown: vrai système de scheduling

### 10.4. Speed / priority / Trick Room

PokeMap:
- priorité puis vitesse effective puis inversion Trick Room puis tie-break stable
- switch priorisé via constante locale `6` dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1451)

Showdown:
- priorité plus large, ordres d'action plus riches, `Trick Room` avec `pseudoWeather`, callbacks et intégration plus profonde dans [data/moves.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/moves.ts:20007)

Verdict:
- PokeMap: localement honnête mais simplifié
- loin d'une convergence Showdown forte

### 10.5. Accuracy / PP / crit

PokeMap:
- accuracy et PP réels
- crit minimal
- pas d'accuracy/evasion stages
- pas de Struggle

Showdown:
- modèle beaucoup plus complet, intégré au moteur global et à la data move

Verdict:
- petit slice local honnête, pas parité Showdown

### 10.6. Dégâts simples

PokeMap:
- vraie formule simple dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:1787)

Showdown:
- pipeline de dégâts plus riche, avec conditions, items, abilities, hooks et cas spéciaux

Verdict:
- PokeMap défendable comme "simplified Pokemon-like damage"
- pas Showdown-like au sens fort

### 10.7. STAB / type effectiveness / immunités

PokeMap:
- chart local et immunités dans [battle_type_chart.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_type_chart.dart:199)

Showdown:
- richesse de résolution bien plus large et plus de dépendances contextuelles

Verdict:
- assez proche pour le petit scope actuel
- pas plus

### 10.8. Statuts majeurs

PokeMap:
- seulement `par`, `brn`, `psn`, `tox` dans [battle_status.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_status.dart:3)

Showdown:
- conditions beaucoup plus riches dans [data/conditions.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/data/conditions.ts:162)

Verdict:
- loin de Showdown

### 10.9. Volatiles

PokeMap:
- `protect`, recharge, charge seulement dans [battle_volatile.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_volatile.dart:48)

Showdown:
- large universe de volatiles, interactions et callbacks

Verdict:
- loin de Showdown

### 10.10. Field / weather / pseudoWeather

PokeMap:
- `rain`, `sandstorm`, `trickRoom` uniquement dans [battle_field.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_field.dart:91)

Showdown:
- `pseudoWeather` map générique avec add/remove/restart dans [sim/field.ts](/Users/karim/Project/pokemonProject/pokemon-showdown-master/sim/field.ts:186)

Verdict:
- PokeMap honnête mais très réduit

### 10.11. Switch volontaire

PokeMap:
- vraiment supporté dans le request model et la résolution

Showdown:
- support beaucoup plus riche avec transitions et actions liées

Verdict:
- proche du minimum utile pour le scope courant

### 10.12. Forced replacement

PokeMap:
- supporté, mais réalisé via prochaine requête explicite

Showdown:
- force switch plus intégré et plus riche

Verdict:
- slice local honnête, pas convergence

### 10.13. Auto-switch ennemi

PokeMap:
- oui, supporté après KO via queue / reserve selection

Showdown:
- oui, mais dans un scheduler plus riche

Verdict:
- localement honnête

### 10.14. Timeline observable

PokeMap:
- vraie `timeline`
- l'overlay en dépend explicitement

Showdown:
- battle log plus riche, plus profond, plus stable dans ses sémantiques

Verdict:
- bon seam produit local
- pas une équivalence de log battle

### 10.15. Queue / scheduling

PokeMap:
- petite queue locale

Showdown:
- vraie action queue centrale

Verdict:
- zone la plus éloignée de Showdown avec le request model et les conditions

### 10.16. Hazards / side-level mechanics

PokeMap:
- `Stealth Rock` et `Spikes` seulement
- groundedness simplifiée
- ordre `Stealth Rock` puis `Spikes` dans [battle_session.dart](/Users/karim/Project/pokemonProject/packages/map_battle/lib/src/battle_session.dart:2284)

Showdown:
- side conditions génériques et ordering plus large dans [test/sim/misc/hazards.js](/Users/karim/Project/pokemonProject/pokemon-showdown-master/test/sim/misc/hazards.js:70)

Verdict:
- slice local honnête
- trop pauvre pour parler de vraie convergence hazard system

### 10.17. Runtime bridge

PokeMap:
- bridge strict et honnête
- pas d'équivalent direct Showdown, car il s'agit d'un seam produit PokeMap

Verdict:
- `not_applicable_yet` côté alignement Showdown fort
- très bon seam de vérité produit

### 10.18. Bootstrap truth

PokeMap:
- seed battleable curaté, vrai host de référence

Showdown:
- pas de rôle équivalent direct

Verdict:
- `not_applicable_yet` pour la parité Showdown
- bon outil de vérité produit locale

### 10.19. Conclusion comparative ciblée

Conclusion Showdown ciblée:
- PokeMap n'est pas "près de Showdown"
- PokeMap a un slice local honnête, branché au produit, qui touche plusieurs familles réelles
- la zone la plus comparable à Showdown aujourd'hui est la petite logique locale de tour / damage / hazards / field
- la zone la moins comparable est la couche request / queue / conditions / targeting

## 11. Incidents rencontrés

Incidents réellement rencontrés pendant l'audit:
- un `rg README.md` a échoué parce qu'il n'existe pas de `README.md` racine à ce chemin. Bruit de commande, pas problème repo.
- deux commandes Flutter ont affiché brièvement `Waiting for another flutter command to release the startup lock...`. Bruit outil, pas problème battle/runtime.
- le reviewer séparé `Huygens` a nécessité un recadrage avant de rendre un retour exploitable.
- un second reviewer `Carson` a été lancé pour trancher une contradiction documentaire / de wording.
- aucune commande de validation ciblée battle/runtime/editor/host n'a échoué.

Limites de comparaison:
- l'audit n'a pas construit de test de parité automatisé PokeMap vs Showdown, move par move
- la comparaison Showdown est fondée sur lecture de sources primaires et tests Showdown consultés, pas sur exécution croisée du même scénario dans les deux moteurs

## 12. Décisions retenues / rejetées

### 12.1. Réellement acquis

Considéré comme réellement acquis:
- true battle loop locale
- player + enemy reserves
- trainer battle multi-Pokémon en singles
- typed request model
- priority / speed / Trick Room local
- PP / accuracy / crit minimal
- simple damage + STAB + type chart
- statuses `par/brn/psn/tox`
- volatiles subset
- weather subset
- SR + Spikes
- true runtime bridge
- true host golden slice
- true capture minimale / write-back minimal

### 12.2. Refusé comme "acquis"

Refusé comme acquis:
- parité Showdown globale
- request model Showdown-like
- generic scheduling layer
- generic side conditions
- generic field condition system
- targeting riche
- broader hazard system
- post-battle persistence riche
- honest support of all seeded or imported move families

### 12.3. Considéré comme fragile

Considéré comme fragile:
- no Struggle
- enemy `Run` fallback edge-case
- double KO victory bias
- hard-fail no-bridgeable-move
- bootstrap structure drift
- roadmap / reports canoniques en retard

### 12.4. Considéré comme trompeur

Considéré comme trompeur:
- lire la roadmap globale comme si elle décrivait encore l'état réel battle/runtime
- lire les reports BE1 / lot11 / post-M8 comme vérité actuelle
- appeler "presque Showdown" le moteur actuel parce qu'il sait SR / Spikes / Trick Room / switch

## 13. Retour des sub-agents

### 13.1. Sub-agent battle-core / architecture: Laplace

Apport:
- a confirmé que le moteur est réellement `singles-only`, avec request model réel, ordre de tour réel, statuts/volatiles/field/hazards réellement vivants
- a mis le doigt sur `battle_session.dart` comme monolithe restant
- a jugé que partir sur H3 était prématuré

Retenu:
- diagnostic structurel sur `battle_session.dart`
- verdict que la tranche actuelle est réelle mais encore étroite
- mise en garde sur le modèle de target plus large que le resolver réel

Rejeté ou nuancé:
- son "pas prêt pour H3" a été gardé comme recommandation finale, mais j'ai nuancé qu'un micro-slice pourrait techniquement encore rentrer; ce n'est simplement pas la décision recommandée

### 13.2. Sub-agent showdown comparison: Dirac

Apport:
- a confirmé la présence d'un clone local Showdown
- a comparé chaque famille importante avec fichiers Showdown précis
- a conclu que le moteur local est Showdown-like seulement sur un slice borné

Retenu:
- request model / queue / conditions bien trop loin de Showdown
- hazards / field / order comme simplifications locales honnêtes
- pas de `not_applicable_yet` généreux sur les familles déjà ouvertes

Rejeté ou nuancé:
- rien de substantiel rejeté; sa lecture a été reprise presque telle quelle

### 13.3. Sub-agent runtime/bootstrap truth: Pasteur

Apport:
- a confirmé que le seam runtime -> battle -> overlay -> write-back est live et honnête
- a identifié des contradictions entre vieux reports et code actuel
- a jugé le bootstrap globalement honnête

Retenu:
- runtime live honnête
- capture / write-back / whiteout-lite réels
- reports BE1 et lot11 dépassés par le code

Rejeté ou nuancé:
- j'ai ensuite précisé avec le reviewer que le `write-back runtime` ne doit pas être sur-vendu: il est réel, mais étroit

## 14. Retour du reviewer séparé

### 14.1. Reviewer principal: Huygens

Findings concrets:
- mon draft sur-vendait un peu le `write-back runtime`; il faut le décrire comme un seam étroit, pas comme une persistance battle large
- le hard-fail `no bridgeable move` doit être traité comme un blocker produit réel
- le bootstrap est globalement honnête, mais sous-déclare légèrement le moteur actuel sur `trick_room`

Ce qu'il a challengé:
- la présentation trop large du write-back
- la décision "non" trop absolue sur H3

Ce que j'en ai retenu:
- correction de wording sur le write-back
- ajout explicite du blocker `no bridgeable move`

Ce que je n'ai pas retenu comme verdict final:
- son `yes under conditions` pour H3
- je l'ai jugé techniquement défendable comme possibilité, mais pas comme recommandation canonique

### 14.2. Reviewer de recadrage: Carson

Findings concrets:
- la bonne formulation n'est pas "duel 1v1 plat", mais moteur `singles-only` avec réserves réelles
- le README de `packages/map_runtime` n'est pas la meilleure source de contradiction produit; le vrai récit produit battleable vit surtout dans le host et la golden slice
- verdict H3: `no`

Ce qu'il a challengé:
- mon ancien wording "1v1" trop étroit
- mon pointage trop lourd sur le README de package runtime

Ce que j'en ai retenu:
- correction du wording vers `singles-only avec réserves`
- recentrage des preuves produit sur le host et la golden slice
- confirmation du verdict final `non`

Doutes restants après review:
- aucun finding structurel nouveau n'a invalidé le diagnostic principal
- le seul vrai désaccord résiduel concernait la recommandation H3; j'ai arbitré contre H3

## 15. Critique explicite du prompt

Ce que le prompt demande correctement:
- source de vérité centrée sur le code réel
- refus explicite des faux "supports"
- obligation de regarder runtime et bootstrap
- obligation de confronter roadmap / reports / code
- exigence utile de comparaison Showdown ciblée, pas globale
- exigence utile de sub-agents et review séparée

Ce qui est discutable:
- le prompt tend à supposer qu'il existe probablement encore un mensonge runtime important; ce n'est plus vraiment le cas sur le seam battle live
- il pousse à parler en `singles 1v1`; le wording exact du repo est un peu plus riche, puisqu'il y a réserves et trainer battles multi-membres dans un cadre `singles-only`
- il sur-indexe parfois le fichier `map_runtime/README.md` comme vérité produit possible, alors que le host de référence et la golden slice sont des preuves plus directes

Ce qui est déjà dépassé par le repo:
- l'idée que handoff réel, combat sauvage réel, capture minimale, whiteout-lite seraient encore simplement des cibles futures
- plusieurs soupçons historiques sur `priority`, `critRatio`, ou l'absence complète de champ / hazards / switch pipeline

Ce qui pourrait pousser vers un faux diagnostic si suivi aveuglément:
- conclure trop vite "il faut H3" juste parce que H1/H2 existent
- conclure trop vite "le runtime ment encore" sans relire le host et les tests actuels
- conclure trop vite "presque Showdown" parce que quelques mécaniques nommées existent

## 16. Autocritique finale

Limites réelles de l'audit:
- je n'ai pas exécuté un harness de comparaison automatique PokeMap vs Showdown
- je n'ai pas relancé l'intégralité de tous les tests de tous les packages du monorepo; j'ai ciblé battle/runtime/bootstrap/host, ce qui est cohérent avec le scope
- je n'ai pas ouvert chaque report historique battle existant; j'ai lu les reports directement pertinents et les plus susceptibles de contredire l'état actuel

Points où je pourrais encore me tromper:
- sur l'importance exacte d'un futur H3 ultra-minimal si le repo voulait volontairement rester longtemps dans des seams très bornés
- sur certaines divergences fines de résolution vis-a-vis de Showdown qui demanderaient des scénarios pas seulement une lecture de code

Zones insuffisamment vérifiées:
- comportement exact de certains cas edge-case non explicitement couverts par les tests ciblés lus pendant l'audit
- impact exact d'éventuels call sites battle directs hors runtime principal

Points qui restent des inférences plutôt que des certitudes:
- le seuil précis a partir duquel un futur slice basculerait de "encore acceptable localement" a "architecture devenue trop pauvre"
- la quantité exacte de consolidation documentaire nécessaire avant d'ouvrir la suite

Mais les points centraux de ce rapport ne sont pas des inférences faibles:
- l'état battle/runtime/host réellement branché
- l'écart structurant avec Showdown
- l'obsolescence partielle de la roadmap et de certains reports
- la centralité encore problématique de `battle_session.dart`

## 17. Décision nette sur la suite

Décision finale

- État réel du moteur par rapport à Showdown : vrai slice `singles-only` avec réserves, trainer battles multi-membres, runtime handoff et write-back minimal réels, mais encore loin de la profondeur structurelle et de la flexibilité de Showdown.
- Niveau de vérité produit actuel : globalement honnête sur la tranche ouverte; les écarts restants sont surtout documentaires, historiques ou de classement bootstrap, pas des promesses live majeures non tenues.
- Roadmap actuelle encore fiable ou non : utile comme vision générale, non fiable comme photo canonique de l'état battle/runtime actuel, et partiellement obsolète sur les slices déjà livrés.
- H3 maintenant : non
- Raison principale : le repo a déjà assez de mécanique réelle pour nécessiter d'abord une consolidation du canon technique et documentaire; ouvrir un H3 maintenant risquerait surtout d'ajouter une nouvelle exception locale sur une architecture encore trop centralisée et des contrats encore trop serrés.
- Prochaine marche recommandée : consolidation d'abord: réaligner roadmap / reports / seed bootstrap / vérité produit, formaliser le canon du slice battle actuel, puis seulement réévaluer le prochain slice battle sur base stabilisée.

## 18. Checklist finale

- ai-je utilisé le code réel comme source de vérité principale ? oui
- ai-je distingué support honnête vs support partiel vs support mensonger ? oui
- ai-je comparé le moteur à Showdown sur le bon périmètre ? oui
- ai-je évalué runtime et bootstrap, pas seulement `map_battle` ? oui
- ai-je signalé les contradictions roadmap / repo ? oui
- ai-je évité tout faux "c'est presque bon" ? oui
- ai-je décidé clairement si H3 est cohérent maintenant ou non ? oui
- ai-je justifié cette décision avec preuves ? oui
- ai-je gardé le travail strictement read-only ? oui, hors création du présent report demandée explicitement
- ai-je utilisé des sub-agents ? oui
- ai-je fait une review séparée ? oui
- ai-je inclus une autocritique finale ? oui
