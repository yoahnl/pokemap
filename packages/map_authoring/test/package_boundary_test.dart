import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('map_authoring package boundary', () {
    test('declares canonical ownership and the only allowed dependency', () {
      expect(MapAuthoringPackageBoundaries.packageName, 'map_authoring');
      expect(
        MapAuthoringPackageBoundaries.allowedPackageDependencies,
        {'map_core'},
      );
      expect(
        MapAuthoringPackageBoundaries.ownedResponsibilities,
        containsAll({
          'authoring contracts',
          'authoring orchestration',
          'action registry',
        }),
      );
      expect(
        MapAuthoringPackageBoundaries.platformAdapterOwners,
        {
          'editor': 'map_editor',
          'runtime': 'map_runtime',
          'mcp': 'tools/pokemap_mcp',
        },
      );
    });

    test('contains no Flutter, Flame, editor, or runtime package imports', () {
      final forbiddenImports = <String>{
        'package:flutter/',
        'package:flame/',
        'package:map_editor/',
        'package:map_runtime/',
      };
      final violations = <String>[];

      for (final file in _dartFiles(Directory('lib'))) {
        final source = file.readAsStringSync();
        for (final forbiddenImport in forbiddenImports) {
          if (source.contains(forbiddenImport)) {
            violations.add('${file.path}: $forbiddenImport');
          }
        }
      }

      expect(violations, isEmpty);
    });

    test('pubspec keeps production dependencies limited to map_core', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final dependenciesBlock = RegExp(
        r'^dependencies:\n(?<body>(?:  .+\n?)+)',
        multiLine: true,
      ).firstMatch(pubspec)?.namedGroup('body');

      expect(dependenciesBlock, isNotNull);
      final dependencyNames = RegExp(
        r'^  ([a-zA-Z0-9_]+):',
        multiLine: true,
      ).allMatches(dependenciesBlock!).map((match) => match.group(1)!).toSet();
      expect(dependencyNames, {'map_core'});
      expect(pubspec, isNot(contains('sdk: flutter')));
    });
  });
}

Iterable<File> _dartFiles(Directory directory) {
  return directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}
