import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('map_distribution remains pure Dart and respects forbidden edges', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final forbidden in <String>[
      'flutter:',
      'flame:',
      'map_runtime:',
      'map_editor:',
      'map_player_ui:',
      'pokemap_hub:',
      'playable_runtime_host',
    ]) {
      expect(pubspec, isNot(contains(forbidden)), reason: forbidden);
    }

    final sources = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final source in sources) {
      final contents = source.readAsStringSync();
      for (final forbiddenImport in <String>[
        "import 'dart:io'",
        'package:flutter/',
        'package:flame/',
        'package:map_runtime/',
        'package:map_editor/',
        'package:map_player_ui/',
        'apps/pokemap_hub',
        'examples/playable_runtime_host',
      ]) {
        expect(
          contents,
          isNot(contains(forbiddenImport)),
          reason: '${source.path}: $forbiddenImport',
        );
      }
    }
  });
}
