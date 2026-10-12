import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

final namespace = ConverterId('review-project');
final snapshotHash = Sha256Hash('a' * 64);
final proposalHash = Sha256Hash('b' * 64);

Map<String, Object?> part(String id, int sourceX, int destinationX) => {
      'partId': id,
      'sourceFileId': 'image-1',
      'sourceRect': {'x': sourceX, 'y': 0, 'width': 32, 'height': 32},
      'destinationOffset': {'x': destinationX, 'y': 0},
      'sourceLayer': 0,
      'sourcePriority': 0,
      'quarterTurns': 0,
      'reflected': false,
      'locator': {
        'file': 'Data/Map001.rxdata',
        'mapId': 1,
        'eventId': null,
        'pageIndex': null,
        'commandIndex': null,
        'tileId': 384 + sourceX ~/ 32,
        'line': null,
      },
    };

AssetCandidate candidate(String id, {bool doubleWidth = false}) =>
    AssetCandidate.fromJson({
      'schemaVersion': '1.0',
      'kind': 'assetCandidate',
      'exampleOnly': false,
      'candidateId': id,
      'revision': 1,
      'logicalProjectNamespace': namespace.value,
      'sourceSnapshotHash': snapshotHash.value,
      'sources': [
        {
          'fileId': 'image-1',
          'contentHash': 'c' * 64,
          'pixelWidth': 96,
          'pixelHeight': 32,
        }
      ],
      'name': id,
      'category': 'nature',
      'state': 'needsReview',
      'parts': [part('p0', 0, 0), if (doubleWidth) part('p1', 32, 32)],
      'canvasSize': {'width': doubleWidth ? 64 : 32, 'height': 32},
      'anchor': {
        'unit': 'pixel',
        'x': doubleWidth ? 32 : 16,
        'y': 32,
        'convention': 'bottomCenter',
      },
      'integrationMode': 'libraryOnly',
      'outputMode': 'standaloneObjects',
      'evidence': <Object?>[],
      'uncertainties': <String>[],
      'approvedRevision': null,
    });

SourceMapIr sourceMap({int mapId = 1, int z = 0}) => SourceMapIr.fromJson({
      'schemaVersion': '1.0',
      'kind': 'sourceMapIr',
      'exampleOnly': false,
      'logicalProjectNamespace': namespace.value,
      'sourceSnapshotHash': snapshotHash.value,
      'sourceProfileId': 'rmxp',
      'map': {
        'sourceMapId': mapId,
        'sourceFileId': 'map-$mapId',
        'name': 'Map $mapId',
        'width': 3,
        'height': 1,
        'tileWidth': 32,
        'tileHeight': 32,
        'sourceTilesetId': 1,
        'layers': [
          for (var layer = 0; layer < 3; layer++)
            {
              'sourceZ': layer,
              'cells': layer == z ? [384, 385, 384] : [0, 0, 0]
            },
        ],
        'events': <Object?>[],
        'unknownDataRefs': <String>[],
      },
    });

SourcePlacementClaim claim(SourceMapIr map,
        {int x = 0, String partId = 'p0'}) =>
    SourcePlacementClaim(
      sourceSnapshotHash: snapshotHash,
      sourceMapHash: map.canonicalHash,
      sourceMapFileId: map.map.sourceFileId,
      sourceMapId: map.map.sourceMapId,
      sourceZ: map.map.layers.firstWhere((l) => l.cells.first != 0).sourceZ,
      x: x,
      y: 0,
      tileId: x == 1 ? 385 : 384,
      partId: ConverterId(partId),
    );

AssetReviewSession session({List<AssetCandidate>? candidates}) =>
    AssetReviewSession.create(
      sessionId: ConverterId('review-1'),
      logicalProjectNamespace: namespace,
      sourceSnapshotHash: snapshotHash,
      selectedSourceMapIds: [1],
      outputMode: AssetOutputMode.standaloneObjects,
      proposalGenerationHash: proposalHash,
      candidates: candidates ?? [candidate('tree')],
    );

AssetCandidate current(AssetReviewSession value, String id) =>
    value.frame.candidates.singleWhere((item) => item.candidateId.value == id);

AssetReviewSession decide(AssetReviewSession value, String id,
        {ReviewAction action = ReviewAction.approve}) =>
    value.decide(
      candidateId: ConverterId(id),
      expectedCandidateHash: current(value, id).canonicalHash,
      expectedSessionHash: value.canonicalHash,
      action: action,
      humanConfirmed: true,
    );

void main() {
  test('REV-01 changed pixel provenance removes stale placement claims', () {
    final map = sourceMap();
    final json = jsonDecode(jsonEncode(candidate('tree').toJson())) as Map;
    (json['sources'] as List).add({
      'fileId': 'image-2',
      'contentHash': 'd' * 64,
      'pixelWidth': 96,
      'pixelHeight': 32,
    });
    final original = AssetCandidate.fromJson(json);
    final initial = AssetReviewSession.create(
        sessionId: ConverterId('pixel-provenance'),
        logicalProjectNamespace: namespace,
        sourceSnapshotHash: snapshotHash,
        selectedSourceMapIds: [1],
        outputMode: AssetOutputMode.standaloneObjects,
        proposalGenerationHash: proposalHash,
        candidates: [original],
        placementClaims: {
          original.candidateId: [claim(map)]
        },
        sourceMaps: [map]);
    final mutations = <String, void Function(Map<String, Object?>)>{
      'sourceFile': (p) => p['sourceFileId'] = 'image-2',
      'sourceRect': (p) => (p['sourceRect'] as Map)['x'] = 32,
      'sourceExtent': (p) => (p['sourceRect'] as Map)['width'] = 16,
      'rotation': (p) => p['quarterTurns'] = 1,
      'reflection': (p) => p['reflected'] = true,
      'layer': (p) => p['sourceLayer'] = 1,
      'priority': (p) => p['sourcePriority'] = 2,
      'locatorFile': (p) =>
          (p['locator'] as Map)['file'] = 'Data/Map999.rxdata',
      'locatorLine': (p) => (p['locator'] as Map)['line'] = 1,
      'locatorTile': (p) => (p['locator'] as Map)['tileId'] = 385,
    };
    for (final mutation in mutations.entries) {
      final p = (jsonDecode(jsonEncode(original.parts.single.toJson())) as Map)
          .cast<String, Object?>();
      mutation.value(p);
      final corrected = initial.changeGeometry(
          candidateId: original.candidateId,
          expectedCandidateHash: original.canonicalHash,
          expectedSessionHash: initial.canonicalHash,
          geometry: AssetReviewGeometry(
              parts: [p],
              canvasWidth: 32,
              canvasHeight: 32,
              anchorX: 16,
              anchorY: 32,
              anchorConvention: AnchorConvention.bottomCenter));
      expect(
          corrected.frame.placementClaims[original.candidateId] ?? [], isEmpty,
          reason: mutation.key);
      expect(
          corrected
              .undo(expectedSessionHash: corrected.canonicalHash)
              .frame
              .canonicalHash,
          initial.frame.canonicalHash);
    }
  });

  test('REV-01 layout-only correction preserves exact source claims', () {
    final map = sourceMap();
    final original = candidate('tree');
    final initial = AssetReviewSession.create(
        sessionId: ConverterId('layout-provenance'),
        logicalProjectNamespace: namespace,
        sourceSnapshotHash: snapshotHash,
        selectedSourceMapIds: [1],
        outputMode: AssetOutputMode.standaloneObjects,
        proposalGenerationHash: proposalHash,
        candidates: [original],
        placementClaims: {
          original.candidateId: [claim(map)]
        },
        sourceMaps: [map]);
    final p = (jsonDecode(jsonEncode(original.parts.single.toJson())) as Map)
        .cast<String, Object?>();
    (p['destinationOffset'] as Map)['x'] = 32;
    final corrected = initial.changeGeometry(
        candidateId: original.candidateId,
        expectedCandidateHash: original.canonicalHash,
        expectedSessionHash: initial.canonicalHash,
        geometry: AssetReviewGeometry(
            parts: [p],
            canvasWidth: 64,
            canvasHeight: 32,
            anchorX: 32,
            anchorY: 16,
            anchorConvention: AnchorConvention.explicit));
    expect(
        corrected.frame.placementClaims[original.candidateId]!
            .map((c) => c.toJson())
            .toList(),
        [claim(map).toJson()]);
    corrected.validatePlacements([map]);
    expect(
        corrected
            .undo(expectedSessionHash: corrected.canonicalHash)
            .frame
            .canonicalHash,
        initial.frame.canonicalHash);
  });

  test('REV-01 a geometry correction expires the exact approval', () {
    final approved = decide(session(), 'tree');
    final before = current(approved, 'tree');
    expect(approved.approvedCandidateHashes[before.candidateId],
        before.canonicalHash);
    final parts = before.parts
        .map((item) => (jsonDecode(jsonEncode(item.toJson())) as Map)
            .cast<String, Object?>())
        .toList();
    (parts.single['sourceRect'] as Map<String, Object?>)['x'] = 32;
    (parts.single['locator'] as Map<String, Object?>)['tileId'] = 385;
    final corrected = approved.changeGeometry(
      candidateId: before.candidateId,
      expectedCandidateHash: before.canonicalHash,
      expectedSessionHash: approved.canonicalHash,
      geometry: AssetReviewGeometry(
        parts: parts,
        canvasWidth: 32,
        canvasHeight: 32,
        anchorX: 16,
        anchorY: 32,
        anchorConvention: AnchorConvention.bottomCenter,
      ),
    );
    final after = current(corrected, 'tree');
    expect(after.state, CandidateState.needsReview);
    expect(after.revision, before.revision + 1);
    expect(after.approvedRevision, isNull);
    expect(corrected.approvedCandidateHashes, isEmpty);
    expect(corrected.activeDecisions.decisions.single.action,
        ReviewAction.changeGeometry);
    expect(current(decide(corrected, 'tree'), 'tree').state,
        CandidateState.approved);
    expect(before.parts.single.sourceRect.x, 0);
  });

  test('REV-02 keepLiteral remains reversible without removing the candidate',
      () {
    final initial = session();
    final refused = decide(initial, 'tree', action: ReviewAction.keepLiteral);
    expect(current(refused, 'tree').state, CandidateState.keepLiteral);
    expect(refused.activeCandidates.single.parts.map((p) => p.toJson()),
        initial.activeCandidates.single.parts.map((p) => p.toJson()));
    expect(refused.approvedCandidateHashes, isEmpty);
    final undone = refused.undo(expectedSessionHash: refused.canonicalHash);
    expect(undone.frame.canonicalHash, initial.frame.canonicalHash);
    expect(undone.revision, refused.revision + 1);
    expect(
        undone
            .redo(expectedSessionHash: undone.canonicalHash)
            .frame
            .canonicalHash,
        refused.frame.canonicalHash);
  });

  test('REV-03 union supersedes parents and split covers every explicit part',
      () {
    final initial =
        session(candidates: [candidate('tree'), candidate('house')]);
    final united = initial.unionCandidates(
      candidateId: ConverterId('union'),
      expectedSessionHash: initial.canonicalHash,
      inputs: [
        for (final (index, item) in initial.activeCandidates.indexed)
          AssetUnionInput(
            candidateId: item.candidateId,
            expectedCandidateHash: item.canonicalHash,
            offsetX: index * 64,
            offsetY: 0,
          ),
      ],
      name: 'Ensemble',
      category: AssetCategory.object,
    );
    expect(current(united, 'tree').state, CandidateState.superseded);
    expect(current(united, 'house').state, CandidateState.superseded);
    final union = current(united, 'union');
    expect(union.parts.map((p) => p.destinationOffset.x), [0, 64]);
    expect(union.canvasSize.width, 96);
    expect(union.parts.map((p) => p.partId).toSet(), hasLength(2));
    final split = united.splitCandidate(
      candidateId: union.candidateId,
      expectedCandidateHash: union.canonicalHash,
      expectedSessionHash: united.canonicalHash,
      groups: [
        for (final (index, p) in union.parts.indexed)
          AssetSplitGroup(
            candidateId: ConverterId('child-$index'),
            partIds: [p.partId],
            name: 'Child $index',
            category: AssetCategory.object,
          ),
      ],
    );
    expect(current(split, 'union').state, CandidateState.superseded);
    expect(split.activeCandidates.map((p) => p.candidateId.value),
        ['child-0', 'child-1']);
    for (final child in split.activeCandidates) {
      expect(child.parts.single.destinationOffset.x, 0);
      expect(child.canvasSize.width, 32);
      expect(child.state, CandidateState.needsReview);
    }
    expect(
        split
            .undo(expectedSessionHash: split.canonicalHash)
            .frame
            .canonicalHash,
        united.frame.canonicalHash);
    expect(
        split.activeDecisions.decisions.every((d) =>
            split.activeCandidates.any((c) => c.candidateId == d.candidateId)),
        isTrue);
  });

  test('REV-03 splitting cannot omit or duplicate source parts', () {
    final initial =
        session(candidates: [candidate('house', doubleWidth: true)]);
    final parent = current(initial, 'house');
    AssetSplitGroup group(String id, List<String> parts) => AssetSplitGroup(
          candidateId: ConverterId(id),
          partIds: parts.map(ConverterId.new).toList(),
          name: id,
          category: AssetCategory.building,
        );
    for (final groups in [
      [
        group('a', ['p0']),
        group('b', ['p0'])
      ],
      [
        group('a', ['p0']),
        group('b', ['missing'])
      ],
    ]) {
      expect(
          () => initial.splitCandidate(
                candidateId: parent.candidateId,
                expectedCandidateHash: parent.canonicalHash,
                expectedSessionHash: initial.canonicalHash,
                groups: groups,
              ),
          throwsFormatException);
    }
    expect(parent.parts, hasLength(2));
  });

  test('REV-03 metadata edits expire approvals and cut the redo branch', () {
    final approved = decide(session(), 'tree');
    final renamed = approved.editMetadata(
      candidateId: ConverterId('tree'),
      expectedCandidateHash: current(approved, 'tree').canonicalHash,
      expectedSessionHash: approved.canonicalHash,
      name: 'Arbre corrigé',
    );
    expect(current(renamed, 'tree').name, 'Arbre corrigé');
    expect(current(renamed, 'tree').state, CandidateState.needsReview);
    final undone = renamed.undo(expectedSessionHash: renamed.canonicalHash);
    expect(undone.frame.canonicalHash, approved.frame.canonicalHash);
    final edited = undone.editMetadata(
      candidateId: ConverterId('tree'),
      expectedCandidateHash: current(undone, 'tree').canonicalHash,
      expectedSessionHash: undone.canonicalHash,
      category: AssetCategory.object,
    );
    expect(edited.canRedo, isFalse);
    expect(() => edited.redo(expectedSessionHash: edited.canonicalHash),
        throwsFormatException);
  });

  test('REV-04 round-trip restores exact history hashes and approvals', () {
    final reviewed = decide(session(), 'tree');
    final restored = AssetReviewSession.fromJson(reviewed.toJson());
    expect(restored.canonicalHash, reviewed.canonicalHash);
    expect(restored.activeDecisions.canonicalHash,
        reviewed.activeDecisions.canonicalHash);
    expect(restored.approvedCandidateHashes, reviewed.approvedCandidateHashes);
    expect(restored.canUndo, isTrue);
    expect(
        restored
            .undo(expectedSessionHash: restored.canonicalHash)
            .frame
            .canonicalHash,
        session().frame.canonicalHash);
    final json = reviewed.toJson();
    expect(json.containsKey('apiKey'), isFalse);
    expect(() => AssetReviewSession.fromJson({...json, 'apiKey': 'secret'}),
        throwsFormatException);
  });

  test('REV-05 exact source cells conflict only for replacement intentions',
      () {
    final map = sourceMap();
    final initial = session(candidates: [candidate('a'), candidate('b')]);
    AssetReviewSession mode(
            AssetReviewSession value, String id, IntegrationMode mode, int x) =>
        value.setIntegrationMode(
          candidateId: ConverterId(id),
          expectedCandidateHash: current(value, id).canonicalHash,
          expectedSessionHash: value.canonicalHash,
          integrationMode: mode,
          placementClaims: [claim(map, x: x)],
          sourceMaps: [map],
        );
    final first = mode(initial, 'a', IntegrationMode.replacePlacements, 0);
    final conflicted = mode(first, 'b', IntegrationMode.replacePlacements, 0);
    expect(conflicted.conflicts, hasLength(1));
    expect(conflicted.conflicts.single.candidateIds.toSet(),
        {ConverterId('a'), ConverterId('b')});
    final distinct = mode(first, 'b', IntegrationMode.replacePlacements, 2);
    expect(distinct.conflicts, isEmpty);
    final libraries = mode(mode(initial, 'a', IntegrationMode.libraryOnly, 0),
        'b', IntegrationMode.libraryOnly, 0);
    expect(libraries.conflicts, isEmpty);
    expect(decide(decide(libraries, 'a'), 'b').approvedCandidateHashes,
        hasLength(2));
    expect(() => decide(first, 'a'), throwsFormatException);
  });

  test('REV-05 forged and stale placement claims are rejected by the source IR',
      () {
    final map = sourceMap();
    final tree = candidate('tree');
    claim(map).validateAgainst(map, tree);
    expect(() => claim(map, x: 1).validateAgainst(map, tree),
        throwsFormatException);
    final wrongCell = SourcePlacementClaim(
      sourceSnapshotHash: snapshotHash,
      sourceMapHash: map.canonicalHash,
      sourceMapFileId: map.map.sourceFileId,
      sourceMapId: 1,
      sourceZ: 0,
      x: 1,
      y: 0,
      tileId: 384,
      partId: ConverterId('p0'),
    );
    expect(() => wrongCell.validateAgainst(map, tree), throwsFormatException);
    expect(() => claim(map).validateAgainst(sourceMap(z: 1), tree),
        throwsFormatException);
  });

  test('manual candidates and output changes preserve corrections', () {
    final initial = session();
    final manual = initial.createManualCandidate(
      candidate: candidate('manual', doubleWidth: true),
      expectedSessionHash: initial.canonicalHash,
    );
    final approved = decide(manual, 'manual');
    final changed = approved.changeOutputMode(
      outputMode: AssetOutputMode.sharedAtlas,
      expectedSessionHash: approved.canonicalHash,
    );
    final object = current(changed, 'manual');
    expect(object.parts.map((p) => p.toJson()),
        current(approved, 'manual').parts.map((p) => p.toJson()));
    expect(object.outputMode, AssetOutputMode.sharedAtlas);
    expect(object.approvedRevision, isNull);
    expect(changed.approvedCandidateHashes, isEmpty);
    expect(
        changed
            .undo(expectedSessionHash: changed.canonicalHash)
            .frame
            .canonicalHash,
        approved.frame.canonicalHash);
  });

  test('stale session and candidate hashes cannot mutate the review', () {
    final initial = session();
    final approved = decide(initial, 'tree');
    expect(
        () => approved.editMetadata(
              candidateId: ConverterId('tree'),
              expectedCandidateHash: current(approved, 'tree').canonicalHash,
              expectedSessionHash: initial.canonicalHash,
              name: 'Late edit',
            ),
        throwsFormatException);
    expect(
        () => approved.editMetadata(
              candidateId: ConverterId('tree'),
              expectedCandidateHash: current(initial, 'tree').canonicalHash,
              expectedSessionHash: approved.canonicalHash,
              name: 'Late edit',
            ),
        throwsFormatException);
  });

  test('history serializes one copy per exact candidate version', () {
    final initial = session(candidates: [candidate('a'), candidate('b')]);
    final renamed = initial.editMetadata(
      candidateId: ConverterId('a'),
      expectedCandidateHash: current(initial, 'a').canonicalHash,
      expectedSessionHash: initial.canonicalHash,
      name: 'Renamed',
    );
    final json = renamed.toJson();
    expect(json['candidateVersions'], hasLength(3));
    expect(json['frames'], hasLength(2));
    expect(
        AssetReviewSession.fromJson(json).canonicalHash, renamed.canonicalHash);
  });

  test('history and geometry quotas reject before accepting another frame', () {
    final initial = AssetReviewSession.create(
      sessionId: ConverterId('bounded'),
      logicalProjectNamespace: namespace,
      sourceSnapshotHash: snapshotHash,
      selectedSourceMapIds: [1],
      outputMode: AssetOutputMode.standaloneObjects,
      proposalGenerationHash: proposalHash,
      candidates: [candidate('tree')],
      limits: const AssetReviewLimits(maxFrames: 1),
    );
    expect(
        () => initial.editMetadata(
              candidateId: ConverterId('tree'),
              expectedCandidateHash: current(initial, 'tree').canonicalHash,
              expectedSessionHash: initial.canonicalHash,
              name: 'Second frame',
            ),
        throwsFormatException);
    expect(
        () => AssetReviewSession.fromJson(session().toJson(),
            limits: const AssetReviewLimits(maxTotalParts: 0)),
        throwsFormatException);
  });

  test('session rejects foreign candidates and manual identities already used',
      () {
    final initial = session();
    expect(
        () => initial.createManualCandidate(
              candidate: candidate('tree'),
              expectedSessionHash: initial.canonicalHash,
            ),
        throwsFormatException);
    final foreign = AssetCandidate.fromJson({
      ...candidate('foreign').toJson(),
      'sourceSnapshotHash': 'd' * 64,
    });
    expect(
        () => initial.createManualCandidate(
              candidate: foreign,
              expectedSessionHash: initial.canonicalHash,
            ),
        throwsFormatException);
    expect(
        () => initial.decide(
              candidateId: ConverterId('tree'),
              expectedCandidateHash: current(initial, 'tree').canonicalHash,
              expectedSessionHash: initial.canonicalHash,
              action: ReviewAction.approve,
              humanConfirmed: false,
            ),
        throwsFormatException);
  });

  test('JSON reload rejects a substituted candidate version and false receipt',
      () {
    final approved = decide(session(), 'tree');
    final json =
        jsonDecode(jsonEncode(approved.toJson())) as Map<String, dynamic>;
    final versions = json['candidateVersions'] as Map<String, dynamic>;
    (versions.values.first as Map<String, dynamic>)['name'] = 'Injected';
    expect(() => AssetReviewSession.fromJson(json), throwsFormatException);
    final falseReceipt =
        jsonDecode(jsonEncode(approved.toJson())) as Map<String, dynamic>;
    final frames = falseReceipt['frames'] as List;
    (frames.last as Map<String, dynamic>)['approvedCandidateHashes'] = {
      'tree': 'f' * 64
    };
    expect(
        () => AssetReviewSession.fromJson(falseReceipt), throwsFormatException);
  });

  test('reload cannot authorize unverified placement replacement', () {
    final approved = decide(session(), 'tree');
    final json = (jsonDecode(jsonEncode(approved.toJson())) as Map)
        .cast<String, Object?>();
    final old = current(approved, 'tree');
    final injected = AssetCandidate.fromJson({
      ...old.toJson(),
      'integrationMode': 'replacePlacements',
    });
    final versions = json['candidateVersions'] as Map;
    versions.remove(old.canonicalHash.value);
    versions[injected.canonicalHash.value] = injected.toJson();
    final last = (json['frames'] as List).last as Map;
    last['candidateHashes'] = [injected.canonicalHash.value];
    last['approvedCandidateHashes'] = {'tree': injected.canonicalHash.value};
    expect(() => AssetReviewSession.fromJson(json), throwsFormatException);
  });

  test(
      'reload rejects approval decisions inconsistent with the candidate state',
      () {
    final initial = session();
    final json = jsonDecode(jsonEncode(initial.toJson())) as Map;
    final first = (json['frames'] as List).first as Map;
    first['decisions'] = [
      {
        'decisionId': 'forged-approval',
        'candidateId': 'tree',
        'candidateRevision': 1,
        'action': 'approve',
        'humanConfirmed': true,
        'replacementCandidateIds': <String>[],
        'note': 'Forged review',
      }
    ];
    expect(() => AssetReviewSession.fromJson(json), throwsFormatException);
  });

  test(
      'union cannot silently stack two parent canvases at the same destination',
      () {
    final initial = session(candidates: [candidate('a'), candidate('b')]);
    expect(
        () => initial.unionCandidates(
              candidateId: ConverterId('stacked'),
              expectedSessionHash: initial.canonicalHash,
              inputs: [
                for (final c in initial.activeCandidates)
                  AssetUnionInput(
                      candidateId: c.candidateId,
                      expectedCandidateHash: c.canonicalHash,
                      offsetX: 0,
                      offsetY: 0)
              ],
              name: 'Stacked',
              category: AssetCategory.object,
            ),
        throwsFormatException);
  });

  test(
      'REV-03 union preserves separate part links to the same source placement through split and restore',
      () {
    final map = sourceMap();
    final initial = AssetReviewSession.create(
      sessionId: ConverterId('shared-placement-review'),
      logicalProjectNamespace: namespace,
      sourceSnapshotHash: snapshotHash,
      selectedSourceMapIds: [1],
      outputMode: AssetOutputMode.standaloneObjects,
      proposalGenerationHash: proposalHash,
      candidates: [candidate('a'), candidate('b')],
      placementClaims: {
        ConverterId('a'): [claim(map)],
        ConverterId('b'): [claim(map)],
      },
      sourceMaps: [map],
    );
    final approved = decide(decide(initial, 'a'), 'b');
    expect(approved.approvedCandidateHashes, hasLength(2));
    expect(approved.conflicts, isEmpty);
    AssetReviewSession unite() => approved.unionCandidates(
          candidateId: ConverterId('shared-combined'),
          expectedSessionHash: approved.canonicalHash,
          inputs: [
            for (final (index, c) in approved.activeCandidates.indexed)
              AssetUnionInput(
                candidateId: c.candidateId,
                expectedCandidateHash: c.canonicalHash,
                offsetX: index * 64,
                offsetY: 0,
              )
          ],
          name: 'Shared source composition',
          category: AssetCategory.object,
        );
    expect(unite, returnsNormally);
    final united = unite();
    final parent = current(united, 'shared-combined');
    final links = united.frame.placementClaims[parent.candidateId]!;
    expect(links, hasLength(2));
    expect(links.map((c) => c.placementKey).toSet(), {claim(map).placementKey});
    expect(links.map((c) => c.partId).toSet(),
        parent.parts.map((p) => p.partId).toSet());
    expect(parent.parts.map((p) => p.destinationOffset.x), [0, 64]);
    expect(united.conflicts, isEmpty);
    united.validatePlacements([map]);
    final split = united.splitCandidate(
      candidateId: parent.candidateId,
      expectedCandidateHash: parent.canonicalHash,
      expectedSessionHash: united.canonicalHash,
      groups: [
        for (final (index, p) in parent.parts.indexed)
          AssetSplitGroup(
            candidateId: ConverterId('shared-result-$index'),
            partIds: [p.partId],
            name: 'Shared result $index',
            category: AssetCategory.object,
          )
      ],
    );
    final restored = AssetReviewSession.fromJson(split.toJson());
    expect(restored.canonicalHash, split.canonicalHash);
    restored.validatePlacements([map]);
    expect(restored.activeCandidates, hasLength(2));
    for (final child in restored.activeCandidates) {
      final childLinks = restored.frame.placementClaims[child.candidateId]!;
      expect(childLinks, hasLength(1));
      expect(childLinks.single.partId, child.parts.single.partId);
      expect(childLinks.single.placementKey, claim(map).placementKey);
    }
    final restoredUnion =
        restored.undo(expectedSessionHash: restored.canonicalHash);
    expect(restoredUnion.frame.canonicalHash, united.frame.canonicalHash);
    expect(
        restoredUnion.frame.placementClaims[parent.candidateId], hasLength(2));
    expect(
        () => AssetReviewSession.create(
              sessionId: ConverterId('duplicated-part-link'),
              logicalProjectNamespace: namespace,
              sourceSnapshotHash: snapshotHash,
              selectedSourceMapIds: [1],
              outputMode: AssetOutputMode.standaloneObjects,
              proposalGenerationHash: proposalHash,
              candidates: [candidate('a')],
              placementClaims: {
                ConverterId('a'): [claim(map), claim(map)]
              },
              sourceMaps: [map],
            ),
        throwsFormatException);
  });

  test('union and split preserve exact claims while remapping part identities',
      () {
    final map = sourceMap();
    final initial = AssetReviewSession.create(
      sessionId: ConverterId('claimed-review'),
      logicalProjectNamespace: namespace,
      sourceSnapshotHash: snapshotHash,
      selectedSourceMapIds: [1],
      outputMode: AssetOutputMode.standaloneObjects,
      proposalGenerationHash: proposalHash,
      candidates: [candidate('a'), candidate('b')],
      placementClaims: {
        ConverterId('a'): [claim(map)],
        ConverterId('b'): [claim(map, x: 2)],
      },
      sourceMaps: [map],
    );
    final united = initial.unionCandidates(
      candidateId: ConverterId('combined'),
      expectedSessionHash: initial.canonicalHash,
      inputs: [
        for (final (index, c) in initial.activeCandidates.indexed)
          AssetUnionInput(
              candidateId: c.candidateId,
              expectedCandidateHash: c.canonicalHash,
              offsetX: index * 64,
              offsetY: 0)
      ],
      name: 'Combined',
      category: AssetCategory.object,
    );
    final parent = current(united, 'combined');
    final remapped = united.frame.placementClaims[parent.candidateId]!;
    expect(remapped.map((c) => c.partId).toSet(),
        parent.parts.map((p) => p.partId).toSet());
    expect(remapped.map((c) => c.x), [0, 2]);
    united.validatePlacements([map]);
    final split = united.splitCandidate(
      candidateId: parent.candidateId,
      expectedCandidateHash: parent.canonicalHash,
      expectedSessionHash: united.canonicalHash,
      groups: [
        for (final (index, part) in parent.parts.indexed)
          AssetSplitGroup(
              candidateId: ConverterId('result-$index'),
              partIds: [part.partId],
              name: 'Result $index',
              category: AssetCategory.object)
      ],
    );
    final restored = AssetReviewSession.fromJson(split.toJson());
    restored.validatePlacements([map]);
    expect(restored.canonicalHash, split.canonicalHash);
    expect(
        restored.activeCandidates.map(
            (c) => restored.frame.placementClaims[c.candidateId]!.single.x),
        [0, 2]);
  });

  test('same tile at another source map or Z does not create a false conflict',
      () {
    final firstMap = sourceMap();
    final otherMap = sourceMap(mapId: 2, z: 1);
    final otherPart = part('p0', 0, 0)..['sourceLayer'] = 1;
    otherPart['locator'] = {...otherPart['locator'] as Map, 'mapId': 2};
    final other = AssetCandidate.fromJson({
      ...candidate('b').toJson(),
      'parts': [otherPart]
    });
    final initial = session(candidates: [candidate('a'), other]);
    AssetReviewSession replace(
            AssetReviewSession value, String id, SourceMapIr map) =>
        value.setIntegrationMode(
            candidateId: ConverterId(id),
            expectedCandidateHash: current(value, id).canonicalHash,
            expectedSessionHash: value.canonicalHash,
            integrationMode: IntegrationMode.replacePlacements,
            placementClaims: [claim(map)],
            sourceMaps: [firstMap, otherMap]);
    final replaced = replace(replace(initial, 'a', firstMap), 'b', otherMap);
    expect(replaced.conflicts, isEmpty);
    final restored = AssetReviewSession.fromJson(replaced.toJson());
    restored.validatePlacements([firstMap, otherMap]);
    expect(restored.conflicts, isEmpty);
    expect(
        () => SourcePlacementClaim.fromJson(
            {...claim(firstMap).toJson(), 'apiKey': 'secret'}),
        throwsFormatException);
  });

  test('review input and exposed collections stay immutable', () {
    final input = [candidate('a')];
    final selected = [1];
    final initial = AssetReviewSession.create(
        sessionId: ConverterId('immutable-review'),
        logicalProjectNamespace: namespace,
        sourceSnapshotHash: snapshotHash,
        selectedSourceMapIds: selected,
        outputMode: AssetOutputMode.standaloneObjects,
        proposalGenerationHash: proposalHash,
        candidates: input);
    final hash = initial.canonicalHash;
    input.clear();
    selected.clear();
    expect(initial.canonicalHash, hash);
    expect(() => initial.frames.clear(), throwsUnsupportedError);
    expect(() => initial.frame.candidates.clear(), throwsUnsupportedError);
    expect(() => initial.baseProposalHashes.clear(), throwsUnsupportedError);
    expect(() => initial.frame.placementClaims.clear(), throwsUnsupportedError);
    expect(() => initial.toJson().clear(), throwsUnsupportedError);
    final parts = [part('p0', 0, 0)];
    final geometry = AssetReviewGeometry(
        parts: parts,
        canvasWidth: 32,
        canvasHeight: 32,
        anchorX: 16,
        anchorY: 32,
        anchorConvention: AnchorConvention.bottomCenter);
    (parts.single['sourceRect'] as Map)['x'] = 32;
    expect((geometry.parts.single['sourceRect'] as Map)['x'], 0);
  });
}
