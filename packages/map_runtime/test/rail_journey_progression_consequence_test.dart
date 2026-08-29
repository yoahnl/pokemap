import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  const writer = SceneConsequenceRuntimeWriter(
    project: ProjectManifest(
      name: 'Rail project',
      maps: <ProjectMapEntry>[],
      tilesets: <ProjectTilesetEntry>[],
    ),
  );

  test('currency grant is payload-bound and replay-safe', () {
    const state = GameState(saveId: 'currency');
    final consequence = SceneConsequence.grantRailCurrency(
      semanticCurrencyId: 'line_tokens',
      amount: 3,
    );

    final first = writer.applyOne(
      state,
      consequence,
      railProgressionOperationId: 'scene:reward:run-1:node-currency',
    );
    final replay = writer.applyOne(
      first.gameState,
      consequence,
      railProgressionOperationId: 'scene:reward:run-1:node-currency',
    );
    final conflict = writer.applyOne(
      first.gameState,
      SceneConsequence.grantRailCurrency(
        semanticCurrencyId: 'line_tokens',
        amount: 4,
      ),
      railProgressionOperationId: 'scene:reward:run-1:node-currency',
    );

    expect(first.success, isTrue);
    expect(first.gameState.railJourneyProgress.semanticCurrencyBalances, {
      'line_tokens': 3,
    });
    expect(replay.success, isTrue);
    expect(replay.gameState, first.gameState);
    expect(conflict.success, isFalse);
    expect(conflict.gameState, first.gameState);
    expect(
      conflict.errorCode,
      SceneConsequenceRuntimeWriteErrorCode.railProgressionIdempotencyConflict,
    );
  });

  test('stamp grant is typed, idempotent and does not use badges or flags', () {
    const state = GameState(saveId: 'stamp');
    final consequence = SceneConsequence.grantRailStamp(
      stampId: 'hanazuki_stamp',
    );

    final first = writer.applyOne(
      state,
      consequence,
      railProgressionOperationId: 'scene:reward:run-1:node-stamp',
    );
    final replay = writer.applyOne(
      first.gameState,
      consequence,
      railProgressionOperationId: 'scene:reward:run-1:node-stamp',
    );

    expect(first.success, isTrue);
    expect(first.gameState.railJourneyProgress.earnedStampIds, {
      'hanazuki_stamp',
    });
    expect(first.gameState.trainerProfile.badgeIds, isEmpty);
    expect(first.gameState.storyFlags.activeFlags, isEmpty);
    expect(replay.gameState, first.gameState);
  });

  test('rail grants require a runtime-derived operation id', () {
    const state = GameState(saveId: 'missing-operation');

    final result = writer.applyOne(
      state,
      SceneConsequence.grantRailStamp(stampId: 'hanazuki_stamp'),
    );

    expect(result.success, isFalse);
    expect(result.gameState, state);
    expect(
      result.errorCode,
      SceneConsequenceRuntimeWriteErrorCode.missingRailProgressionOperationId,
    );
  });

  test('rail receipt id derives from scene execution context only for grants',
      () {
    final grant = SceneConsequence.grantRailStamp(stampId: 'hanazuki_stamp');

    expect(
      sceneRailProgressionOperationId(
        sceneId: 'scene_reward',
        executionId: 'execution_2',
        nodeId: 'node_stamp',
        consequence: grant,
      ),
      'scene:scene_reward:execution_2:node_stamp',
    );
    expect(
      sceneRailProgressionOperationId(
        sceneId: 'scene_reward',
        executionId: 'execution_2',
        nodeId: 'node_money',
        consequence: SceneConsequence.giveMoney(amount: 1),
      ),
      isNull,
    );
  });
}
