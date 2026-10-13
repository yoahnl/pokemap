import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import 'package:avelune_converter_adapters/src/approved_asset_library.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/macos_source_tree.dart';
import 'package:avelune_converter_adapters/src/snapshot_source_files.dart';
import 'support/original_asset_fixture.dart';
import 'support/literal_tile_fixture.dart';

void main() {
  test('approved cardinal terrain publishes an exact native paintable preset',
      () async {
    final fixture =
        await OriginalAssetFixture.create(includeTerrainPixels: true);
    final candidate = _approved(fixture.terrainCandidate());
    final result = await _compose(fixture, [candidate]);
    expect(result.canExport, isTrue);
    expect(result.mutations.map((mutation) => mutation.operationId).toSet(),
        hasLength(result.mutations.length));
    final actions = result.mutations.map((mutation) => mutation.actionId);
    expect(actions.where((action) => action == 'tileset.import_image'),
        hasLength(2));
    expect(actions, contains('smart_tile.atlas.upsert'));
    expect(actions, contains('smart_tile.material.upsert'));
    final preset = result.mutations
        .singleWhere(
            (mutation) => mutation.actionId == 'smart_tile.preset.publish')
        .parameters['preset'] as Map;
    expect(preset['usage'], 'path');
    expect(preset['status'], 'published');
    expect(preset['coveragePolicy'], 'sparse');
    expect(preset['rules'], hasLength(16));
    final terrain =
        result.candidateBindings.single.record['terrainBrush'] as Map;
    final artifact = result.artifacts
        .singleWhere((entry) => entry.handle == terrain['pngArtifactHandle']);
    final raster = image.decodePng(Uint8List.fromList(artifact.bytes))!;
    expect((raster.width, raster.height), (128, 128));
    expect(terrain['layout'], 'cardinal3x3');
    expect(terrain['placementsSubstituted'], isFalse);
    expect(
        result.mutations.every((mutation) =>
            mutation.sourceEntityIds.single == candidate.candidateId),
        isTrue);
  });

  test('atlas-only provenance must point to the actual part image before IO',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final original = fixture.treeCandidate();
    final candidate = _approved(AssetCandidate.fromJson({
      ...original.toJson(),
      'parts': [
        {
          ...original.parts.single.toJson(),
          'locator': {...original.parts.single.locator.toJson(), 'mapId': null}
        }
      ]
    }));
    final files = _CountingFiles(fixture.literalFixture.files);
    _blocked(await _compose(fixture, [candidate], files: files),
        'library.source.locator');
    expect(files.readCount, 0);
  });

  test(
      'AST-04 real scanner and snapshot-bound source files preserve source pixels',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('ac08-library-original-source-');
    addTearDown(() => directory.delete(recursive: true));
    final fixture = await OriginalAssetFixture.create(
        namespace: 'ac08-library-original-source',
        sourceRootPath: directory.path);
    final tree = await MacOsSourceTree.open(directory.path);
    addTearDown(tree.close);
    final snapshot = await SourceScanner().scan(
        source: tree,
        logicalProjectNamespace: ConverterId('ac08-library-original-source'));
    expect(snapshot.state, SourceScanState.complete);
    final files =
        await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot, files: files, selectedMapIds: {1, 8, 12, 20, 21});
    expect(source.canPlan, isTrue);
    final entry = snapshot.entries.singleWhere(
        (entry) => entry.relativePath == OriginalAssetFixture.imagePath);
    final original = fixture.houseCandidate();
    final candidate = _approved(AssetCandidate.fromJson({
      ...original.toJson(),
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'sources': [
        {...original.sources.single.toJson(), 'fileId': entry.fileId.value}
      ],
      'parts': [
        for (final part in original.parts)
          {...part.toJson(), 'sourceFileId': entry.fileId.value}
      ],
    }));
    await files.verifyUnchanged();
    final result = await const ApprovedAssetLibraryComposer().compose(
        source: source,
        files: files,
        candidates: [candidate],
        approvedCandidateHashes: {
          candidate.candidateId: candidate.canonicalHash
        },
        decisions: ReviewDecisions.fromJson({
          ..._decisions(fixture, [candidate]).toJson(),
          'sourceSnapshotHash': snapshot.canonicalHash.value
        }),
        outputMode: AssetOutputMode.standaloneObjects);
    expect(result.canExport, isTrue);
    expect(_png(result).getBytes(order: image.ChannelOrder.rgba),
        fixture.expectedHouseRgba);
    await files.verifyUnchanged();
    expect(
        await File('${directory.path}/${OriginalAssetFixture.imagePath}')
            .readAsBytes(),
        fixture.pngBytes);
  }, skip: !Platform.isMacOS);
  test('AST-04 unknown shared image returns a blocked diagnostic before IO',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final original =
        fixture.treeCandidate(outputMode: AssetOutputMode.sharedAtlas);
    final candidate = _approved(AssetCandidate.fromJson({
      ...original.toJson(),
      'sources': [
        {
          ...original.sources.single.toJson(),
          'fileId': 'missing-library-source'
        }
      ],
      'parts': [
        {
          ...original.parts.single.toJson(),
          'sourceFileId': 'missing-library-source'
        }
      ]
    }));
    final files = _CountingFiles(fixture.literalFixture.files);
    _blocked(
        await _compose(fixture, [candidate],
            files: files, outputMode: AssetOutputMode.sharedAtlas),
        'library.source.binding');
    expect(files.readCount, 0);
  });
  test('AST-01 approved ambiguous group keeps uncertainty visible in metadata',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final candidate = _approved(fixture.ambiguousCandidate(
        outputMode: AssetOutputMode.standaloneObjects));
    final result = await _compose(fixture, [candidate]);
    expect(result.canExport, isTrue);
    expect(result.diagnostics.map((value) => value.code),
        contains('library.candidate.uncertainty'));
    expect(result.candidateBindings.single.record['uncertainties'],
        candidate.uncertainties);
  });
  test(
      'AST-04 adversarial declared dimensions cannot overflow pixel accounting',
      () async {
    final original = await OriginalAssetFixture.create();
    final fixture = await LiteralTileFixture.create(
        namespace: 'library-declared-overflow',
        tilesets: [
          for (var i = 1; i <= 4; i++)
            LiteralFixtureTileset(
                id: i, imageName: 'Overflow$i', png: original.pngBytes)
        ],
        maps: [
          for (var i = 1; i <= 4; i++)
            LiteralFixtureMap(
                id: i,
                tilesetId: i,
                width: 1,
                height: 1,
                layers: [
                  [384],
                  [0],
                  [0]
                ])
        ]);
    final entries = [
      for (var i = 1; i <= 4; i++)
        fixture.snapshot.entries.singleWhere(
            (entry) => entry.relativePath == 'Graphics/Tilesets/Overflow$i.png')
    ];
    final candidate = _approved(AssetCandidate.fromJson({
      ...original.treeCandidate().toJson(),
      'logicalProjectNamespace': fixture.snapshot.logicalProjectNamespace.value,
      'sourceSnapshotHash': fixture.snapshot.canonicalHash.value,
      'sources': [
        for (final entry in entries)
          {
            'fileId': entry.fileId.value,
            'contentHash': entry.sha256!.value,
            'pixelWidth': 2147483647,
            'pixelHeight': 2147483647
          }
      ],
      'parts': [
        for (var i = 0; i < 4; i++)
          {
            ...original.treeCandidate().parts.single.toJson(),
            'partId': 'part-overflow-$i',
            'sourceFileId': entries[i].fileId.value,
            'sourceRect': {'x': 0, 'y': 0, 'width': 32, 'height': 32},
            'destinationOffset': {'x': (i % 2) * 32, 'y': (i ~/ 2) * 32},
            'locator': {
              ...original.treeCandidate().parts.single.locator.toJson(),
              'file': 'Data/Map${(i + 1).toString().padLeft(3, '0')}.rxdata',
              'mapId': i + 1
            }
          }
      ],
      'canvasSize': {'width': 64, 'height': 64},
      'anchor': {
        'unit': 'pixel',
        'x': 32,
        'y': 64,
        'convention': 'bottomCenter'
      },
    }));
    final files = _CountingFiles(fixture.files);
    await expectLater(
        const ApprovedAssetLibraryComposer().compose(
            source: fixture.source,
            files: files,
            candidates: [candidate],
            approvedCandidateHashes: {
              candidate.candidateId: candidate.canonicalHash
            },
            decisions: ReviewDecisions.fromJson({
              ..._decisions(original, [candidate]).toJson(),
              'sourceSnapshotHash': fixture.snapshot.canonicalHash.value
            }),
            outputMode: AssetOutputMode.standaloneObjects),
        throwsA(isA<ApprovedAssetLibraryFailure>()
            .having((f) => f.code, 'code', 'library.quota.pixels')));
    expect(files.readCount, 0);
  });
  test('AST-04 malformed admitted PNG refuses safely without output', () async {
    final original = await OriginalAssetFixture.create();
    final bytes = Uint8List.fromList(original.pngBytes);
    bytes[0] = 0;
    final fixture = await LiteralTileFixture.create(
        namespace: 'library-malformed-png',
        tilesets: [
          LiteralFixtureTileset(id: 1, imageName: 'OriginalAssets', png: bytes)
        ],
        maps: [
          LiteralFixtureMap(id: 1, width: 2, height: 3, layers: [
            [384, 385, 392, 393, 400, 401],
            List.filled(6, 0),
            List.filled(6, 0)
          ])
        ]);
    final entry = fixture.snapshot.entries
        .singleWhere((e) => e.relativePath == OriginalAssetFixture.imagePath);
    final originalCandidate = original.treeCandidate();
    final candidate = _approved(AssetCandidate.fromJson({
      ...originalCandidate.toJson(),
      'logicalProjectNamespace': fixture.snapshot.logicalProjectNamespace.value,
      'sourceSnapshotHash': fixture.snapshot.canonicalHash.value,
      'sources': [
        {
          ...originalCandidate.sources.single.toJson(),
          'fileId': entry.fileId.value,
          'contentHash': entry.sha256!.value
        }
      ],
      'parts': [
        {
          ...originalCandidate.parts.single.toJson(),
          'sourceFileId': entry.fileId.value
        }
      ],
    }));
    await expectLater(
        const ApprovedAssetLibraryComposer().compose(
            source: fixture.source,
            files: fixture.files,
            candidates: [candidate],
            approvedCandidateHashes: {
              candidate.candidateId: candidate.canonicalHash
            },
            decisions: ReviewDecisions.fromJson({
              ..._decisions(original, [candidate]).toJson(),
              'sourceSnapshotHash': fixture.snapshot.canonicalHash.value
            }),
            outputMode: AssetOutputMode.standaloneObjects),
        throwsA(isA<NativeWriteException>()));
  });
  for (final field in ['sourceLayer', 'sourcePriority']) {
    test('AST-05 reapproved contradictory $field refuses before IO', () async {
      final fixture = await OriginalAssetFixture.create();
      final original = fixture.treeCandidate();
      final candidate = _approved(AssetCandidate.fromJson({
        ...original.toJson(),
        'parts': [
          {...original.parts.single.toJson(), field: 2}
        ],
      }));
      final files = _CountingFiles(fixture.literalFixture.files);
      _blocked(await _compose(fixture, [candidate], files: files),
          'library.source.locator');
      expect(files.readCount, 0);
    });
  }
  test('AST-04 shared rectangle raster pixels are included in aggregate quota',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final files = _CountingFiles(fixture.literalFixture.files);
    await expectLater(
        _compose(
            fixture,
            [
              _approved(fixture.treeCandidate(
                  outputMode: AssetOutputMode.sharedAtlas))
            ],
            outputMode: AssetOutputMode.sharedAtlas,
            files: files,
            limits: const NativeWriteLimits(maxImagePixels: 65536)),
        throwsA(isA<ApprovedAssetLibraryFailure>()
            .having((f) => f.code, 'code', 'library.quota.pixels')));
    expect(files.readCount, 0);
  });
  test('AST-04 raster yields to cooperative event-loop cancellation', () async {
    final fixture = await OriginalAssetFixture.create();
    final cancellation = ScanCancellation();
    await expectLater(
        _compose(fixture, [_approved(fixture.treeCandidate())],
            files: _TimedCancellingFiles(
                fixture.literalFixture.files, cancellation),
            cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((f) => f.code, 'code', 'source.cancelled')));
  });
  test('AST-04 tree preserves transparent RGB partial alpha and magenta',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final result =
        await _compose(fixture, [_approved(fixture.treeCandidate())]);
    final rgba = _png(result).getBytes(order: image.ChannelOrder.rgba);
    expect(rgba, fixture.expectedTreeRgba);
    expect(rgba.sublist(0, 4), [17, 61, 91, 0]);
    expect(rgba.sublist(4, 8), [20, 61, 91, 127]);
    final offset = (2 * 64 + 2) * 4;
    expect(rgba.sublist(offset, offset + 4), [255, 0, 255, 255]);
    expect(result.sourceArtifacts.single.bytes, fixture.pngBytes);
  });
  test('AST-04 operation IDs satisfy native transaction gateway grammar',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final candidate = _approved(fixture.houseCandidate());
    final result = await _compose(fixture, [candidate]);
    expect(result.canExport, isTrue);
    expect(result.mutations.map((mutation) => mutation.actionId), [
      'tileset.import_image',
      'element_category.upsert',
      'element.upsert',
      'asset.import',
    ]);
    final grammar = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$');
    for (final mutation in result.mutations) {
      expect(mutation.operationId.value, matches(grammar));
      expect(mutation.operationId.value.length, lessThanOrEqualTo(120));
      expect(mutation.operationId.value.trim(), mutation.operationId.value);
      expect(mutation.sourceEntityIds, [candidate.candidateId]);
    }
    expect(result.candidateBindings.single.candidateId, candidate.candidateId);
    expect(result.mutations.map((mutation) => mutation.operationId).toSet(),
        hasLength(4));
  });
  test('AST-03 shared tiles retain distinct semantic object identities',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final result = await _compose(
        fixture, fixture.sharedCandidates().map(_approved).toList());
    expect(result.canExport, isTrue);
    expect(
        result.candidateBindings
            .map((binding) => binding.nativeElementId)
            .toSet(),
        hasLength(2));
    expect(
        result.candidateBindings
            .map((binding) => binding.nativeTilesetId)
            .toSet(),
        hasLength(2));
    expect(result.sourceArtifacts, hasLength(1));
    expect(
        ((result.candidateBindings[0].record['parts'] as List)[1]
            as Map)['sourceRect'],
        ((result.candidateBindings[1].record['parts'] as List)[1]
            as Map)['sourceRect']);
  });
  test(
      'AST-05 mixed priorities preserve metadata without changing literal maps',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final before = await fixture.compose();
    final result =
        await _compose(fixture, [_approved(fixture.houseCandidate())]);
    final after = await fixture.compose();
    expect(after.compositionHash, before.compositionHash);
    expect(after.draft!.canonicalHash, before.draft!.canonicalHash);
    expect(
        result.mutations
            .any((mutation) => mutation.actionId.startsWith('map.')),
        isFalse);
    final parts = result.candidateBindings.single.record['parts'] as List;
    expect(parts.map((part) => (part as Map)['sourcePriority']), [2, 0, 0]);
    expect(parts.map((part) => (part as Map)['sourceLayer']), [2, 0, 0]);
  });
  test('AST-04 shared atlas references original PNG and native grid rectangle',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final candidate = _approved(
        fixture.treeCandidate(outputMode: AssetOutputMode.sharedAtlas));
    final result = await _compose(fixture, [candidate],
        outputMode: AssetOutputMode.sharedAtlas);
    expect(result.canExport, isTrue);
    expect(result.artifacts.first.bytes, fixture.pngBytes);
    expect(result.candidateBindings.single.record['nativeSourceRect'],
        {'x': 0, 'y': 0, 'width': 2, 'height': 3});
    expect((result.mutations[2].parameters['element'] as Map)['frames'],
        hasLength(1));
  });
  for (final kind in ['house', 'ambiguous']) {
    test('AST-02 shared atlas refuses $kind without implicit fallback',
        () async {
      final fixture = await OriginalAssetFixture.create();
      final candidate = _approved(kind == 'house'
          ? fixture.houseCandidate(outputMode: AssetOutputMode.sharedAtlas)
          : fixture.ambiguousCandidate());
      final files = _CountingFiles(fixture.literalFixture.files);
      _blocked(
          await _compose(fixture, [candidate],
              files: files, outputMode: AssetOutputMode.sharedAtlas),
          'library.shared_atlas.geometry');
      expect(files.readCount, 0);
    });
  }
  final mirrored = [
    [(2, 0), (1, 0), (0, 0), (2, 1), (1, 1), (0, 1)],
    [(2, 1), (2, 0), (1, 1), (1, 0), (0, 1), (0, 0)],
    [(0, 1), (1, 1), (2, 1), (0, 0), (1, 0), (2, 0)],
    [(0, 0), (0, 1), (1, 0), (1, 1), (2, 0), (2, 1)],
  ];
  for (var quarter = 0; quarter < 4; quarter++) {
    test('AST-04 exact reflected quarter turn $quarter and native padding',
        () async {
      final fixture = await OriginalAssetFixture.create();
      final original = fixture.treeCandidate();
      final width = quarter.isOdd ? 2 : 3;
      final height = quarter.isOdd ? 3 : 2;
      final candidate = _approved(AssetCandidate.fromJson({
        ...original.toJson(),
        'parts': [
          {
            ...original.parts.single.toJson(),
            'sourceRect': {'x': 0, 'y': 0, 'width': 3, 'height': 2},
            'quarterTurns': quarter,
            'reflected': true
          }
        ],
        'canvasSize': {'width': width, 'height': height},
        'anchor': {'unit': 'pixel', 'x': 0, 'y': 0, 'convention': 'topLeft'},
      }));
      final result = await _compose(fixture, [candidate]);
      final decoded = _png(result);
      expect((decoded.width, decoded.height), (32, 32));
      final expected = Uint8List(32 * 32 * 4);
      for (var index = 0; index < 6; index++) {
        final (sx, sy) = mirrored[quarter][index];
        final offset = ((index ~/ width) * 32 + index % width) * 4;
        expected.setRange(
            offset, offset + 4, fixture.rgba, (sy * 256 + sx) * 4);
      }
      expect(decoded.getBytes(order: image.ChannelOrder.rgba), expected);
      expect(result.candidateBindings.single.record['padding'],
          {'right': 32 - width, 'bottom': 32 - height, 'transparent': true});
      expect(result.candidateBindings.single.record['canvasSize'],
          {'width': width, 'height': height});
    });
  }
  for (final kind in [
    'pending',
    'missingReceipt',
    'staleReceipt',
    'missingDecision'
  ]) {
    test('AST-04 $kind refuses before source reading', () async {
      final fixture = await OriginalAssetFixture.create();
      final original = fixture.treeCandidate();
      final candidate = kind == 'pending' ? original : _approved(original);
      final files = _CountingFiles(fixture.literalFixture.files);
      final result = await _compose(fixture, [candidate],
          files: files,
          approvedCandidateHashes: kind == 'missingReceipt'
              ? {}
              : kind == 'staleReceipt'
                  ? {candidate.candidateId: original.canonicalHash}
                  : null,
          decisions:
              kind == 'missingDecision' ? _decisions(fixture, []) : null);
      _blocked(result, 'library.candidate.approval');
      expect(files.readCount, 0);
    });
  }
  for (final kind in [
    'foreignSnapshot',
    'foreignNamespace',
    'replacePlacements',
    'animation',
    'staleSourceHash',
    'forgedLocator',
    'overlap'
  ]) {
    test('AST-04 $kind binding refuses before IO', () async {
      final fixture = await OriginalAssetFixture.create();
      final original = kind == 'overlap'
          ? fixture.houseCandidate()
          : fixture.treeCandidate();
      final json = Map<String, Object?>.of(original.toJson());
      switch (kind) {
        case 'foreignSnapshot':
          json['sourceSnapshotHash'] = '0' * 64;
        case 'foreignNamespace':
          json['logicalProjectNamespace'] = 'foreign-source';
        case 'replacePlacements':
          json['integrationMode'] = 'replacePlacements';
        case 'animation':
          json['category'] = 'animation';
        case 'staleSourceHash':
          json['sources'] = [
            {...original.sources.single.toJson(), 'contentHash': '0' * 64}
          ];
        case 'forgedLocator':
          json['parts'] = [
            {
              ...original.parts.single.toJson(),
              'locator': {
                ...original.parts.single.locator.toJson(),
                'mapId': 999
              }
            }
          ];
        case 'overlap':
          final parts = original.parts.map((part) => part.toJson()).toList();
          parts[1] = {
            ...parts[1],
            'destinationOffset': {'x': 0, 'y': 0}
          };
          json['parts'] = parts;
      }
      final files = _CountingFiles(fixture.literalFixture.files);
      final result = await _compose(
          fixture, [_approved(AssetCandidate.fromJson(json))],
          files: files);
      expect(result.canExport, isFalse);
      expect(result.mutations, isEmpty);
      expect(files.readCount, 0);
    });
  }
  test('AST-04 mutated content fails exact inventory hash', () async {
    final fixture = await OriginalAssetFixture.create();
    await expectLater(
        _compose(fixture, [_approved(fixture.treeCandidate())],
            files: _ChangedFiles(fixture.literalFixture.files)),
        throwsA(isA<ApprovedAssetLibraryFailure>()
            .having((f) => f.code, 'code', 'library.source.hash')));
  });
  test('AST-04 same revision mutation rejects the old candidate receipt',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final original = _approved(fixture.treeCandidate());
    final candidate = AssetCandidate.fromJson(
        {...original.toJson(), 'name': 'Altered same revision'});
    _blocked(
        await _compose(fixture, [
          candidate
        ], approvedCandidateHashes: {
          candidate.candidateId: original.canonicalHash
        }),
        'library.candidate.approval');
  });
  for (final kind in ['pixels', 'output', 'entries']) {
    test('AST-04 $kind quota precedes source reads and collection copies',
        () async {
      final fixture = await OriginalAssetFixture.create();
      final files = _CountingFiles(fixture.literalFixture.files);
      final candidate = _approved(fixture.treeCandidate());
      await expectLater(
          _compose(
              fixture, kind == 'entries' ? _OversizedCandidates() : [candidate],
              files: files,
              approvedCandidateHashes: kind == 'entries' ? {} : null,
              decisions: kind == 'entries' ? _decisions(fixture, []) : null,
              limits: kind == 'pixels'
                  ? const NativeWriteLimits(maxImagePixels: 65536)
                  : kind == 'output'
                      ? NativeWriteLimits(
                          maxArtifactBytes: fixture.pngBytes.length + 1)
                      : const NativeWriteLimits()),
          throwsA(isA<ApprovedAssetLibraryFailure>()
              .having((f) => f.code, 'code', 'library.quota.$kind')));
      expect(files.readCount, 0);
    });
  }
  test('AST-04 cancellation after asynchronous source read yields no output',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final cancellation = ScanCancellation();
    await expectLater(
        _compose(fixture, [_approved(fixture.treeCandidate())],
            files: _CancellingFiles(fixture.literalFixture.files, cancellation),
            cancellation: cancellation),
        throwsA(isA<ContractError>()
            .having((f) => f.code, 'code', 'source.cancelled')));
  });
  test('AST-04 async inputs and nested evidence are immutable', () async {
    final fixture = await OriginalAssetFixture.create();
    final candidate = _approved(fixture.treeCandidate());
    final candidates = [candidate];
    final receipts = {candidate.candidateId: candidate.canonicalHash};
    final files = _DeferredFiles(fixture.literalFixture.files);
    final future = _compose(fixture, candidates,
        files: files, approvedCandidateHashes: receipts);
    await files.entered.future;
    candidates.clear();
    receipts.clear();
    files.resume.complete();
    final result = await future;
    expect(result.canExport, isTrue);
    expect(() => result.artifacts.clear(), throwsUnsupportedError);
    expect(
        () =>
            (result.evidence['record'] as Map)['outputMode'] = 'packedObjects',
        throwsUnsupportedError);
    expect(
        () => ((result.candidateBindings.single.record['parts'] as List).first
            as Map)['quarterTurns'] = 2,
        throwsUnsupportedError);
    final repeated = await _compose(fixture, [candidate]);
    expect(repeated.compositionHash, result.compositionHash);
    expect(repeated.artifacts.first.bytes, result.artifacts.first.bytes);
  });
  test('AST-02 approved disjoint house exports exact independent RGBA',
      () async {
    final fixture = await OriginalAssetFixture.create();
    final candidate = _approved(fixture.houseCandidate());
    final result = await _compose(fixture, [candidate]);
    expect(result.canExport, isTrue);
    expect(result.candidateBindings, hasLength(1));
    final binding = result.candidateBindings.single;
    final png = result.artifacts.singleWhere(
        (artifact) => artifact.handle == binding.pngArtifactHandle);
    final decoded = image.decodePng(Uint8List.fromList(png.bytes))!;
    expect(decoded.width, 64);
    expect(decoded.height, 96);
    expect(decoded.getBytes(order: image.ChannelOrder.rgba),
        fixture.expectedHouseRgba);
    expect(result.mutations.map((mutation) => mutation.actionId), [
      'tileset.import_image',
      'element_category.upsert',
      'element.upsert',
      'asset.import',
    ]);
    expect(
        result.mutations.every((mutation) =>
            mutation.sourceEntityIds.length == 1 &&
            mutation.sourceEntityIds.single == candidate.candidateId),
        isTrue);
    final companion = result.artifacts.singleWhere(
        (artifact) => artifact.handle == binding.companionArtifactHandle);
    final metadata = jsonDecode(utf8.decode(companion.bytes)) as Map;
    expect(metadata['anchor'], candidate.anchor.toJson());
    expect(metadata['parts'],
        candidate.parts.map((part) => part.toJson()).toList());
    expect(metadata['canvasSize'], candidate.canvasSize.toJson());
  });
}

AssetCandidate _approved(AssetCandidate candidate) => AssetCandidate.fromJson({
      ...candidate.toJson(),
      'state': 'approved',
      'approvedRevision': candidate.revision,
    });

Future<ApprovedAssetLibraryComposition> _compose(
        OriginalAssetFixture fixture, List<AssetCandidate> candidates,
        {AssetOutputMode outputMode = AssetOutputMode.standaloneObjects,
        SourceFilePort? files,
        Map<ConverterId, Sha256Hash>? approvedCandidateHashes,
        ReviewDecisions? decisions,
        NativeWriteLimits limits = const NativeWriteLimits(),
        ScanCancellation? cancellation}) =>
    const ApprovedAssetLibraryComposer().compose(
      source: fixture.literalFixture.source,
      files: files ?? fixture.literalFixture.files,
      candidates: candidates,
      approvedCandidateHashes: approvedCandidateHashes ??
          {
            for (final candidate in candidates)
              candidate.candidateId: candidate.canonicalHash,
          },
      decisions: decisions ?? _decisions(fixture, candidates),
      outputMode: outputMode,
      limits: limits,
      cancellation: cancellation,
    );

ReviewDecisions _decisions(
        OriginalAssetFixture fixture, List<AssetCandidate> candidates) =>
    ReviewDecisions.fromJson({
      'schemaVersion': '1.0',
      'kind': 'reviewDecisions',
      'exampleOnly': false,
      'sessionId': 'original-library-test',
      'sourceSnapshotHash': fixture.literalFixture.snapshot.canonicalHash.value,
      'revision': 1,
      'decisions': [
        for (final candidate in candidates)
          {
            'decisionId': 'approve:${candidate.candidateId.value}',
            'candidateId': candidate.candidateId.value,
            'candidateRevision': candidate.revision,
            'action': 'approve',
            'humanConfirmed': true,
            'replacementCandidateIds': <String>[],
            'note': 'Explicit test-only approval of original fixture geometry',
          },
      ],
    });

image.Image _png(ApprovedAssetLibraryComposition result) =>
    image.decodePng(Uint8List.fromList(result.artifacts
        .singleWhere((artifact) =>
            artifact.handle ==
            result.candidateBindings.single.pngArtifactHandle)
        .bytes))!;

void _blocked(ApprovedAssetLibraryComposition result, String code) {
  expect(result.canExport, isFalse);
  expect(result.artifacts, isEmpty);
  expect(result.mutations, isEmpty);
  expect(result.diagnostics.map((d) => d.code), contains(code));
}

final class _CountingFiles implements SourceFilePort {
  _CountingFiles(this.inner);
  final SourceFilePort inner;
  int readCount = 0;
  @override
  Future<List<int>> read(ConverterId id) {
    readCount++;
    return inner.read(id);
  }
}

final class _ChangedFiles implements SourceFilePort {
  _ChangedFiles(this.inner);
  final SourceFilePort inner;
  @override
  Future<List<int>> read(ConverterId id) async {
    final bytes = List<int>.of(await inner.read(id));
    bytes[0] ^= 1;
    return bytes;
  }
}

final class _CancellingFiles implements SourceFilePort {
  _CancellingFiles(this.inner, this.cancellation);
  final SourceFilePort inner;
  final ScanCancellation cancellation;
  @override
  Future<List<int>> read(ConverterId id) async {
    final bytes = await inner.read(id);
    cancellation.cancel();
    return bytes;
  }
}

final class _TimedCancellingFiles implements SourceFilePort {
  _TimedCancellingFiles(this.inner, this.cancellation);
  final SourceFilePort inner;
  final ScanCancellation cancellation;
  @override
  Future<List<int>> read(ConverterId id) async {
    final bytes = await inner.read(id);
    Timer.run(cancellation.cancel);
    return bytes;
  }
}

final class _DeferredFiles implements SourceFilePort {
  _DeferredFiles(this.inner);
  final SourceFilePort inner;
  final entered = Completer<void>();
  final resume = Completer<void>();
  @override
  Future<List<int>> read(ConverterId id) async {
    entered.complete();
    await resume.future;
    return inner.read(id);
  }
}

final class _OversizedCandidates extends ListBase<AssetCandidate> {
  @override
  int get length => 1000;
  @override
  set length(int value) => throw StateError('Quota must precede mutation');
  @override
  AssetCandidate operator [](int index) =>
      throw StateError('Quota must precede entry access');
  @override
  void operator []=(int index, AssetCandidate value) =>
      throw StateError('Quota must precede mutation');
}
