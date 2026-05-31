import 'package:map_core/map_core.dart';

import 'scene_battle_runtime_outcome_result.dart';

abstract interface class SceneBattleRuntimeLauncher {
  Future<SceneBattleRuntimeOutcomeResult> startTrainerBattle(
    SceneBattleRuntimeBattleRequest request,
  );
}

final class SceneBattleRuntimeBattleRequest {
  const SceneBattleRuntimeBattleRequest({
    required this.requestId,
    required this.createdAtEpochMs,
    required this.trainerId,
    required this.npcEntityId,
    this.battleTemplateId,
  });

  final String requestId;
  final int createdAtEpochMs;
  final String trainerId;
  final String npcEntityId;
  final String? battleTemplateId;
}

final class SceneBattleRuntimeOutcomeAdapter {
  const SceneBattleRuntimeOutcomeAdapter({
    required this.runtimeSourceId,
    required this.defaultNpcEntityId,
    required this.launcher,
    this.createdAtEpochMs = _systemNowMs,
  });

  final String runtimeSourceId;
  final String defaultNpcEntityId;
  final SceneBattleRuntimeLauncher launcher;
  final int Function() createdAtEpochMs;

  Future<SceneBattleRuntimeOutcomeResult> startBattle(
    SceneRuntimePlanIntent intent,
  ) async {
    final battleKind = intent.battleKind?.trim();
    if (battleKind != 'trainer') {
      return SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.unsupportedBattleKind,
        message: 'Scene battle kind "$battleKind" is not supported in V0.',
      );
    }

    final trainerId = intent.trainerId?.trim();
    if (trainerId == null || trainerId.isEmpty) {
      return const SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.missingTrainerId,
        message: 'Scene trainer battle intent is missing trainerId.',
      );
    }

    final npcEntityId = _resolveNpcEntityId(intent);
    if (npcEntityId == null) {
      return const SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.missingNpcEntityId,
        message: 'Scene trainer battle intent is missing npcEntityId.',
      );
    }

    final now = createdAtEpochMs();
    final request = SceneBattleRuntimeBattleRequest(
      requestId: '$runtimeSourceId:$trainerId:$now',
      createdAtEpochMs: now,
      trainerId: trainerId,
      npcEntityId: npcEntityId,
      battleTemplateId: intent.battleTemplateId,
    );

    try {
      return await launcher.startTrainerBattle(request);
    } catch (error) {
      return SceneBattleRuntimeOutcomeResult.failed(
        errorCode: SceneBattleRuntimeOutcomeErrorCode.launcherFailed,
        message: 'Scene trainer battle launcher failed: $error',
      );
    }
  }

  String? _resolveNpcEntityId(SceneRuntimePlanIntent intent) {
    final npcEntityId = intent.npcEntityId?.trim();
    if (npcEntityId != null && npcEntityId.isNotEmpty) {
      return npcEntityId;
    }
    final fallbackNpcEntityId = defaultNpcEntityId.trim();
    return fallbackNpcEntityId.isEmpty ? null : fallbackNpcEntityId;
  }
}

int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;
