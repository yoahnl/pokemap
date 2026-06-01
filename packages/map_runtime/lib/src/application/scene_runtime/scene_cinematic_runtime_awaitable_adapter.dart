import 'package:map_core/map_core.dart';

import 'scene_cinematic_runtime_awaitable_result.dart';

abstract interface class SceneCinematicRuntimePlayer {
  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
    SceneCinematicRuntimeRequest request,
  );
}

final class SceneCinematicRuntimeRequest {
  const SceneCinematicRuntimeRequest({
    required this.requestId,
    required this.createdAtEpochMs,
    required this.cinematicId,
    required this.asset,
  });

  final String requestId;
  final int createdAtEpochMs;
  final String cinematicId;
  final CinematicAsset asset;
}

final class SceneCinematicRuntimeAwaitableAdapter {
  const SceneCinematicRuntimeAwaitableAdapter({
    required this.runtimeSourceId,
    required this.project,
    required this.player,
    this.createdAtEpochMs = _systemNowMs,
  });

  final String runtimeSourceId;
  final ProjectManifest project;
  final SceneCinematicRuntimePlayer player;
  final int Function() createdAtEpochMs;

  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
    SceneRuntimePlanIntent intent,
  ) async {
    final cinematicId = intent.cinematicId?.trim();
    if (cinematicId == null || cinematicId.isEmpty) {
      return const SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.missingCinematicId,
        message: 'Scene cinematic intent is missing cinematicId.',
      );
    }

    final asset = _findCanonicalCinematic(cinematicId);
    if (asset == null) {
      if (_isLegacyScenarioBridge(cinematicId)) {
        return SceneCinematicRuntimeAwaitableResult.legacyBridgeAcknowledged(
          message: 'Scene cinematic "$cinematicId" uses a legacy scenario '
              'bridge; it is not a canonical CinematicAsset.',
        );
      }
      return SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.unknownCinematicId,
        message: 'Scene cinematic "$cinematicId" was not found.',
      );
    }

    final now = createdAtEpochMs();
    final request = SceneCinematicRuntimeRequest(
      requestId: '$runtimeSourceId:$cinematicId:$now',
      createdAtEpochMs: now,
      cinematicId: cinematicId,
      asset: asset,
    );

    try {
      return await player.playCinematic(request);
    } catch (error) {
      return SceneCinematicRuntimeAwaitableResult.failed(
        errorCode: SceneCinematicRuntimeAwaitableErrorCode.playerFailed,
        message: 'Scene cinematic player failed: $error',
      );
    }
  }

  CinematicAsset? _findCanonicalCinematic(String cinematicId) {
    for (final cinematic in project.cinematics) {
      if (cinematic.id == cinematicId) {
        return cinematic;
      }
    }
    return null;
  }

  bool _isLegacyScenarioBridge(String cinematicId) {
    for (final contract in buildCinematicPublicContracts(project)) {
      if (contract.id == cinematicId &&
          contract.sourceKind ==
              CinematicPublicContractSourceKind.scenarioBridge) {
        return true;
      }
    }
    return false;
  }
}

final class SceneCinematicRuntimeNoVisualPlayer
    implements SceneCinematicRuntimePlayer {
  const SceneCinematicRuntimeNoVisualPlayer();

  @override
  Future<SceneCinematicRuntimeAwaitableResult> playCinematic(
    SceneCinematicRuntimeRequest request,
  ) async {
    final duration = _estimatedDuration(request.asset.timeline);
    await Future<void>.delayed(duration);
    return const SceneCinematicRuntimeAwaitableResult.completed();
  }
}

Duration _estimatedDuration(CinematicTimeline timeline) {
  var totalMs = 0;
  for (final step in timeline.steps) {
    final durationMs = step.durationMs;
    if (durationMs != null && durationMs > 0) {
      totalMs += durationMs;
    }
  }
  if (totalMs <= 0) {
    return Duration.zero;
  }
  return Duration(milliseconds: totalMs);
}

int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;
