import 'dart:convert';

import 'package:avelune_converter_adapters/src/converter_asset_review_set.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

final _namespace = ConverterId('original-segmented-review');
final _snapshot = Sha256Hash('a' * 64);
final _normalized = Sha256Hash('b' * 64);

String _mapPath(int id) =>
    "Data/Map${id.toString().padLeft(3, '0')}.rxdata";

SourceMapIr _sourceMap(int id) => SourceMapIr.fromJson({
      'schemaVersion': '1.0',
      'kind': 'sourceMapIr',
      'exampleOnly': false,
      'logicalProjectNamespace': _namespace.value,
      'sourceSnapshotHash': _snapshot.value,
      'sourceProfileId': 'rmxp',
      'map': {
        'sourceMapId': id,
        'sourceFileId': 'map-$id',
        'name': 'Original map',
        'width': 2,
        'height': 1,
        'tileWidth': 32,
        'tileHeight': 32,
        'sourceTilesetId': 1,
        'layers': [
          {
            'sourceZ': 0,
            'cells': [384, 385]
          },
          {
            'sourceZ': 1,
            'cells': [0, 0]
          },
          {
            'sourceZ': 2,
            'cells': [0, 0]
          },
        ],
        'events': <Object?>[],
        'unknownDataRefs': <String>[],
      },
    });

AssetCandidate _candidate(int mapId, int x,
        {String? id,
        AssetOutputMode mode = AssetOutputMode.sharedAtlas,
        Sha256Hash? snapshot}) =>
    AssetCandidate.fromJson({
      'schemaVersion': '1.0',
      'kind': 'assetCandidate',
      'exampleOnly': false,
      'candidateId': id ?? 'seed-$mapId-$x',
      'revision': 1,
      'logicalProjectNamespace': _namespace.value,
      'sourceSnapshotHash': (snapshot ?? _snapshot).value,
      'sources': [
        {
          'fileId': 'image-1',
          'contentHash': 'c' * 64,
          'pixelWidth': 96,
          'pixelHeight': 32,
        }
      ],
      'name': 'Original tree',
      'category': 'nature',
      'state': 'needsReview',
      'parts': [
        {
          'partId': 'p0',
          'sourceFileId': 'image-1',
          'sourceRect': {'x': x * 32, 'y': 0, 'width': 32, 'height': 32},
          'destinationOffset': {'x': 0, 'y': 0},
          'sourceLayer': 0,
          'sourcePriority': 0,
          'quarterTurns': 0,
          'reflected': false,
          'locator': {
            'file': _mapPath(mapId),
            'mapId': mapId,
            'eventId': null,
            'pageIndex': null,
            'commandIndex': null,
            'tileId': 384 + x,
            'line': null,
          }
        }
      ],
      'canvasSize': {'width': 32, 'height': 32},
      'anchor': {
        'unit': 'pixel',
        'x': 16,
        'y': 32,
        'convention': 'bottomCenter'
      },
      'integrationMode': 'libraryOnly',
      'outputMode': mode.name,
      'evidence': <Object?>[],
      'uncertainties': <String>[],
      'approvedRevision': null,
    });

AssetReviewSession _session(int mapId,
    {AssetOutputMode mode = AssetOutputMode.sharedAtlas,
    List<int> selected = const [98, 100],
    AssetReviewLimits limits = const AssetReviewLimits(),
    Sha256Hash? snapshot,
    String? firstId,
    bool claims = true}) {
  final map = _sourceMap(mapId);
  final candidates = [
    _candidate(mapId, 0, id: firstId, mode: mode, snapshot: snapshot),
    _candidate(mapId, 1, mode: mode, snapshot: snapshot)
  ];
  return AssetReviewSession.create(
      sessionId: ConverterId('original-review-$mapId'),
      logicalProjectNamespace: _namespace,
      sourceSnapshotHash: snapshot ?? _snapshot,
      selectedSourceMapIds: selected,
      outputMode: mode,
      proposalGenerationHash: canonicalHashOf({'map': mapId}),
      candidates: candidates,
      placementClaims: claims
          ? {
              for (var x = 0; x < candidates.length; x++)
                candidates[x].candidateId: [
                  SourcePlacementClaim(
                      sourceSnapshotHash: _snapshot,
                      sourceMapHash: map.canonicalHash,
                      sourceMapFileId: map.map.sourceFileId,
                      sourceMapId: mapId,
                      sourceZ: 0,
                      x: x,
                      y: 0,
                      tileId: 384 + x,
                      partId: ConverterId('p0'))
                ]
            }
          : const {},
      sourceMaps: [map],
      limits: limits);
}

ConverterAssetReviewSet _set({
  Map<int, AssetReviewSession>? segments,
  List<int> selected = const [98, 100],
  List<int> proposalIds = const [98, 100],
  ConverterAssetReviewSetLimits limits =
      const ConverterAssetReviewSetLimits(maxTotalCandidates: 512),
}) =>
    ConverterAssetReviewSet.create(
        sessionId: ConverterId('original-review-set'),
        logicalProjectNamespace: _namespace,
        sourceSnapshotHash: _snapshot,
        normalizedSourceHash: _normalized,
        selectedSourceMapIds: selected,
        proposalSourceMapIds: proposalIds,
        segments: segments ?? {98: _session(98), 100: _session(100)},
        limits: limits);

AssetReviewSession _manySession(int mapId, int count) {
  final raw = jsonDecode(jsonEncode(_sourceMap(mapId).toJson()))
      as Map<String, dynamic>;
  raw['map']['width'] = count;
  raw['map']['layers'][0]['cells'] = List.filled(count, 384);
  raw['map']['layers'][1]['cells'] = List.filled(count, 0);
  raw['map']['layers'][2]['cells'] = List.filled(count, 0);
  final map = SourceMapIr.fromJson(raw);
  final candidates = [
    for (var i = 0; i < count; i++)
      _candidate(mapId, 0, id: 'original-$mapId-$i')
  ];
  return AssetReviewSession.create(
      sessionId: ConverterId('original-review-$mapId'),
      logicalProjectNamespace: _namespace,
      sourceSnapshotHash: _snapshot,
      selectedSourceMapIds: const [98, 100],
      outputMode: AssetOutputMode.sharedAtlas,
      proposalGenerationHash: canonicalHashOf({'map': mapId}),
      candidates: candidates,
      sourceMaps: [map],
      placementClaims: {
        for (var i = 0; i < count; i++)
          candidates[i].candidateId: [
            SourcePlacementClaim(
                sourceSnapshotHash: _snapshot,
                sourceMapHash: map.canonicalHash,
                sourceMapFileId: map.map.sourceFileId,
                sourceMapId: mapId,
                sourceZ: 0,
                x: i,
                y: 0,
                tileId: 384,
                partId: ConverterId('p0'))
          ]
      });
}

Matcher _error(String code) =>
    throwsA(isA<ContractError>().having((e) => e.code, 'code', code));

Map<String, dynamic> _raw(ConverterAssetReviewSet value) =>
    jsonDecode(jsonEncode(value.toJson())) as Map<String, dynamic>;

AssetReviewSession _rename(AssetReviewSession value) {
  final candidate = value.activeCandidates.first;
  return value.editMetadata(
      candidateId: candidate.candidateId,
      expectedCandidateHash: candidate.canonicalHash,
      expectedSessionHash: value.canonicalHash,
      name: 'Exact original tree');
}

void main() {
  test('set preserves global context and strict source claims round trip', () {
    final value = _set();
    final loaded = ConverterAssetReviewSet.fromJson(value.toJson());
    expect(loaded.selectedSourceMapIds, [98, 100]);
    expect(loaded.proposalSourceMapIds, [98, 100]);
    expect(loaded.segments.keys, [98, 100]);
    expect(loaded.canonicalHash, value.canonicalHash);
    expect(loaded.toJson(), value.toJson());
    for (final entry in loaded.segments.entries) {
      expect(entry.value.selectedSourceMapIds, [98, 100]);
      expect(entry.value.toJson(), value.segments[entry.key]!.toJson());
      expect(
          entry.value.frame.placementClaims.values
              .expand((claims) => claims)
              .map((claim) => claim.sourceMapId),
          everyElement(entry.key));
      entry.value.validatePlacements([_sourceMap(98), _sourceMap(100)]);
    }
    expect(loaded.activeCandidates, hasLength(4));
    expect(loaded.approvedCandidateHashes, isEmpty);
  });

  test('set hash and JSON normalize input map permutations', () {
    final sessions = {98: _session(98), 100: _session(100)};
    final normal = _set(segments: sessions);
    final reversed = _set(
        segments: {100: sessions[100]!, 98: sessions[98]!},
        selected: [100, 98],
        proposalIds: [100, 98]);
    expect(reversed.canonicalHash, normal.canonicalHash);
    expect(reversed.toJson(), normal.toJson());
    expect(reversed.activeCandidates.map((c) => c.candidateId.value),
        orderedEquals(normal.activeCandidates.map((c) => c.candidateId.value)));
  });

  test('set context and collections are immutable', () {
    final ids = [98, 100];
    final sessions = {98: _session(98), 100: _session(100)};
    final value = _set(segments: sessions, selected: ids);
    ids.clear();
    sessions.clear();
    expect(value.segments.keys, [98, 100]);
    expect(value.selectedSourceMapIds, [98, 100]);
    expect(() => value.segments.clear(), throwsUnsupportedError);
    expect(() => value.selectedSourceMapIds.clear(), throwsUnsupportedError);
    expect(() => value.proposalSourceMapIds.clear(), throwsUnsupportedError);
    expect(() => value.activeCandidates.clear(), throwsUnsupportedError);
  });

  test('set hash binds limits and full child effective limits', () {
    final normal = _set();
    final limited = _set(
        limits: const ConverterAssetReviewSetLimits(maxTotalCandidates: 511));
    expect(limited.canonicalHash, isNot(normal.canonicalHash));
    const childLimits = AssetReviewLimits(maxFrames: 8, maxTotalClaims: 8);
    final custom = _set(
        segments: {98: _session(98, limits: childLimits), 100: _session(100)});
    final loaded = ConverterAssetReviewSet.fromJson(custom.toJson());
    expect(loaded.segments[98]!.limits.maxFrames, 8);
    expect(loaded.segments[98]!.limits.maxTotalClaims, 8);
    expect(loaded.segments[100]!.limits.maxFrames, 64);
    expect(custom.canonicalHash, isNot(normal.canonicalHash));
    expect(loaded.toJson(), custom.toJson());
  });

  test('set uses compact ordered session hashes', () {
    final value = _set();
    final descriptor = _raw(value);
    descriptor.remove('setHash');
    for (final raw in descriptor['segments'] as List) {
      (raw as Map).remove('session');
    }
    expect(value.canonicalHash, canonicalHashOf(descriptor));
    expect(utf8.encode(jsonEncode(descriptor)).length,
        lessThan(utf8.encode(jsonEncode(value.toJson())).length));
  });

  for (final segments in [
    () => {98: _session(98)},
    () => {98: _session(98), 100: _session(100), 105: _session(105)},
    () => {98: _session(100), 100: _session(98)},
    () => {
          98: _session(98, selected: [98]),
          100: _session(100)
        },
    () => {98: _session(98), 100: _session(100, firstId: 'seed-98-0')},
    () => {
          98: _session(98),
          100: _session(100, snapshot: Sha256Hash('d' * 64), claims: false)
        },
    () => {
          98: _session(98),
          100: _session(100, mode: AssetOutputMode.standaloneObjects)
        },
  ]) {
    test(
        'set refuses incomplete foreign or conflicting segment context',
        () => expect(
            () => _set(segments: segments()), _error('review.set.context')));
  }

  test('set permits exact dependency map scope without reducing selection', () {
    final value = _set(
        proposalIds: [98, 100, 105],
        segments: {98: _session(98), 100: _session(100), 105: _session(105)});
    expect(value.selectedSourceMapIds, [98, 100]);
    expect(value.proposalSourceMapIds, [98, 100, 105]);
  });

  test('set rejects duplicate or absent globally selected maps', () {
    expect(() => _set(selected: [98, 98]), _error('review.set.context'));
    expect(() => _set(selected: [98, 105]), _error('review.set.context'));
    expect(
        () => _set(proposalIds: [98, 98, 100]), _error('review.set.context'));
  });

  test('replace CAS updates one segment and preserves the other bytes', () {
    final value = _set();
    final next = _rename(value.segments[98]!);
    final changed = value.replaceSegment(
        sourceMapId: 98,
        next: next,
        expectedSetHash: value.canonicalHash,
        expectedSegmentHash: value.segments[98]!.canonicalHash);
    expect(changed.revision, 2);
    expect(changed.canonicalHash, isNot(value.canonicalHash));
    expect(changed.segments[98]!.canonicalHash, next.canonicalHash);
    expect(changed.segments[100]!.toJson(), value.segments[100]!.toJson());
    expect(value.revision, 1);
    expect(ConverterAssetReviewSet.fromJson(changed.toJson()).toJson(),
        changed.toJson());
  });

  test('replace rejects stale set segment identity generation and revisions',
      () {
    final value = _set();
    final original = value.segments[98]!;
    final next = _rename(original);
    expect(
        () => value.replaceSegment(
            sourceMapId: 98,
            next: next,
            expectedSetHash: Sha256Hash('e' * 64),
            expectedSegmentHash: original.canonicalHash),
        _error('review.set.conflict'));
    expect(
        () => value.replaceSegment(
            sourceMapId: 98,
            next: next,
            expectedSetHash: value.canonicalHash,
            expectedSegmentHash: Sha256Hash('e' * 64)),
        _error('review.set.conflict'));
    expect(
        () => value.replaceSegment(
            sourceMapId: 105,
            next: next,
            expectedSetHash: value.canonicalHash,
            expectedSegmentHash: original.canonicalHash),
        _error('review.set.conflict'));
    final changed = value.replaceSegment(
        sourceMapId: 98,
        next: next,
        expectedSetHash: value.canonicalHash,
        expectedSegmentHash: original.canonicalHash);
    expect(
        () => changed.replaceSegment(
            sourceMapId: 98,
            next: original,
            expectedSetHash: changed.canonicalHash,
            expectedSegmentHash: next.canonicalHash),
        _error('review.set.conflict'));
    expect(
        () => value.replaceSegment(
            sourceMapId: 98,
            next: _session(100),
            expectedSetHash: value.canonicalHash,
            expectedSegmentHash: original.canonicalHash),
        _error('review.set.conflict'));
    expect(
        value.replaceSegment(
            sourceMapId: 98,
            next: original,
            expectedSetHash: value.canonicalHash,
            expectedSegmentHash: original.canonicalHash),
        same(value));
  });

  test('union keeps all original and new claims through undo redo round trip',
      () {
    final value = _set();
    final original = value.segments[98]!;
    final union = original.unionCandidates(
        candidateId: ConverterId('whole-original-tree'),
        expectedSessionHash: original.canonicalHash,
        inputs: [
          for (var i = 0; i < original.activeCandidates.length; i++)
            AssetUnionInput(
                candidateId: original.activeCandidates[i].candidateId,
                expectedCandidateHash:
                    original.activeCandidates[i].canonicalHash,
                offsetX: i * 32,
                offsetY: 0)
        ],
        name: 'Whole original tree',
        category: AssetCategory.nature);
    var changed = value.replaceSegment(
        sourceMapId: 98,
        next: union,
        expectedSetHash: value.canonicalHash,
        expectedSegmentHash: original.canonicalHash);
    final child =
        union.frame.placementClaims[ConverterId('whole-original-tree')]!;
    expect(child.map((c) => c.x), [0, 1]);
    expect(child.map((c) => c.sourceMapId), [98, 98]);
    final undo = union.undo(expectedSessionHash: union.canonicalHash);
    changed = changed.replaceSegment(
        sourceMapId: 98,
        next: undo,
        expectedSetHash: changed.canonicalHash,
        expectedSegmentHash: union.canonicalHash);
    final redo = undo.redo(expectedSessionHash: undo.canonicalHash);
    changed = changed.replaceSegment(
        sourceMapId: 98,
        next: redo,
        expectedSetHash: changed.canonicalHash,
        expectedSegmentHash: undo.canonicalHash);
    final loaded = ConverterAssetReviewSet.fromJson(changed.toJson());
    expect(loaded.segments[98]!.toJson(), redo.toJson());
    expect(loaded.segments[100]!.toJson(), value.segments[100]!.toJson());
    expect(loaded.activeCandidates, hasLength(3));
  });

  test('common output mode is atomic and clears active approvals', () {
    var first = _session(98);
    final candidate = first.activeCandidates.first;
    first = first.decide(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: first.canonicalHash,
        action: ReviewAction.approve,
        humanConfirmed: true);
    final value = _set(segments: {98: first, 100: _session(100)});
    expect(value.approvedCandidateHashes, hasLength(1));
    expect(value.activeDecisions.decisions, hasLength(1));
    final changed = value.changeOutputMode(
        outputMode: AssetOutputMode.standaloneObjects,
        expectedSetHash: value.canonicalHash);
    expect(changed.revision, 2);
    expect(changed.outputMode, AssetOutputMode.standaloneObjects);
    expect(changed.seedOutputMode, AssetOutputMode.sharedAtlas);
    expect(changed.approvedCandidateHashes, isEmpty);
    for (final entry in changed.segments.entries) {
      expect(entry.value.outputMode, AssetOutputMode.standaloneObjects);
      expect(entry.value.frame.placementClaims,
          value.segments[entry.key]!.frame.placementClaims);
    }
    expect(
        changed.changeOutputMode(
            outputMode: AssetOutputMode.standaloneObjects,
            expectedSetHash: changed.canonicalHash),
        same(changed));
    expect(
        () => value.changeOutputMode(
            outputMode: AssetOutputMode.packedObjects,
            expectedSetHash: value.canonicalHash),
        _error('review.set.output_mode'));
    expect(
        () => value.changeOutputMode(
            outputMode: AssetOutputMode.standaloneObjects,
            expectedSetHash: Sha256Hash('e' * 64)),
        _error('review.set.conflict'));
  });

  test('failed common mode change retains every original segment', () {
    const oneFrame = AssetReviewLimits(maxFrames: 1);
    final value = _set(
        segments: {98: _session(98), 100: _session(100, limits: oneFrame)});
    final before = value.toJson();
    expect(
        () => value.changeOutputMode(
            outputMode: AssetOutputMode.standaloneObjects,
            expectedSetHash: value.canonicalHash),
        throwsA(isA<ContractError>()));
    expect(value.toJson(), before);
    expect(value.outputMode, AssetOutputMode.sharedAtlas);
  });

  for (final limits in [
    const ConverterAssetReviewSetLimits(maxTotalCandidates: 3),
    const ConverterAssetReviewSetLimits(
        maxTotalCandidates: 512, maxSegments: 1),
    const ConverterAssetReviewSetLimits(
        maxTotalCandidates: 512, maxTotalFrames: 1),
    const ConverterAssetReviewSetLimits(
        maxTotalCandidates: 512, maxTotalCandidateVersions: 3),
    const ConverterAssetReviewSetLimits(
        maxTotalCandidates: 512, maxTotalParts: 3),
    const ConverterAssetReviewSetLimits(
        maxTotalCandidates: 512, maxTotalClaims: 3),
    const ConverterAssetReviewSetLimits(
        maxTotalCandidates: 512, maxJsonBytes: 1),
  ]) {
    test('set global quotas count both preserved segments',
        () => expect(() => _set(limits: limits), _error('review.set.quota')));
  }

  test('global quotas include history superseded versions and decisions', () {
    final first = _rename(_session(98));
    final second = _rename(_session(100));
    expect(
        () => _set(
            segments: {98: first, 100: second},
            limits: const ConverterAssetReviewSetLimits(
                maxTotalCandidates: 512, maxTotalDecisions: 1)),
        _error('review.set.quota'));
    expect(
        () => _set(
            segments: {98: first, 100: second},
            limits: const ConverterAssetReviewSetLimits(
                maxTotalCandidates: 512, maxTotalFrames: 3)),
        _error('review.set.quota'));
    expect(
        () => _set(
            segments: {98: first, 100: second},
            limits: const ConverterAssetReviewSetLimits(
                maxTotalCandidates: 512, maxTotalCandidateVersions: 5)),
        _error('review.set.quota'));
  });

  test('set never broadens caller admission limits while restoring', () {
    final value = _set();
    expect(
        () => ConverterAssetReviewSet.fromJson(value.toJson(),
            admissionLimits:
                const ConverterAssetReviewSetLimits(maxTotalCandidates: 511)),
        _error('review.set.limits'));
    final custom = _set(
        limits: const ConverterAssetReviewSetLimits(maxTotalCandidates: 4));
    final loaded = ConverterAssetReviewSet.fromJson(custom.toJson(),
        admissionLimits:
            const ConverterAssetReviewSetLimits(maxTotalCandidates: 512));
    expect(loaded.limits.maxTotalCandidates, 4);
  });

  test('undo preserves the cumulative retained candidate admission', () {
    final original = _session(98);
    final union = original.unionCandidates(
        candidateId: ConverterId('whole-original-tree'),
        expectedSessionHash: original.canonicalHash,
        inputs: [
          for (var i = 0; i < original.activeCandidates.length; i++)
            AssetUnionInput(
                candidateId: original.activeCandidates[i].candidateId,
                expectedCandidateHash:
                    original.activeCandidates[i].canonicalHash,
                offsetX: i * 32,
                offsetY: 0)
        ],
        name: 'Whole original tree',
        category: AssetCategory.nature);
    final undo = union.undo(expectedSessionHash: union.canonicalHash);
    expect(undo.frame.candidates, hasLength(2));
    expect(
        () => _set(
            segments: {98: undo, 100: _session(100)},
            limits:
                const ConverterAssetReviewSetLimits(maxTotalCandidates: 4)),
        _error('review.set.quota'));
    final admitted = _set(
        segments: {98: undo, 100: _session(100)},
        limits: const ConverterAssetReviewSetLimits(maxTotalCandidates: 5));
    expect(ConverterAssetReviewSet.fromJson(admitted.toJson()).toJson(),
        admitted.toJson());
    admitted.validatePlacements([_sourceMap(98), _sourceMap(100)]);
  });

  test(
      'set retains 280 candidates with explicit total admission and child caps',
      () {
    final segments = {98: _manySession(98, 140), 100: _manySession(100, 140)};
    final value = _set(segments: segments);
    expect(value.activeCandidates, hasLength(280));
    expect(
        value.segments.values
            .expand((s) => s.frame.placementClaims.values)
            .expand((c) => c),
        hasLength(280));
    final loaded = ConverterAssetReviewSet.fromJson(value.toJson());
    expect(loaded.toJson(), value.toJson());
    expect(
        () => _set(
            segments: segments,
            limits:
                const ConverterAssetReviewSetLimits(maxTotalCandidates: 256)),
        _error('review.set.quota'));
  });

  test(
      'set preserves and hashes every nested JSON budget without broadening admission',
      () {
    const jsonLimits = ContractLimits(
        maxDepth: 32,
        maxNodes: 20000,
        maxStringCodeUnits: 8192,
        maxTextCodeUnits: 65536);
    const childLimits = AssetReviewLimits(
        maxFrames: 8,
        maxCandidates: 8,
        maxCandidateVersions: 16,
        maxTotalParts: 32,
        maxTotalClaims: 32,
        maxTotalDecisions: 16,
        jsonLimits: jsonLimits);
    const limits = ConverterAssetReviewSetLimits(
        maxTotalCandidates: 8,
        maxSegments: 2,
        maxTotalFrames: 16,
        maxTotalCandidateVersions: 32,
        maxTotalParts: 64,
        maxTotalClaims: 64,
        maxTotalDecisions: 32,
        maxJsonBytes: 131072,
        segmentLimits: childLimits,
        jsonLimits: jsonLimits);
    final value = _set(limits: limits, segments: {
      98: _session(98, limits: childLimits),
      100: _session(100, limits: childLimits)
    });
    final loaded = ConverterAssetReviewSet.fromJson(value.toJson(),
        admissionLimits: limits);
    expect(loaded.toJson(), value.toJson());
    for (final key in [
      'maxDepth',
      'maxNodes',
      'maxStringCodeUnits',
      'maxTextCodeUnits'
    ]) {
      final raw = _raw(value);
      raw['segments'][0]['limits']['jsonLimits'].remove(key);
      expect(() => ConverterAssetReviewSet.fromJson(raw),
          _error('review.set.document'));
    }
    expect(
        () => ConverterAssetReviewSet.fromJson(value.toJson(),
            admissionLimits: const ConverterAssetReviewSetLimits(
                maxTotalCandidates: 8,
                jsonLimits: ContractLimits(maxTextCodeUnits: 32768))),
        _error('review.set.limits'));
  });

  test('set refuses invalid global and child admission budgets', () {
    for (final limits in [
      const ConverterAssetReviewSetLimits(maxTotalCandidates: 0),
      const ConverterAssetReviewSetLimits(maxTotalCandidates: 1025),
      const ConverterAssetReviewSetLimits(
          maxTotalCandidates: 512, maxSegments: 0),
      const ConverterAssetReviewSetLimits(
          maxTotalCandidates: 512,
          segmentLimits: AssetReviewLimits(maxCandidates: 257)),
      const ConverterAssetReviewSetLimits(
          maxTotalCandidates: 512, jsonLimits: ContractLimits(maxNodes: 0)),
    ]) {
      expect(() => _set(limits: limits), _error('review.set.limits'));
    }
  });

  test(
      'set rejects individual output change and changed proposal generation under CAS',
      () {
    final value = _set();
    final first = value.segments[98]!;
    final changedMode = first.changeOutputMode(
        outputMode: AssetOutputMode.standaloneObjects,
        expectedSessionHash: first.canonicalHash);
    expect(
        () => value.replaceSegment(
            sourceMapId: 98,
            next: changedMode,
            expectedSetHash: value.canonicalHash,
            expectedSegmentHash: first.canonicalHash),
        _error('review.set.conflict'));
    final raw =
        jsonDecode(jsonEncode(_rename(first).toJson())) as Map<String, dynamic>;
    raw['proposalGenerationHash'] = 'f' * 64;
    final changedGeneration = AssetReviewSession.fromJson(raw);
    expect(
        () => value.replaceSegment(
            sourceMapId: 98,
            next: changedGeneration,
            expectedSetHash: value.canonicalHash,
            expectedSegmentHash: first.canonicalHash),
        _error('review.set.conflict'));
  });

  test('set placement validation includes inactive history frames', () {
    final value = _set();
    final first = _rename(value.segments[98]!);
    final changed = value.replaceSegment(
        sourceMapId: 98,
        next: first,
        expectedSetHash: value.canonicalHash,
        expectedSegmentHash: value.segments[98]!.canonicalHash);
    changed.validatePlacements([_sourceMap(98), _sourceMap(100)]);
    expect(() => changed.validatePlacements([_sourceMap(98)]),
        _error('review.claim.map'));
    expect(() => changed.validatePlacements([_sourceMap(98), _sourceMap(98)]),
        _error('review.set.context'));
  });

  test('set rejects current-format tampering without fallback', () {
    final value = _set();
    for (final key in value.toJson().keys) {
      final raw = _raw(value)..remove(key);
      expect(() => ConverterAssetReviewSet.fromJson(raw),
          throwsA(isA<ContractError>()),
          reason: key);
    }
    for (final change in [
      {'schemaVersion': '0.9'},
      {'unknown': true},
      {'setHash': 'e' * 64},
      {'revision': 0},
      {'outputMode': 'standaloneObjects'},
    ]) {
      expect(
          () =>
              ConverterAssetReviewSet.fromJson({...value.toJson(), ...change}),
          throwsA(isA<ContractError>()));
    }
    var raw = _raw(value);
    (raw['segments'] as List).first['sessionHash'] = 'e' * 64;
    expect(
        () => ConverterAssetReviewSet.fromJson(raw), _error('review.set.hash'));
    raw = _raw(value);
    (raw['segments'] as List).first['limits'].remove('maxFrames');
    expect(() => ConverterAssetReviewSet.fromJson(raw),
        _error('review.set.document'));
    raw = _raw(value);
    (raw['segments'] as List).first['sourceMapId'] = 100;
    expect(() => ConverterAssetReviewSet.fromJson(raw),
        _error('review.set.context'));
  });
}
