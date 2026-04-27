# PSDK Battle - Lot 16 Weight Power Moves

## Resume executif

Ce lot ajoute dans `packages/map_battle` le port Dart des familles Pokemon SDK dont la puissance depend du poids :

- `s_low_kick`
- `s_heavy_slam`

Les deux methods passent de `missing` a `partial` dans la matrice PSDK. Le statut reste volontairement `partial`, car PSDK gere aussi des cas non encore portes : effet `Minimize` pour Heavy Slam, bypass d'accuracy sur `Minimize`, et fallback de poids modifie selon abilities/effects.

## Scope confirme

Inclus :

- Contrat poids minimal dans le snapshot de combat PSDK pur Dart.
- Behavior dediee `WeightPowerMoveBehavior`.
- Registre `StaticBasicMoveRegistry`.
- Scenario CLI `weight_power`, couvrant Low Kick et Heavy Slam dans le meme tour.
- Tests TDD sur seuils stricts, garde-fou poids invalide, secondary chain, CLI et manifest.
- Regeneration des matrices PSDK.

Hors scope volontaire :

- Wiring `map_runtime` / species loader vers le poids des especes.
- Effet `Minimize`.
- Bypass d'accuracy conditionnel cible pour Heavy Slam.
- Abilities/effects qui modifient ou annulent les changements de poids.

## Audit initial

Scripts PSDK lus :

- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 LowKick.rb`
- `pokemonsdk-development/scripts/5 Battle/10 Move/2 Definitions/300 HeavySlam.rb`

Formules relevees :

- Low Kick :
  - seuils stricts cible `< 10`, `< 25`, `< 50`, `< 100`, `< 200`
  - puissance `20 + 20 * index`, soit `20/40/60/80/100/120`
- Heavy Slam :
  - ratio `target_weight / user.weight`
  - seuils stricts `> 0.5`, `> 0.3334`, `> 0.25`, `> 0.20`
  - puissance `40 + 20 * index`, soit `40/60/80/100/120`
  - si cible sous `minimize`, puissance x2 et bypass accuracy

Contrats Dart existants :

- `VariablePowerMoveBehavior` portait deja les formules de puissance locale mais signalait explicitement que les familles a poids etaient hors scope.
- `PsdkBattleCombatantSetup` et `PsdkBattleCombatant` ne transportaient pas encore de poids.
- `PsdkBattleCli` avait deja des scenarios par famille de formule.
- `extract_psdk_move_registry.dart` pilotait le manifest et la matrice.

Decision :

- Ajouter `baseWeightKg` et `currentWeightKg` dans le snapshot PSDK, avec default `1` pour ne pas casser les anciens fixtures.
- Creer `WeightPowerMoveBehavior` separee de `VariablePowerMoveBehavior`, pour garder la limite de lot visible.
- Garder `partial`.

## Sub-agents et passes

### Audit / Architecture - Carson

Verdict :

- Les formules exactes sont celles listees ci-dessus.
- `s_low_kick` et `s_heavy_slam` doivent rester `partial`.
- Ajouter le poids dans `PsdkBattleCombatantSetup` / `PsdkBattleCombatant`, pas dans `map_core`.
- Couvrir les seuils stricts et les poids invalides.

### Implementation

Actions :

- Ajout du contrat poids dans `psdk_battle_combatant.dart`.
- Creation de `weight_power_move_behavior.dart`.
- Enregistrement des deux behaviors.
- Ajout scenario CLI `weight_power`.
- Mise a jour extracteur/manifest/matrice.

### Tests

Cycle TDD :

- RED `weight_power_test.dart` : echec attendu sur parametre `baseWeightKg` absent.
- RED `psdk_battle_cli_test.dart` : echec attendu sur scenario `weight_power` inconnu.
- RED `psdk_registry_manifest_test.dart` : echec attendu car `s_low_kick` et `s_heavy_slam` etaient encore `missing`.
- GREEN apres implementation et regeneration.

### Critique finale - Turing

Verdict initial :

- Aucun bloquant.
- Low Kick et Heavy Slam corrects.
- Statuts `partial` corrects.
- Point non bloquant : le CLI ne couvrait initialement que Low Kick.

Action prise :

- Le scenario `weight_power` couvre maintenant Low Kick puis Heavy Slam.
- Le test CLI verifie `low_kick=19`, `heavy_slam=22`, `opponentHp=81`, `playerHp=78`.

## Fichiers modifies / crees

### `packages/map_battle/lib/src/psdk/domain/psdk_battle_combatant.dart`

Zones modifiees :

- `PsdkBattleCombatantSetup`
  - ajout `baseWeightKg`
  - ajout `currentWeightKg`
  - validation poids fini et positif
- `PsdkBattleCombatant`
  - ajout `baseWeightKg`
  - ajout `currentWeightKg`
  - passage depuis `fromSetup`
  - support dans `copyWith`
- helper `_requirePositiveWeight`

Raison :

- Les moves PSDK a poids doivent lire une donnee de combat, sans coupler le moteur aux donnees d'espece ou a `map_core`.

Impact attendu :

- Les anciens tests continuent de fonctionner via default `1kg`.
- Les futurs effects pourront modifier `currentWeightKg`.

### `packages/map_battle/lib/src/domain/move/behaviors/weight_power_move_behavior.dart`

Statut : fichier cree.

Contenu complet :

```dart
import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _WeightPowerKind {
  lowKick,
  heavySlam,
}

/// Ports PSDK moves whose base power is determined by battler weight.
///
/// The formulas intentionally consume the combatant's battle snapshot rather
/// than reaching into species data. That keeps the battle engine pure and lets
/// runtime/editor import layers decide later how base/current weights are
/// hydrated. PSDK's Minimize bonus/bypass and ability fallback around modified
/// weights remain outside this slice, so these methods stay `partial`.
final class WeightPowerMoveBehavior implements BattleMoveBehavior {
  const WeightPowerMoveBehavior.lowKick()
      : battleEngineMethod = 's_low_kick',
        _kind = _WeightPowerKind.lowKick;

  const WeightPowerMoveBehavior.heavySlam()
      : battleEngineMethod = 's_heavy_slam',
        _kind = _WeightPowerKind.heavySlam;

  @override
  final String battleEngineMethod;
  final _WeightPowerKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final resolvedPower = switch (_kind) {
      _WeightPowerKind.lowKick => _lowKickPower(target),
      _WeightPowerKind.heavySlam => _heavySlamPower(user, target),
    };

    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(power: resolvedPower),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: damageResult.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  int _lowKickPower(PsdkBattleCombatant target) {
    final targetWeight = target.currentWeightKg;
    const maximumWeights = <double>[10, 25, 50, 100, 200];
    final index = maximumWeights.indexWhere((weight) => targetWeight < weight);
    return 20 + 20 * (index == -1 ? maximumWeights.length : index);
  }

  int _heavySlamPower(
    PsdkBattleCombatant user,
    PsdkBattleCombatant target,
  ) {
    final weightPercent = target.currentWeightKg / user.currentWeightKg;
    const minimumWeightPercent = <double>[0.5, 0.3334, 0.25, 0.20];
    final index =
        minimumWeightPercent.indexWhere((weight) => weightPercent > weight);
    return 40 + 20 * (index == -1 ? minimumWeightPercent.length : index);
  }
}
```

### `packages/map_battle/lib/src/data/static_basic_move_registry.dart`

Zones modifiees :

- Import de `weight_power_move_behavior.dart`.
- Ajout :
  - `WeightPowerMoveBehavior.lowKick`
  - `WeightPowerMoveBehavior.heavySlam`

### `packages/map_battle/lib/src/psdk/cli/psdk_battle_cli.dart`

Zones modifiees :

- Nouveau scenario `weightPower`.
- Parsing `weight_power` / `weight-power`.
- Message d'erreur scenario mis a jour.
- Fixture `weight_power` :
  - joueur `low_kick`, poids joueur `20kg`
  - adversaire `heavy_slam`, poids adversaire `100kg`
  - sortie attendue : Low Kick `19`, Heavy Slam `22`

### `packages/map_battle/tool/extract_psdk_move_registry.dart`

Zones modifiees :

- Ajout dans `_knownDartBehaviors` :
  - `s_low_kick` => `WeightPowerMoveBehavior.lowKick`, `partial`
  - `s_heavy_slam` => `WeightPowerMoveBehavior.heavySlam`, `partial`

### `packages/map_battle/lib/src/data/generated/psdk_move_registry_manifest.dart`

Zones modifiees :

- Regeneration.
- `s_low_kick` et `s_heavy_slam` passent de `missing` a `partial`.

### `reports/psdk-move-porting-matrix.md`

Zones modifiees :

- Regeneration.
- Counts :
  - `ported`: 16
  - `partial`: 12
  - `missing`: 288

### `reports/psdk-effect-porting-matrix.md`

Zones modifiees :

- Regeneration via l'extracteur d'effets, sans nouveau port d'effet.

## Tests crees ou modifies

### `packages/map_battle/test/psdk_move_families/weight_power_test.dart`

Statut : fichier cree.

Contenu complet :

```dart
import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK weight-power move families', () {
    test('s_low_kick keeps PSDK strict target-weight thresholds', () {
      PsdkBattleTurnResult runLowKickAtWeight(double targetWeight) {
        return _runMove(
          playerMove: _move(
            id: 'low_kick',
            battleEngineMethod: 's_low_kick',
            power: 1,
          ),
          opponentWeight: targetWeight,
        );
      }

      // PSDK uses strict `<` limits: exact thresholds already belong to the
      // next stronger bucket.
      expect(_damage(runLowKickAtWeight(9), moveId: 'low_kick'), 5);
      expect(_damage(runLowKickAtWeight(10), moveId: 'low_kick'), 8);
      expect(_damage(runLowKickAtWeight(25), moveId: 'low_kick'), 12);
      expect(_damage(runLowKickAtWeight(50), moveId: 'low_kick'), 15);
      expect(_damage(runLowKickAtWeight(100), moveId: 'low_kick'), 19);
      expect(_damage(runLowKickAtWeight(200), moveId: 'low_kick'), 22);
    });

    test('s_heavy_slam keeps PSDK strict weight-ratio thresholds', () {
      PsdkBattleTurnResult runHeavySlamAtTargetWeight(double targetWeight) {
        return _runMove(
          playerMove: _move(
            id: 'heavy_slam',
            battleEngineMethod: 's_heavy_slam',
            power: 1,
          ),
          playerWeight: 100,
          opponentWeight: targetWeight,
        );
      }

      // PSDK uses strict `>` ratio limits. With user weight 100:
      // 51% => 40 power, 50% => 60, 33% => 80, 25% => 100, 20% => 120.
      expect(_damage(runHeavySlamAtTargetWeight(51), moveId: 'heavy_slam'), 8);
      expect(_damage(runHeavySlamAtTargetWeight(50), moveId: 'heavy_slam'), 12);
      expect(_damage(runHeavySlamAtTargetWeight(33), moveId: 'heavy_slam'), 15);
      expect(_damage(runHeavySlamAtTargetWeight(25), moveId: 'heavy_slam'), 19);
      expect(_damage(runHeavySlamAtTargetWeight(20), moveId: 'heavy_slam'), 22);
    });

    test('weight-power moves keep the post-damage secondary chain', () {
      final result = _runMove(
        playerMove: _move(
          id: 'low_kick',
          battleEngineMethod: 's_low_kick',
          power: 1,
          stageMods: const <PsdkBattleMoveStageMod>[
            PsdkBattleMoveStageMod(
              stat: 'speed',
              stages: -1,
              chance: 100,
            ),
          ],
        ),
        opponentWeight: 100,
      );

      final events = result.timeline.events.map((event) => event.kind).toList();
      expect(
        events,
        containsAllInOrder(<String>[
          'damage',
          'stat_stage_change',
        ]),
      );
      expect(
        result.state.battlerAt(psdkOpponentSlot).statStages.valueOf('speed'),
        -1,
      );
    });

    test('rejects non-positive battler weights before damage math', () {
      expect(
        () => _combatant(
          id: 'invalid',
          weight: 0,
          move: _move(id: 'low_kick', power: 1),
        ),
        throwsArgumentError,
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  double playerWeight = 100,
  double opponentWeight = 100,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        weight: playerWeight,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        weight: opponentWeight,
        move: _move(
          id: 'opponent_wait',
          power: 0,
          accuracy: 1,
        ),
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required double weight,
  required PsdkBattleMoveData move,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    // Keep fixture types away from move types so formula assertions do not
    // measure STAB or type effectiveness by accident.
    types: const PsdkBattleTypes(primary: 'fire'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    baseWeightKg: weight,
    moves: <PsdkBattleMoveData>[move],
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  int criticalRate = 0,
  String battleEngineMethod = 's_basic',
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: 0,
    criticalRate: criticalRate,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
    stageMods: stageMods,
  );
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
```

### `packages/map_battle/test/psdk_battle_cli_test.dart`

Zones modifiees :

- Ajout test `prints a weight-power scenario for PSDK weight formulas`.
- Verifie Low Kick et Heavy Slam dans le meme JSON CLI.

### `packages/map_battle/test/psdk_registry_manifest_test.dart`

Zones modifiees :

- `s_low_kick` et `s_heavy_slam` attendus en `partial` avec mapping Dart explicite.

## Commandes lancees

Generation :

```bash
cd packages/map_battle
dart run tool/extract_psdk_move_registry.dart ../../pokemonsdk-development/scripts/5\ Battle ../../reports/psdk-move-porting-matrix.md --manifest lib/src/data/generated/psdk_move_registry_manifest.dart
dart run tool/extract_psdk_effect_matrix.dart ../../pokemonsdk-development/scripts/5\ Battle ../../reports/psdk-effect-porting-matrix.md
```

Tests et validation :

- `dart test test/psdk_move_families/weight_power_test.dart` => `+4: All tests passed!`
- `dart test test/psdk_battle_cli_test.dart` => `+14: All tests passed!`
- `dart test test/psdk_registry_manifest_test.dart` => `+11: All tests passed!`
- `dart analyze` => `No issues found!`
- `dart test` => `+344: All tests passed!`
- `dart compile exe bin/psdk_battle_cli.dart -o /tmp/psdk_battle_cli_check` => `Generated: /tmp/psdk_battle_cli_check`
- `dart run bin/psdk_battle_cli.dart --scenario weight_power --format json` => `low_kick damage 19`, `heavy_slam damage 22`
- `dart compile exe tool/extract_psdk_move_registry.dart -o /tmp/extract_psdk_move_registry_check` => `Generated: /tmp/extract_psdk_move_registry_check`
- `dart compile exe tool/extract_psdk_effect_matrix.dart -o /tmp/extract_psdk_effect_matrix_check` => `Generated: /tmp/extract_psdk_effect_matrix_check`
- `dart format --set-exit-if-changed ...` => `Formatted 8 files (0 changed)`
- `git diff --check` => exit code 0

## Etat git

Le worktree etait deja dirty avant ce lot. Ce lot ajoute/modifie des fichiers dans `packages/map_battle` et `reports`. Aucun changement preexistant dans `map_core`, `map_editor` ou `.idea` n'a ete revert.

## Limites et risques restants

- Heavy Slam ne gere pas encore `Minimize`.
- Le bypass accuracy de Heavy Slam sous `Minimize` necessitera un hook cible-scopé ou un prepare specialise.
- Le runtime ne renseigne pas encore les poids d'especes dans les setups PSDK reels.
- Le fallback PSDK `target.data.weight` selon modification de poids et ability/effect reste a porter.

## Prochaines etapes proposees

- Brancher les poids des especes depuis le loader runtime/import PSDK.
- Ajouter l'effet `Minimize`, son multiplicateur Heavy Slam et son bypass accuracy.
- Porter un nouveau groupe de moves `missing` proche : `s_triple_kick`, `s_population_bomb`, `s_water_shuriken` ou les moves conditionnels d'historique de tour.
