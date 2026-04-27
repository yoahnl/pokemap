# Rapport Lot 16 - Portage des familles de moves avancees, tranche HP-only

## Resume executif

Une premiere tranche du Lot 16 est implementee dans `packages/map_battle`.
Elle porte les familles PSDK qui peuvent fonctionner avec le state Dart actuel:

- degats fixes: `s_fixed_damage`, `s_hp_eq_level`, `s_psywave`, `s_super_fang`;
- multi-hit de base: `s_2hits`, `s_3hits`, `s_multi_hit`.

La tranche reste volontairement bornee:

- `s_2hits` et `s_3hits` sont marques `ported`;
- `s_multi_hit` est marque `partial`, car Skill Link n'existe pas encore dans
  le state/ability Dart;
- `s_triple_kick`, `s_population_bomb`, `s_water_shuriken` restent `missing`.

Le CLI PSDK expose maintenant deux scenarios de smoke test:

- `--scenario fixed_damage`;
- `--scenario multi_hit`.

## Scope confirme

Inclus:

- pipeline commun PSDK: declaration, targeting, accuracy, Protect, immunite type;
- application directe de degats HP sans RNG critique/damage pour les degats fixes;
- Psywave avec RNG `moveDamage`;
- multi-hit 2, 3 et distribution PSDK `[2, 2, 2, 3, 3, 5, 4, 3]`;
- arret multi-hit quand l'utilisateur ou la cible tombe KO;
- chaine secondaire post-degats existante (`status`, `stat_stage_change`) apres
  fixed-damage et apres le loop multi-hit.

Exclus:

- Skill Link;
- Triple Kick / Triple Axel;
- Population Bomb;
- Water Shuriken forme Greninja;
- event resume "hit N times";
- hazards, weather, terrain, force switch, switch-after-hit;
- state abilities/items/weights requis par d'autres familles.

## Audit initial

Fichiers PSDK consultes:

- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 FixedDamages.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 HPEqLevel.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 SuperFang.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/1 Mechanics/103 TwoHit MultiHit.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/120 Procedure.rb`

Fichiers Dart consultes:

- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_procedure.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_damage_calculator.dart`
- `packages/map_battle/lib/src/domain/move/battle_move_secondary_effect_resolver.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_state.dart`
- `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Risques identifies:

- weather/hazards/switch demandent du state PSDK manquant;
- multi-hit complet depend d'abilities et de recalculs accuracy par hit;
- fixed-damage et multi-hit ne doivent pas court-circuiter la chaine secondaire
  post-degats PSDK.

## Etat git initial

Le worktree etait deja sale et contient de nombreux fichiers non suivis des
lots precedents. Le travail de ce lot a ete limite a `packages/map_battle` et
aux matrices `reports/psdk-*-porting-matrix.md`.

## Fichiers crees

### `packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart`

Raison:

- extraire la preparation commune PSDK partagee par `s_basic`, `s_status`,
  `s_protect`, fixed-damage et multi-hit;
- eviter de dupliquer target/accuracy/Protect/immunity.

Zones principales:

- `prepareBattleMove`
- `applyDirectDamage`
- `precheckTypeImmunityAndProtect`
- conversions `BattlePositionRef` / `PsdkBattleSlotRef`
- `PreparedBattleMove`
- `BattleDirectDamageResult`

Impact:

- le registry peut ajouter des familles sans recopier le pipeline PSDK commun;
- les comportements HP-only utilisent les memes evenements de preparation que
  `s_basic`.

### `packages/map_battle/lib/src/domain/move/behaviors/fixed_damage_move_behavior.dart`

Raison:

- porter les classes Ruby `FixedDamages`, `HPEqLevel`, `Psywave`, `SuperFang`.

Logique:

- `sonic_boom`: 20 HP;
- `dragon_rage`: 40 HP;
- fallback PSDK `FixedDamages`: 1 HP;
- `s_hp_eq_level`: niveau du lanceur;
- `s_psywave`: `floor(level * (roll + 50) / 100)` avec roll 1..100 sur
  `moveDamage`;
- `s_super_fang`: moitie des HP courants de la cible, minimum 1;
- puis `BattleMoveSecondaryEffectResolver`.

Impact:

- degats directs sans consommation de RNG critique/damage sauf Psywave;
- respect du pipeline secondaire post-degats.

### `packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart`

Raison:

- porter `TwoHit`, `ThreeHit`, et la base `MultiHit`.

Logique:

- `s_2hits`: 2 hits;
- `s_3hits`: 3 hits;
- `s_multi_hit`: distribution PSDK `[2, 2, 2, 3, 3, 5, 4, 3]`;
- un damage event par hit;
- animation cue supplementaire apres le premier hit;
- arret si user ou target KO;
- secondary effects executes une seule fois apres le loop.

Impact:

- `double_slap` et autres multi-hit de base deviennent testables;
- variantes complexes restent hors scope.

### `packages/map_battle/test/psdk_move_families/fixed_damage_and_multi_hit_test.dart`

Raison:

- couvrir la tranche Lot 16 en TDD.

Cas couverts:

- Sonic Boom / Dragon Rage et absence de RNG damage/crit;
- miss commun sans degat;
- niveau utilisateur;
- Psywave et RNG `moveDamage`;
- Super Fang;
- secondary chain pour fixed-damage;
- `s_2hits`, `s_3hits`;
- distribution `s_multi_hit`;
- arret au KO;
- secondary chain multi-hit une seule fois.

## Fichiers modifies

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

Modifications:

- remplace la preparation locale par `prepareBattleMove`;
- reutilise `applyDirectDamage` dans `s_basic`;
- enregistre les nouveaux behaviors:
  - `FixedDamageMoveBehavior.psdkFixedDamage`
  - `FixedDamageMoveBehavior.userLevel`
  - `FixedDamageMoveBehavior.psywave`
  - `FixedDamageMoveBehavior.halfCurrentTargetHp`
  - `MultiHitMoveBehavior.fixed(2)`
  - `MultiHitMoveBehavior.fixed(3)`
  - `MultiHitMoveBehavior.psdkRandom`

Impact:

- registry par `battleEngineMethod`, pas par move id;
- pas de fallback silencieux.

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Modifications:

- ajoute `_PsdkBattleCliScenario.fixedDamage`;
- ajoute `_PsdkBattleCliScenario.multiHit`;
- parse aliases `fixed_damage` / `fixed-damage`, `multi_hit` / `multi-hit`;
- ajoute fixtures CLI.

Impact:

- les sub-agents peuvent tester la tranche moteur via CLI JSON.

### `packages/map_battle/tool/extract_psdk_move_registry.dart`

Modifications:

- table `_knownDartBehaviors` enrichie avec les methods du lot.

Impact:

- matrices et manifeste reflectent l'etat reel du moteur.

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Modifications:

- tests CLI `fixed_damage` et `multi_hit`.

### `packages/map_battle/test/psdk_registry_manifest_test.dart`

Modifications:

- test du statut Lot 16:
  - `s_fixed_damage`, `s_hp_eq_level`, `s_psywave`, `s_super_fang`,
    `s_2hits`, `s_3hits` en `ported`;
  - `s_multi_hit` en `partial`;
  - variantes complexes en `missing`.

### `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`

Genere apres mise a jour de l'extracteur.

### `reports/psdk-move-porting-matrix.md`

Generee apres mise a jour.

Etat:

```text
Total registered methods: 316
ported: 6
partial: 4
missing: 306
```

### `reports/psdk-effect-porting-matrix.md`

Regeneree pour garder les artefacts synchronises.

Etat:

```text
Total effect classes: 482
ported: 0
partial: 1
missing: 481
```

## Sub-agents et verdicts

### Audit / Architecture - Epicurus

Verdict:

- les points d'extension surs sont `BattleMoveBehavior`,
  `createStaticBasicMoveRegistry`, `BattleMoveProcedure`,
  `BattleMoveDamageCalculator`, `BattleMoveSecondaryEffectResolver`;
- weather/hazards/switch doivent attendre le state PSDK dedie;
- fixed-damage et multi-hit mono-cible sont les plus petits lots executables.

### Audit PSDK - Pauli

Verdict:

- fixed damage en premier;
- multi-hit coherent mais en sous-tranche;
- `triple_kick`, `population_bomb`, `water_shuriken` a repousser.

### Implementation - passe principale

Verdict:

- implementation bornee aux familles HP-only;
- pas de couplage Flutter/Flame;
- pas de dependance ajoutee.

### Tests / Build

Verdict:

- tests RED observes sur methods non supportees;
- tests RED observes sur manifeste encore `missing`;
- tests RED observes sur secondary chain manquante;
- tous corriges puis repasses au vert.

### Critique finale - Helmholtz

Findings:

- P2: multi-hit court-circuitait les effets secondaires post-degats;
- P3: fixed-damage court-circuitait aussi la chaine secondaire.

Correction:

- ajout de tests pour status/stat-stage apres fixed-damage et multi-hit;
- appel de `BattleMoveSecondaryEffectResolver` apres les degats.

## Commandes et resultats

Tests cibles:

```bash
cd packages/map_battle
dart test test/psdk_move_families/fixed_damage_and_multi_hit_test.dart
```

Resultat:

```text
00:00 +10: All tests passed!
```

Tests cibles larges:

```bash
dart test test/psdk_move_families/fixed_damage_and_multi_hit_test.dart test/psdk_battle_cli_test.dart test/psdk_registry_manifest_test.dart
```

Resultat:

```text
00:01 +30: All tests passed!
```

Analyse:

```bash
dart analyze
```

Resultat:

```text
Analyzing map_battle...
No issues found!
```

Suite complete:

```bash
dart test
```

Resultat:

```text
00:02 +317: All tests passed!
```

Build CLI:

```bash
dart compile exe bin/psdk_battle_cli.dart -o /tmp/pokemon_project_psdk_battle_cli
```

Resultat:

```text
Generated: /tmp/pokemon_project_psdk_battle_cli
```

Build outils:

```bash
dart compile exe tool/extract_psdk_move_registry.dart -o /tmp/pokemon_project_extract_psdk_move_registry
dart compile exe tool/extract_psdk_effect_matrix.dart -o /tmp/pokemon_project_extract_psdk_effect_matrix
```

Resultats:

```text
Generated: /tmp/pokemon_project_extract_psdk_move_registry
Generated: /tmp/pokemon_project_extract_psdk_effect_matrix
```

CLI smoke fixed damage:

```bash
dart run bin/psdk_battle_cli.dart --scenario fixed_damage --format json
```

Observation:

```text
outcome=ongoing, playerHp=100, opponentHp=60, dragon_rage damage=40
```

CLI smoke multi-hit:

```bash
dart run bin/psdk_battle_cli.dart --scenario multi_hit --format json
```

Observation:

```text
outcome=ongoing, playerHp=100, opponentHp=55, double_slap damage events=5
```

Diff hygiene:

```bash
git diff --check
```

Resultat: aucune sortie.

## Etat git final

Le worktree reste sale avec les lots precedents et des modifications hors scope
dans `map_core` / `map_editor`. Rien n'a ete revert.

Fichiers Lot 16 principaux:

- `packages/map_battle/lib/src/domain/move/behaviors/battle_move_behavior_support.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/fixed_damage_move_behavior.dart`
- `packages/map_battle/lib/src/domain/move/behaviors/multi_hit_move_behavior.dart`
- `packages/map_battle/test/psdk_move_families/fixed_damage_and_multi_hit_test.dart`
- `packages/map_battle/lib/src/data/static_basic_move_registry.dart`
- `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`
- `packages/map_battle/tool/extract_psdk_move_registry.dart`
- `packages/map_battle/test/psdk_battle_cli_test.dart`
- `packages/map_battle/test/psdk_registry_manifest_test.dart`
- `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`
- `reports/psdk-move-porting-matrix.md`
- `reports/psdk-effect-porting-matrix.md`

## Limites explicitement conservees

- Pas de Skill Link.
- Pas de per-hit accuracy pour Triple Kick/Population Bomb.
- Pas de forme Greninja / Battle Bond pour Water Shuriken.
- Pas de weights/items/abilities.
- Pas de hazards/weather/switch avant contrats PSDK dedies.
- Pas de summary event "hit N times".

## Auto-critique finale

La tranche est volontairement utile mais petite. Le choix de `s_multi_hit` en
`partial` est important: la distribution PSDK marche, mais l'ability Skill Link
manque. Les fixed-damage methods sont marquees `ported` parce que les classes
canoniques PSDK de cette famille sont couvertes, y compris la chaine secondaire
commune apres correction de revue.

## Prochaines etapes proposees sans implementation

1. Ajouter les contrats de poids/stat source pour `low_kick`, `heavy_slam`,
   `body_press`, `foul_play`.
2. Porter les custom power simples qui ne demandent pas de nouveau state.
3. Ajouter le state PSDK field/bank effects avant hazards/weather.
4. Reprendre `triple_kick`, `population_bomb`, `water_shuriken` quand accuracy
   par hit, ability et formes sont disponibles.
