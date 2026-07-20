import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../map_core/test/fixtures/border/selbrume_two_tier_stone_chain_v4_fixture.dart';
import '../tool/build_selbrume_two_tier_cliff_pack.dart';

const _palette = <(int, int, int)>[
  (166, 156, 123),
  (145, 136, 109),
  (126, 118, 96),
  (108, 101, 84),
  (91, 85, 72),
  (77, 72, 62),
  (62, 58, 51),
  (48, 45, 40),
];

const _orientations = <String>['n', 'e', 's', 'w'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('checked-in V4 fixture matches the compact draft and source PNGs', () {
    final projectRoot = Directory(
      p.normalize(
          p.absolute(p.join(Directory.current.path, '..', '..', 'selbrume'))),
    );
    final projectJson = jsonDecode(
      File(p.join(projectRoot.path, 'project.json')).readAsStringSync(),
    ) as Map<String, dynamic>;
    final records = (projectJson['borderCatalog']
        as Map<String, dynamic>)['records'] as List<dynamic>;
    final record = records.cast<Map<String, dynamic>>().singleWhere(
          (item) => item['id'] == 'border-blueprint-4',
        );
    final draft = record['draft'] as Map<String, dynamic>;
    final definition = draft['definition'] as Map<String, dynamic>;
    final draftPrimitives = (definition['primitives'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final provenanceJson = jsonDecode(
      File(
        p.join(
          projectRoot.path,
          'assets',
          'provenance',
          'selbrume_two_tier_cliff_v2.json',
        ),
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final provenanceEntries = (provenanceJson['entries'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    final fixturePrimitives = selbrumeTwoTierV4PublishedPrimitives();

    expect(draftPrimitives, hasLength(24));
    expect(provenanceEntries, hasLength(24));
    expect(fixturePrimitives, hasLength(24));
    for (final fixture in fixturePrimitives) {
      final draftPrimitive = draftPrimitives.singleWhere(
        (item) => item['id'] == fixture.id,
      );
      final metrics = fixture.publishedMetrics;
      final currentMetrics =
          draftPrimitive['currentMetrics'] as Map<String, dynamic>;
      final provenanceEntry = provenanceEntries.singleWhere(
        (item) => item['id'] == fixture.id,
      );
      final sourceName =
          '${fixture.id.substring('selbrume-cliff-'.length).replaceAll('-', '_')}.png';
      final sourceFile = File(
        p.join(
          projectRoot.path,
          'assets',
          'sources',
          'border_studio',
          'two_tier_cliff_v2',
          sourceName,
        ),
      );

      expect(sourceFile.existsSync(), isTrue, reason: fixture.id);
      expect(draftPrimitive['sourceElementId'], fixture.sourceElementId,
          reason: fixture.id);
      expect(draftPrimitive['role'], fixture.role.name, reason: fixture.id);
      expect(
        draftPrimitive['authoredOrientation'],
        fixture.authoredOrientation.name,
        reason: fixture.id,
      );
      expect(draftPrimitive['weight'], fixture.weight, reason: fixture.id);
      expect(
          draftPrimitive['anchorPx'],
          <String, int>{
            'x': fixture.anchorPx.x,
            'y': fixture.anchorPx.y,
          },
          reason: fixture.id);
      expect(
        currentMetrics['assetFingerprint'],
        metrics.assetFingerprint,
        reason: fixture.id,
      );
      expect(provenanceEntry['fileName'], sourceName, reason: fixture.id);
      expect(
        provenanceEntry['sourceRelativePath'],
        'assets/sources/border_studio/two_tier_cliff_v2/$sourceName',
        reason: fixture.id,
      );
      expect(
        provenanceEntry['sha256'],
        sha256.convert(sourceFile.readAsBytesSync()).toString(),
        reason: fixture.id,
      );
      expect(
          currentMetrics['pixelSize'],
          <String, int>{
            'width': metrics.pixelSize.width,
            'height': metrics.pixelSize.height,
          },
          reason: fixture.id);
      expect(
          currentMetrics['opaqueBounds'],
          <String, int>{
            'x': metrics.opaqueBounds.x,
            'y': metrics.opaqueBounds.y,
            'width': metrics.opaqueBounds.width,
            'height': metrics.opaqueBounds.height,
          },
          reason: fixture.id);
      expect(
          currentMetrics['defaultAnchorPx'],
          <String, int>{
            'x': metrics.defaultAnchorPx.x,
            'y': metrics.defaultAnchorPx.y,
          },
          reason: fixture.id);
      expect(
        currentMetrics['occupancyMaskRle'],
        metrics.occupancyMaskRle,
        reason: fixture.id,
      );
    }
  });

  test('builds 24 directional stones and the atlas byte-identically', () async {
    final fixture = await _fixture(componentCount: 24);
    final firstRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_first_',
    );
    final secondRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_second_',
    );
    addTearDown(() => fixture.root.delete(recursive: true));
    addTearDown(() => firstRoot.delete(recursive: true));
    addTearDown(() => secondRoot.delete(recursive: true));

    final first = await buildSelbrumeTwoTierCliffPack(
      SelbrumeTwoTierCliffPackOptions(
        sheet: fixture.sheet,
        projectRoot: firstRoot,
        outputAtlas: File(p.join(firstRoot.path, 'atlas.png')),
        provenance: File(p.join(firstRoot.path, 'provenance.json')),
        chromaRgb: 0xFF00FF,
        chromaTolerance: 48,
      ),
    );
    final second = await buildSelbrumeTwoTierCliffPack(
      SelbrumeTwoTierCliffPackOptions(
        sheet: fixture.sheet,
        projectRoot: secondRoot,
        outputAtlas: File(p.join(secondRoot.path, 'atlas.png')),
        provenance: File(p.join(secondRoot.path, 'provenance.json')),
        chromaRgb: 0xFF00FF,
        chromaTolerance: 48,
      ),
    );

    expect(first.sourceFiles, hasLength(24));
    expect(first.atlasSha256, second.atlasSha256);
    expect(
      first.outputAtlas.readAsBytesSync(),
      orderedEquals(second.outputAtlas.readAsBytesSync()),
    );
    expect(
      first.provenance.readAsBytesSync(),
      orderedEquals(second.provenance.readAsBytesSync()),
    );
    expect(
      first.atlasSha256,
      sha256.convert(first.outputAtlas.readAsBytesSync()).toString(),
    );

    final expectedNames = <String>{
      for (final orientation in _orientations)
        for (var variant = 1; variant <= 3; variant += 1)
          'top_${orientation}_${variant.toString().padLeft(2, '0')}.png',
      for (final orientation in _orientations)
        for (var variant = 1; variant <= 3; variant += 1)
          'face_${orientation}_${variant.toString().padLeft(2, '0')}.png',
    };
    expect(
      first.sourceFiles.map((file) => p.basename(file.path)).toSet(),
      expectedNames,
    );

    final expectedBoundsByName = _expectedBoundsByName();
    for (final file in first.sourceFiles) {
      final decoded = _decode(file.readAsBytesSync());
      final name = p.basename(file.path);
      expect((decoded.width, decoded.height), (32, 32), reason: name);
      expect(_alphaValues(decoded), <int>{0, 255}, reason: name);
      expect(_opaqueComponentCount(decoded), 1, reason: name);
      expect(_opaqueBounds(decoded), expectedBoundsByName[name], reason: name);
      expect(_opaqueRgb(decoded).difference(_palette.toSet()), isEmpty,
          reason: name);
      expect(
        _opaqueRgb(decoded).where((color) => color.$2 > color.$1),
        isEmpty,
        reason: '$name must contain no green-dominant pixels.',
      );
      expect(
        _opaqueRgb(decoded).where((color) => color.$3 > color.$1),
        isEmpty,
        reason: '$name must contain no blue-dominant pixels.',
      );
      final tonePermille = _tonePermille(decoded);
      final expectedTone = name.startsWith('top_')
          ? tonePermille.lightOrMedium
          : tonePermille.dark;
      expect(
        expectedTone,
        inInclusiveRange(550, 650),
        reason: '$name must preserve the intended two-tier light balance.',
      );
    }

    final atlas = _decode(first.outputAtlas.readAsBytesSync());
    expect((atlas.width, atlas.height), (192, 128));
    expect(_alphaValues(atlas), <int>{0, 255});

    final provenance =
        jsonDecode(first.provenance.readAsStringSync()) as Map<String, dynamic>;
    expect(provenance['schemaVersion'], 1);
    expect(provenance['collisionIntent'], 'visual_only_no_collision');
    expect(provenance['source'], isNotEmpty);
    expect(provenance['license'], isNotEmpty);
    expect(provenance['status'], 'approved');
    expect(provenance['sheetSha256'], fixture.sheetSha256);
    expect(provenance['atlasSha256'], first.atlasSha256);
    expect(provenance['chroma'], '#FF00FF');
    expect(provenance['chromaTolerance'], 48);
    expect(provenance['palette'], const <String>[
      '#A69C7B',
      '#91886D',
      '#7E7660',
      '#6C6554',
      '#5B5548',
      '#4D483E',
      '#3E3A33',
      '#302D28',
    ]);
    final inventoryAssets = provenance['assets'] as Map<String, dynamic>;
    expect(inventoryAssets, hasLength(25));
    expect(
      inventoryAssets.keys,
      contains('tilesets/falaises_selbrume_deux_etages_v2.png'),
    );
    for (final value in inventoryAssets.values) {
      expect(
        value,
        containsPair('source', isNotEmpty),
      );
      expect(value, containsPair('license', isNotEmpty));
      expect(value, containsPair('status', 'approved'));
    }
    final entries = provenance['entries'] as List<dynamic>;
    expect(entries, hasLength(24));
    final rebuiltAtlas = img.Image(width: 192, height: 128, numChannels: 4);
    final sourceHashes = <String>{};
    for (var index = 0; index < entries.length; index += 1) {
      final entry = entries[index] as Map<String, dynamic>;
      final role = entry['role'] as String;
      final fileName = entry['fileName'] as String;
      final sourceFile = first.sourceFiles.singleWhere(
        (file) => p.basename(file.path) == fileName,
      );
      final sourceBytes = sourceFile.readAsBytesSync();
      final atlasCell = entry['atlasCell'] as Map<String, dynamic>;
      final orientationWire = fileName.split('_')[1];
      final orientation = switch (orientationWire) {
        'n' => 'north',
        'e' => 'east',
        's' => 'south',
        'w' => 'west',
        _ => throw StateError('Unexpected orientation in $fileName.'),
      };

      expect(entry['id'], startsWith('selbrume-cliff-$role-'));
      expect(
        entry['sourceRelativePath'],
        'assets/sources/border_studio/two_tier_cliff_v2/$fileName',
      );
      expect(entry['sha256'], sha256.convert(sourceBytes).toString());
      sourceHashes.add(entry['sha256'] as String);
      expect(entry['authoredOrientation'], orientation);
      expect(entry['anchorPx'], _expectedAnchor(role, orientationWire));
      expect(entry['collisionIntent'], 'visual_only_no_collision');
      expect(entry['license'], isNotEmpty);
      expect(entry['status'], 'approved');
      expect(
        atlasCell,
        <String, int>{'column': index % 6, 'row': index ~/ 6},
      );
      expect(entry['lightOrMediumPermille'], isA<int>());
      expect(entry['darkPermille'], isA<int>());
      expect(
        role == 'top' ? entry['lightOrMediumPermille'] : entry['darkPermille'],
        inInclusiveRange(550, 650),
      );
      img.compositeImage(
        rebuiltAtlas,
        _decode(sourceBytes),
        dstX: (atlasCell['column'] as int) * 32,
        dstY: (atlasCell['row'] as int) * 32,
      );
    }
    expect(sourceHashes, hasLength(24));
    expect(
      img.encodePng(rebuiltAtlas),
      orderedEquals(first.outputAtlas.readAsBytesSync()),
    );
  });

  test('normalizes an overly light raw sheet into the two tier tone bands',
      () async {
    final fixture = await _fixture(componentCount: 24, forceLightPalette: true);
    final projectRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_tone_normalization_',
    );
    addTearDown(() => fixture.root.delete(recursive: true));
    addTearDown(() => projectRoot.delete(recursive: true));

    final result = await buildSelbrumeTwoTierCliffPack(
      SelbrumeTwoTierCliffPackOptions(
        sheet: fixture.sheet,
        projectRoot: projectRoot,
        outputAtlas: File(p.join(projectRoot.path, 'atlas.png')),
        provenance: File(p.join(projectRoot.path, 'provenance.json')),
      ),
    );

    for (final file in result.sourceFiles) {
      final name = p.basename(file.path);
      final tone = _tonePermille(_decode(file.readAsBytesSync()));
      expect(
        name.startsWith('top_') ? tone.lightOrMedium : tone.dark,
        inInclusiveRange(550, 650),
        reason: name,
      );
    }
  });

  test('rebuild preserves approved provenance for byte-identical snapshots',
      () async {
    final fixture = await _fixture(componentCount: 24);
    final projectRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_snapshot_provenance_',
    );
    addTearDown(() => fixture.root.delete(recursive: true));
    addTearDown(() => projectRoot.delete(recursive: true));
    final provenance = File(p.join(projectRoot.path, 'provenance.json'));
    final options = SelbrumeTwoTierCliffPackOptions(
      sheet: fixture.sheet,
      projectRoot: projectRoot,
      outputAtlas: File(p.join(projectRoot.path, 'atlas.png')),
      provenance: provenance,
    );
    final first = await buildSelbrumeTwoTierCliffPack(options);
    final source = first.sourceFiles.singleWhere(
      (file) => p.basename(file.path) == 'top_n_01.png',
    );
    const snapshotId =
        '1111111111111111111111111111111111111111111111111111111111111111';
    final snapshot = File(
      p.join(
        projectRoot.path,
        'assets',
        'borders',
        'snapshots',
        snapshotId,
        'frame_0000.png',
      ),
    )..createSync(recursive: true);
    snapshot.writeAsBytesSync(source.readAsBytesSync());

    await buildSelbrumeTwoTierCliffPack(options);
    final secondBytes = provenance.readAsBytesSync();
    final decoded =
        jsonDecode(utf8.decode(secondBytes)) as Map<String, dynamic>;
    final assets = decoded['assets'] as Map<String, dynamic>;
    final digest = sha256.convert(source.readAsBytesSync()).toString();
    const sourcePath = 'sources/border_studio/two_tier_cliff_v2/top_n_01.png';
    const snapshotPath = 'borders/snapshots/$snapshotId/frame_0000.png';

    expect(assets, hasLength(26));
    expect(
      assets[snapshotPath],
      <String, String>{
        'source': 'Byte-identical immutable Border Studio publication snapshot '
            'derived from assets/$sourcePath (sha256:$digest)',
        'license': 'project-owned generated asset',
        'status': 'approved',
      },
    );

    await buildSelbrumeTwoTierCliffPack(options);
    expect(provenance.readAsBytesSync(), orderedEquals(secondBytes));
  });

  test('preserves only cryptographically validated historical snapshots',
      () async {
    final firstFixture = await _fixture(componentCount: 24);
    final replacementFixture = await _fixture(
      componentCount: 24,
      forceLightPalette: true,
    );
    final projectRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_historical_snapshot_provenance_',
    );
    addTearDown(() => firstFixture.root.delete(recursive: true));
    addTearDown(() => replacementFixture.root.delete(recursive: true));
    addTearDown(() => projectRoot.delete(recursive: true));
    final provenance = File(p.join(projectRoot.path, 'provenance.json'));
    SelbrumeTwoTierCliffPackOptions options(File sheet) =>
        SelbrumeTwoTierCliffPackOptions(
          sheet: sheet,
          projectRoot: projectRoot,
          outputAtlas: File(p.join(projectRoot.path, 'atlas.png')),
          provenance: provenance,
        );

    final first = await buildSelbrumeTwoTierCliffPack(
      options(firstFixture.sheet),
    );
    final source = first.sourceFiles.singleWhere(
      (file) => p.basename(file.path) == 'top_n_01.png',
    );
    final historicalBytes = source.readAsBytesSync();
    final historicalDigest = sha256.convert(historicalBytes).toString();
    const validSnapshotId =
        '2222222222222222222222222222222222222222222222222222222222222222';
    const invalidSnapshotId =
        '3333333333333333333333333333333333333333333333333333333333333333';
    File snapshot(String id) => File(
          p.join(
            projectRoot.path,
            'assets',
            'borders',
            'snapshots',
            id,
            'frame_0000.png',
          ),
        )..createSync(recursive: true);
    snapshot(validSnapshotId).writeAsBytesSync(historicalBytes);
    snapshot(invalidSnapshotId).writeAsBytesSync(historicalBytes);

    await buildSelbrumeTwoTierCliffPack(options(firstFixture.sheet));
    final approved =
        jsonDecode(provenance.readAsStringSync()) as Map<String, dynamic>;
    final approvedAssets = approved['assets'] as Map<String, dynamic>;
    const invalidPath = 'borders/snapshots/$invalidSnapshotId/frame_0000.png';
    final invalidRecord = Map<String, dynamic>.of(
      approvedAssets[invalidPath] as Map<String, dynamic>,
    );
    invalidRecord['source'] = (invalidRecord['source'] as String).replaceFirst(
      historicalDigest,
      'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
    );
    approvedAssets[invalidPath] = invalidRecord;
    provenance.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(approved)}\n',
    );

    await buildSelbrumeTwoTierCliffPack(options(replacementFixture.sheet));
    expect(
      sha256.convert(source.readAsBytesSync()).toString(),
      isNot(historicalDigest),
      reason: 'The second generation must make the snapshot historical.',
    );
    final rebuilt =
        jsonDecode(provenance.readAsStringSync()) as Map<String, dynamic>;
    final rebuiltAssets = rebuilt['assets'] as Map<String, dynamic>;
    const validPath = 'borders/snapshots/$validSnapshotId/frame_0000.png';
    const sourcePath = 'sources/border_studio/two_tier_cliff_v2/top_n_01.png';

    expect(
      rebuiltAssets[validPath],
      <String, String>{
        'source': 'Byte-identical immutable Border Studio publication snapshot '
            'derived from assets/$sourcePath (sha256:$historicalDigest)',
        'license': 'project-owned generated asset',
        'status': 'approved',
      },
    );
    expect(
      rebuiltAssets.containsKey(invalidPath),
      isFalse,
      reason: 'A historical record with a forged digest must be discarded.',
    );
  });

  for (final componentCount in <int>[23, 25]) {
    test('rejects $componentCount components without replacing outputs',
        () async {
      final fixture = await _fixture(componentCount: componentCount);
      addTearDown(() => fixture.root.delete(recursive: true));
      final projectRoot = await Directory.systemTemp.createTemp(
        'selbrume_two_tier_atomic_',
      );
      addTearDown(() => projectRoot.delete(recursive: true));
      final outputAtlas = File(p.join(projectRoot.path, 'atlas.png'))
        ..writeAsBytesSync(<int>[1, 2, 3]);
      final provenance = File(p.join(projectRoot.path, 'provenance.json'))
        ..writeAsStringSync('sentinel');

      await expectLater(
        buildSelbrumeTwoTierCliffPack(
          SelbrumeTwoTierCliffPackOptions(
            sheet: fixture.sheet,
            projectRoot: projectRoot,
            outputAtlas: outputAtlas,
            provenance: provenance,
            chromaRgb: 0xFF00FF,
            chromaTolerance: 48,
          ),
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('exactly 24'),
          ),
        ),
      );
      expect(outputAtlas.readAsBytesSync(), <int>[1, 2, 3]);
      expect(provenance.readAsStringSync(), 'sentinel');
      expect(
        Directory(
          p.join(
            projectRoot.path,
            'assets',
            'sources',
            'border_studio',
            'two_tier_cliff_v2',
          ),
        ).existsSync(),
        isFalse,
      );
    });
  }

  test('rejects ambiguous component rows without replacing outputs', () async {
    final fixture = await _fixture(componentCount: 24, ambiguousRows: true);
    await _expectAtomicFailure(fixture, contains('rows'));
  });

  test('rejects ambiguous component columns without replacing outputs',
      () async {
    final fixture = await _fixture(componentCount: 24, ambiguousColumns: true);
    await _expectAtomicFailure(fixture, contains('columns'));
  });

  test('rejects a source stone clipped by the sheet edge atomically', () async {
    final fixture = await _fixture(componentCount: 24, clippedStone: true);
    await _expectAtomicFailure(fixture, contains('sheet edge'));
  });

  test('rejects a detached opaque chip without replacing outputs', () async {
    final fixture = await _fixture(componentCount: 24, detachedChip: true);
    await _expectAtomicFailure(fixture, contains('exactly 24'));
  });

  test('rolls back the whole pack when a destination cannot be replaced',
      () async {
    final fixture = await _fixture(componentCount: 24);
    final projectRoot = await Directory.systemTemp.createTemp(
      'selbrume_two_tier_pack_rollback_',
    );
    addTearDown(() => fixture.root.delete(recursive: true));
    addTearDown(() => projectRoot.delete(recursive: true));
    final sourceDirectory = Directory(
      p.join(
        projectRoot.path,
        'assets',
        'sources',
        'border_studio',
        'two_tier_cliff_v2',
      ),
    )..createSync(recursive: true);
    final sentinelSource = File(p.join(sourceDirectory.path, 'top_n_01.png'))
      ..writeAsBytesSync(<int>[9, 8, 7]);
    final provenance = File(p.join(projectRoot.path, 'provenance.json'))
      ..writeAsStringSync('provenance-sentinel');
    final invalidAtlasDestination = Directory(
      p.join(projectRoot.path, 'atlas.png'),
    )..createSync();

    await expectLater(
      buildSelbrumeTwoTierCliffPack(
        SelbrumeTwoTierCliffPackOptions(
          sheet: fixture.sheet,
          projectRoot: projectRoot,
          outputAtlas: File(invalidAtlasDestination.path),
          provenance: provenance,
        ),
      ),
      throwsA(anything),
    );

    expect(sentinelSource.readAsBytesSync(), <int>[9, 8, 7]);
    expect(
      sourceDirectory.listSync().map((entry) => p.basename(entry.path)),
      orderedEquals(<String>['top_n_01.png']),
    );
    expect(provenance.readAsStringSync(), 'provenance-sentinel');
    expect(invalidAtlasDestination.existsSync(), isTrue);
  });
}

Future<({Directory root, File sheet, String sheetSha256})> _fixture({
  required int componentCount,
  bool ambiguousRows = false,
  bool ambiguousColumns = false,
  bool clippedStone = false,
  bool detachedChip = false,
  bool forceLightPalette = false,
}) async {
  final root = await Directory.systemTemp.createTemp(
    'selbrume_two_tier_sheet_',
  );
  final sheet = File(p.join(root.path, 'sheet.png'));
  final image = img.Image(width: 768, height: 512, numChannels: 4);
  for (var y = 0; y < image.height; y += 1) {
    final background = switch (y % 3) {
      0 => (255, 0, 255),
      1 => (248, 8, 250),
      _ => (246, 5, 252),
    };
    for (var x = 0; x < image.width; x += 1) {
      image.setPixelRgba(
        x,
        y,
        background.$1,
        background.$2,
        background.$3,
        255,
      );
    }
  }
  const centersX = <int>[63, 181, 307, 432, 557, 696];
  const centersY = <int>[62, 178, 310, 447];
  final regularComponentCount = componentCount < 24 ? componentCount : 24;
  for (var index = 0; index < regularComponentCount; index += 1) {
    final row = index ~/ 6;
    final column = index % 6;
    final face = row >= 2;
    final width = face ? 31 + index % 7 : 42 + index % 9;
    final centerX = clippedStone && index == 0
        ? width ~/ 2
        : ambiguousColumns && index == 5
            ? (centersX[4] + centersX[5]) ~/ 2
            : centersX[column] + ((index * 7) % 9) - 4;
    final centerY = ambiguousRows && index == 5
        ? (centersY[0] + centersY[1]) ~/ 2
        : centersY[row] + ((index * 5) % 11) - 5;
    _paintStone(
      image,
      centerX: centerX,
      centerY: centerY,
      width: width,
      height: face ? 70 + index % 13 : 30 + index % 8,
      paletteOffset: index,
      forceLightPalette: forceLightPalette,
    );
  }
  if (detachedChip) {
    final color = _palette.last;
    image.setPixelRgba(19, 19, color.$1, color.$2, color.$3, 255);
  }
  for (var index = 24; index < componentCount; index += 1) {
    _paintStone(
      image,
      centerX: 748,
      centerY: 498,
      width: 10,
      height: 10,
      paletteOffset: index,
    );
  }
  final bytes = Uint8List.fromList(img.encodePng(image));
  sheet.writeAsBytesSync(bytes);
  return (
    root: root,
    sheet: sheet,
    sheetSha256: sha256.convert(bytes).toString(),
  );
}

Future<void> _expectAtomicFailure(
  ({Directory root, File sheet, String sheetSha256}) fixture,
  Matcher messageMatcher,
) async {
  addTearDown(() => fixture.root.delete(recursive: true));
  final projectRoot = await Directory.systemTemp.createTemp(
    'selbrume_two_tier_atomic_guard_',
  );
  addTearDown(() => projectRoot.delete(recursive: true));
  final outputAtlas = File(p.join(projectRoot.path, 'atlas.png'))
    ..writeAsBytesSync(<int>[1, 2, 3]);
  final provenance = File(p.join(projectRoot.path, 'provenance.json'))
    ..writeAsStringSync('sentinel');

  await expectLater(
    buildSelbrumeTwoTierCliffPack(
      SelbrumeTwoTierCliffPackOptions(
        sheet: fixture.sheet,
        projectRoot: projectRoot,
        outputAtlas: outputAtlas,
        provenance: provenance,
        chromaRgb: 0xFF00FF,
        chromaTolerance: 48,
      ),
    ),
    throwsA(
      isA<StateError>().having(
        (error) => error.message,
        'message',
        messageMatcher,
      ),
    ),
  );
  expect(outputAtlas.readAsBytesSync(), <int>[1, 2, 3]);
  expect(provenance.readAsStringSync(), 'sentinel');
  expect(
    Directory(
      p.join(
        projectRoot.path,
        'assets',
        'sources',
        'border_studio',
        'two_tier_cliff_v2',
      ),
    ).existsSync(),
    isFalse,
  );
}

void _paintStone(
  img.Image image, {
  required int centerX,
  required int centerY,
  required int width,
  required int height,
  required int paletteOffset,
  bool forceLightPalette = false,
}) {
  final left = centerX - width ~/ 2;
  final top = centerY - height ~/ 2;
  for (var y = 0; y < height; y += 1) {
    for (var x = 0; x < width; x += 1) {
      if (paletteOffset == 15) {
        final bridgeY = height ~/ 2;
        final upper = y < bridgeY && x < width ~/ 2;
        final bridge =
            y == bridgeY && x >= width ~/ 2 - 1 && x <= width ~/ 2 + 3;
        final lower = y > bridgeY && x >= width ~/ 2 + 3;
        if (!upper && !bridge && !lower) continue;
      }
      if (paletteOffset == 0 &&
          (y == 0 || y == height - 1) &&
          x != width ~/ 2 - 1) {
        continue;
      }
      final inset = y < 3 || y >= height - 3 ? 3 : 0;
      if (x < inset || x >= width - inset) continue;
      final tonePhase = (x * 3 + y * 7 + paletteOffset * 5) % 10;
      final lightPixel = forceLightPalette ||
          (paletteOffset < 12 ? tonePhase < 6 : tonePhase < 4);
      final shade = (paletteOffset + x ~/ 9 + y ~/ 11) % 4;
      final color = _palette[lightPixel ? shade : 4 + shade];
      image.setPixelRgba(
        left + x,
        top + y,
        color.$1,
        color.$2,
        color.$3,
        255,
      );
    }
  }
}

Map<String, (int, int, int, int)> _expectedBoundsByName() {
  final result = <String, (int, int, int, int)>{};
  for (final orientation in _orientations) {
    for (var variant = 1; variant <= 3; variant += 1) {
      // The source sheet contains deliberately narrow individual stones.
      // Keep that cadence: widening them back into 20-24 px modules makes a
      // one-cell coast read as a prefab wall instead of interlocked rocks.
      final topTangent = 10 + variant * 2;
      final topNormal = 8 + variant * 2;
      final faceTangent = 8 + variant * 2;
      // Every face keeps a five-pixel opaque neck under the lip and exposes
      // twenty-two pixels beyond it. Tangent variation still prevents a
      // mechanical picket-fence silhouette without changing cliff height.
      const faceNormal = 27;
      result['top_${orientation}_${variant.toString().padLeft(2, '0')}.png'] =
          _expectedDirectionalBounds(
        orientation: orientation,
        tangent: topTangent,
        normal: topNormal,
      );
      result['face_${orientation}_${variant.toString().padLeft(2, '0')}.png'] =
          _expectedDirectionalBounds(
        orientation: orientation,
        tangent: faceTangent,
        normal: faceNormal,
      );
    }
  }
  return result;
}

Map<String, int> _expectedAnchor(String role, String orientation) {
  final face = role == 'face';
  final anchor = switch (orientation) {
    'n' => (16, face ? 31 : 9),
    'e' => (face ? 0 : 22, 16),
    's' => (16, face ? 0 : 22),
    'w' => (face ? 31 : 9, 16),
    _ => throw ArgumentError.value(orientation),
  };
  return <String, int>{'x': anchor.$1, 'y': anchor.$2};
}

(int, int, int, int) _expectedDirectionalBounds({
  required String orientation,
  required int tangent,
  required int normal,
}) {
  final tangentStart = (32 - tangent) ~/ 2;
  return switch (orientation) {
    'n' => (tangentStart, 0, tangent, normal),
    'e' => (32 - normal, tangentStart, normal, tangent),
    's' => (tangentStart, 32 - normal, tangent, normal),
    'w' => (0, tangentStart, normal, tangent),
    _ => throw ArgumentError.value(orientation),
  };
}

img.Image _decode(Uint8List bytes) {
  final decoded = img.decodePng(bytes);
  if (decoded == null) throw StateError('Expected PNG bytes.');
  return decoded;
}

Set<int> _alphaValues(img.Image image) =>
    <int>{for (final pixel in image) pixel.a.toInt()};

Set<(int, int, int)> _opaqueRgb(img.Image image) => <(int, int, int)>{
      for (final pixel in image)
        if (pixel.a.toInt() != 0)
          (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()),
    };

({int lightOrMedium, int dark}) _tonePermille(img.Image image) {
  var opaque = 0;
  var lightOrMedium = 0;
  for (final pixel in image) {
    if (pixel.a.toInt() == 0) continue;
    opaque += 1;
    final color = (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt());
    if (_palette.take(4).contains(color)) lightOrMedium += 1;
  }
  final lightPermille = (lightOrMedium * 1000 / opaque).round();
  return (lightOrMedium: lightPermille, dark: 1000 - lightPermille);
}

(int, int, int, int) _opaqueBounds(img.Image image) {
  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      if (image.getPixel(x, y).a.toInt() == 0) continue;
      if (x < left) left = x;
      if (y < top) top = y;
      if (x > right) right = x;
      if (y > bottom) bottom = y;
    }
  }
  if (right < left || bottom < top) return (0, 0, 0, 0);
  return (left, top, right - left + 1, bottom - top + 1);
}

int _opaqueComponentCount(img.Image image) {
  final visited = List<bool>.filled(image.width * image.height, false);
  var components = 0;
  for (var y = 0; y < image.height; y += 1) {
    for (var x = 0; x < image.width; x += 1) {
      final index = y * image.width + x;
      if (visited[index] || image.getPixel(x, y).a.toInt() == 0) continue;
      components += 1;
      final pending = <(int, int)>[(x, y)];
      visited[index] = true;
      while (pending.isNotEmpty) {
        final current = pending.removeLast();
        for (final delta in const <(int, int)>[
          (-1, 0),
          (1, 0),
          (0, -1),
          (0, 1),
        ]) {
          final nextX = current.$1 + delta.$1;
          final nextY = current.$2 + delta.$2;
          if (nextX < 0 ||
              nextY < 0 ||
              nextX >= image.width ||
              nextY >= image.height) {
            continue;
          }
          final nextIndex = nextY * image.width + nextX;
          if (visited[nextIndex] ||
              image.getPixel(nextX, nextY).a.toInt() == 0) {
            continue;
          }
          visited[nextIndex] = true;
          pending.add((nextX, nextY));
        }
      }
    }
  }
  return components;
}
