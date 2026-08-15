import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Presentation execution observability', () {
    test('exports a deterministic ordered receipt with one terminal', () {
      final correlation = _correlation();
      final first = PresentationExecutionRecorder(
        correlation: correlation,
        platform: PresentationMediaTargetPlatform.android,
      );
      final second = PresentationExecutionRecorder(
        correlation: correlation,
        platform: PresentationMediaTargetPlatform.android,
      );

      for (final recorder in [first, second]) {
        recorder.record(
          PresentationExecutionEventKind.prepare,
          source: PresentationExecutionSource.player,
        );
        recorder.record(
          PresentationExecutionEventKind.start,
          source: PresentationExecutionSource.player,
        );
        recorder.record(
          PresentationExecutionEventKind.fallback,
          source: PresentationExecutionSource.player,
        );
        recorder.record(
          PresentationExecutionEventKind.skip,
          source: PresentationExecutionSource.player,
        );
        final terminal = recorder.finish(
          PresentationExecutionOutcome.skipped,
          source: PresentationExecutionSource.player,
        );

        expect(
          recorder.finish(
            PresentationExecutionOutcome.completed,
            source: PresentationExecutionSource.editor,
          ),
          same(terminal),
        );
      }

      expect(first.receipt, isNotNull);
      expect(first.receipt!.events.map((event) => event.sequence), [
        0,
        1,
        2,
        3,
      ]);
      expect(first.receipt!.terminal.sequence, 4);
      expect(
        first.receipt!.terminal.outcome,
        PresentationExecutionOutcome.skipped,
      );
      expect(
        first.receipt!.encodeCanonical(),
        second.receipt!.encodeCanonical(),
      );
      expect(
        first.receipt!.encodeCanonical(),
        '{"assetId":"opening","contentHash":"${correlation.contentHash}",'
        '"events":[{"kind":"prepare","sequence":0,"source":"player"},'
        '{"kind":"start","sequence":1,"source":"player"},'
        '{"kind":"fallback","sequence":2,"source":"player"},'
        '{"kind":"skip","sequence":3,"source":"player"}],'
        '"platform":"android","projectRevision":"${correlation.projectRevision}",'
        '"runId":"${correlation.runId}","schemaVersion":1,'
        '"terminal":{"outcome":"skipped","sequence":4,"source":"player"}}',
      );
    });

    test('correlates stable failures without accepting private fields', () {
      final secretAsset = PresentationCinematicAsset(
        id: 'opening',
        title: 'Yoahn secret player name',
        description: '/Users/yoahn/private/caption.txt',
        durationUs: 1000000,
      );
      final recorder = PresentationExecutionRecorder(
        correlation: PresentationExecutionCorrelation(
          runId: buildPresentationExecutionRunId(
            runtimeSourceId: '/Users/yoahn/private/project',
            assetId: secretAsset.id,
            nonce: 42,
          ),
          projectRevision: _sha256('b'),
          assetId: secretAsset.id,
          contentHash: computePresentationCinematicContentHash(secretAsset),
        ),
        platform: PresentationMediaTargetPlatform.macos,
      );

      expect(recorder.receipt, isNull);
      recorder.record(
        PresentationExecutionEventKind.failure,
        source: PresentationExecutionSource.editor,
        stableErrorCode: PresentationDiagnosticCodes.playbackFailed,
      );
      recorder.finish(
        PresentationExecutionOutcome.failed,
        source: PresentationExecutionSource.mcp,
        stableErrorCode: PresentationDiagnosticCodes.playbackFailed,
      );

      final encoded = recorder.receipt!.encodeCanonical();
      expect(encoded, contains(PresentationDiagnosticCodes.playbackFailed));
      expect(encoded, isNot(contains('Yoahn secret player name')));
      expect(encoded, isNot(contains('/Users/yoahn')));
      expect(encoded, isNot(contains('caption.txt')));
      expect(
        buildPresentationExecutionAssetCorrelationId(
          '/Users/yoahn/private/opening',
        ),
        startsWith('asset:sha256:'),
      );
      expect(
        buildPresentationExecutionAssetCorrelationId(
          '/Users/yoahn/private/opening',
        ),
        isNot(contains('/Users/yoahn')),
      );
      expect(
        recorder.receipt!.events.single.source,
        PresentationExecutionSource.editor,
      );
      expect(
        recorder.receipt!.terminal.source,
        PresentationExecutionSource.mcp,
      );
    });

    test('rejects unsafe correlation and diagnostic values', () {
      expect(
        () => PresentationExecutionCorrelation(
          runId: '/Users/yoahn/private',
          projectRevision: _sha256('a'),
          assetId: 'opening',
          contentHash: _sha256('b'),
        ),
        throwsArgumentError,
      );
      final recorder = PresentationExecutionRecorder(
        correlation: _correlation(),
        platform: PresentationMediaTargetPlatform.linux,
      );
      expect(
        () => recorder.record(
          PresentationExecutionEventKind.failure,
          source: PresentationExecutionSource.jsonl,
          stableErrorCode: '/Users/yoahn/private/error.log',
        ),
        throwsArgumentError,
      );
    });
  });
}

PresentationExecutionCorrelation _correlation() {
  final asset = PresentationCinematicAsset(
    id: 'opening',
    title: 'Opening',
    durationUs: 1000000,
  );
  return PresentationExecutionCorrelation(
    runId: buildPresentationExecutionRunId(
      runtimeSourceId: 'scene:pre-session:opening',
      assetId: asset.id,
      nonce: 1234,
    ),
    projectRevision: _sha256('a'),
    assetId: asset.id,
    contentHash: computePresentationCinematicContentHash(asset),
  );
}

String _sha256(String character) =>
    'sha256:${List<String>.filled(64, character).join()}';
