import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../tool/build_selbrume_stone_chain_pack.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds the 16-stone pack byte-for-byte deterministically', () async {
    final fixture = await _createFixtureProject();
    final firstOutput = await Directory.systemTemp.createTemp(
      'selbrume_stone_chain_first_',
    );
    final secondOutput = await Directory.systemTemp.createTemp(
      'selbrume_stone_chain_second_',
    );
    addTearDown(() => fixture.delete(recursive: true));
    addTearDown(() => firstOutput.delete(recursive: true));
    addTearDown(() => secondOutput.delete(recursive: true));

    final sourceBytesBefore = await _sourceBytes(fixture);
    final first = await buildSelbrumeStoneChainPack(
      SelbrumeStoneChainPackOptions(
        projectRoot: fixture,
        outputDirectory: firstOutput,
        manifestFile: File(p.join(firstOutput.path, 'manifest.json')),
      ),
    );
    final second = await buildSelbrumeStoneChainPack(
      SelbrumeStoneChainPackOptions(
        projectRoot: fixture,
        outputDirectory: secondOutput,
        manifestFile: File(p.join(secondOutput.path, 'manifest.json')),
      ),
    );

    expect(first.entryCount, 16);
    expect(second.entryCount, 16);
    expect(first.atlasSha256, second.atlasSha256);
    expect(
      first.atlasFile.readAsBytesSync(),
      orderedEquals(second.atlasFile.readAsBytesSync()),
    );
    expect(
      first.manifestFile.readAsBytesSync(),
      orderedEquals(second.manifestFile.readAsBytesSync()),
    );
    expect(
      first.atlasSha256,
      sha256.convert(first.atlasFile.readAsBytesSync()).toString(),
    );
    expect(await _sourceBytes(fixture), sourceBytesBefore);

    final atlas = _decode(first.atlasFile.readAsBytesSync());
    expect((atlas.width, atlas.height), (128, 128));
    expect(atlas.numChannels, 4);
    final alphaValues = <int>{};
    for (final pixel in atlas) {
      alphaValues.add(pixel.a.toInt());
    }
    expect(alphaValues, containsAll(<int>[0, 255]));
    expect(alphaValues.difference(<int>{0, 255}), isEmpty);

    final manifest = jsonDecode(first.manifestFile.readAsStringSync())
        as Map<String, dynamic>;
    expect(manifest['schemaVersion'], 1);
    expect(manifest['atlasId'], 'ts_selbrume_cliff_stone_chain_v1');
    expect(manifest['atlasSha256'], first.atlasSha256);
    expect(manifest['referenceImagesUsedAsUnderlays'], isFalse);
    expect(manifest['collisionIntent'], 'visual_only_no_collision');
    expect(manifest['tileSize'], <String, dynamic>{'width': 32, 'height': 32});
    expect(manifest['grid'], <String, dynamic>{'columns': 4, 'rows': 4});

    final entries =
        (manifest['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
    expect(entries, hasLength(16));
    expect(entries.map((entry) => entry['id']).toSet(), hasLength(16));
    expect(
      entries.map((entry) => entry['sourceRelativePath']).toSet(),
      hasLength(16),
    );
    expect(
      entries.map((entry) => entry['sourceSha256']).toSet(),
      hasLength(16),
    );
    expect(
      entries.map((entry) => entry['normalizedSha256']).toSet(),
      hasLength(16),
    );
    for (var index = 0; index < entries.length; index += 1) {
      final entry = entries[index];
      expect(entry['anchor'], <String, dynamic>{'x': 16, 'y': 29});
      expect(entry['collisionIntent'], 'visual_only_no_collision');
      expect(entry['licenseStatus'], 'unverified');
      expect(entry['prompt'], isNotEmpty);
      expect(
        entry['atlasCell'],
        <String, dynamic>{
          'column': index % 4,
          'row': index ~/ 4,
          'widthCells': 1,
          'heightCells': 1,
        },
      );
      final footprint = entry['opaqueFootprintPx'] as Map<String, dynamic>;
      expect(footprint['width'], greaterThan(0));
      expect(footprint['height'], greaterThan(0));
    }
  });

  test('rebuilds the checked-in Selbrume pack from its real sources', () async {
    final projectRoot = _realSelbrumeProjectRoot();
    final output = await Directory.systemTemp.createTemp(
      'selbrume_stone_chain_real_sources_',
    );
    addTearDown(() => output.delete(recursive: true));

    final committedAtlas = File(
      p.join(
        projectRoot.path,
        'assets',
        'tilesets',
        selbrumeStoneChainAtlasFileName,
      ),
    );
    final committedManifest = File(
      p.join(
        projectRoot.path,
        'assets',
        'provenance',
        'selbrume_stone_chain_v1.json',
      ),
    );
    final sourceBytesBefore = await _sourceBytes(projectRoot);
    final committedAtlasBefore = committedAtlas.readAsBytesSync();
    final committedManifestBefore = committedManifest.readAsBytesSync();

    final rebuilt = await buildSelbrumeStoneChainPack(
      SelbrumeStoneChainPackOptions(
        projectRoot: projectRoot,
        outputDirectory: output,
        manifestFile: File(p.join(output.path, 'manifest.json')),
      ),
    );

    expect(rebuilt.entryCount, 16);
    expect(
      rebuilt.atlasFile.readAsBytesSync(),
      orderedEquals(committedAtlasBefore),
    );
    expect(
      rebuilt.manifestFile.readAsBytesSync(),
      orderedEquals(committedManifestBefore),
    );
    expect(await _sourceBytes(projectRoot), sourceBytesBefore);
    expect(
        committedAtlas.readAsBytesSync(), orderedEquals(committedAtlasBefore));
    expect(
      committedManifest.readAsBytesSync(),
      orderedEquals(committedManifestBefore),
    );

    final manifest = jsonDecode(rebuilt.manifestFile.readAsStringSync())
        as Map<String, dynamic>;
    final entries =
        (manifest['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
    final byId = <String, Map<String, dynamic>>{
      for (final entry in entries) entry['id'] as String: entry,
    };
    for (final id in const <String>[
      'stone_chain_corner_01',
      'stone_chain_corner_02',
    ]) {
      final footprint = byId[id]!['opaqueFootprintPx'] as Map<String, dynamic>;
      final width = footprint['width'] as int;
      final height = footprint['height'] as int;
      expect(width, inInclusiveRange(15, 17), reason: id);
      expect(height, inInclusiveRange(14, 16), reason: id);
      expect(
        width,
        greaterThan(height),
        reason: '$id must stay low and rounded, never vertical or cubic.',
      );
    }
    for (final id in const <String>[
      'stone_chain_cap_01',
      'stone_chain_cap_02',
    ]) {
      final footprint = byId[id]!['opaqueFootprintPx'] as Map<String, dynamic>;
      final width = footprint['width'] as int;
      final height = footprint['height'] as int;
      expect(width, inInclusiveRange(7, 8), reason: id);
      expect(height, inInclusiveRange(6, 8), reason: id);
      expect(
        width,
        greaterThanOrEqualTo(height),
        reason: '$id must be a compact pebble, not a diagonal sliver.',
      );
    }
  });

  test('corrective sheet replaces only two corners and two caps', () async {
    final fixture = await _createFixtureProject();
    final correctiveDirectory = await Directory.systemTemp.createTemp(
      'selbrume_stone_chain_corrective_',
    );
    final correctiveSheet = File(
      p.join(correctiveDirectory.path, 'corrective-sheet-alpha.png'),
    )..writeAsBytesSync(_correctiveSheetPng());
    addTearDown(() => fixture.delete(recursive: true));
    addTearDown(() => correctiveDirectory.delete(recursive: true));

    final before = await _sourceBytes(fixture);
    final written = await applySelbrumeStoneChainCorrectiveSheet(
      projectRoot: fixture,
      chromaRemovedContactSheet: correctiveSheet,
    );
    final after = await _sourceBytes(fixture);

    expect(
      written.map((file) => p.basename(file.path)).toSet(),
      <String>{'corner_01.png', 'corner_02.png', 'cap_01.png', 'cap_02.png'},
    );
    expect(
      <String>{
        for (final name in _sourceNames)
          if (before[name] != after[name]) name,
      },
      <String>{'corner_01.png', 'corner_02.png', 'cap_01.png', 'cap_02.png'},
    );

    final output = await Directory.systemTemp.createTemp(
      'selbrume_stone_chain_corrected_build_',
    );
    addTearDown(() => output.delete(recursive: true));
    final built = await buildSelbrumeStoneChainPack(
      SelbrumeStoneChainPackOptions(
        projectRoot: fixture,
        outputDirectory: output,
        manifestFile: File(p.join(output.path, 'manifest.json')),
      ),
    );
    final manifest = jsonDecode(built.manifestFile.readAsStringSync())
        as Map<String, dynamic>;
    final entries =
        (manifest['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
    final footprints = <String, (int, int)>{
      for (final entry in entries)
        entry['id'] as String: (
          (entry['opaqueFootprintPx'] as Map<String, dynamic>)['width'] as int,
          (entry['opaqueFootprintPx'] as Map<String, dynamic>)['height'] as int,
        ),
    };
    expect(footprints['stone_chain_corner_01'], (22, 16));
    expect(footprints['stone_chain_corner_02'], (20, 15));
    expect(footprints['stone_chain_cap_01'], (11, 8));
    expect(footprints['stone_chain_cap_02'], (9, 7));
  });

  test('replacement sheet rebuilds all stones and removes chroma', () async {
    final fixture = await _createFixtureProject();
    final replacementDirectory = await Directory.systemTemp.createTemp(
      'selbrume_stone_chain_replacement_',
    );
    final replacementSheet = File(
      p.join(replacementDirectory.path, 'replacement-sheet-magenta.png'),
    )..writeAsBytesSync(_replacementSheetPng());
    addTearDown(() => fixture.delete(recursive: true));
    addTearDown(() => replacementDirectory.delete(recursive: true));

    final before = await _sourceBytes(fixture);
    final written = await applySelbrumeStoneChainReplacementSheet(
      projectRoot: fixture,
      rawContactSheet: replacementSheet,
    );
    final after = await _sourceBytes(fixture);

    expect(written.map((file) => p.basename(file.path)), _sourceNames);
    expect(
      <String>{
        for (final name in _sourceNames)
          if (before[name] != after[name]) name,
      },
      _sourceNames.toSet(),
    );
    for (var index = 0; index < _sourceNames.length; index += 1) {
      final source = _decode(
        File(
          p.join(
            fixture.path,
            'assets',
            'sources',
            'border_studio',
            'stone_chain_v1',
            _sourceNames[index],
          ),
        ).readAsBytesSync(),
      );
      var opaqueCount = 0;
      var transparentCount = 0;
      var partialAlphaCount = 0;
      var minX = source.width;
      var maxX = -1;
      var minY = source.height;
      var maxY = -1;
      for (final pixel in source) {
        final alpha = pixel.a.toInt();
        if (alpha == 0) {
          transparentCount += 1;
        } else if (alpha == 255) {
          opaqueCount += 1;
          minX = minX < pixel.x ? minX : pixel.x;
          maxX = maxX > pixel.x ? maxX : pixel.x;
          minY = minY < pixel.y ? minY : pixel.y;
          maxY = maxY > pixel.y ? maxY : pixel.y;
        } else {
          partialAlphaCount += 1;
        }
      }
      expect(opaqueCount, greaterThan(0), reason: _sourceNames[index]);
      expect(transparentCount, greaterThan(0), reason: _sourceNames[index]);
      expect(partialAlphaCount, 0, reason: _sourceNames[index]);
      expect(
        _opaqueComponentCount(source),
        1,
        reason: '${_sourceNames[index]} must contain exactly one isolated '
            'stone even when source rows cross nominal quarter-cell bounds.',
      );
      final expected = _replacementFootprints[index];
      expect(
        opaqueCount,
        lessThan(expected.$1 * expected.$2 * 9 ~/ 10),
        reason: '${_sourceNames[index]} must not quantize the chroma matte '
            'into one opaque rectangle.',
      );
      expect(
        maxX - minX + 1,
        inInclusiveRange(expected.$1 - 1, expected.$1),
        reason: _sourceNames[index],
      );
      expect(
        maxY - minY + 1,
        inInclusiveRange(expected.$2 - 1, expected.$2),
        reason: _sourceNames[index],
      );
    }
  });
}

const _sourceNames = <String>[
  'primary_01.png',
  'primary_02.png',
  'primary_03.png',
  'primary_04.png',
  'primary_05.png',
  'secondary_01.png',
  'secondary_02.png',
  'secondary_03.png',
  'secondary_04.png',
  'filler_01.png',
  'filler_02.png',
  'filler_03.png',
  'corner_01.png',
  'corner_02.png',
  'cap_01.png',
  'cap_02.png',
];

const _footprints = <(int, int)>[
  (16, 10),
  (17, 11),
  (18, 13),
  (20, 15),
  (22, 17),
  (12, 8),
  (13, 10),
  (15, 12),
  (18, 14),
  (5, 4),
  (7, 6),
  (10, 8),
  (20, 14),
  (18, 13),
  (11, 8),
  (9, 7),
];

const _replacementFootprints = <(int, int)>[
  (19, 14),
  (18, 17),
  (18, 17),
  (19, 14),
  (17, 17),
  (14, 14),
  (14, 14),
  (14, 13),
  (14, 10),
  (6, 6),
  (7, 6),
  (6, 5),
  (17, 15),
  (17, 14),
  (8, 8),
  (7, 7),
];

const _palette = <(int, int, int)>[
  (48, 45, 40),
  (62, 58, 51),
  (77, 72, 62),
  (91, 85, 72),
  (108, 101, 84),
  (126, 118, 96),
  (145, 136, 109),
  (166, 156, 123),
];

Directory _realSelbrumeProjectRoot() {
  var cursor = Directory(p.normalize(p.absolute(Directory.current.path)));
  while (true) {
    final candidate = Directory(p.join(cursor.path, 'selbrume'));
    final sourceDirectory = Directory(
      p.join(
        candidate.path,
        'assets',
        'sources',
        'border_studio',
        'stone_chain_v1',
      ),
    );
    if (sourceDirectory.existsSync()) {
      return candidate;
    }
    final parent = cursor.parent;
    if (parent.path == cursor.path) {
      throw StateError(
        'Could not locate the checked-in Selbrume stone-chain sources from '
        '${Directory.current.path}.',
      );
    }
    cursor = parent;
  }
}

Future<Directory> _createFixtureProject() async {
  final root = await Directory.systemTemp.createTemp(
    'selbrume_stone_chain_fixture_',
  );
  final sourceDirectory = Directory(
    p.join(
      root.path,
      'assets',
      'sources',
      'border_studio',
      'stone_chain_v1',
    ),
  )..createSync(recursive: true);
  for (var index = 0; index < _sourceNames.length; index += 1) {
    File(p.join(sourceDirectory.path, _sourceNames[index])).writeAsBytesSync(
      _stonePng(index, _footprints[index].$1, _footprints[index].$2),
    );
  }
  return root;
}

Uint8List _stonePng(int variant, int width, int height) {
  final image = img.Image(width: 32, height: 32, numChannels: 4);
  final left = (32 - width) ~/ 2;
  final top = 30 - height;
  final base = _palette[(variant + 2) % _palette.length];
  final light = _palette[(variant + 4) % _palette.length];
  final dark = _palette[variant % 3];
  for (var y = 0; y < height; y += 1) {
    final inset = y == 0 || y == height - 1
        ? 2
        : y == 1
            ? 1
            : 0;
    for (var x = inset; x < width - inset; x += 1) {
      final color = y < height ~/ 3 && x < width * 2 ~/ 3
          ? light
          : (y >= height - 2 || x >= width - 2 ? dark : base);
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
  image.setPixelRgba(left, top + height ~/ 2, base.$1, base.$2, base.$3, 255);
  image.setPixelRgba(
    left + width - 1,
    top + height ~/ 2,
    dark.$1,
    dark.$2,
    dark.$3,
    255,
  );
  image.setPixelRgba(
    16,
    29,
    dark.$1,
    dark.$2,
    dark.$3,
    255,
  );
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _correctiveSheetPng() {
  final image = img.Image(width: 256, height: 256, numChannels: 4);
  _paintCorrectiveStone(
    image,
    centerX: 64,
    bottomY: 112,
    width: 76,
    height: 48,
    variant: 1,
  );
  _paintCorrectiveStone(
    image,
    centerX: 192,
    bottomY: 112,
    width: 72,
    height: 48,
    variant: 2,
  );
  _paintCorrectiveStone(
    image,
    centerX: 64,
    bottomY: 240,
    width: 44,
    height: 34,
    variant: 3,
  );
  _paintCorrectiveStone(
    image,
    centerX: 192,
    bottomY: 240,
    width: 40,
    height: 32,
    variant: 4,
  );
  return Uint8List.fromList(img.encodePng(image));
}

Uint8List _replacementSheetPng() {
  final image = img.Image(width: 512, height: 512, numChannels: 4);
  for (final pixel in image) {
    pixel
      ..r = 240
      ..g = 145
      ..b = 225
      ..a = 255;
  }
  for (var index = 0; index < 16; index += 1) {
    final cellX = index % 4;
    final cellY = index ~/ 4;
    _paintCorrectiveStone(
      image,
      centerX: cellX * 128 + 64,
      // The first visual row deliberately crosses the nominal quarter-cell
      // boundary while remaining isolated from row two. Image-generated
      // contact sheets commonly have uneven gutters, so extraction must use
      // the sixteen stone components rather than destructive fixed crops.
      bottomY: cellY * 128 + (cellY == 0 ? 136 : 108),
      width: 48 + index,
      height: 28 + index % 5,
      variant: index,
    );
  }
  return Uint8List.fromList(img.encodePng(image));
}

void _paintCorrectiveStone(
  img.Image image, {
  required int centerX,
  required int bottomY,
  required int width,
  required int height,
  required int variant,
}) {
  final left = centerX - width ~/ 2;
  final top = bottomY - height + 1;
  for (var y = 0; y < height; y += 1) {
    final normalizedY = (y * 2 - height + 1) / height;
    for (var x = 0; x < width; x += 1) {
      final normalizedX = (x * 2 - width + 1) / width;
      if (normalizedX * normalizedX + normalizedY * normalizedY > 1) {
        continue;
      }
      final color = normalizedY < -0.15 && normalizedX < 0.35
          ? _palette[(variant + 5) % _palette.length]
          : normalizedY > 0.5 || normalizedX > 0.6
              ? _palette[variant % 3]
              : _palette[(variant + 3) % _palette.length];
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

Future<Map<String, String>> _sourceBytes(Directory root) async {
  final sourceDirectory = Directory(
    p.join(
      root.path,
      'assets',
      'sources',
      'border_studio',
      'stone_chain_v1',
    ),
  );
  final result = <String, String>{};
  for (final name in _sourceNames) {
    result[name] = base64Encode(
      File(p.join(sourceDirectory.path, name)).readAsBytesSync(),
    );
  }
  return result;
}

img.Image _decode(Uint8List bytes) {
  final decoded = img.decodePng(bytes);
  if (decoded == null) {
    throw StateError('Generated bytes are not a PNG.');
  }
  return decoded;
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
        for (var deltaY = -1; deltaY <= 1; deltaY += 1) {
          for (var deltaX = -1; deltaX <= 1; deltaX += 1) {
            if (deltaX == 0 && deltaY == 0) continue;
            final nextX = current.$1 + deltaX;
            final nextY = current.$2 + deltaY;
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
  }
  return components;
}
