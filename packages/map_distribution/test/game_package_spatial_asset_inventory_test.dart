import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void main() {
  const logicalPaths = {
    'project/assets/hero.png',
    'project/assets/models3d/model.glb',
  };

  test('a verified inventory proves logical copies without reading them', () {
    final files = spatialPayload();
    final reads = <String>[];
    _validate(files, reads, inventory: _inventory(files));
    expect(reads.toSet().intersection(logicalPaths), isEmpty);
    expect(reads.where((path) => path.endsWith('.blob')), hasLength(2));
  });

  test('without an inventory logical copies are still read and compared', () {
    final files = spatialPayload();
    final reads = <String>[];
    _validate(files, reads);
    expect(reads.toSet(), containsAll(logicalPaths));
  });

  test('an inventory without the logical entry falls back to reading it', () {
    final files = spatialPayload();
    final reads = <String>[];
    final inventory = _inventory(files)
      ..removeWhere((entry) => entry.path == 'project/assets/hero.png');
    _validate(files, reads, inventory: inventory);
    expect(reads, contains('project/assets/hero.png'));
    expect(reads, isNot(contains('project/assets/models3d/model.glb')));
  });

  for (final withInventory in [true, false]) {
    test(
        'a logical copy that differs from its blob is rejected '
        '${withInventory ? 'with' : 'without'} an inventory', () {
      final files = spatialPayload();
      files['project/assets/hero.png'] =
          img.encodePng(img.Image(width: 32, height: 32, numChannels: 4));
      expect(
          () => _validate(files, [],
              inventory: withInventory ? _inventory(files) : null),
          throwsA(isA<GamePackageFormatException>()
              .having((error) => error.code, 'code',
                  'runtime3d.asset_integrity_mismatch')
              .having((error) => error.path, 'path', 'assets/hero.png')
              .having((error) => error.message, 'message',
                  'Logical content differs from its canonical blob.')));
    });
  }
}

List<GamePackageFileEntry> _inventory(Map<String, List<int>> files) => [
      for (final MapEntry(key: path, value: bytes) in files.entries)
        GamePackageFileEntry(
            path: path,
            size: bytes.length,
            sha256: sha256.convert(bytes).toString()),
    ];

void _validate(Map<String, List<int>> files, List<String> reads,
    {List<GamePackageFileEntry>? inventory}) {
  final project = ProjectManifest.fromJson(
      jsonDecode(utf8.decode(files['project/project.json']!)));
  const GamePackageSpatialProjectValidator().validate(project, (path) {
    reads.add(path);
    return files[path];
  }, verifiedInventory: inventory);
}
