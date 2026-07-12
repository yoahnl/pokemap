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
    expect((manifest['entries'] as List), hasLength(35));
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
