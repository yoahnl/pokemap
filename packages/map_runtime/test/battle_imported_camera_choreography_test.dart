import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_runner.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_recipe_compiler.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_offline_move_recipe_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';

Map<String, Object> _recipe(
  Map<String, Object> program,
  List<String> capabilities,
) => {
  'schemaVersion': 1,
  'recipeId': 'camera-test',
  'revision': '1',
  'moveSourceId': 'source',
  'variant': 'default',
  'requiredCapabilities': capabilities,
  'provenance': {
    'source': 'synthetic',
    'sourceRevision': '1',
    'sourcePaths': <String>[],
    'converter': 'test',
  },
  'resources': <Object>[],
  'program': program,
};

Future<PreparedBattleMoveRecipe> _install(
  Directory root,
  Map<String, Object> recipe, {
  String moveId = 'tackle',
}) async {
  final bytes = utf8.encode(jsonEncode(recipe));
  final binding = BattleMoveRecipeBinding.fromJson({
    'schemaVersion': 1,
    'projectMoveId': moveId,
    'sourceMoveId': 'source',
    'catalogReleaseId': 'test',
    'recipeId': 'camera-test',
    'variant': 'default',
    'revision': '1',
    'recipeSha256': sha256.convert(bytes).toString(),
  });
  Future<void> write(String path, List<int> contents) async {
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(contents);
  }

  await write(
    battleRecipeBindingPath(moveId),
    utf8.encode(
      jsonEncode(BattleRecipeProjectBinding(binding: binding).toJson()),
    ),
  );
  await write(
    battleRecipeBlobPath(
      binding.recipeSha256,
      'application/vnd.avelune.battle-recipe+json',
      projectMoveId: moveId,
    ),
    bytes,
  );
  final loaded = await BattleOfflineMoveRecipeLoader(
    projectRootDirectory: root.path,
  ).load(moveId);
  expect(loaded.prepared, isNotNull);
  return loaded.prepared!;
}

BattleAnimationPlan _plan(
  PreparedBattleMoveRecipe? recipe, {
  bool fieldTarget = false,
  String recipeKey = 'tackle',
}) {
  BattleCombatantData combatant(String id) => BattleCombatantData(
    speciesId: id,
    lineupIndex: 0,
    level: 30,
    maxHp: 40,
    stats: const BattleStatsSnapshot(
      attack: 60,
      defense: 60,
      specialAttack: 60,
      specialDefense: 60,
      speed: 50,
    ),
    moves: [],
  );
  final session = createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: combatant('player'),
      enemyPokemon: combatant('enemy'),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
  final execution = BattleMoveExecution(
    attackerSlot: const BattleSlotRef.active(BattleSideId.player),
    move: const BattleMove(id: 'tackle', name: 'Tackle', power: 40),
    targetKind: fieldTarget
        ? BattleMoveExecutionTargetKind.field
        : BattleMoveExecutionTargetKind.combatant,
    targetSlot: fieldTarget
        ? null
        : const BattleSlotRef.active(BattleSideId.enemy),
    damage: fieldTarget ? 0 : 7,
    didHit: true,
  );
  final catalog = RuntimeMoveCatalog.fromEntries({});
  return BattleTurnAnimationPlanner(
    importedRecipes: {recipeKey: ?recipe},
    recipeBuilder: (_, _) => const [
      CombatantMotionStep(
        side: BattleSideId.player,
        motionKind: BattleCombatantMotionKind.lunge,
        durationSeconds: .1,
      ),
      PlaySeStep(seName: 'legacy'),
      SpawnFxStep(
        effectId: 'legacy-fx',
        attackerSide: BattleSideId.player,
        defenderSide: BattleSideId.enemy,
        from: BattleVisualAnchor.attackerCenter,
        to: BattleVisualAnchor.defenderCenter,
        durationSeconds: .1,
      ),
    ],
  ).buildForTurn(
    playerBefore: session.state.player,
    enemyBefore: session.state.enemy,
    turnResult: BattleTurnResult(
      playerAction: const BattleActionNone(),
      enemyAction: const BattleActionNone(),
      executions: [execution],
      timeline: [BattleTurnExecutionEvent(execution)],
    ),
    moveCatalog: catalog,
    resolver: BattleMoveVisualResolver(catalog),
  );
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('imported-camera-');
  });
  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'plays the local camera choreography and the legacy attack once',
    () async {
      final imported = await _install(
        root,
        _recipe(
          {
            'kind': 'sequence',
            'steps': [
              {'kind': 'cameraFocus', 'target': 'target', 'durationMs': 250},
              {'kind': 'wait', 'durationMs': 125},
            ],
          },
          ['sequence', 'cameraFocus', 'wait'],
        ),
      );
      final plan = _plan(imported);
      final steps = plan.flattenedSteps.toList();
      expect(steps.whereType<ShowMessageStep>(), hasLength(1));
      expect(steps.whereType<HudHpTweenStep>(), hasLength(1));
      expect(
        steps.whereType<CameraFocusStep>().where(
          (step) => step.durationSeconds == .25,
        ),
        hasLength(1),
      );
      expect(
        steps.whereType<WaitStep>().where(
          (step) => step.durationSeconds == .125,
        ),
        hasLength(1),
      );
      expect(steps.whereType<CombatantMotionStep>(), hasLength(1));
      expect(
        steps.whereType<SpawnFxStep>().where(
          (step) => step.effectId == 'legacy-fx',
        ),
        hasLength(1),
      );

      final events = <String>[];
      final runner = BattleAnimationRunner(
        onPresentationChanged: () {},
        onSpawnFx: (step) => events.add('fx:${step.effectId}'),
        onScreenFlash: (_) {},
        onCombatantMotion: (_) => events.add('motion'),
        onCombatantFlash: (_) {},
        onCombatantShake: (_) {},
        onFaintCombatant: (_) {},
        onHudHpTween: (step) => events.add('hp:${step.fromHp}->${step.toHp}'),
        onBarrierPulse: (_) {},
        onSwapCombatantVisual: (_) {},
        onPlaySe: (step) => events.add('sound:${step.seName}'),
        onCameraFocus: (step) {
          if (step.durationSeconds == .25) events.add('imported-camera');
        },
        onBattleCameraReset: (_) {},
        messageStepSeconds: 0,
      );
      runner.start(plan);
      for (var i = 0; i < 200 && runner.isActive; i++) {
        runner.update(.1);
      }
      expect(runner.isActive, isFalse);
      expect(events.where((event) => event == 'imported-camera'), hasLength(1));
      expect(events.where((event) => event == 'motion'), hasLength(1));
      expect(events.where((event) => event == 'sound:legacy'), hasLength(1));
      expect(events.where((event) => event == 'fx:legacy-fx'), hasLength(1));
      expect(events.where((event) => event == 'hp:40->33'), hasLength(1));
      expect(
        events.indexOf('imported-camera'),
        lessThan(events.indexOf('motion')),
      );
      expect(
        events.indexOf('fx:legacy-fx'),
        lessThan(events.indexOf('hp:40->33')),
      );
    },
  );

  test(
    'keeps the legacy attack when the required target is unavailable',
    () async {
      final imported = await _install(
        root,
        _recipe(
          {'kind': 'cameraFocus', 'target': 'target', 'durationMs': 250},
          ['cameraFocus'],
        ),
      );
      final steps = _plan(imported, fieldTarget: true).flattenedSteps;
      expect(
        steps.whereType<CameraFocusStep>().where(
          (step) => step.durationSeconds == .25,
        ),
        isEmpty,
      );
      expect(steps.whereType<CombatantMotionStep>(), hasLength(1));
      expect(
        steps.whereType<PlaySeStep>().where((step) => step.seName == 'legacy'),
        hasLength(1),
      );
    },
  );

  test('ignores a prepared recipe bound to a different move', () async {
    final imported = await _install(
      root,
      _recipe({'kind': 'wait', 'durationMs': 125}, ['wait']),
      moveId: 'other',
    );
    expect(
      _plan(imported).flattenedSteps
          .whereType<WaitStep>()
          .where((step) => step.durationSeconds == .125),
      isEmpty,
    );
  });

  test('falls back for a valid but excessively long choreography', () async {
    final imported = await _install(
      root,
      _recipe({'kind': 'wait', 'durationMs': 30001}, ['wait']),
    );
    final steps = _plan(imported).flattenedSteps;
    expect(
      steps.whereType<WaitStep>().where(
        (step) => step.durationSeconds == 30.001,
      ),
      isEmpty,
    );
    expect(steps.whereType<CombatantMotionStep>(), hasLength(1));
  });

  test('falls back for a valid choreography with too many steps', () async {
    final imported = await _install(
      root,
      _recipe(
        {
          'kind': 'sequence',
          'steps': List.generate(256, (_) => {'kind': 'wait', 'durationMs': 1}),
        },
        ['sequence', 'wait'],
      ),
    );
    final steps = _plan(imported).flattenedSteps;
    expect(
      steps.whereType<WaitStep>().where((step) => step.durationSeconds == .001),
      isEmpty,
    );
    expect(steps.whereType<CombatantMotionStep>(), hasLength(1));
  });

  test('adds sequential durations when checking the bound', () async {
    final imported = await _install(
      root,
      _recipe(
        {
          'kind': 'sequence',
          'steps': [
            {'kind': 'wait', 'durationMs': 15001},
            {'kind': 'wait', 'durationMs': 15000},
          ],
        },
        ['sequence', 'wait'],
      ),
    );
    final steps = _plan(imported).flattenedSteps;
    expect(
      steps.whereType<WaitStep>().where(
        (step) => step.durationSeconds == 15.001,
      ),
      isEmpty,
    );
    expect(steps.whereType<CombatantMotionStep>(), hasLength(1));
  });

  test('uses the longest parallel branch when checking the bound', () async {
    final imported = await _install(
      root,
      _recipe(
        {
          'kind': 'parallel',
          'steps': [
            {'kind': 'wait', 'durationMs': 20000},
            {'kind': 'wait', 'durationMs': 20000},
          ],
        },
        ['parallel', 'wait'],
      ),
    );
    final steps = _plan(imported).flattenedSteps;
    expect(
      steps.whereType<WaitStep>().where((step) => step.durationSeconds == 20),
      hasLength(2),
    );
    expect(steps.whereType<CombatantMotionStep>(), hasLength(1));
  });
}
