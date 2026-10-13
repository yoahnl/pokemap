import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'package:avelune_converter_adapters/src/local_asset_proposer.dart';
import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'support/original_asset_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<LiteralTileFixture> _usedTileFixture(
    {bool reverseManifest = false, int mapWidth = 81, int mapHeight = 41}) {
  final raster = image.Image(width: 256, height: 1792, numChannels: 4);
  for (var y = 0; y < raster.height; y++) {
    for (var x = 0; x < raster.width; x++) {
      raster.setPixelRgba(x, y, x % 251, y % 241, (x + y) % 239, 255);
    }
  }
  return LiteralTileFixture.create(
      namespace: 'used-static-tile-fixture',
      reverseManifest: reverseManifest,
      tilesets: [
        LiteralFixtureTileset(
            id: 1,
            metadataTileCount: 832,
            png: image.encodePng(raster),
            priorities: {804: 2}),
      ],
      maps: [
        LiteralFixtureMap(id: 1, width: mapWidth, height: mapHeight, layers: [
          List.filled(mapWidth * mapHeight, 384),
          List.filled(mapWidth * mapHeight, 0),
          List.filled(mapWidth * mapHeight, 804),
        ]),
        LiteralFixtureMap(id: 8, width: 1, height: 1, layers: [
          [804],
          [0],
          [804],
        ]),
      ]);
}

Future<LiteralTileComposition> _usedTileLiteral(
    LiteralTileFixture fixture) async {
  final literal = await const LiteralTileComposer().compose(
      source: fixture.source,
      files: fixture.files,
      selectedSourceMapIds: const [1, 8],
      projectName: 'Original used tile study',
      parentPath: '/private/tmp/used-static-tiles-output',
      folderName: 'original-used-static-tiles');
  expect(literal.canWrite, isTrue,
      reason: literal.diagnostics.map((d) => d.toJson()).toString());
  return literal;
}

Future<LiteralTileFixture> _manyTileFixture(
    {int firstCount = 140, int secondCount = 140}) {
  final raster = image.Image(width: 256, height: 1792, numChannels: 4);
  for (var y = 0; y < raster.height; y++) {
    for (var x = 0; x < raster.width; x++) {
      raster.setPixelRgba(x, y, x % 251, y % 241, (x + y) % 239, 255);
    }
  }
  return LiteralTileFixture.create(
      namespace: 'original-many-map-tiles',
      tilesets: [
        LiteralFixtureTileset(
            id: 1, metadataTileCount: 832, png: image.encodePng(raster))
      ],
      maps: [
        for (final record in [(1, firstCount), (8, secondCount)])
          LiteralFixtureMap(
              id: record.$1,
              width: record.$2,
              height: 1,
              layers: [
                List.generate(record.$2, (index) => 384 + index),
                List.filled(record.$2, 0),
                List.filled(record.$2, 0),
              ])
      ]);
}

Future<LocalAssetProposalSet> _usedTiles(
        LiteralTileFixture fixture, LiteralTileComposition literal,
        {LocalAssetProposalLimits limits = const LocalAssetProposalLimits(),
        ScanCancellation? cancellation}) =>
    const LocalAssetProposer().propose(
        source: fixture.source,
        files: fixture.files,
        literal: literal,
        strategy: LocalAssetProposalStrategy.usedStaticTiles,
        limits: limits,
        cancellation: cancellation);

List<LocalAssetCell> _houseCells() => const [
      LocalAssetCell(mapId: 8, sourceZ: 2, x: 0, y: 0),
      LocalAssetCell(mapId: 8, sourceZ: 2, x: 1, y: 0),
      LocalAssetCell(mapId: 8, sourceZ: 0, x: 0, y: 1),
      LocalAssetCell(mapId: 8, sourceZ: 0, x: 0, y: 2),
      LocalAssetCell(mapId: 8, sourceZ: 0, x: 1, y: 2),
    ];

Future<LocalAssetProposalSet> _propose(
        OriginalAssetFixture fixture, LiteralTileComposition literal,
        {LocalAssetProposalLimits limits = const LocalAssetProposalLimits(),
        ScanCancellation? cancellation}) =>
    const LocalAssetProposer().propose(
        source: fixture.literalFixture.source,
        files: fixture.literalFixture.files,
        literal: literal,
        limits: limits,
        cancellation: cancellation);

Matcher _failure(String code) =>
    isA<ContractError>().having((e) => e.code, 'code', code);

Future<LiteralTileFixture> _mapFileLookupFixture() =>
    LiteralTileFixture.create(namespace: 'original-map-file-lookup', maps: [
      LiteralFixtureMap(id: 1, width: 2, height: 1, layers: const [
        [384, 384],
        [391, 0],
        [0, 0],
      ]),
      LiteralFixtureMap(id: 8, width: 2, height: 1, layers: const [
        [392, 392],
        [0, 0],
        [391, 0],
      ]),
    ]);

void main() {
  test(
      'map segments preserve all proposal identities geometry and exact claims',
      () async {
    final fixture = await _usedTileFixture(mapWidth: 5, mapHeight: 2);
    final literal = await _usedTileLiteral(fixture);
    final whole = await _usedTiles(fixture, literal,
        limits: const LocalAssetProposalLimits(maxCandidates: 512));
    fixture.files.reads.clear();
    final segmented = await const LocalAssetProposer().proposeByMap(
        source: fixture.source,
        files: fixture.files,
        literal: literal,
        limits: const LocalAssetProposalLimits(maxCandidates: 512));
    expect(segmented.keys, [1, 8]);
    final combined = [
      for (final segment in segmented.values) ...segment.candidates,
    ]..sort((a, b) => a.candidateId.value.compareTo(b.candidateId.value));
    expect(combined.map((c) => c.toJson()).toList(),
        whole.candidates.map((c) => c.toJson()).toList());
    expect({
      for (final segment in segmented.values)
        for (final entry in segment.placementClaims.entries)
          entry.key: entry.value.map((claim) => claim.toJson()).toList()
    }, {
      for (final entry in whole.placementClaims.entries)
        entry.key: entry.value.map((claim) => claim.toJson()).toList()
    });
    for (final entry in segmented.entries) {
      expect(entry.value.normalizedSourceHash, fixture.source.canonicalHash);
      expect(entry.value.sourceSnapshotHash, fixture.snapshot.canonicalHash);
      expect(entry.value.literalCompositionHash, whole.literalCompositionHash);
      expect(entry.value.sourceImages.map((s) => s.toJson()).toList(),
          whole.sourceImages.map((s) => s.toJson()).toList());
      expect(
          entry.value.candidates
              .expand((c) => c.parts)
              .map((p) => p.locator.mapId),
          everyElement(entry.key));
      expect(
          entry.value.placementClaims.values
              .expand((claims) => claims)
              .map((claim) => claim.sourceMapId),
          everyElement(entry.key));
    }
    expect(fixture.files.reads, hasLength(1));
    expect(() => segmented.clear(), throwsUnsupportedError);
  });

  test('map segments order is canonical despite inventory permutation',
      () async {
    final first = await _usedTileFixture(mapWidth: 3, mapHeight: 1);
    final second = await _usedTileFixture(
        reverseManifest: true, mapWidth: 3, mapHeight: 1);
    Future<Map<int, LocalAssetProposalSet>> read(
        LiteralTileFixture fixture) async {
      final literal = await _usedTileLiteral(fixture);
      return const LocalAssetProposer().proposeByMap(
          source: fixture.source, files: fixture.files, literal: literal);
    }

    final a = await read(first);
    final b = await read(second);
    expect({for (final e in a.entries) e.key: e.value.toJson()},
        {for (final e in b.entries) e.key: e.value.toJson()});
  });

  test('map segments retain cumulative claims and usage quotas', () async {
    final fixture = await _mapFileLookupFixture();
    final literal = await _usedTileLiteral(fixture);
    for (final limits in [
      const LocalAssetProposalLimits(maxCandidates: 512, maxTotalClaims: 5),
      const LocalAssetProposalLimits(
          maxCandidates: 512, maxUsageComparisons: 11),
      const LocalAssetProposalLimits(maxCandidates: 3),
    ]) {
      await expectLater(
          const LocalAssetProposer().proposeByMap(
              source: fixture.source,
              files: fixture.files,
              literal: literal,
              limits: limits),
          throwsA(_failure('asset.proposal.quota')));
    }
  });

  test('map segments reject invalid per-map limits before source reads',
      () async {
    final fixture = await _mapFileLookupFixture();
    final literal = await _usedTileLiteral(fixture);
    for (final invalid in [0, -1, 257]) {
      fixture.files.reads.clear();
      await expectLater(
          const LocalAssetProposer().proposeByMap(
              source: fixture.source,
              files: fixture.files,
              literal: literal,
              maxCandidatesPerMap: invalid),
          throwsA(_failure('asset.proposal.limits')));
      expect(fixture.files.reads, isEmpty);
    }
  });

  test('map segments refuse any per-map excess without retaining a subset',
      () async {
    final fixture = await _mapFileLookupFixture();
    final literal = await _usedTileLiteral(fixture);
    await expectLater(
        const LocalAssetProposer().proposeByMap(
            source: fixture.source,
            files: fixture.files,
            literal: literal,
            limits: const LocalAssetProposalLimits(maxCandidates: 512),
            maxCandidatesPerMap: 1),
        throwsA(_failure('asset.proposal.quota')));
  });

  test('map segments preserve cancellation and source byte drift refusal',
      () async {
    final fixture = await _mapFileLookupFixture();
    final literal = await _usedTileLiteral(fixture);
    fixture.files.reads.clear();
    await expectLater(
        const LocalAssetProposer().proposeByMap(
            source: fixture.source,
            files: fixture.files,
            literal: literal,
            cancellation: ScanCancellation()..cancel()),
        throwsA(_failure('source.cancelled')));
    expect(fixture.files.reads, isEmpty);
    final file = fixture.snapshot.entries
        .singleWhere((e) => e.relativePath.startsWith('Graphics/Tilesets/'));
    fixture.files.overrides[file.relativePath] = [0, 1, 2];
    await expectLater(
        const LocalAssetProposer().proposeByMap(
            source: fixture.source, files: fixture.files, literal: literal),
        throwsA(_failure('asset.proposal.source_changed')));
  });

  test(
      'map segments admit 280 exact seeds only under explicit cumulative budget',
      () async {
    final fixture = await _manyTileFixture();
    final literal = await _usedTileLiteral(fixture);
    final whole = await _usedTiles(fixture, literal,
        limits: const LocalAssetProposalLimits(maxCandidates: 512));
    expect(whole.candidates, hasLength(280));
    await expectLater(
        const LocalAssetProposer().proposeByMap(
            source: fixture.source, files: fixture.files, literal: literal),
        throwsA(_failure('asset.proposal.quota')));
    final byMap = await const LocalAssetProposer().proposeByMap(
        source: fixture.source,
        files: fixture.files,
        literal: literal,
        limits: const LocalAssetProposalLimits(maxCandidates: 512));
    expect(byMap[1]!.candidates, hasLength(140));
    expect(byMap[8]!.candidates, hasLength(140));
    final flattened = byMap.values.expand((set) => set.candidates).toList()
      ..sort((a, b) => a.candidateId.value.compareTo(b.candidateId.value));
    expect(flattened.map((c) => c.toJson()).toList(),
        whole.candidates.map((c) => c.toJson()).toList());
    expect(
        byMap.values
            .expand((set) => set.placementClaims.values)
            .expand((claims) => claims),
        hasLength(280));
  });

  test('map segments preserve aggregate API but reject one map with 257 seeds',
      () async {
    final fixture = await _manyTileFixture(firstCount: 257, secondCount: 2);
    final literal = await _usedTileLiteral(fixture);
    expect(
        (await _usedTiles(fixture, literal,
                limits: const LocalAssetProposalLimits(maxCandidates: 512)))
            .candidates,
        hasLength(259));
    await expectLater(
        const LocalAssetProposer().proposeByMap(
            source: fixture.source,
            files: fixture.files,
            literal: literal,
            limits: const LocalAssetProposalLimits(maxCandidates: 512)),
        throwsA(_failure('asset.proposal.quota')));
  });

  test('map segments enforce global JSON admission before partition', () async {
    final fixture = await _mapFileLookupFixture();
    final literal = await _usedTileLiteral(fixture);
    const limits = LocalAssetProposalLimits(
        jsonLimits: ContractLimits(maxNodes: 200));
    await expectLater(_usedTiles(fixture, literal, limits: limits),
        throwsA(_failure('json.quota')));
    await expectLater(
        const LocalAssetProposer().proposeByMap(
            source: fixture.source,
            files: fixture.files,
            literal: literal,
            limits: limits),
        throwsA(_failure('json.quota')));
  });

  test('map file lookup preserves every locator and claim across two maps',
      () async {
    final fixture = await _mapFileLookupFixture();
    final literal = await _usedTileLiteral(fixture);
    final beforeMaps = {
      for (final entry in literal.nativeMaps.entries)
        entry.key: canonicalHashOf(entry.value.toJson()),
    };
    final result = await _usedTiles(fixture, literal);
    expect(result.candidates, hasLength(4));
    expect(
        result.placementClaims.values.expand((claims) => claims), hasLength(6));
    for (final candidate in result.candidates) {
      final part = candidate.parts.single;
      final map = fixture.source.maps
          .singleWhere((map) => map.map.sourceMapId == part.locator.mapId);
      final sourceFile = fixture.snapshot.entries
          .singleWhere((entry) => entry.fileId == map.map.sourceFileId);
      expect(part.locator.file, sourceFile.relativePath);
      expect(part.sourcePriority, 0);
      for (final claim in result.placementClaims[candidate.candidateId]!) {
        expect(claim.sourceMapFileId, sourceFile.fileId);
        expect(claim.sourceSnapshotHash, fixture.snapshot.canonicalHash);
        expect(claim.sourceMapHash, map.canonicalHash);
        expect(claim.sourceMapId, part.locator.mapId);
        expect(claim.sourceZ, part.sourceLayer);
        expect(claim.tileId, part.locator.tileId);
        expect(claim.partId, part.partId);
        expect(
            map.map.layers
                .singleWhere((layer) => layer.sourceZ == claim.sourceZ)
                .cells[claim.y * map.map.width + claim.x],
            claim.tileId);
      }
      const LocalAssetProposer().validatePlacementClaims(
          source: fixture.source,
          literal: literal,
          candidate: candidate,
          claims: result.placementClaims[candidate.candidateId]!);
    }
    expect({
      for (final entry in literal.nativeMaps.entries)
        entry.key: canonicalHashOf(entry.value.toJson()),
    }, beforeMaps);
    expect((await _usedTiles(fixture, literal)).toJson(), result.toJson());
    expect((await _usedTiles(fixture, literal)).canonicalHash,
        result.canonicalHash);
  });

  test('map file lookup refuses claims with another map file or hash',
      () async {
    final fixture = await _mapFileLookupFixture();
    final literal = await _usedTileLiteral(fixture);
    final result = await _usedTiles(fixture, literal);
    final candidate = result.candidates
        .firstWhere((candidate) => candidate.parts.single.locator.mapId == 1);
    final claim = result.placementClaims[candidate.candidateId]!.first;
    final other =
        fixture.source.maps.singleWhere((map) => map.map.sourceMapId == 8);
    for (final fields in [
      {'sourceMapFileId': other.map.sourceFileId.value},
      {'sourceMapHash': other.canonicalHash.value},
    ]) {
      final changed = SourcePlacementClaim.fromJson({
        ...claim.toJson(),
        ...fields,
      });
      expect(
          () => const LocalAssetProposer().validatePlacementClaims(
              source: fixture.source,
              literal: literal,
              candidate: candidate,
              claims: [changed]),
          throwsA(_failure('review.claim.source')));
    }
    for (final fields in [
      {'sourceMapId': 8},
      {'sourceZ': 2},
    ]) {
      final changed = SourcePlacementClaim.fromJson({
        ...claim.toJson(),
        ...fields,
      });
      expect(
          () => const LocalAssetProposer().validatePlacementClaims(
              source: fixture.source,
              literal: literal,
              candidate: candidate,
              claims: [changed]),
          throwsA(_failure('review.claim.locator')));
    }
    final raw =
        jsonDecode(jsonEncode(candidate.toJson())) as Map<String, dynamic>;
    final locator =
        (raw['parts'] as List).single['locator'] as Map<String, dynamic>;
    locator['file'] = 'Data/Map008.rxdata';
    final wrongFile = AssetCandidate.fromJson(raw);
    expect(
        () => const LocalAssetProposer().validatePlacementClaims(
            source: fixture.source,
            literal: literal,
            candidate: wrongFile,
            claims: [claim]),
        throwsA(_failure('asset.proposal.claim_crop')));
  });

  test('map file lookup refuses missing inventory maps before image reads',
      () async {
    final fixture = await _mapFileLookupFixture();
    final literal = await _usedTileLiteral(fixture);
    final snapshot = fixture.snapshot;
    final missing = SourceSnapshot(
        logicalProjectNamespace: snapshot.logicalProjectNamespace,
        policyHash: snapshot.policyHash,
        entries: snapshot.entries
            .where((entry) => entry.relativePath != 'Data/Map001.rxdata')
            .toList(),
        diagnostics: snapshot.diagnostics,
        excludedPaths: snapshot.excludedPaths,
        profileEvidence: snapshot.profileEvidence,
        state: snapshot.state);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: missing, files: fixture.files, selectedMapIds: {1, 8});
    expect(source.canPlan, isFalse);
    fixture.files.reads.clear();
    await expectLater(
        const LocalAssetProposer().propose(
            source: source,
            files: fixture.files,
            literal: literal,
            strategy: LocalAssetProposalStrategy.usedStaticTiles),
        throwsA(_failure('asset.proposal.binding')));
    expect(fixture.files.reads, isEmpty);
  });

  test('map file lookup refuses duplicated inventory file identities',
      () async {
    final fixture = await _mapFileLookupFixture();
    final snapshot = fixture.snapshot;
    final original = snapshot.entries
        .singleWhere((entry) => entry.relativePath == 'Data/Map001.rxdata');
    final duplicate = SourceFileEntry(
        fileId: original.fileId,
        relativePath: 'Data/Map999.rxdata',
        kind: original.kind,
        byteLength: original.byteLength,
        sha256: original.sha256,
        format: original.format,
        family: original.family);
    expect(
        () => SourceSnapshot(
            logicalProjectNamespace: snapshot.logicalProjectNamespace,
            policyHash: snapshot.policyHash,
            entries: [...snapshot.entries, duplicate],
            diagnostics: snapshot.diagnostics,
            excludedPaths: snapshot.excludedPaths,
            profileEvidence: snapshot.profileEvidence,
            state: snapshot.state),
        throwsA(_failure('source.snapshot_duplicate')));
  });

  test('used static tile fixture metadata bounds are explicit', () {
    for (final count in [0, -1, 65537]) {
      expect(() => LiteralFixtureTileset(id: 1, metadataTileCount: count),
          throwsRangeError);
    }
    expect(LiteralFixtureTileset(id: 1).metadataTileCount, 512);
  });

  test('used static tile seeds preserve 3321 repeats and every exact claim',
      () async {
    final fixture = await _usedTileFixture();
    final literal = await _usedTileLiteral(fixture);
    final mapsBefore = {
      for (final entry in literal.nativeMaps.entries)
        entry.key: canonicalHashOf(entry.value.toJson()),
    };
    final sourceBefore = {
      for (final entry in fixture.sourceBytes.entries)
        entry.key: base64Encode(entry.value),
    };
    final result = await _usedTiles(fixture, literal,
        limits: const LocalAssetProposalLimits(maxPartsPerCandidate: 1));
    expect(result.candidates, hasLength(4));
    expect(result.candidates.map((c) => c.candidateId).toSet(), hasLength(4));
    expect(result.candidates.every((c) => c.parts.length == 1), isTrue);
    expect(
        result.candidates.every((c) =>
            c.canvasSize.width == 32 &&
            c.canvasSize.height == 32 &&
            c.category == AssetCategory.unclassified &&
            c.state == CandidateState.needsReview &&
            c.approvedRevision == null &&
            c.integrationMode == IntegrationMode.libraryOnly),
        isTrue);
    expect(result.candidates.map((c) => c.parts.single.locator.tileId).toSet(),
        {384, 804});
    expect(
        result.candidates.any((c) =>
            c.parts.single.locator.tileId == 820 ||
            c.parts.single.locator.tileId == 821),
        isFalse);
    final allClaims = result.placementClaims.values.expand((c) => c).toList();
    expect(allClaims, hasLength(6644));
    expect(allClaims.map((c) => c.placementKey).toSet(), hasLength(6644));
    for (final candidate in result.candidates) {
      final claims = result.placementClaims[candidate.candidateId]!;
      final part = candidate.parts.single;
      expect(claims.length, part.locator.mapId == 1 ? 3321 : 1);
      expect(
          claims.every((claim) =>
              claim.sourceMapId == part.locator.mapId &&
              claim.sourceZ == part.sourceLayer &&
              claim.tileId == part.locator.tileId &&
              claim.partId == part.partId),
          isTrue);
      if (part.locator.tileId == 804) {
        expect(part.sourceRect.toJson(),
            {'x': 128, 'y': 1664, 'width': 32, 'height': 32});
        expect(part.sourcePriority, 2);
      }
      const LocalAssetProposer().validatePlacementClaims(
          source: fixture.source,
          literal: literal,
          candidate: candidate,
          claims: claims);
      final reference = candidate.evidence.last.reference;
      expect(
          reference,
          'claims:${claims.length};sha256:${canonicalHashOf({
                'kind': 'sourcePlacementOccurrences',
                'version': 1,
                'claims': claims.map((c) => c.toJson()).toList(),
              }).value}');
      expect(reference.length, lessThan(128));
    }
    expect({
      for (final entry in literal.nativeMaps.entries)
        entry.key: canonicalHashOf(entry.value.toJson()),
    }, mapsBefore);
    expect({
      for (final entry in fixture.sourceBytes.entries)
        entry.key: base64Encode(entry.value),
    }, sourceBefore);
    await expectLater(
        const LocalAssetProposer().propose(
            source: fixture.source, files: fixture.files, literal: literal),
        throwsA(_failure('asset.proposal.quota')));
  });

  test('used static tile identities and claims are deterministically ordered',
      () async {
    final a = await _usedTileFixture(mapWidth: 3, mapHeight: 2);
    final b = await _usedTileFixture(
        reverseManifest: true, mapWidth: 3, mapHeight: 2);
    final first = await _usedTiles(a, await _usedTileLiteral(a));
    final second = await _usedTiles(b, await _usedTileLiteral(b));
    expect(first.toJson(), second.toJson());
    expect(first.canonicalHash, second.canonicalHash);
  });

  test('used static tile quotas refuse the whole proposal without truncation',
      () async {
    final fixture = await _usedTileFixture();
    final literal = await _usedTileLiteral(fixture);
    for (final limits in [
      const LocalAssetProposalLimits(maxCandidates: 3),
      const LocalAssetProposalLimits(maxTotalParts: 3),
      const LocalAssetProposalLimits(maxComponents: 3),
      const LocalAssetProposalLimits(maxClaimsPerCandidate: 3320),
      const LocalAssetProposalLimits(maxTotalClaims: 6643),
      const LocalAssetProposalLimits(maxUsageComparisons: 1),
    ]) {
      await expectLater(_usedTiles(fixture, literal, limits: limits),
          throwsA(_failure('asset.proposal.quota')));
    }
  });

  test('used static tile strategy preserves cancellation and source guards',
      () async {
    final fixture = await _usedTileFixture();
    final literal = await _usedTileLiteral(fixture);
    fixture.files.reads.clear();
    final cancellation = ScanCancellation()..cancel();
    await expectLater(_usedTiles(fixture, literal, cancellation: cancellation),
        throwsA(_failure('source.cancelled')));
    expect(fixture.files.reads, isEmpty);
    final imagePath =
        fixture.sourceBytes.keys.singleWhere((path) => path.endsWith('.png'));
    fixture.files.overrides[imagePath] = [1, 2, 3];
    await expectLater(_usedTiles(fixture, literal),
        throwsA(_failure('asset.proposal.source_changed')));
  });

  test('unplaced alpha island is a proposal without invented map usage',
      () async {
    final fixture =
        await OriginalAssetFixture.create(includeUnplacedAlphaIsland: true);
    final result = await _propose(fixture, await fixture.compose());
    final island = result.candidates.singleWhere((candidate) =>
        candidate.parts.every((part) => part.locator.mapId == null));
    expect(island.parts, hasLength(2));
    expect(island.parts.map((part) => part.sourceRect.x), [0, 32]);
    expect(island.parts.map((part) => part.sourceRect.y), [192, 192]);
    expect(island.canvasSize.toJson(), {'width': 64, 'height': 32});
    expect(
        island.parts.every(
            (part) => part.sourceLayer == null && part.sourcePriority == null),
        isTrue);
    expect(
        island.parts.every((part) =>
            part.locator.file == OriginalAssetFixture.imagePath &&
            part.locator.tileId == null),
        isTrue);
    expect(
        island.evidence.map((e) => e.type), contains(EvidenceType.alphaRegion));
    expect(island.evidence.any((e) => e.type == EvidenceType.repeatedPlacement),
        isFalse);
    expect(island.state, CandidateState.needsReview);
    expect(island.category, AssetCategory.unclassified);
    expect(island.integrationMode, IntegrationMode.libraryOnly);
  });

  test(
      'AST-01 proposes original tree from traced grid usages without approving',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    final mapBefore = canonicalHashOf(literal.nativeMaps[1]!.toJson());
    final bytesBefore = base64Encode(fixture.pngBytes);
    final result = await const LocalAssetProposer().propose(
      source: fixture.literalFixture.source,
      files: fixture.literalFixture.files,
      literal: literal,
    );
    final trees = result.candidates.where((c) =>
        c.canvasSize.width == 64 &&
        c.canvasSize.height == 96 &&
        c.parts.every((p) => p.locator.mapId == 1));
    expect(trees, hasLength(1));
    final tree = trees.single;
    expect(tree.state, CandidateState.needsReview);
    expect(tree.category, AssetCategory.unclassified);
    expect(tree.integrationMode, IntegrationMode.libraryOnly);
    expect(tree.approvedRevision, isNull);
    expect(tree.anchor.x, 32);
    expect(tree.anchor.y, 96);
    expect(tree.uncertainties, isNotEmpty);
    expect(
        tree.sourceSnapshotHash, fixture.literalFixture.snapshot.canonicalHash);
    expect(tree.parts.map((p) => p.sourceRect.x).toSet(), {0, 32});
    expect(tree.parts.map((p) => p.sourceRect.y).toSet(), {0, 32, 64});
    expect(canonicalHashOf(literal.nativeMaps[1]!.toJson()), mapBefore);
    expect(base64Encode(fixture.pngBytes), bytesBefore);
  });

  test('AST-02 map usage preserves disjoint source cells and a canvas hole',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    final result = await _propose(fixture, literal);
    final house = result.candidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 8));
    expect(house.parts, hasLength(5));
    expect(house.canvasSize.width, 64);
    expect(house.canvasSize.height, 96);
    expect(house.parts.map((p) => p.sourceRect.y).toSet(), {0, 192, 224});
    expect(
        house.parts
            .map((p) => '${p.destinationOffset.x},${p.destinationOffset.y}')
            .toSet(),
        {'0,0', '32,0', '0,32', '0,64', '32,64'});
    expect(house.parts.map((p) => p.sourcePriority).toSet(), {0, 2});
    expect(house.parts.map((p) => p.sourceLayer).toSet(), {0, 2});
    expect(house.evidence.map((e) => e.type),
        contains(EvidenceType.formatMetadata));
    expect(house.integrationMode, IntegrationMode.libraryOnly);
  });

  test('AST-01 touching occurrences remain ambiguous and unclassified',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final result = await _propose(fixture, await fixture.compose());
    final group = result.candidates
        .singleWhere((c) => c.parts.every((p) => p.locator.mapId == 12));
    expect(group.canvasSize.width, 128);
    expect(group.parts, hasLength(12));
    expect(group.state, CandidateState.needsReview);
    expect(group.category, AssetCategory.unclassified);
    expect(group.uncertainties.join(' '), contains('ambiguous'));
    expect(
        result.diagnostics
            .any((d) => d.code == 'asset.proposal.ambiguous' && d.mapId == 12),
        isTrue);
  });

  test('AST-03 shared source tile does not merge two object identities',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final result = await _propose(fixture, await fixture.compose());
    final objects = [
      for (final id in [20, 21])
        result.candidates
            .singleWhere((c) => c.parts.every((p) => p.locator.mapId == id)),
    ];
    expect(objects[0].candidateId, isNot(objects[1].candidateId));
    final a = objects[0].parts.singleWhere((p) => p.locator.tileId == 446);
    final b = objects[1].parts.singleWhere((p) => p.locator.tileId == 446);
    expect(a.sourceFileId, b.sourceFileId);
    expect(a.sourceRect.toJson(), b.sourceRect.toJson());
    expect(a.destinationOffset.toJson(), b.destinationOffset.toJson());
  });

  test('AST-05 all literal maps and collisions stay exactly unchanged',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    final before = {
      for (final e in literal.nativeMaps.entries)
        e.key: canonicalHashOf(e.value.toJson())
    };
    final result = await _propose(fixture, literal);
    expect(
        result.candidates.every((c) =>
            c.integrationMode == IntegrationMode.libraryOnly &&
            c.approvedRevision == null),
        isTrue);
    expect({
      for (final e in literal.nativeMaps.entries)
        e.key: canonicalHashOf(e.value.toJson())
    }, before);
    expect(literal.playableCertified, isFalse);
  });

  test('proposal identity and order are independent of manifest enumeration',
      () async {
    final a = await OriginalAssetFixture.create();
    final b = await OriginalAssetFixture.create(reverseManifest: true);
    final first = await _propose(a, await a.compose());
    final second = await _propose(b, await b.compose());
    expect(first.canonicalHash, second.canonicalHash);
    expect(first.toJson(), second.toJson());
    final namespaced =
        await OriginalAssetFixture.create(namespace: 'other-assets-fixture');
    final third = await _propose(namespaced, await namespaced.compose());
    expect(
        third.candidates
            .map((c) => c.candidateId)
            .toSet()
            .intersection(first.candidates.map((c) => c.candidateId).toSet()),
        isEmpty);
  });

  test('manual cells are canonical in any enumeration and preserve mixed Z',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    final proposer = const LocalAssetProposer();
    final first = proposer.manualFromCells(
        source: fixture.literalFixture.source,
        literal: literal,
        cells: _houseCells());
    final second = proposer.manualFromCells(
        source: fixture.literalFixture.source,
        literal: literal,
        cells: _houseCells().reversed.toList());
    expect(first.canonicalHash, second.canonicalHash);
    expect(first.parts, hasLength(5));
    expect(first.state, CandidateState.needsReview);
    expect(first.evidence.any((e) => e.type == EvidenceType.human), isTrue);
    expect(first.approvedRevision, isNull);
  });

  test('manual duplicate empty foreign and out of bounds cells are refused',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    final a = _houseCells().first;
    for (final cells in <List<LocalAssetCell>>[
      [],
      [a, a],
      [const LocalAssetCell(mapId: 8, sourceZ: 0, x: 1, y: 1)],
      [const LocalAssetCell(mapId: 8, sourceZ: 0, x: 2, y: 0)],
      [const LocalAssetCell(mapId: 999, sourceZ: 0, x: 0, y: 0)],
      [const LocalAssetCell(mapId: 8, sourceZ: 9, x: 0, y: 0)],
    ]) {
      expect(
          () => const LocalAssetProposer().manualFromCells(
              source: fixture.literalFixture.source,
              literal: literal,
              cells: cells),
          throwsA(_failure('asset.proposal.cells')));
    }
  });

  test('invalid limits and quotas refuse before source reads', () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    fixture.literalFixture.files.reads.clear();
    for (final limits in [
      const LocalAssetProposalLimits(maxPixels: 0),
      const LocalAssetProposalLimits(maxSourceBytes: 1),
      const LocalAssetProposalLimits(maxPixels: 1),
      const LocalAssetProposalLimits(maxMapCells: 1),
    ]) {
      await expectLater(_propose(fixture, literal, limits: limits),
          throwsA(isA<ContractError>()));
      expect(fixture.literalFixture.files.reads, isEmpty);
    }
  });

  test('candidate and part quotas fail explicitly rather than dropping groups',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    for (final limits in [
      const LocalAssetProposalLimits(maxCandidates: 1),
      const LocalAssetProposalLimits(maxTotalParts: 1),
      const LocalAssetProposalLimits(maxPartsPerCandidate: 1),
      const LocalAssetProposalLimits(maxComponents: 1),
      const LocalAssetProposalLimits(maxUsageComparisons: 1),
    ]) {
      await expectLater(_propose(fixture, literal, limits: limits),
          throwsA(_failure('asset.proposal.quota')));
    }
  });

  test('cancelled proposal exits before source reads', () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    fixture.literalFixture.files.reads.clear();
    final token = ScanCancellation()..cancel();
    await expectLater(_propose(fixture, literal, cancellation: token),
        throwsA(_failure('source.cancelled')));
    expect(fixture.literalFixture.files.reads, isEmpty);
  });

  test('mid read cancellation closes without creating proposals', () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    final token = ScanCancellation();
    fixture.literalFixture.files.onRead = (_) => token.cancel();
    await expectLater(_propose(fixture, literal, cancellation: token),
        throwsA(_failure('source.cancelled')));
  });

  test('source byte drift and malformed replacement are refused before decode',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final literal = await fixture.compose();
    final bytes = fixture.pngBytes.toList()..[20] ^= 1;
    for (final bad in [
      bytes,
      <int>[1, 2, 3]
    ]) {
      fixture.literalFixture.files.overrides[OriginalAssetFixture.imagePath] =
          bad;
      await expectLater(_propose(fixture, literal),
          throwsA(_failure('asset.proposal.source_changed')));
    }
    fixture.literalFixture.files.readFailure =
        StateError('Controlled read failure');
    await expectLater(
        _propose(fixture, literal), throwsA(_failure('asset.proposal.read')));
  });

  test('foreign normalized source cannot consume an old literal composition',
      () async {
    final a = await OriginalAssetFixture.create();
    final literal = await a.compose();
    final b = await OriginalAssetFixture.create(namespace: 'foreign-proposal');
    b.literalFixture.files.reads.clear();
    await expectLater(
        _propose(b, literal), throwsA(_failure('asset.proposal.binding')));
    expect(b.literalFixture.files.reads, isEmpty);
  });

  test('proposal collections and candidate geometry are deeply immutable',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final result = await _propose(fixture, await fixture.compose());
    expect(() => result.candidates.clear(), throwsUnsupportedError);
    expect(() => result.diagnostics.clear(), throwsUnsupportedError);
    final candidate = result.candidates.first;
    expect(() => candidate.parts.clear(), throwsUnsupportedError);
    expect(() => candidate.toJson()['parts'] = [], throwsUnsupportedError);
    expect(() => candidate.parts.first.toJson()['sourceRect'] = {},
        throwsUnsupportedError);
  });
}
