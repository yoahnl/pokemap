import 'dart:async';

import 'package:map_core/map_core.dart';

import '../../player/runtime_presentation_execution_controller.dart';
import 'scene_presentation_cinematic_runtime_awaitable_result.dart';

abstract final class ScenePresentationCinematicRuntimeDiagnosticCodes {
  static const launchFailed = PresentationDiagnosticCodes.launchFailed;
}

abstract interface class ScenePresentationCinematicRuntimePlayer {
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest request,
  );
}

typedef ScenePresentationInteractionCueHandler = Future<void> Function(
  String markerId,
);

final class ScenePresentationCinematicRuntimeRequest {
  ScenePresentationCinematicRuntimeRequest({
    required this.requestId,
    required this.createdAtEpochMs,
    required this.projectRevision,
    required this.contentHash,
    required this.presentationCinematicId,
    required this.asset,
    this.onInteractionCue,
    Set<String> interactionCueMarkerIds = const <String>{},
  }) : interactionCueMarkerIds = Set<String>.unmodifiable(
          interactionCueMarkerIds,
        );

  final String requestId;
  final int createdAtEpochMs;
  final String projectRevision;
  final String contentHash;
  final String presentationCinematicId;
  final PresentationCinematicAsset asset;
  final ScenePresentationInteractionCueHandler? onInteractionCue;
  final Set<String> interactionCueMarkerIds;
}

typedef RuntimePresentationSceneLaunch = FutureOr<void> Function(
  ScenePresentationCinematicRuntimeRequest request,
  RuntimePresentationRunToken runToken,
);

final class RuntimePresentationScenePlayer
    implements ScenePresentationCinematicRuntimePlayer {
  const RuntimePresentationScenePlayer({
    required this.executionController,
    required this.launch,
  });

  final RuntimePresentationExecutionController executionController;
  final RuntimePresentationSceneLaunch launch;

  @override
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest request,
  ) {
    PresentationExecutionCorrelation? observability;
    try {
      observability = PresentationExecutionCorrelation(
        runId: request.requestId,
        projectRevision: request.projectRevision,
        assetId: buildPresentationExecutionAssetCorrelationId(
          request.presentationCinematicId,
        ),
        contentHash: request.contentHash,
      );
    } on Object {
      observability = null;
    }
    final runToken = executionController.start(
      observability: observability,
    );
    final terminal = executionController.waitForTerminal(runToken);
    unawaited(
      Future<void>.sync(() => launch(request, runToken)).then<void>(
        (_) {},
        onError: (Object _, StackTrace __) async {
          await executionController.fail(
            runToken,
            diagnosticCode:
                ScenePresentationCinematicRuntimeDiagnosticCodes.launchFailed,
          );
        },
      ),
    );
    return terminal;
  }
}

final class ScenePresentationCinematicRuntimeAwaitableAdapter {
  ScenePresentationCinematicRuntimeAwaitableAdapter({
    required this.runtimeSourceId,
    required this.projectRevision,
    required Iterable<PresentationCinematicAsset> assets,
    required this.player,
    this.createdAtEpochMs = _systemNowMs,
  }) : _assetsById = _indexAssets(assets);

  final String runtimeSourceId;
  final String projectRevision;
  final Map<String, PresentationCinematicAsset> _assetsById;
  final ScenePresentationCinematicRuntimePlayer player;
  final int Function() createdAtEpochMs;
  var _nextRunSequence = 1;

  Future<ScenePresentationCinematicRuntimeAwaitableResult>
      playPresentationCinematic(
    SceneRuntimePlanIntent intent, {
    ScenePresentationInteractionCueHandler? onInteractionCue,
  }) async {
    final presentationCinematicId = intent.presentationCinematicId?.trim();
    if (presentationCinematicId == null || presentationCinematicId.isEmpty) {
      return const ScenePresentationCinematicRuntimeAwaitableResult.failed(
        errorCode: ScenePresentationCinematicRuntimeAwaitableErrorCode
            .missingPresentationCinematicId,
        message: 'Scene Presentation cinematic intent is missing its asset id.',
      );
    }
    final asset = _assetsById[presentationCinematicId];
    if (asset == null) {
      return ScenePresentationCinematicRuntimeAwaitableResult.failed(
        errorCode: ScenePresentationCinematicRuntimeAwaitableErrorCode
            .unknownPresentationCinematicId,
        message:
            'Presentation cinematic "$presentationCinematicId" was not found.',
      );
    }

    final now = createdAtEpochMs();
    final request = ScenePresentationCinematicRuntimeRequest(
      requestId: buildPresentationExecutionRunId(
        runtimeSourceId: runtimeSourceId,
        assetId: presentationCinematicId,
        nonce: now,
        sequence: _nextRunSequence++,
      ),
      createdAtEpochMs: now,
      projectRevision: projectRevision,
      contentHash: computePresentationCinematicContentHash(asset),
      presentationCinematicId: presentationCinematicId,
      asset: asset,
      onInteractionCue: onInteractionCue,
      interactionCueMarkerIds:
          intent.presentationAwaitableNodeIdsByMarkerId.keys.toSet(),
    );
    RuntimePresentationExecutionTerminal terminal;
    try {
      terminal = await player.playPresentationCinematic(request);
    } on Object {
      return const ScenePresentationCinematicRuntimeAwaitableResult.failed(
        errorCode:
            ScenePresentationCinematicRuntimeAwaitableErrorCode.playerFailed,
        message: 'Presentation cinematic player failed.',
      );
    }

    return switch (terminal.result) {
      RuntimePresentationExecutionResult.completed =>
        const ScenePresentationCinematicRuntimeAwaitableResult.completed(),
      RuntimePresentationExecutionResult.skipped =>
        const ScenePresentationCinematicRuntimeAwaitableResult.skipped(),
      RuntimePresentationExecutionResult.cancelled =>
        ScenePresentationCinematicRuntimeAwaitableResult.cancelled(
          cancellationReason: terminal.cancellationReason ??
              RuntimePresentationCancellationReason.requested,
        ),
      RuntimePresentationExecutionResult.failed =>
        ScenePresentationCinematicRuntimeAwaitableResult.failed(
          errorCode: ScenePresentationCinematicRuntimeAwaitableErrorCode
              .playbackFailed,
          message: 'Presentation cinematic playback failed.',
          diagnosticCode: terminal.diagnosticCode,
        ),
    };
  }
}

int _systemNowMs() => DateTime.now().millisecondsSinceEpoch;

Map<String, PresentationCinematicAsset> _indexAssets(
  Iterable<PresentationCinematicAsset> assets,
) {
  final indexed = <String, PresentationCinematicAsset>{};
  for (final asset in assets) {
    if (indexed.containsKey(asset.id)) {
      throw ArgumentError.value(
        asset.id,
        'assets',
        'contains a duplicate Presentation cinematic id',
      );
    }
    indexed[asset.id] = asset;
  }
  return Map<String, PresentationCinematicAsset>.unmodifiable(indexed);
}
