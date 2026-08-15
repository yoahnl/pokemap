import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('ScenePresentationCinematicRuntimeAwaitableAdapter', () {
    test('awaits one terminal before Scene resumes', () async {
      final mediaController = _mediaController();
      PresentationExecutionReceipt? receipt;
      final executionController = RuntimePresentationExecutionController(
        mediaController: mediaController,
        onReceipt: (nextReceipt) => receipt = nextReceipt,
      );
      late ScenePresentationCinematicRuntimeRequest request;
      late RuntimePresentationRunToken runToken;
      final player = RuntimePresentationScenePlayer(
        executionController: executionController,
        launch: (nextRequest, nextRunToken) {
          request = nextRequest;
          runToken = nextRunToken;
        },
      );
      final adapter = ScenePresentationCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:pre-session:opening',
        projectRevision: _projectRevision,
        assets: [_presentation()],
        createdAtEpochMs: () => 1234,
        player: player,
      );
      var completed = false;
      final execution = SceneRuntimeExecutor(
        callbacks: _hostCallbacks(
          playPresentationCinematic: (intent) async {
            final result = await adapter.playPresentationCinematic(intent);
            if (!result.success || result.scenePortId == null) {
              throw StateError(
                result.message ?? 'Presentation cinematic handoff failed.',
              );
            }
            return result.scenePortId!;
          },
        ).toExecutionCallbacks(applyConsequence: (_) => 'completed'),
      ).execute(_presentationPlan()).then((result) {
        completed = true;
        return result;
      });

      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      expect(
        request.requestId,
        buildPresentationExecutionRunId(
          runtimeSourceId: 'scene:pre-session:opening',
          assetId: 'opening',
          nonce: 1234,
          sequence: 1,
        ),
      );
      expect(request.projectRevision, _projectRevision);
      expect(
        request.contentHash,
        computePresentationCinematicContentHash(_presentation()),
      );
      expect(request.presentationCinematicId, 'opening');
      expect(request.asset, _presentation());

      final terminal = await executionController.complete(runToken);
      await executionController.fail(
        runToken,
        diagnosticCode: 'late.presentation.callback',
      );
      final result = await execution;

      expect(terminal?.result, RuntimePresentationExecutionResult.completed);
      expect(
        receipt!.events.map((event) => event.kind),
        [
          PresentationExecutionEventKind.prepare,
          PresentationExecutionEventKind.start,
        ],
      );
      expect(receipt!.terminal.outcome, PresentationExecutionOutcome.completed);
      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(
        result.trace
            .where((entry) =>
                entry.intentKind ==
                SceneRuntimePlanIntentKind.playPresentationCinematic)
            .single
            .outputPortId,
        'completed',
      );
    });

    test('records fallback and skip once for the active run', () async {
      PresentationExecutionReceipt? receipt;
      final executionController = RuntimePresentationExecutionController(
        mediaController: _mediaController(),
        onReceipt: (nextReceipt) => receipt = nextReceipt,
      );
      final token = executionController.start(
        observability: _observabilityCorrelation(),
      );

      executionController.observeMediaPlaybackSnapshot(
        token,
        const RuntimePresentationMediaPlaybackSnapshot(
          status: RuntimePresentationMediaPlaybackStatus.showingPoster,
          requestedMediaId: 'opening-video',
          resolvedMediaId: 'opening-poster',
          usedFallback: true,
        ),
      );
      final first = await executionController.skip(token);
      final second = await executionController.complete(token);

      expect(second, same(first));
      expect(
        receipt!.events.map((event) => event.kind),
        [
          PresentationExecutionEventKind.prepare,
          PresentationExecutionEventKind.start,
          PresentationExecutionEventKind.fallback,
          PresentationExecutionEventKind.skip,
        ],
      );
      expect(receipt!.terminal.outcome, PresentationExecutionOutcome.skipped);
    });

    test('keeps run ids unique when the clock does not advance', () async {
      final requests = <ScenePresentationCinematicRuntimeRequest>[];
      final adapter = ScenePresentationCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:pre-session:opening',
        projectRevision: _projectRevision,
        assets: [_presentation()],
        createdAtEpochMs: () => 1234,
        player: _CallbackPlayer((request) {
          requests.add(request);
          return const RuntimePresentationExecutionTerminal(
            runToken: RuntimePresentationRunToken(1),
            result: RuntimePresentationExecutionResult.completed,
          );
        }),
      );

      await adapter.playPresentationCinematic(
        SceneRuntimePlanIntent.playPresentationCinematic(
          presentationCinematicId: 'opening',
        ),
      );
      await adapter.playPresentationCinematic(
        SceneRuntimePlanIntent.playPresentationCinematic(
          presentationCinematicId: 'opening',
        ),
      );

      expect(
          requests.map((request) => request.requestId).toSet(), hasLength(2));
    });

    test('maps skip to completed without falling back to world cinematic',
        () async {
      var worldCalls = 0;
      final adapter = ScenePresentationCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:pre-session:opening',
        projectRevision: _projectRevision,
        assets: [_presentation()],
        player: _TerminalPlayer(
          const RuntimePresentationExecutionTerminal(
            runToken: RuntimePresentationRunToken(7),
            result: RuntimePresentationExecutionResult.skipped,
          ),
        ),
      );

      final result = await adapter.playPresentationCinematic(
        SceneRuntimePlanIntent.playPresentationCinematic(
          presentationCinematicId: 'opening',
        ),
      );
      await SceneRuntimeExecutor(
        callbacks: _hostCallbacks(
          playCinematic: (_) {
            worldCalls++;
            return 'completed';
          },
        ).toExecutionCallbacks(applyConsequence: (_) => 'completed'),
      ).execute(_worldPlan());

      expect(
        result.status,
        ScenePresentationCinematicRuntimeAwaitableStatus.skipped,
      );
      expect(result.scenePortId, 'completed');
      expect(worldCalls, 1);
    });

    test('returns stable cancellation and playback failure results', () async {
      final cancelled = ScenePresentationCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:pre-session:opening',
        projectRevision: _projectRevision,
        assets: [_presentation()],
        player: _TerminalPlayer(
          const RuntimePresentationExecutionTerminal(
            runToken: RuntimePresentationRunToken(1),
            result: RuntimePresentationExecutionResult.cancelled,
            cancellationReason: RuntimePresentationCancellationReason.requested,
          ),
        ),
      );
      final failed = ScenePresentationCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:pre-session:opening',
        projectRevision: _projectRevision,
        assets: [_presentation()],
        player: _TerminalPlayer(
          const RuntimePresentationExecutionTerminal(
            runToken: RuntimePresentationRunToken(2),
            result: RuntimePresentationExecutionResult.failed,
            diagnosticCode: 'cinematic.presentation.decoder_failed',
          ),
        ),
      );

      final cancelledResult = await cancelled.playPresentationCinematic(
        SceneRuntimePlanIntent.playPresentationCinematic(
          presentationCinematicId: 'opening',
        ),
      );
      final failedResult = await failed.playPresentationCinematic(
        SceneRuntimePlanIntent.playPresentationCinematic(
          presentationCinematicId: 'opening',
        ),
      );

      expect(cancelledResult.success, isFalse);
      expect(cancelledResult.scenePortId, isNull);
      expect(
        cancelledResult.errorCode,
        ScenePresentationCinematicRuntimeAwaitableErrorCode.cancelled,
      );
      expect(failedResult.success, isFalse);
      expect(failedResult.scenePortId, isNull);
      expect(
        failedResult.errorCode,
        ScenePresentationCinematicRuntimeAwaitableErrorCode.playbackFailed,
      );
      expect(
        failedResult.diagnosticCode,
        'cinematic.presentation.decoder_failed',
      );
    });

    test('fails a missing reference without launching the player', () async {
      var launchCount = 0;
      final adapter = ScenePresentationCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:pre-session:opening',
        projectRevision: _projectRevision,
        assets: [_presentation()],
        player: _CallbackPlayer((_) {
          launchCount++;
          return const RuntimePresentationExecutionTerminal(
            runToken: RuntimePresentationRunToken(1),
            result: RuntimePresentationExecutionResult.completed,
          );
        }),
      );

      final result = await adapter.playPresentationCinematic(
        SceneRuntimePlanIntent.playPresentationCinematic(
          presentationCinematicId: 'missing',
        ),
      );

      expect(
        result.errorCode,
        ScenePresentationCinematicRuntimeAwaitableErrorCode
            .unknownPresentationCinematicId,
      );
      expect(result.scenePortId, isNull);
      expect(launchCount, 0);
    });

    test('rejects duplicate Presentation identities before execution', () {
      expect(
        () => ScenePresentationCinematicRuntimeAwaitableAdapter(
          runtimeSourceId: 'scene:pre-session:opening',
          projectRevision: _projectRevision,
          assets: [_presentation(), _presentation()],
          player: _TerminalPlayer(
            const RuntimePresentationExecutionTerminal(
              runToken: RuntimePresentationRunToken(1),
              result: RuntimePresentationExecutionResult.completed,
            ),
          ),
        ),
        throwsArgumentError,
      );
    });

    test('converts a player exception into a stable failure', () async {
      final adapter = ScenePresentationCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:pre-session:opening',
        projectRevision: _projectRevision,
        assets: [_presentation()],
        player: _CallbackPlayer(
          (_) => throw StateError('renderer exploded'),
        ),
      );

      final result = await adapter.playPresentationCinematic(
        SceneRuntimePlanIntent.playPresentationCinematic(
          presentationCinematicId: 'opening',
        ),
      );

      expect(
        result.errorCode,
        ScenePresentationCinematicRuntimeAwaitableErrorCode.playerFailed,
      );
      expect(result.scenePortId, isNull);
      expect(result.message, contains('player failed'));
      expect(result.message, isNot(contains('renderer exploded')));
    });

    test('maps a launch failure to the stable Presentation diagnostic',
        () async {
      PresentationExecutionReceipt? receipt;
      final executionController = RuntimePresentationExecutionController(
        mediaController: _mediaController(),
        onReceipt: (nextReceipt) => receipt = nextReceipt,
      );
      final adapter = ScenePresentationCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:pre-session:opening',
        projectRevision: _projectRevision,
        assets: [_presentation()],
        player: RuntimePresentationScenePlayer(
          executionController: executionController,
          launch: (_, __) => throw StateError('renderer exploded'),
        ),
      );

      final result = await adapter.playPresentationCinematic(
        SceneRuntimePlanIntent.playPresentationCinematic(
          presentationCinematicId: 'opening',
        ),
      );

      expect(
        result.errorCode,
        ScenePresentationCinematicRuntimeAwaitableErrorCode.playbackFailed,
      );
      expect(
        result.diagnosticCode,
        PresentationDiagnosticCodes.launchFailed,
      );
      expect(
        receipt!.events.last.kind,
        PresentationExecutionEventKind.failure,
      );
      expect(receipt!.terminal.outcome, PresentationExecutionOutcome.failed);
      expect(
        receipt!.terminal.stableErrorCode,
        PresentationDiagnosticCodes.launchFailed,
      );
    });

    test('maps controller disposal to one terminal cancellation', () async {
      PresentationExecutionReceipt? receipt;
      final executionController = RuntimePresentationExecutionController(
        mediaController: _mediaController(),
        onReceipt: (nextReceipt) => receipt = nextReceipt,
      );
      final adapter = ScenePresentationCinematicRuntimeAwaitableAdapter(
        runtimeSourceId: 'scene:pre-session:opening',
        projectRevision: _projectRevision,
        assets: [_presentation()],
        player: RuntimePresentationScenePlayer(
          executionController: executionController,
          launch: (_, __) {},
        ),
      );
      final execution = adapter.playPresentationCinematic(
        SceneRuntimePlanIntent.playPresentationCinematic(
          presentationCinematicId: 'opening',
        ),
      );

      await Future<void>.delayed(Duration.zero);
      await executionController.dispose();
      final result = await execution;

      expect(
        result.status,
        ScenePresentationCinematicRuntimeAwaitableStatus.cancelled,
      );
      expect(
        result.cancellationReason,
        RuntimePresentationCancellationReason.disposed,
      );
      expect(
        receipt!.events.last.kind,
        PresentationExecutionEventKind.dispose,
      );
      expect(
        receipt!.terminal.outcome,
        PresentationExecutionOutcome.cancelled,
      );
    });

    test('ignores observability sink failures', () async {
      final executionController = RuntimePresentationExecutionController(
        mediaController: _mediaController(),
        onReceipt: (_) => throw StateError('diagnostic exporter unavailable'),
      );
      final token = executionController.start(
        observability: _observabilityCorrelation(),
      );

      final terminal = await executionController.complete(token);

      expect(terminal!.result, RuntimePresentationExecutionResult.completed);
      expect(
        executionController.snapshot.phase,
        RuntimePresentationExecutionPhase.terminated,
      );
    });

    test('keeps execution behavior when a diagnostic cannot be observed',
        () async {
      final executionController = RuntimePresentationExecutionController(
        mediaController: _mediaController(),
      );
      final token = executionController.start(
        observability: _observabilityCorrelation(),
      );

      final terminal = await executionController.fail(
        token,
        diagnosticCode: '/Users/yoahn/private/decoder.log',
      );

      expect(terminal!.result, RuntimePresentationExecutionResult.failed);
      expect(terminal.diagnosticCode, '/Users/yoahn/private/decoder.log');
      expect(executionController.lastReceipt, isNull);
    });

    test('rejects an unknown capability before launching Presentation',
        () async {
      var presentationCalls = 0;
      final result = await SceneRuntimeExecutor(
        callbacks: _hostCallbacks(
          playPresentationCinematic: (_) {
            presentationCalls++;
            return 'completed';
          },
        ).toExecutionCallbacks(applyConsequence: (_) => 'completed'),
      ).execute(
        _presentationPlan(
          presentationCapabilityId: 'cinematic.presentation.future',
        ),
      );

      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(
        result.errorCode,
        SceneRuntimeExecutionErrorCode.capabilityViolation,
      );
      expect(
        result.capabilityIssueCode,
        SceneExecutionCapabilityIssueCode.unknownCapability,
      );
      expect(presentationCalls, 0);
    });
  });
}

SceneRuntimeHostCallbacks _hostCallbacks({
  SceneRuntimeIntentCallback? playCinematic,
  SceneRuntimeIntentCallback? playPresentationCinematic,
}) =>
    SceneRuntimeHostCallbacks(
      evaluateCondition: (_) => 'false',
      showDialogue: (_) => 'completed',
      startBattle: (_) => 'victory',
      playCinematic: playCinematic ?? (_) => 'completed',
      playPresentationCinematic: playPresentationCinematic,
    );

SceneRuntimePlan _presentationPlan({String? presentationCapabilityId}) => _plan(
      profile: SceneExecutionProfile.preSession,
      middleKind: SceneNodeKind.presentationCinematic,
      middleIntent: SceneRuntimePlanIntent.playPresentationCinematic(
        presentationCinematicId: 'opening',
      ),
      middleEdgeKind: SceneEdgeKind.presentationCompleted,
      middleCapabilityId: presentationCapabilityId,
    );

SceneRuntimePlan _worldPlan() => _plan(
      profile: SceneExecutionProfile.world,
      middleKind: SceneNodeKind.cinematic,
      middleIntent: SceneRuntimePlanIntent.playCinematic(
        cinematicId: 'world-opening',
      ),
      middleEdgeKind: SceneEdgeKind.cinematicCompleted,
    );

SceneRuntimePlan _plan({
  required SceneExecutionProfile profile,
  required SceneNodeKind middleKind,
  required SceneRuntimePlanIntent middleIntent,
  required SceneEdgeKind middleEdgeKind,
  String? middleCapabilityId,
}) =>
    SceneRuntimePlan(
      sceneId: 'scene-opening',
      executionProfile: profile,
      startNodeId: 'start',
      nodes: <SceneRuntimePlanNode>[
        SceneRuntimePlanNode(
          id: 'start',
          kind: SceneNodeKind.start,
          intent: SceneRuntimePlanIntent.start(),
        ),
        SceneRuntimePlanNode(
          id: 'cinematic',
          kind: middleKind,
          intent: middleIntent,
          capabilityId: middleCapabilityId,
        ),
        SceneRuntimePlanNode(
          id: 'end',
          kind: SceneNodeKind.end,
          intent: SceneRuntimePlanIntent.end(),
        ),
      ],
      edges: <SceneRuntimePlanEdge>[
        const SceneRuntimePlanEdge(
          id: 'start-cinematic',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'cinematic',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneRuntimePlanEdge(
          id: 'cinematic-end',
          fromNodeId: 'cinematic',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: middleEdgeKind,
        ),
      ],
      declaredOutcomes: const <SceneOutcome>[],
    );

PresentationCinematicAsset _presentation() => PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 1000000,
    );

final _projectRevision = 'sha256:${List<String>.filled(64, 'a').join()}';

PresentationExecutionCorrelation _observabilityCorrelation() =>
    PresentationExecutionCorrelation(
      runId: buildPresentationExecutionRunId(
        runtimeSourceId: 'scene:pre-session:opening',
        assetId: 'opening',
        nonce: 1234,
      ),
      projectRevision: _projectRevision,
      assetId: 'opening',
      contentHash: computePresentationCinematicContentHash(_presentation()),
    );

RuntimePresentationMediaPlaybackController _mediaController() =>
    RuntimePresentationMediaPlaybackController(
      catalog: ProjectMediaCatalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: _NoopVideoDriver(),
    );

final class _TerminalPlayer implements ScenePresentationCinematicRuntimePlayer {
  const _TerminalPlayer(this.terminal);

  final RuntimePresentationExecutionTerminal terminal;

  @override
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest request,
  ) async =>
      terminal;
}

final class _CallbackPlayer implements ScenePresentationCinematicRuntimePlayer {
  const _CallbackPlayer(this.callback);

  final FutureOr<RuntimePresentationExecutionTerminal> Function(
    ScenePresentationCinematicRuntimeRequest request,
  ) callback;

  @override
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest request,
  ) async =>
      callback(request);
}

final class _NoopVideoDriver implements RuntimePresentationVideoPlaybackDriver {
  @override
  Future<void> dispose(Object handle) async {}

  @override
  Future<void> pause(Object handle) async {}

  @override
  Future<void> play(Object handle) async {}

  @override
  Future<Object> prepare(Uri source, {required double initialVolume}) async =>
      Object();

  @override
  Future<void> setVolume(Object handle, double volume) async {}
}
