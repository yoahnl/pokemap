import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'package:avelune_converter_adapters/src/local_asset_proposer.dart';
import 'support/literal_tile_fixture.dart';
import 'support/original_asset_fixture.dart';

Map<String, Object?> _copy(Map<String, Object?> value) =>
    (jsonDecode(jsonEncode(value)) as Map).cast<String, Object?>();

Future<(LiteralTileFixture, LiteralTileComposition)> _repeated() async {
  final fixture = await LiteralTileFixture.create(maps: [
    LiteralFixtureMap(id: 1, width: 3, layers: [
      [384, 0, 384],
      [0, 0, 0],
      [0, 0, 0],
    ]),
    LiteralFixtureMap(id: 2, width: 1, layers: [
      [384],
      [0],
      [0],
    ]),
    LiteralFixtureMap(id: 3, width: 2, layers: [
      [384, 385],
      [0, 0],
      [0, 0],
    ]),
  ]);
  final literal = await const LiteralTileComposer().compose(
    source: fixture.source,
    files: fixture.files,
    selectedSourceMapIds: const [1, 2, 3],
    projectName: 'Original exact placement claims',
    parentPath: '/private/tmp/exact-placement-claims',
    folderName: 'project',
  );
  return (fixture, literal);
}

void main() {
  test('zero proposals retain an attested atlas for manual review', () async {
    final raster = image.Image(width: 256, height: 32, numChannels: 4);
    final fixture = await LiteralTileFixture.create(tilesets: [
      LiteralFixtureTileset(id: 1, png: image.encodePng(raster))
    ], maps: [
      LiteralFixtureMap(id: 1, width: 1, layers: [
        [0],
        [0],
        [0],
      ]),
    ]);
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1],
        projectName: 'Original empty map manual selection',
        parentPath: '/private/tmp/zero-proposals-attested-sources',
        folderName: 'project');
    expect(literal.crops, isEmpty);
    expect(literal.draft, isNotNull);
    final result = await const LocalAssetProposer().propose(
        source: fixture.source, files: fixture.files, literal: literal);
    expect(result.candidates, isEmpty);
    expect(result.placementClaims, isEmpty);
    expect(result.sourceImages, hasLength(1));
    final source = result.sourceImages.single;
    final entry = fixture.snapshot.entries.singleWhere((entry) =>
        entry.relativePath == 'Graphics/Tilesets/OriginalAtlas1.png');
    expect(source.fileId, entry.fileId);
    expect(source.contentHash, entry.sha256);
    expect((source.pixelWidth, source.pixelHeight), (256, 32));
    expect(result.toJson()['sourceImages'], [source.toJson()]);
    expect(result.canonicalHash, canonicalHashOf(result.toJson()));
    expect(() => result.sourceImages.clear(), throwsUnsupportedError);
  });

  test('REV-05 proposal claims retain exact prototype cells and map hashes',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    final source = fixture.literalFixture.source;
    final before = source.canonicalHash;
    final nativeBefore = {
      for (final entry in literal.nativeMaps.entries)
        entry.key: canonicalHashOf(entry.value.toJson()),
    };
    final result = await const LocalAssetProposer().propose(
        source: source, files: fixture.literalFixture.files, literal: literal);
    final house = result.candidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 8));
    final claims = result.placementClaims[house.candidateId] ?? [];
    expect(claims, hasLength(5));
    expect(claims.map((c) => (c.sourceZ, c.x, c.y)).toSet(), {
      (2, 0, 0),
      (2, 1, 0),
      (0, 0, 1),
      (0, 0, 2),
      (0, 1, 2),
    });
    final map = source.maps.singleWhere((ir) => ir.map.sourceMapId == 8);
    for (final claim in claims) {
      expect(claim.sourceSnapshotHash, source.snapshot.canonicalHash);
      expect(claim.sourceMapHash, map.canonicalHash);
      expect(claim.sourceMapFileId, map.map.sourceFileId);
      claim.validateAgainst(map, house);
    }
    const LocalAssetProposer().validatePlacementClaims(
        source: source, literal: literal, candidate: house, claims: claims);
    expect(source.canonicalHash, before);
    expect({
      for (final entry in literal.nativeMaps.entries)
        entry.key: canonicalHashOf(entry.value.toJson()),
    }, nativeBefore);
  });

  test('REV-05 same-map exact repetitions retain X/Y without multi-map merge',
      () async {
    final (fixture, literal) = await _repeated();
    final result = await const LocalAssetProposer().propose(
        source: fixture.source, files: fixture.files, literal: literal);
    final prototype = result.candidates.singleWhere((candidate) =>
        candidate.parts.length == 1 &&
        candidate.parts.single.locator.mapId == 1);
    final claims = result.placementClaims[prototype.candidateId] ?? [];
    expect(claims, hasLength(2));
    expect(claims.map((c) => (c.sourceMapId, c.sourceZ, c.x, c.y)).toSet(),
        {(1, 0, 0, 0), (1, 0, 2, 0)});
    expect(
        claims.every((c) => c.partId == prototype.parts.single.partId), isTrue);
    expect(claims.map((c) => c.placementKey).toSet(), hasLength(2));
    expect(
        result.placementClaims.values
            .expand((c) => c)
            .any((c) => c.sourceMapId == 2),
        isFalse);
    for (final candidate in result.candidates) {
      const LocalAssetProposer().validatePlacementClaims(
          source: fixture.source,
          literal: literal,
          candidate: candidate,
          claims: result.placementClaims[candidate.candidateId] ?? []);
    }
  });

  test('manual proposal proves only the explicitly selected cells', () async {
    final (fixture, literal) = await _repeated();
    final result = const LocalAssetProposer().manualProposalFromCells(
        source: fixture.source,
        literal: literal,
        cells: const [LocalAssetCell(mapId: 1, sourceZ: 0, x: 2, y: 0)]);
    final candidate = result.candidates.single;
    final claims = result.placementClaims[candidate.candidateId] ?? [];
    expect(claims, hasLength(1));
    expect((claims.single.sourceMapId, claims.single.x, claims.single.y),
        (1, 2, 0));
    const LocalAssetProposer().validatePlacementClaims(
        source: fixture.source,
        literal: literal,
        candidate: candidate,
        claims: claims);
    expect(candidate.integrationMode, IntegrationMode.libraryOnly);
    expect(candidate.approvedRevision, isNull);
  });

  test('REV-05 real proposal selections expose concurrent placement conflicts',
      () async {
    final (fixture, literal) = await _repeated();
    final automatic = await const LocalAssetProposer().propose(
        source: fixture.source, files: fixture.files, literal: literal);
    final a = automatic.candidates.singleWhere((candidate) =>
        candidate.parts.length == 1 &&
        candidate.parts.single.locator.mapId == 1);
    final manual = const LocalAssetProposer().manualProposalFromCells(
        source: fixture.source,
        literal: literal,
        cells: const [
          LocalAssetCell(mapId: 1, sourceZ: 0, x: 0, y: 0),
          LocalAssetCell(mapId: 1, sourceZ: 0, x: 2, y: 0),
        ]);
    final b = manual.candidates.single;
    expect(a.candidateId, isNot(b.candidateId));
    final claims = {
      a.candidateId: automatic.placementClaims[a.candidateId] ?? [],
      b.candidateId: manual.placementClaims[b.candidateId] ?? [],
    };
    expect(claims[a.candidateId], hasLength(2));
    expect(claims[b.candidateId], hasLength(2));
    var session = AssetReviewSession.create(
        sessionId: ConverterId('original-overlapping-selections'),
        logicalProjectNamespace:
            fixture.source.snapshot.logicalProjectNamespace,
        sourceSnapshotHash: fixture.source.snapshot.canonicalHash,
        selectedSourceMapIds: [1],
        outputMode: AssetOutputMode.sharedAtlas,
        proposalGenerationHash: automatic.canonicalHash,
        candidates: [a, b],
        placementClaims: claims,
        sourceMaps: fixture.source.maps);
    expect(session.conflicts, isEmpty);
    for (final candidate in [a, b]) {
      session = session.setIntegrationMode(
          candidateId: candidate.candidateId,
          expectedCandidateHash: session.activeCandidates
              .singleWhere((c) => c.candidateId == candidate.candidateId)
              .canonicalHash,
          expectedSessionHash: session.canonicalHash,
          integrationMode: IntegrationMode.replacePlacements,
          placementClaims: claims[candidate.candidateId]!,
          sourceMaps: fixture.source.maps);
    }
    expect(session.conflicts, hasLength(2));
    expect(
        session.conflicts
            .map((c) => (c.claim.sourceMapId, c.claim.x, c.claim.y))
            .toSet(),
        {(1, 0, 0), (1, 2, 0)});
    expect(
        session.conflicts.every((c) =>
            c.candidateIds.toSet().containsAll([a.candidateId, b.candidateId])),
        isTrue);
    final replacing = session.activeCandidates.first;
    expect(
        () => session.decide(
            candidateId: replacing.candidateId,
            expectedCandidateHash: replacing.canonicalHash,
            expectedSessionHash: session.canonicalHash,
            action: ReviewAction.approve,
            humanConfirmed: true),
        throwsA(isA<ContractError>()
            .having((e) => e.code, 'code', 'review.replacement.uncertified')));
    for (final candidate in [a, b]) {
      var active = session.activeCandidates
          .singleWhere((c) => c.candidateId == candidate.candidateId);
      session = session.setIntegrationMode(
          candidateId: active.candidateId,
          expectedCandidateHash: active.canonicalHash,
          expectedSessionHash: session.canonicalHash,
          integrationMode: IntegrationMode.libraryOnly,
          placementClaims: claims[active.candidateId]!,
          sourceMaps: fixture.source.maps);
      active = session.activeCandidates
          .singleWhere((c) => c.candidateId == candidate.candidateId);
      session = session.editMetadata(
          candidateId: active.candidateId,
          expectedCandidateHash: active.canonicalHash,
          expectedSessionHash: session.canonicalHash,
          category: AssetCategory.nature);
      active = session.activeCandidates
          .singleWhere((c) => c.candidateId == candidate.candidateId);
      session = session.decide(
          candidateId: active.candidateId,
          expectedCandidateHash: active.canonicalHash,
          expectedSessionHash: session.canonicalHash,
          action: ReviewAction.approve,
          humanConfirmed: true);
    }
    expect(session.conflicts, isEmpty);
    expect(session.approvedCandidateHashes, hasLength(2));
  });

  test('placement sidecar is immutable and included in generation hash',
      () async {
    final (fixture, literal) = await _repeated();
    final result = const LocalAssetProposer().manualProposalFromCells(
        source: fixture.source,
        literal: literal,
        cells: const [LocalAssetCell(mapId: 1, sourceZ: 0, x: 0, y: 0)]);
    final candidate = result.candidates.single;
    final claims = result.placementClaims[candidate.candidateId] ?? [];
    expect(claims, hasLength(1));
    expect(() => result.placementClaims.clear(), throwsUnsupportedError);
    expect(() => claims.clear(), throwsUnsupportedError);
    final json = result.toJson();
    expect(json['placementClaims'], {
      candidate.candidateId.value: [claims.single.toJson()],
    });
    expect(result.canonicalHash, canonicalHashOf(json));
    final forged = _copy(json);
    final claim = ((forged['placementClaims']
            as Map)[candidate.candidateId.value] as List)
        .single as Map;
    claim['x'] = 2;
    expect(canonicalHashOf(forged), isNot(result.canonicalHash));
  });

  test('pixel-only alpha proposal has no invented placement claims', () async {
    final fixture =
        await OriginalAssetFixture.create(includeUnplacedAlphaIsland: true);
    final result = await const LocalAssetProposer().propose(
        source: fixture.literalFixture.source,
        files: fixture.literalFixture.files,
        literal: await fixture.compose());
    final alpha = result.candidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == null));
    expect(result.placementClaims[alpha.candidateId] ?? [], isEmpty);
    expect(result.placementClaims, isNotEmpty);
  });

  test('claim validator rejects valid cells with different crop provenance',
      () async {
    final (fixture, literal) = await _repeated();
    final source = fixture.source;
    final candidate = const LocalAssetProposer().manualFromCells(
        source: source,
        literal: literal,
        cells: const [LocalAssetCell(mapId: 1, sourceZ: 0, x: 0, y: 0)]);
    final map = source.maps.singleWhere((ir) => ir.map.sourceMapId == 1);
    final claim = SourcePlacementClaim(
        sourceSnapshotHash: source.snapshot.canonicalHash,
        sourceMapHash: map.canonicalHash,
        sourceMapFileId: map.map.sourceFileId,
        sourceMapId: 1,
        sourceZ: 0,
        x: 0,
        y: 0,
        tileId: 384,
        partId: candidate.parts.single.partId);
    final mutations = <String, void Function(Map<String, Object?>)>{
      'sourceFile': (json) {
        final extra = Map<String, Object?>.from(
            ((json['sources'] as List).single as Map).cast<String, Object?>());
        extra['fileId'] = 'foreign-image';
        (json['sources'] as List).add(extra);
        ((json['parts'] as List).single as Map)['sourceFileId'] =
            'foreign-image';
      },
      'rectangle': (json) =>
          (((json['parts'] as List).single as Map)['sourceRect'] as Map)['x'] =
              32,
      'rotation': (json) =>
          ((json['parts'] as List).single as Map)['quarterTurns'] = 1,
      'reflection': (json) =>
          ((json['parts'] as List).single as Map)['reflected'] = true,
      'priority': (json) =>
          ((json['parts'] as List).single as Map)['sourcePriority'] = 2,
      'imageHash': (json) =>
          ((json['sources'] as List).single as Map)['contentHash'] = 'd' * 64,
      'imageGeometry': (json) =>
          ((json['sources'] as List).single as Map)['pixelWidth'] = 512,
      'locatorFile': (json) =>
          (((json['parts'] as List).single as Map)['locator'] as Map)['file'] =
              'Data/Map999.rxdata',
    };
    for (final mutation in mutations.entries) {
      final json = _copy(candidate.toJson());
      mutation.value(json);
      final forged = AssetCandidate.fromJson(json);
      claim.validateAgainst(map, forged);
      expect(
          () => const LocalAssetProposer().validatePlacementClaims(
              source: source,
              literal: literal,
              candidate: forged,
              claims: [claim]),
          throwsA(isA<ContractError>()),
          reason: mutation.key);
    }
    const LocalAssetProposer().validatePlacementClaims(
        source: source,
        literal: literal,
        candidate: candidate,
        claims: [claim]);
  });

  test('claim validator rejects foreign IR and wrong exact cell', () async {
    final (fixture, literal) = await _repeated();
    final candidate = const LocalAssetProposer().manualFromCells(
        source: fixture.source,
        literal: literal,
        cells: const [LocalAssetCell(mapId: 1, sourceZ: 0, x: 0, y: 0)]);
    final map =
        fixture.source.maps.singleWhere((ir) => ir.map.sourceMapId == 1);
    for (final (hash, x, tileId) in [
      (map.canonicalHash, 1, 384),
      (Sha256Hash('d' * 64), 0, 384),
      (map.canonicalHash, 0, 385),
    ]) {
      final claim = SourcePlacementClaim(
          sourceSnapshotHash: fixture.source.snapshot.canonicalHash,
          sourceMapHash: hash,
          sourceMapFileId: map.map.sourceFileId,
          sourceMapId: 1,
          sourceZ: 0,
          x: x,
          y: 0,
          tileId: tileId,
          partId: candidate.parts.single.partId);
      expect(
          () => const LocalAssetProposer().validatePlacementClaims(
              source: fixture.source,
              literal: literal,
              candidate: candidate,
              claims: [claim]),
          throwsA(isA<ContractError>()));
    }
  });

  test('claim quotas reject the whole result instead of truncating occurrences',
      () async {
    final (fixture, literal) = await _repeated();
    for (final limits in [
      const LocalAssetProposalLimits(maxClaimsPerCandidate: 1),
      const LocalAssetProposalLimits(maxTotalClaims: 1),
    ]) {
      await expectLater(
          const LocalAssetProposer().propose(
              source: fixture.source,
              files: fixture.files,
              literal: literal,
              limits: limits),
          throwsA(isA<ContractError>()));
    }
  });

  test('invalid claim limits are rejected before reading source images',
      () async {
    final (fixture, literal) = await _repeated();
    fixture.files.reads.clear();
    for (final limits in [
      const LocalAssetProposalLimits(maxClaimsPerCandidate: 0),
      const LocalAssetProposalLimits(maxTotalClaims: 65537),
    ]) {
      await expectLater(
          const LocalAssetProposer().propose(
              source: fixture.source,
              files: fixture.files,
              literal: literal,
              limits: limits),
          throwsA(isA<ContractError>()));
      expect(fixture.files.reads, isEmpty);
    }
  });
}
