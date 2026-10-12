import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'package:avelune_converter_adapters/src/local_asset_proposer.dart';
import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'support/original_asset_fixture.dart';

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

void main() {
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
