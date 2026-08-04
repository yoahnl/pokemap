import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final rootPath = Platform.environment['POKEMAP_TMX_CORPUS_ROOT'];

  test(
    'parses every supported finite map in a local generic TMX corpus',
    () {
      final files = Directory(rootPath!)
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.tmx'))
          .toList(growable: false)
        ..sort((left, right) => left.path.compareTo(right.path));
      expect(files, isNotEmpty);

      var parsed = 0;
      var rejectedNonPlayable = 0;
      for (final file in files) {
        try {
          parseTiledMap(file.readAsStringSync());
          parsed += 1;
        } on TiledMapImportException catch (error) {
          if (error.code == 'map.tiled.infinite_unsupported') {
            rejectedNonPlayable += 1;
            continue;
          }
          if (error.code == 'map.tiled.internal_dependency_unsupported') {
            rejectedNonPlayable += 1;
            continue;
          }
          fail('${file.path}: $error');
        }
      }

      expect(parsed, greaterThan(0));
      // A mixed corpus may contain automapping inputs. They remain explicit
      // rejections instead of being silently interpreted as playable maps.
      expect(parsed + rejectedNonPlayable, files.length);
    },
    skip: rootPath == null
        ? 'Set POKEMAP_TMX_CORPUS_ROOT to a local generic Tiled map corpus.'
        : false,
  );
}
