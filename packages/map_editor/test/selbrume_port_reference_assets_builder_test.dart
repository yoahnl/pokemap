import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../tool/build_selbrume_port_reference_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds the Port reference family deterministically without underlay',
      () async {
    final fixture = _copyFixture();
    addTearDown(() => fixture.parent.delete(recursive: true));

    final dryRun = await buildSelbrumePortReferenceAssets(
      SelbrumePortReferenceAssetOptions(projectRoot: fixture),
    );
    expect(dryRun.exitCode, selbrumePortReferenceAssetDivergenceExitCode);
    expect(dryRun.divergentRelativePaths, hasLength(4));
    expect(
      File(p.join(fixture.path, selbrumePortReferenceSpriteAtlasPath))
          .existsSync(),
      isFalse,
    );

    final first = await buildSelbrumePortReferenceAssets(
      SelbrumePortReferenceAssetOptions(projectRoot: fixture, write: true),
    );
    expect(first.exitCode, 0);
    expect(first.entryCount, 35);
    final firstHashes = await _outputHashes(fixture);

    final second = await buildSelbrumePortReferenceAssets(
      SelbrumePortReferenceAssetOptions(projectRoot: fixture, write: true),
    );
    final clean = await buildSelbrumePortReferenceAssets(
      SelbrumePortReferenceAssetOptions(projectRoot: fixture),
    );
    expect(second.exitCode, 0);
    expect(clean.exitCode, 0);
    expect(clean.divergentRelativePaths, isEmpty);
    expect(await _outputHashes(fixture), firstHashes);

    final manifest = jsonDecode(
      File(p.join(fixture.path, selbrumePortReferenceManifestPath))
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    expect(manifest['status'], 'candidate_pending_owner_approval');
    expect(
      (manifest['referenceOnlySource'] as Map)['runtimeUnderlay'],
      isFalse,
    );
    final entries = (manifest['entries'] as List).cast<Map>();
    expect(entries, hasLength(35));
    _expectPublishedEntryRectsStayFixed(entries);
    _expectTileModulesAreAppendOnly(
      manifest: manifest,
      spriteAtlas: _decode(
        fixture,
        selbrumePortReferenceSpriteAtlasPath,
      ),
    );
    expect(
      (((manifest['atlases'] as Map)['water'] as Map)['frameDurationMs']),
      180,
    );
    expect(manifest, isNot(contains('pavementTextureSources')));
    expect(
      manifest['nativePavementPath'],
      containsPair('presetId', 'pavement_path'),
    );
    expect(
      manifest['nativePavementPath'],
      containsPair('tilesetId', 'pavement_path'),
    );
    expect(
      (manifest['entries'] as List)
          .cast<Map>()
          .every((entry) => entry['source'] is Map),
      isTrue,
    );

    final spriteAtlas = _decode(
      fixture,
      selbrumePortReferenceSpriteAtlasPath,
    );
    expect(spriteAtlas.width % 32, 0);
    expect(spriteAtlas.height % 32, 0);
    expect(_hasRealAlpha(spriteAtlas), isTrue);
    expect(_hasOpaqueMagenta(spriteAtlas), isFalse);

    final ground = _decode(fixture, selbrumePortReferenceGroundAtlasPath);
    expect((ground.width, ground.height), (2112, 32));
    final water = _decode(fixture, selbrumePortReferenceWaterAtlasPath);
    expect((water.width, water.height), (2048, 256));
    _expectWaterFramesTileAndLoop(water);
    _expectWaterUsesLayeredCurvedWavelets(water);
  });
}

void _expectPublishedEntryRectsStayFixed(List<Map> entries) {
  final actual = <String, Map<String, Object?>>{
    for (final entry in entries)
      entry['id']! as String:
          Map<String, Object?>.from(entry['source']! as Map),
  };
  expect(actual, _publishedEntrySources);
}

void _expectTileModulesAreAppendOnly({
  required Map<String, dynamic> manifest,
  required img.Image spriteAtlas,
}) {
  final atlas = (manifest['atlases'] as Map)['sprites'] as Map;
  final atlasWidthCells = atlas['widthCells']! as int;
  final atlasHeightCells = atlas['heightCells']! as int;
  expect(atlasWidthCells, 48);
  expect(atlasHeightCells, greaterThan(44));
  expect(
    manifest['tileModuleGeneration'],
    containsPair('generativeArt', false),
  );
  expect(
    manifest['tileModuleGeneration'],
    containsPair('packing', 'append_only_after_published_entries'),
  );

  final modules = (manifest['tileModules'] as List).cast<Map>();
  expect(
    modules.map((module) => module['id']).toList(),
    _expectedTileModuleIds,
  );
  final occupiedTileIds = <int>{};
  for (final module in modules) {
    final source = module['source']! as Map;
    final x = source['x']! as int;
    final y = source['y']! as int;
    final width = source['width']! as int;
    final height = source['height']! as int;
    expect(x, inInclusiveRange(0, atlasWidthCells - 1));
    expect(y, greaterThanOrEqualTo(44));
    expect(width, greaterThan(0));
    expect(height, greaterThan(0));
    expect(x + width, lessThanOrEqualTo(atlasWidthCells));
    expect(y + height, lessThanOrEqualTo(atlasHeightCells));

    final expectedTileIds = <int>[
      for (var localY = 0; localY < height; localY += 1)
        for (var localX = 0; localX < width; localX += 1)
          (y + localY) * atlasWidthCells + x + localX + 1,
    ];
    expect(module['tileIds'], expectedTileIds);
    for (final tileId in expectedTileIds) {
      expect(
        occupiedTileIds.add(tileId),
        isTrue,
        reason: 'tile modules must not overlap in the atlas',
      );
    }
    expect(module['sha256'], matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(module['futurePlacement'], isNotEmpty);
    final derivation = module['derivation']! as Map;
    expect(derivation['kind'], isNotEmpty);
    expect(
      (derivation['sourceSheets'] as List).isNotEmpty ||
          (derivation['sourceEntries'] as List).isNotEmpty,
      isTrue,
      reason: '${module['id']} must name a sheet or published entry source',
    );
    expect(derivation['generativeArt'], isFalse);
    expect(
      _moduleHasOpaquePixel(
        spriteAtlas,
        x: x,
        y: y,
        width: width,
        height: height,
      ),
      isTrue,
      reason: '${module['id']} must contain visible pixels',
    );
  }

  final gardenBoundaryIds = <String>{
    'module_port_ref_wall_h_short',
    'module_port_ref_wall_h_long',
    'module_port_ref_wall_end_left',
    'module_port_ref_wall_end_right',
    'module_port_ref_garden_gate_open',
  };
  for (final module in modules.where(
    (candidate) => gardenBoundaryIds.contains(candidate['id']),
  )) {
    final derivation = module['derivation']! as Map;
    expect(
      derivation['sourceEntries'],
      contains('el_port_ref_walled_garden'),
      reason: '${module['id']} must reuse the low garden language',
    );
  }
}

bool _moduleHasOpaquePixel(
  img.Image atlas, {
  required int x,
  required int y,
  required int width,
  required int height,
}) {
  for (var pixelY = y * 32; pixelY < (y + height) * 32; pixelY += 1) {
    for (var pixelX = x * 32; pixelX < (x + width) * 32; pixelX += 1) {
      if (atlas.getPixel(pixelX, pixelY).a.toInt() > 0) return true;
    }
  }
  return false;
}

const List<String> _expectedTileModuleIds = <String>[
  'module_port_ref_wall_h_short',
  'module_port_ref_wall_h_long',
  'module_port_ref_wall_end_left',
  'module_port_ref_wall_end_right',
  'module_port_ref_garden_gate_open',
  'module_port_ref_flower_bed_compact',
  'module_port_ref_quay_steps_compact',
  'module_port_ref_quay_pier_join',
  'module_port_ref_pier_endcap',
  'module_port_ref_coast_east_complete',
  'module_port_ref_coast_quay_join',
  'module_port_ref_coast_quay_join_mirrored',
  'module_port_ref_foam_h_short',
  'module_port_ref_foam_corner',
  'module_port_ref_foam_wake_short',
];

const Map<String, Map<String, Object?>> _publishedEntrySources =
    <String, Map<String, Object?>>{
  'el_port_ref_harbor_master': {'x': 0, 'y': 0, 'width': 8, 'height': 6},
  'el_port_ref_house_orange': {'x': 8, 'y': 0, 'width': 7, 'height': 5},
  'el_port_ref_house_blue': {'x': 15, 'y': 0, 'width': 7, 'height': 5},
  'el_port_ref_fish_market': {'x': 22, 'y': 0, 'width': 8, 'height': 6},
  'el_port_ref_chandlery': {'x': 30, 'y': 0, 'width': 8, 'height': 6},
  'el_port_ref_quay_horizontal': {'x': 0, 'y': 6, 'width': 12, 'height': 4},
  'el_port_ref_pier_t': {'x': 12, 'y': 6, 'width': 9, 'height': 9},
  'el_port_ref_pier_vertical': {'x': 21, 'y': 6, 'width': 5, 'height': 9},
  'el_port_ref_boat_large': {'x': 26, 'y': 6, 'width': 10, 'height': 5},
  'el_port_ref_boat_medium': {'x': 36, 'y': 6, 'width': 8, 'height': 4},
  'el_port_ref_boat_small': {'x': 0, 'y': 15, 'width': 6, 'height': 4},
  'el_port_ref_forest_cluster': {'x': 6, 'y': 15, 'width': 11, 'height': 7},
  'el_port_ref_tree': {'x': 17, 'y': 15, 'width': 5, 'height': 6},
  'el_port_ref_walled_garden': {'x': 22, 'y': 15, 'width': 7, 'height': 5},
  'el_port_ref_flower_bed': {'x': 29, 'y': 15, 'width': 8, 'height': 4},
  'el_port_ref_rock_cluster': {'x': 37, 'y': 15, 'width': 6, 'height': 4},
  'el_port_ref_coast_west_continuous': {
    'x': 0,
    'y': 22,
    'width': 8,
    'height': 19
  },
  'el_port_ref_coast_east_peninsula': {
    'x': 8,
    'y': 22,
    'width': 9,
    'height': 5
  },
  'el_port_ref_quay_steps': {'x': 17, 'y': 22, 'width': 7, 'height': 7},
  'el_port_ref_foam_quay_horizontal': {
    'x': 24,
    'y': 22,
    'width': 12,
    'height': 2
  },
  'el_port_ref_foam_rock_cluster': {'x': 36, 'y': 22, 'width': 6, 'height': 4},
  'el_port_ref_foam_boat_wake': {'x': 42, 'y': 22, 'width': 4, 'height': 2},
  'el_port_ref_fish_crates_small': {'x': 46, 'y': 22, 'width': 2, 'height': 2},
  'el_port_ref_rope_coil_small': {'x': 0, 'y': 41, 'width': 2, 'height': 2},
  'el_port_ref_net_rack_small': {'x': 2, 'y': 41, 'width': 2, 'height': 3},
  'el_port_ref_fish_basket_small': {'x': 4, 'y': 41, 'width': 2, 'height': 2},
  'el_port_ref_lobster_pots_small': {'x': 6, 'y': 41, 'width': 2, 'height': 2},
  'el_port_ref_barrel_buoy_small': {'x': 8, 'y': 41, 'width': 2, 'height': 2},
  'el_port_ref_nest': {'x': 10, 'y': 41, 'width': 2, 'height': 2},
  'el_port_ref_lamp': {'x': 12, 'y': 41, 'width': 1, 'height': 3},
  'el_port_ref_bench': {'x': 13, 'y': 41, 'width': 3, 'height': 2},
  'el_port_ref_sign_small': {'x': 16, 'y': 41, 'width': 2, 'height': 2},
  'el_port_ref_rock_small': {'x': 18, 'y': 41, 'width': 1, 'height': 1},
  'el_port_ref_rock_pair': {'x': 19, 'y': 41, 'width': 2, 'height': 2},
  'el_port_ref_rock_trio': {'x': 21, 'y': 41, 'width': 3, 'height': 2},
};

void _expectWaterUsesLayeredCurvedWavelets(img.Image water) {
  const frameSize = 256;
  var diagonalCrestPairs = 0;
  var crestsWithShadow = 0;
  for (var frame = 0; frame < 8; frame += 1) {
    final originX = frame * frameSize;
    for (var y = 2; y < frameSize - 2; y += 1) {
      for (var x = 1; x < frameSize - 1; x += 1) {
        final pixel = water.getPixel(originX + x, y);
        if (!_isWaterCrest(pixel)) continue;
        if (_isWaterCrest(water.getPixel(originX + x + 1, y - 1)) ||
            _isWaterCrest(water.getPixel(originX + x + 1, y + 1))) {
          diagonalCrestPairs += 1;
        }
        if (_isWaterShadow(water.getPixel(originX + x, y + 1)) ||
            _isWaterShadow(water.getPixel(originX + x, y + 2))) {
          crestsWithShadow += 1;
        }
      }
    }
  }
  expect(
    diagonalCrestPairs,
    greaterThan(24),
    reason: 'wave crests must bend instead of blinking as straight dashes',
  );
  expect(
    crestsWithShadow,
    greaterThan(24),
    reason: 'wave crests need a restrained darker underside for depth',
  );
}

bool _isWaterCrest(img.Pixel pixel) {
  return pixel.r.toInt() >= 55 &&
      pixel.g.toInt() >= 140 &&
      pixel.b.toInt() >= 200;
}

bool _isWaterShadow(img.Pixel pixel) {
  return pixel.r.toInt() <= 14 &&
      pixel.g.toInt() <= 80 &&
      pixel.b.toInt() <= 155;
}

Directory _copyFixture() {
  final repositoryRoot = _findRepositoryRoot();
  final sourceRoot = Directory(
    p.join(
      repositoryRoot.path,
      'selbrume',
      'assets',
      'sources',
      'port_reference_v3',
    ),
  );
  final parent = Directory.systemTemp.createTempSync('port_ref_assets_');
  final fixture = Directory(p.join(parent.path, 'selbrume'))..createSync();
  File(p.join(fixture.path, 'project.json')).writeAsStringSync('{}');
  final targetRoot = Directory(
    p.join(fixture.path, 'assets', 'sources', 'port_reference_v3'),
  )..createSync(recursive: true);
  for (final source in sourceRoot.listSync().whereType<File>()) {
    source.copySync(p.join(targetRoot.path, p.basename(source.path)));
  }
  return fixture;
}

img.Image _decode(Directory fixture, String relativePath) {
  final decoded = img.decodePng(
    File(p.join(fixture.path, relativePath)).readAsBytesSync(),
  );
  if (decoded == null) throw StateError('Invalid PNG: $relativePath');
  return decoded;
}

bool _hasRealAlpha(img.Image image) {
  var transparent = false;
  var opaque = false;
  for (final pixel in image) {
    transparent |= pixel.a.toInt() == 0;
    opaque |= pixel.a.toInt() == 255;
    if (transparent && opaque) return true;
  }
  return false;
}

bool _hasOpaqueMagenta(img.Image image) {
  for (final pixel in image) {
    if (pixel.a.toInt() > 0 &&
        pixel.r.toInt() > 230 &&
        pixel.g.toInt() < 30 &&
        pixel.b.toInt() > 220) {
      return true;
    }
  }
  return false;
}

void _expectWaterFramesTileAndLoop(img.Image water) {
  const frameSize = 256;
  for (var frame = 0; frame < 8; frame += 1) {
    final originX = frame * frameSize;
    for (var y = 0; y < frameSize; y += 1) {
      expect(
        water.getPixel(originX, y),
        water.getPixel(originX + frameSize - 1, y),
        reason: 'horizontal seam frame $frame row $y',
      );
    }
    for (var x = 0; x < frameSize; x += 1) {
      expect(
        water.getPixel(originX + x, 0),
        water.getPixel(originX + x, frameSize - 1),
        reason: 'vertical seam frame $frame column $x',
      );
    }
  }
  for (var frame = 0; frame < 8; frame += 1) {
    final delta = _meanDelta(water, frame, (frame + 1) % 8);
    expect(delta, greaterThan(0.01), reason: 'water frame $frame is animated');
    expect(delta, lessThan(1), reason: 'water frame $frame stays subtle');
  }
}

double _meanDelta(img.Image image, int leftFrame, int rightFrame) {
  const frameSize = 256;
  var total = 0;
  var samples = 0;
  for (var y = 0; y < frameSize; y += 4) {
    for (var x = 0; x < frameSize; x += 4) {
      final left = image.getPixel(leftFrame * frameSize + x, y);
      final right = image.getPixel(rightFrame * frameSize + x, y);
      total += (left.r.toInt() - right.r.toInt()).abs();
      total += (left.g.toInt() - right.g.toInt()).abs();
      total += (left.b.toInt() - right.b.toInt()).abs();
      samples += 3;
    }
  }
  return total / samples;
}

Future<Map<String, String>> _outputHashes(Directory fixture) async {
  final output = <String, String>{};
  for (final path in <String>[
    selbrumePortReferenceSpriteAtlasPath,
    selbrumePortReferenceGroundAtlasPath,
    selbrumePortReferenceWaterAtlasPath,
    selbrumePortReferenceManifestPath,
  ]) {
    final result = await Process.run(
      'shasum',
      <String>['-a', '256', p.join(fixture.path, path)],
    );
    expect(result.exitCode, 0);
    output[path] = result.stdout.toString().trim().split(RegExp(r'\s+')).first;
  }
  return output;
}

Directory _findRepositoryRoot() {
  var current = Directory.current.absolute;
  while (true) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        Directory(p.join(current.path, 'selbrume')).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('Repository root not found.');
    }
    current = current.parent;
  }
}
