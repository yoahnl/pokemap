import 'dart:async';
import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'asset_review_session_test.dart' as fixture;

final account = ConverterId('account-revision-1');
final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==');

VisionCrop crop(
        {String id = 'region-1', List<int>? bytes, int x = 0, int width = 1}) =>
    VisionCrop(
      regionId: ConverterId(id),
      fileId: ConverterId('image-1'),
      sourceHash: Sha256Hash('c' * 64),
      sourceRect: {'x': x, 'y': 0, 'width': 1, 'height': 1},
      pngBytes: bytes ?? png,
      transmittedWidth: width,
      transmittedHeight: 1,
    );

VisionMaterial material(AssetReviewSession session,
        {List<VisionCrop>? crops,
        Map<String, Object?> options = const {},
        String model = 'documented-model',
        VisionLimits limits = const VisionLimits()}) =>
    VisionMaterial(
      context: VisionRequestContext(
          requestId: ConverterId('request-1'),
          sourceSnapshotHash: session.sourceSnapshotHash,
          inputRevision: session.revision,
          candidateIds:
              session.activeCandidates.map((c) => c.candidateId).toSet(),
          sourceRegionIds: (crops ?? [crop()]).map((c) => c.regionId).toSet()),
      expectedSessionHash: session.canonicalHash,
      candidateHashes: {
        for (final c in session.activeCandidates) c.candidateId: c.canonicalHash
      },
      crops: crops ?? [crop()],
      model: model,
      promptVersion: 'prompt-1',
      options: options,
      limits: limits,
    );

VisionRequest request(AssetReviewSession session, {VisionMaterial? value}) {
  final selected = value ?? material(session);
  return VisionRequest(
      context: selected.context,
      material: selected,
      consent: VisionConsent.grant(
          materialHash: selected.canonicalHash,
          accountRevision: account,
          humanConfirmed: true));
}

VisionLiveContext live(VisionRequest request,
        {Sha256Hash? sessionHash,
        Sha256Hash? selectionHash,
        Sha256Hash? sourceHash,
        ConverterId? accountRevision,
        bool verified = true}) =>
    VisionLiveContext(
      sourceVerified: verified,
      sourceSnapshotHash: sourceHash ?? request.context.sourceSnapshotHash,
      sessionHash: sessionHash ?? request.material.expectedSessionHash,
      selectionHash: selectionHash ?? request.material.selectionHash,
      inputRevision: request.context.inputRevision,
      accountRevision: accountRevision ?? account,
    );

VisionResponse response(VisionRequest request,
        {List<String>? candidates,
        List<String> regions = const ['region-1'],
        int? revision}) =>
    VisionResponse.fromJson({
      'schemaVersion': '1.0',
      'kind': 'visionResponse',
      'exampleOnly': false,
      'requestId': request.context.requestId.value,
      'sourceSnapshotHash': request.context.sourceSnapshotHash.value,
      'inputRevision': revision ?? request.context.inputRevision,
      'suggestions': [
        {
          'suggestionId': 'suggestion-1',
          'candidateIds': candidates ??
              request.context.candidateIds.map((id) => id.value).toList(),
          'sourceRegionIds': regions,
          'proposedName': 'Arbre suggéré',
          'category': 'nature',
          'tags': ['arbre'],
          'evidenceSummary': 'Classification proposée',
          'uncertainties': ['À confirmer'],
          'confidenceLabel': 'medium'
        }
      ],
    });

AssetReviewSession imported(AssetReviewSession session, VisionRequest request,
        {VisionResponse? result}) =>
    session.importVisionSuggestions(
      response: result ?? response(request),
      request: request,
      live: live(request),
      verifiedSources:
          session.activeCandidates.expand((c) => c.sources).toList(),
      expectedSessionHash: session.canonicalHash,
    );

void main() {
  test('crop copies bytes and metadata without serializing pixels', () {
    final bytes = [...png];
    final rect = <String, Object?>{'x': 0, 'y': 0, 'width': 1, 'height': 1};
    final value = VisionCrop(
        regionId: ConverterId('region-1'),
        fileId: ConverterId('image-1'),
        sourceHash: Sha256Hash('c' * 64),
        sourceRect: rect,
        pngBytes: bytes,
        transmittedWidth: 1,
        transmittedHeight: 1);
    final hash = value.byteHash;
    bytes[bytes.length - 1] = 0;
    rect['x'] = 32;
    expect(value.byteHash, hash);
    expect(value.pngBytes, png);
    expect(value.sourceRect['x'], 0);
    expect(() => value.pngBytes.add(1), throwsUnsupportedError);
    expect(jsonEncode(value.toJson()), isNot(contains(base64Encode(png))));
  });
  test(
      'invalid PNG signature is rejected',
      () =>
          expect(() => crop(bytes: List.filled(70, 0)), throwsFormatException));
  test('PNG header dimensions must match transmitted dimensions',
      () => expect(() => crop(width: 2), throwsFormatException));
  test('negative source geometry is rejected',
      () => expect(() => crop(x: -1), throwsFormatException));
  test(
      'crop byte quota is enforced before admission',
      () => expect(
          () => material(fixture.session(),
              limits: const VisionLimits(maxImageBytes: 16)),
          throwsFormatException));
  test(
      'duplicate crop IDs are rejected',
      () => expect(() => material(fixture.session(), crops: [crop(), crop()]),
          throwsFormatException));
  test('material copies caller maps and derives hashes from all options', () {
    final options = <String, Object?>{'detail': 'high'};
    final value = material(fixture.session(), options: options);
    final hash = value.canonicalHash;
    options['detail'] = 'low';
    expect(value.canonicalHash, hash);
    expect(value.options['detail'], 'high');
    expect(value.options['maxOutputTokens'], 2048);
    expect(
        value.canonicalHash,
        isNot(material(fixture.session(), options: {'detail': 'low'})
            .canonicalHash));
    expect(
        value.canonicalHash,
        isNot(
            material(fixture.session(), model: 'another-model').canonicalHash));
  });
  test(
      'unknown provider options cannot carry endpoints or secrets',
      () => expect(
          () =>
              material(fixture.session(), options: {'apiKey': 'decoy-secret'}),
          throwsFormatException));
  test(
      'output token limit is positive and bounded',
      () => expect(
          () => material(fixture.session(), options: {'maxOutputTokens': 0}),
          throwsFormatException));
  test(
      'unconfirmed consent is refused',
      () => expect(
          () => VisionConsent.grant(
              materialHash: Sha256Hash('d' * 64),
              accountRevision: account,
              humanConfirmed: false),
          throwsFormatException));
  test('consent is tied to exact material bytes and options', () {
    final session = fixture.session();
    final first = material(session);
    final second = material(session, options: {'detail': 'low'});
    expect(
        () => VisionRequest(
            context: second.context,
            material: second,
            consent: VisionConsent.grant(
                materialHash: first.canonicalHash,
                accountRevision: account,
                humanConfirmed: true)),
        throwsFormatException);
  });
  for (final guard in [
    'session',
    'selection',
    'source',
    'account',
    'verified'
  ]) {
    test('dispatch rejects changed $guard context', () {
      final req = request(fixture.session());
      final changed = Sha256Hash('f' * 64);
      expect(
          () => validateVisionDispatch(
              req,
              live(req,
                  sessionHash: guard == 'session' ? changed : null,
                  selectionHash: guard == 'selection' ? changed : null,
                  sourceHash: guard == 'source' ? changed : null,
                  accountRevision:
                      guard == 'account' ? ConverterId('account-2') : null,
                  verified: guard != 'verified')),
          throwsFormatException);
    });
  }
  test('matching result remains a proposal on known IDs', () {
    final req = request(fixture.session());
    expect(() => validateVisionResult(response(req), req, live(req)),
        returnsNormally);
  });
  test('result rejects unrequested region IDs', () {
    final req = request(fixture.session());
    expect(
        () => validateVisionResult(
            response(req, regions: ['unknown']), req, live(req)),
        throwsFormatException);
  });
  test('result rejects obsolete revision', () {
    final req = request(fixture.session());
    expect(
        () => validateVisionResult(response(req, revision: 2), req, live(req)),
        throwsFormatException);
  });
  test('late result is rejected after selection changes', () {
    final req = request(fixture.session());
    expect(
        () => validateVisionResult(
            response(req), req, live(req, selectionHash: Sha256Hash('e' * 64))),
        throwsFormatException);
  });
  test('fake preserves an in-flight gate and records exact requests', () async {
    final req = request(fixture.session());
    final gate = Completer<void>();
    final port = FakeVisionPort(response: response(req), gate: gate.future);
    var completed = false;
    final pending = port.suggest(req).then((value) {
      completed = true;
      return value;
    });
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);
    expect(port.requests, [req]);
    gate.complete();
    expect((await pending).canonicalHash, response(req).canonicalHash);
  });
  test('fake error leaves the review unchanged', () async {
    final session = fixture.session();
    final req = request(session);
    final failure = StateError('simulated-failure');
    final port = FakeVisionPort(error: failure);
    await expectLater(port.suggest(req), throwsA(same(failure)));
    expect(session.frame.visionProposals, isEmpty);
  });
  test('fake cancellation rejects a late response', () async {
    final req = request(fixture.session());
    final gate = Completer<void>();
    final cancel = ScanCancellation();
    final port = FakeVisionPort(response: response(req), gate: gate.future);
    final pending = port.suggest(req, cancellation: cancel);
    cancel.cancel();
    gate.complete();
    await expectLater(pending, throwsFormatException);
  });
  test('import is atomic and does not change an approved candidate', () {
    final session = fixture.decide(fixture.session(), 'tree');
    final req = request(session);
    final next = imported(session, req);
    expect(next.frame.visionProposals, hasLength(1));
    expect(next.frame.visionProposals.single.state, CandidateState.needsReview);
    expect(next.frame.candidates.single.canonicalHash,
        session.frame.candidates.single.canonicalHash);
    expect(next.frame.approvedCandidateHashes,
        session.frame.approvedCandidateHashes);
    expect(next.frame.placementClaims, session.frame.placementClaims);
    expect(next.revision, session.revision + 1);
    expect(session.frame.visionProposals, isEmpty);
  });
  test('import rejects a crop beyond verified source bounds without mutation',
      () {
    final session = fixture.session();
    final req =
        request(session, value: material(session, crops: [crop(x: 96)]));
    expect(() => imported(session, req), throwsFormatException);
    expect(session.frame.visionProposals, isEmpty);
  });
  test('human metadata application expires approval and preserves pixels', () {
    final session = fixture.decide(fixture.session(), 'tree');
    final next = imported(session, request(session));
    final applied = next.applyVisionMetadata(
        proposalId: next.frame.visionProposals.single.proposalId,
        expectedSessionHash: next.canonicalHash,
        humanConfirmed: true);
    expect(applied.frame.candidates.single.name, 'Arbre suggéré');
    expect(applied.frame.candidates.single.state, CandidateState.needsReview);
    expect(applied.frame.approvedCandidateHashes, isEmpty);
    expect(applied.frame.candidates.single.parts.map((p) => p.toJson()),
        session.frame.candidates.single.parts.map((p) => p.toJson()));
    expect(applied.frame.candidates.single.evidence.last.type,
        EvidenceType.aiSuggestion);
    expect(applied.frame.visionProposals, isEmpty);
  });
  test('unconfirmed metadata application cannot mutate review', () {
    final session = fixture.session();
    final next = imported(session, request(session));
    expect(
        () => next.applyVisionMetadata(
            proposalId: next.frame.visionProposals.single.proposalId,
            expectedSessionHash: next.canonicalHash,
            humanConfirmed: false),
        throwsFormatException);
  });
  test('metadata proposal rejects a changed candidate', () {
    final session = fixture.session();
    final next = imported(session, request(session));
    final candidate = next.frame.candidates.single;
    final changed = next.editMetadata(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: next.canonicalHash,
        name: 'Nom humain');
    expect(changed.frame.visionProposals, hasLength(1));
    expect(
        () => changed.applyVisionMetadata(
            proposalId: changed.frame.visionProposals.single.proposalId,
            expectedSessionHash: changed.canonicalHash,
            humanConfirmed: true),
        throwsFormatException);
    expect(changed.frame.candidates.single.name, 'Nom humain');
  });
  test('grouping stays inspectable without invented geometry', () {
    final session = fixture.session(
        candidates: [fixture.candidate('tree'), fixture.candidate('bush')]);
    final next = imported(session, request(session));
    expect(next.frame.visionProposals.single.suggestion.candidateIds,
        hasLength(2));
    expect(next.frame.candidates.map((c) => c.canonicalHash),
        session.frame.candidates.map((c) => c.canonicalHash));
    expect(
        () => next.applyVisionMetadata(
            proposalId: next.frame.visionProposals.single.proposalId,
            expectedSessionHash: next.canonicalHash,
            humanConfirmed: true),
        throwsFormatException);
  });
  test('proposal history roundtrips and undo redo restores exact frames', () {
    final session = fixture.session();
    final next = imported(session, request(session));
    final restored =
        AssetReviewSession.fromJson(jsonDecode(jsonEncode(next.toJson())));
    expect(restored.canonicalHash, next.canonicalHash);
    final undone = restored.undo(expectedSessionHash: restored.canonicalHash);
    expect(undone.frame.visionProposals, isEmpty);
    final redone = undone.redo(expectedSessionHash: undone.canonicalHash);
    expect(redone.frame.canonicalHash, next.frame.canonicalHash);
  });
  test('private session 1.0 and 1.1 are explicitly rejected', () {
    final session = fixture.session();
    expect(session.toJson()['schemaVersion'], '1.2');
    for (final version in ['1.0', '1.1']) {
      final old =
          jsonDecode(jsonEncode(session.toJson())) as Map<String, Object?>;
      old['schemaVersion'] = version;
      expect(() => AssetReviewSession.fromJson(old), throwsFormatException);
    }
  });
  test('discard removes only the proposal and can be undone', () {
    final session = fixture.session();
    final next = imported(session, request(session));
    final removed = next.removeVisionProposal(
        proposalId: next.frame.visionProposals.single.proposalId,
        expectedSessionHash: next.canonicalHash,
        humanConfirmed: true);
    expect(removed.frame.visionProposals, isEmpty);
    expect(removed.frame.candidates.single.canonicalHash,
        session.frame.candidates.single.canonicalHash);
    expect(
        removed
            .undo(expectedSessionHash: removed.canonicalHash)
            .frame
            .canonicalHash,
        next.frame.canonicalHash);
  });
  test('material context must match requested crop and candidate IDs', () {
    final session = fixture.session();
    final value = material(session);
    expect(
        () => VisionMaterial(
            context: value.context,
            expectedSessionHash: value.expectedSessionHash,
            candidateHashes: {},
            crops: value.crops,
            model: value.model,
            promptVersion: value.promptVersion),
        throwsFormatException);
  });
  test('request cannot substitute another context after consent', () {
    final session = fixture.session();
    final value = material(session);
    final other = VisionRequestContext(
        requestId: ConverterId('request-2'),
        sourceSnapshotHash: session.sourceSnapshotHash,
        inputRevision: session.revision,
        candidateIds: value.context.candidateIds,
        sourceRegionIds: value.context.sourceRegionIds);
    expect(
        () => VisionRequest(
            context: other,
            material: value,
            consent: VisionConsent.grant(
                materialHash: value.canonicalHash,
                accountRevision: account,
                humanConfirmed: true)),
        throwsFormatException);
  });
  test('import quota rejects complete batch without partial changes', () {
    final session = fixture.session();
    final req = request(session,
        value: material(session, limits: const VisionLimits(maxProposals: 1)));
    final batch = response(req).toJson();
    final first = (batch['suggestions'] as List).single as Map<String, Object?>;
    final extra = VisionResponse.fromJson({
      ...batch,
      'suggestions': [
        first,
        {...first, 'suggestionId': 'suggestion-2'}
      ]
    });
    expect(() => imported(session, req, result: extra), throwsFormatException);
    expect(session.frame.visionProposals, isEmpty);
  });
  test('one invalid suggestion refuses the entire import batch', () {
    final session = fixture.session();
    final req = request(session);
    final json = response(req).toJson();
    final first = (json['suggestions'] as List).single as Map<String, Object?>;
    final batch = VisionResponse.fromJson({
      ...json,
      'suggestions': [
        first,
        {
          ...first,
          'suggestionId': 'suggestion-2',
          'candidateIds': ['unknown-candidate']
        }
      ]
    });
    expect(() => imported(session, req, result: batch), throwsFormatException);
    expect(session.frame.visionProposals, isEmpty);
  });
  test('import validates selected candidate hashes against actual review', () {
    final session = fixture.session();
    final value = material(session);
    final stale = VisionMaterial(
        context: value.context,
        expectedSessionHash: value.expectedSessionHash,
        candidateHashes: {
          session.activeCandidates.single.candidateId: Sha256Hash('d' * 64)
        },
        crops: value.crops,
        model: value.model,
        promptVersion: value.promptVersion);
    expect(() => imported(session, request(session, value: stale)),
        throwsFormatException);
  });
  test('persisted AI proposal refuses forged approval', () {
    final session = fixture.session();
    final next = imported(session, request(session));
    final json = jsonDecode(jsonEncode(next.toJson())) as Map<String, Object?>;
    final last = (json['frames'] as List).last as Map<String, Object?>;
    final proposal =
        (last['visionProposals'] as List).single as Map<String, Object?>;
    proposal['state'] = 'approved';
    expect(() => AssetReviewSession.fromJson(json), throwsFormatException);
  });
  test('duplicate import proposal cannot overwrite a pending human review', () {
    final session = fixture.session();
    final req = request(session);
    final next = imported(session, req);
    expect(
        () => next.importVisionSuggestions(
            response: response(req),
            request: req,
            live: live(req),
            verifiedSources: session.activeCandidates.single.sources,
            expectedSessionHash: next.canonicalHash),
        throwsFormatException);
    expect(next.frame.visionProposals, hasLength(1));
  });
}
