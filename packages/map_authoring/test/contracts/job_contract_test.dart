import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('authoring job contracts', () {
    test('round-trips a retryable job and keeps event order explicit', () {
      final request = AuthoringJobRequest(
        requestId: 'request-071',
        kind: 'playtest.run',
        projectId: 'selbrume',
        projectRevision: 'sha256:${'a' * 64}',
        input: <String, Object?>{
          'scenarioId': 'golden.slice',
          'seed': 42,
        },
      );
      final snapshot = AuthoringJobSnapshot(
        jobId: 'job-071',
        request: request,
        attempt: 2,
        state: AuthoringJobState.running,
        createdAtUtc: '2026-07-31T12:00:00.000Z',
        updatedAtUtc: '2026-07-31T12:00:01.000Z',
        lastEventSequence: 3,
        retryOfJobId: 'job-070',
      );
      final event = AuthoringJobEvent(
        jobId: 'job-071',
        sequence: 3,
        type: 'runtime.snapshot',
        state: AuthoringJobState.running,
        occurredAtUtc: '2026-07-31T12:00:01.000Z',
        payload: const <String, Object?>{'mapId': 'selbrume_depart'},
      );

      expect(
        AuthoringJobSnapshot.fromJson(snapshot.toJson()).toJson(),
        snapshot.toJson(),
      );
      expect(
        AuthoringJobEvent.fromJson(event.toJson()).toJson(),
        event.toJson(),
      );
      expect(snapshot.request.input['seed'], 42);
    });

    test('rejects invalid transition and sequence values', () {
      expect(
        () => AuthoringJobEvent(
          jobId: 'job-071',
          sequence: 0,
          type: 'queued',
          state: AuthoringJobState.queued,
          occurredAtUtc: '2026-07-31T12:00:00.000Z',
        ),
        throwsArgumentError,
      );
      expect(
        AuthoringJobState.succeeded.canTransitionTo(
          AuthoringJobState.running,
        ),
        isFalse,
      );
      expect(
        AuthoringJobState.running.canTransitionTo(
          AuthoringJobState.cancelled,
        ),
        isTrue,
      );
    });

    test('binds image, log, and receipt artifacts without local paths', () {
      final artifacts = <AuthoringJobArtifact>[
        _artifact(ArtifactKind.image, 'image/png', 'a'),
        _artifact(ArtifactKind.log, 'application/x-ndjson', 'b'),
        _artifact(ArtifactKind.receipt, 'application/json', 'c'),
      ];
      final manifest = AuthoringArtifactManifest(
        jobId: 'job-071',
        artifacts: artifacts,
      );

      expect(
        AuthoringArtifactManifest.fromJson(manifest.toJson()).toJson(),
        manifest.toJson(),
      );
      expect(
        manifest.artifacts.map((artifact) => artifact.kind),
        containsAll(ArtifactKind.values),
      );
      expect(
        manifest.artifacts.every(
          (artifact) => artifact.reference.uri.startsWith('artifact://'),
        ),
        isTrue,
      );
    });

    test('visual assertions require content identity, not a file path', () {
      final assertion = ArtifactAssertion(
        artifactId: 'artifact-image',
        expectedKind: ArtifactKind.image,
        expectedMediaType: 'image/png',
        expectedSha256: 'a' * 64,
        expectedByteLength: 128,
      );

      expect(
        assertion.matches(_artifact(ArtifactKind.image, 'image/png', 'a')),
        isTrue,
      );
      expect(
        assertion.matches(_artifact(ArtifactKind.image, 'image/png', 'd')),
        isFalse,
      );
    });
  });
}

AuthoringJobArtifact _artifact(
  ArtifactKind kind,
  String mediaType,
  String digestCharacter,
) {
  return AuthoringJobArtifact(
    jobId: 'job-071',
    sequence: kind.index + 1,
    kind: kind,
    createdAtUtc: '2026-07-31T12:00:0${kind.index}.000Z',
    reference: AuthoringArtifactRef(
      id: 'artifact-${kind.wireName}',
      mediaType: mediaType,
      uri: 'artifact://sha256/${digestCharacter * 64}',
      byteLength: kind == ArtifactKind.image ? 128 : 64,
      sha256: digestCharacter * 64,
    ),
  );
}
