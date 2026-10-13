import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'vision_assistance_test.dart' as vision;

final _snapshot = Sha256Hash('a' * 64);
final _namespace = ConverterId('original-terrain-review');

Map<String, Object?> _part(int cell) => {
      'partId': 'part-$cell',
      'sourceFileId': 'original-atlas',
      'sourceRect': {
        'x': 128 + cell % 3 * 32,
        'y': 1664 + cell ~/ 3 * 32,
        'width': 32,
        'height': 32,
      },
      'destinationOffset': {'x': cell % 3 * 32, 'y': cell ~/ 3 * 32},
      'sourceLayer': null,
      'sourcePriority': null,
      'quarterTurns': 0,
      'reflected': false,
      'locator': {
        'file': 'Graphics/Tilesets/OriginalAtlas.png',
        'mapId': null,
        'eventId': null,
        'pageIndex': null,
        'commandIndex': null,
        'tileId': null,
        'line': null,
      },
    };

AssetCandidate _candidate(String id,
        {String category = 'nature', bool layout = false}) =>
    AssetCandidate.fromJson({
      'schemaVersion': '1.0',
      'kind': 'assetCandidate',
      'exampleOnly': false,
      'candidateId': id,
      'revision': 1,
      'logicalProjectNamespace': _namespace.value,
      'sourceSnapshotHash': _snapshot.value,
      'sources': [
        {
          'fileId': 'original-atlas',
          'contentHash': 'b' * 64,
          'pixelWidth': 256,
          'pixelHeight': 2048,
        },
      ],
      'name': 'Original nine-cell atlas region',
      'category': category,
      'state': 'needsReview',
      'parts': List.generate(9, _part),
      'canvasSize': {'width': 96, 'height': 96},
      'anchor': {
        'unit': 'pixel',
        'x': 48,
        'y': 96,
        'convention': 'bottomCenter'
      },
      'integrationMode': 'libraryOnly',
      'outputMode': 'standaloneObjects',
      if (layout) 'terrainLayout': 'cardinal3x3',
      'evidence': <Object?>[],
      'uncertainties': <String>[],
      'approvedRevision': null,
    });

AssetReviewSession _session(List<AssetCandidate> candidates) =>
    AssetReviewSession.create(
      sessionId: ConverterId('original-terrain-session'),
      logicalProjectNamespace: _namespace,
      sourceSnapshotHash: _snapshot,
      selectedSourceMapIds: [1],
      outputMode: AssetOutputMode.standaloneObjects,
      proposalGenerationHash: Sha256Hash('c' * 64),
      candidates: candidates,
    );

AssetCandidate _current(AssetReviewSession session, [String id = 'terrain']) =>
    session.activeCandidates
        .singleWhere((value) => value.candidateId.value == id);

AssetReviewSession _configure(AssetReviewSession session,
        [AssetTerrainLayout? layout = AssetTerrainLayout.cardinal3x3]) =>
    session.configureTerrainLayout(
      candidateId: _current(session).candidateId,
      expectedCandidateHash: _current(session).canonicalHash,
      expectedSessionHash: session.canonicalHash,
      layout: layout,
    );

AssetReviewSession _approve(AssetReviewSession session) => session.decide(
      candidateId: _current(session).candidateId,
      expectedCandidateHash: _current(session).canonicalHash,
      expectedSessionHash: session.canonicalHash,
      action: ReviewAction.approve,
      humanConfirmed: true,
    );

Map<String, Object?> _mutable(AssetCandidate candidate) =>
    (jsonDecode(jsonEncode(candidate.toJson())) as Map).cast<String, Object?>();

void main() {
  test('optional absent or null layout preserves ordinary object behavior', () {
    final original = _candidate('terrain');
    expect(original.terrainLayout, isNull);
    expect(original.toJson().containsKey('terrainLayout'), isFalse);
    final explicitNull =
        AssetCandidate.fromJson({...original.toJson(), 'terrainLayout': null});
    expect(explicitNull.terrainLayout, isNull);
    expect(explicitNull.category, AssetCategory.nature);
    expect(_current(_approve(_session([original]))).state,
        CandidateState.approved);
  });

  test('explicit cardinal layout is typed hashed and round-trips', () {
    final candidate = _candidate('terrain', category: 'terrain', layout: true);
    expect(candidate.terrainLayout, AssetTerrainLayout.cardinal3x3);
    expect(AssetCandidate.fromJson(candidate.toJson()).canonicalHash,
        candidate.canonicalHash);
    expect(candidate.canonicalHash,
        isNot(_candidate('terrain', category: 'terrain').canonicalHash));
  });

  test('configuration changes metadata but never approves or invents claims',
      () {
    final initial = _approve(_session([_candidate('terrain')]));
    final previous = _current(initial);
    final next = _configure(initial);
    final terrain = _current(next);
    expect(terrain.terrainLayout, AssetTerrainLayout.cardinal3x3);
    expect(terrain.category, AssetCategory.terrain);
    expect(terrain.state, CandidateState.needsReview);
    expect(terrain.approvedRevision, isNull);
    expect(terrain.revision, previous.revision + 1);
    expect(terrain.integrationMode, IntegrationMode.libraryOnly);
    expect(next.approvedCandidateHashes, isEmpty);
    expect(next.frame.placementClaims.values.expand((v) => v), isEmpty);
    expect(next.activeDecisions.decisions.single.action,
        ReviewAction.changeGeometry);
    expect(
        _current(_approve(next)).terrainLayout, AssetTerrainLayout.cardinal3x3);
  });

  test('clearing layout revokes the exact current approval', () {
    final initial = _approve(_configure(_session([_candidate('terrain')])));
    final next = _configure(initial, null);
    expect(_current(next).terrainLayout, isNull);
    expect(_current(next).toJson()['terrainLayout'], isNull);
    expect(_current(next).state, CandidateState.needsReview);
    expect(_current(next).category, AssetCategory.terrain);
    expect(next.approvedCandidateHashes, isEmpty);
  });

  test('configuration refuses stale candidate or session hashes', () {
    final initial = _session([_candidate('terrain')]);
    final next = _configure(initial);
    for (final hashes in [
      (_current(initial).canonicalHash, next.canonicalHash),
      (_current(next).canonicalHash, initial.canonicalHash),
    ]) {
      expect(
          () => next.configureTerrainLayout(
              candidateId: _current(next).candidateId,
              expectedCandidateHash: hashes.$1,
              expectedSessionHash: hashes.$2,
              layout: null),
          throwsA(isA<ContractError>()));
    }
  });

  for (final mutation in <String, void Function(Map<String, Object?>)>{
    'category': (json) => json['category'] = 'object',
    'canvas': (json) {
      json['canvasSize'] = {'width': 128, 'height': 96};
      (json['anchor'] as Map)['convention'] = 'explicit';
    },
    'rotation': (json) =>
        ((json['parts'] as List).first as Map)['quarterTurns'] = 1,
    'reflection': (json) =>
        ((json['parts'] as List).first as Map)['reflected'] = true,
    'source alignment': (json) =>
        ((((json['parts'] as List).first as Map)['sourceRect']) as Map)['x'] =
            129,
    'destination alignment': (json) => ((((json['parts'] as List).first
        as Map)['destinationOffset']) as Map)['x'] = 1,
    'part size': (json) => ((((json['parts'] as List).first
        as Map)['sourceRect']) as Map)['width'] = 16,
    'occlusive priority': (json) =>
        ((json['parts'] as List).first as Map)['sourcePriority'] = 1,
    'hole': (json) => (json['parts'] as List).removeLast(),
    'duplicate coverage': (json) => ((json['parts'] as List).last
        as Map)['destinationOffset'] = {'x': 0, 'y': 0},
  }.entries) {
    test('cardinal layout rejects ${mutation.key}', () {
      final json =
          _mutable(_candidate('terrain', category: 'terrain', layout: true));
      mutation.value(json);
      expect(
          () => AssetCandidate.fromJson(json), throwsA(isA<ContractError>()));
    });
  }

  test('one aligned rectangle or strips may cover all nine cells exactly', () {
    for (final strips in [false, true]) {
      final json =
          _mutable(_candidate('terrain', category: 'terrain', layout: true));
      json['parts'] = [
        for (var row = 0; row < (strips ? 3 : 1); row++)
          {
            ..._part(row * 3),
            'sourceRect': {
              'x': 128,
              'y': 1664 + row * 32,
              'width': 96,
              'height': strips ? 32 : 96
            },
            'destinationOffset': {'x': 0, 'y': row * 32},
            'sourcePriority': 0,
          },
      ];
      expect(AssetCandidate.fromJson(json).terrainLayout,
          AssetTerrainLayout.cardinal3x3);
    }
  });

  for (final metadata in ['name', 'category']) {
    test('changing $metadata clears the layout and its approval', () {
      final initial = _approve(
          _session([_candidate('terrain', category: 'terrain', layout: true)]));
      final next = initial.editMetadata(
          candidateId: _current(initial).candidateId,
          expectedCandidateHash: _current(initial).canonicalHash,
          expectedSessionHash: initial.canonicalHash,
          name: metadata == 'name' ? 'Changed terrain name' : null,
          category: metadata == 'category' ? AssetCategory.surface : null);
      expect(_current(next).toJson()['terrainLayout'], isNull);
      expect(_current(next).approvedRevision, isNull);
      expect(next.approvedCandidateHashes, isEmpty);
    });
  }

  test('geometry changes clear layout even when the nine cells still fit', () {
    final initial = _approve(
        _session([_candidate('terrain', category: 'terrain', layout: true)]));
    final candidate = _current(initial);
    final next = initial.changeGeometry(
        candidateId: candidate.candidateId,
        expectedCandidateHash: candidate.canonicalHash,
        expectedSessionHash: initial.canonicalHash,
        geometry: AssetReviewGeometry(
            parts: candidate.parts.map((p) => p.toJson()).toList(),
            canvasWidth: 96,
            canvasHeight: 96,
            anchorX: 0,
            anchorY: 0,
            anchorConvention: AnchorConvention.topLeft));
    expect(_current(next).toJson()['terrainLayout'], isNull);
    expect(next.approvedCandidateHashes, isEmpty);
  });

  test('applying reviewed suggested metadata clears layout and approval', () {
    final initial = _approve(_session([
      _candidate('terrain', category: 'terrain', layout: true),
    ]));
    final request = vision.request(initial,
        value: vision.material(initial, crops: [
          VisionCrop(
              regionId: ConverterId('region-1'),
              fileId: ConverterId('original-atlas'),
              sourceHash: Sha256Hash('b' * 64),
              sourceRect: {'x': 128, 'y': 1664, 'width': 1, 'height': 1},
              pngBytes: vision.png,
              transmittedWidth: 1,
              transmittedHeight: 1),
        ]));
    final imported = vision.imported(initial, request);
    final next = imported.applyVisionMetadata(
        proposalId: imported.frame.visionProposals.single.proposalId,
        expectedSessionHash: imported.canonicalHash,
        humanConfirmed: true);
    expect(_current(next).terrainLayout, isNull);
    expect(_current(next).category, AssetCategory.nature);
    expect(_current(next).approvedRevision, isNull);
    expect(next.approvedCandidateHashes, isEmpty);
    expect(_current(next).parts.map((part) => part.toJson()),
        _current(initial).parts.map((part) => part.toJson()));
  });

  test('union children require a new terrain layout decision', () {
    final initial = _session([
      _candidate('terrain', category: 'terrain', layout: true),
      _candidate('other', category: 'terrain', layout: true),
    ]);
    final next = initial.unionCandidates(
        candidateId: ConverterId('union'),
        expectedSessionHash: initial.canonicalHash,
        inputs: [
          AssetUnionInput(
              candidateId: _current(initial).candidateId,
              expectedCandidateHash: _current(initial).canonicalHash,
              offsetX: 0,
              offsetY: 0),
          AssetUnionInput(
              candidateId: _current(initial, 'other').candidateId,
              expectedCandidateHash: _current(initial, 'other').canonicalHash,
              offsetX: 96,
              offsetY: 0),
        ],
        name: 'Explicit union',
        category: AssetCategory.terrain);
    expect(_current(next, 'union').toJson()['terrainLayout'], isNull);
    expect(next.approvedCandidateHashes, isEmpty);
  });

  test('split children require a new terrain layout decision', () {
    final initial =
        _session([_candidate('terrain', category: 'terrain', layout: true)]);
    final next = initial.splitCandidate(
        candidateId: _current(initial).candidateId,
        expectedCandidateHash: _current(initial).canonicalHash,
        expectedSessionHash: initial.canonicalHash,
        groups: [
          for (var row = 0; row < 3; row++)
            AssetSplitGroup(
                candidateId: ConverterId('row-$row'),
                partIds: List.generate(
                    3, (column) => ConverterId('part-${row * 3 + column}')),
                name: 'Explicit row $row',
                category: AssetCategory.terrain),
        ]);
    for (final child in next.activeCandidates) {
      expect(child.toJson()['terrainLayout'], isNull);
      expect(child.state, CandidateState.needsReview);
    }
  });

  test('undo redo and session restore retain the exact hashed layout decision',
      () {
    final initial = _session([_candidate('terrain')]);
    final configured = _configure(initial);
    final approved = _approve(configured);
    final restored = AssetReviewSession.fromJson(approved.toJson());
    expect(restored.canonicalHash, approved.canonicalHash);
    expect(_current(restored).terrainLayout, AssetTerrainLayout.cardinal3x3);
    expect(restored.approvedCandidateHashes, approved.approvedCandidateHashes);
    final undone = restored.undo(expectedSessionHash: restored.canonicalHash);
    expect(_current(undone).terrainLayout, AssetTerrainLayout.cardinal3x3);
    expect(_current(undone).state, CandidateState.needsReview);
    final redone = undone.redo(expectedSessionHash: undone.canonicalHash);
    expect(redone.frame.canonicalHash, approved.frame.canonicalHash);
    expect(_current(redone).terrainLayout, AssetTerrainLayout.cardinal3x3);
  });
}
