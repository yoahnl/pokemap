import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('map_authoring package boundary', () {
    test('declares canonical ownership and the only allowed dependency', () {
      expect(MapAuthoringPackageBoundaries.packageName, 'map_authoring');
      expect(
        MapAuthoringPackageBoundaries.allowedPackageDependencies,
        {'map_core', 'map_distribution'},
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

    test('pubspec keeps production dependencies within the approved set', () {
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
      expect(dependencyNames, {'map_core', 'map_distribution'});
      expect(pubspec, isNot(contains('sdk: flutter')));
    });

    test('keeps canonical cross-domain composition in the application layer',
        () {
      final applicationDispatcher =
          File('lib/src/application/map_mutation_dispatcher.dart');
      final legacyMapsEntryPoint =
          File('lib/src/domains/maps/map_mutation_dispatcher.dart');

      expect(applicationDispatcher.existsSync(), isTrue);
      expect(
        legacyMapsEntryPoint.readAsStringSync(),
        isNot(anyOf(contains('domains/assets'), contains('domains/narrative'))),
      );
    });

    test('publishes focused API and local composition entry points', () {
      final apiBarrel = File('lib/map_authoring_api.dart');
      final localBarrel = File('lib/map_authoring_local.dart');

      expect(apiBarrel.existsSync(), isTrue);
      expect(localBarrel.existsSync(), isTrue);

      final apiSource = apiBarrel.readAsStringSync();
      expect(
        apiSource,
        isNot(
          anyOf(
            contains("export 'src/domains/"),
            contains("export 'src/history/"),
            contains("export 'src/security/"),
            contains("export 'src/tooling/"),
            contains('local_map_authoring_mutation_api.dart'),
          ),
        ),
      );
      expect(
        localBarrel.readAsStringSync(),
        contains("export 'map_authoring_api.dart';"),
      );
    });

    test('editor application adapters avoid the legacy umbrella barrel', () {
      final adapterSources = [
        File(
          '../map_editor/lib/src/application/authoring_api/'
          'authoring_query_adapter.dart',
        ).readAsStringSync(),
        File(
          '../map_editor/lib/src/application/authoring_api/'
          'authoring_mutation_adapter.dart',
        ).readAsStringSync(),
      ];

      expect(
        adapterSources,
        everyElement(
          contains('package:map_authoring/map_authoring_local.dart'),
        ),
      );
      expect(
        adapterSources,
        everyElement(
          isNot(contains('package:map_authoring/map_authoring.dart')),
        ),
      );
    });

    test('keeps Environment generation internals outside the action adapter',
        () {
      final actionFile = File(
        'lib/src/domains/maps/environment_actions.dart',
      );
      final generationSupport = File(
        'lib/src/domains/maps/environment_generation_support.dart',
      );

      expect(generationSupport.existsSync(), isTrue);
      expect(actionFile.readAsLinesSync(), hasLength(lessThan(1300)));
      expect(
        actionFile.readAsStringSync(),
        contains("part 'environment_generation_support.dart';"),
      );
    });

    test('keeps Tiled map validation outside the transaction adapter', () {
      final actionFile = File(
        'lib/src/domains/maps/tiled_map_import_actions.dart',
      );
      final importSupport = File(
        'lib/src/domains/maps/tiled_map_import_support.dart',
      );

      expect(importSupport.existsSync(), isTrue);
      expect(actionFile.readAsLinesSync(), hasLength(lessThan(1200)));
      expect(
        actionFile.readAsStringSync(),
        contains("part 'tiled_map_import_support.dart';"),
      );
    });

    test('keeps Smart Tile catalog validation outside the action adapter', () {
      final actionFile = File(
        'lib/src/domains/maps/smart_tile_catalog_actions.dart',
      );
      final catalogSupport = File(
        'lib/src/domains/maps/smart_tile_catalog_support.dart',
      );

      expect(catalogSupport.existsSync(), isTrue);
      expect(actionFile.readAsLinesSync(), hasLength(lessThan(1000)));
      expect(
        actionFile.readAsStringSync(),
        contains("part 'smart_tile_catalog_support.dart';"),
      );
    });
  });
}

Iterable<File> _dartFiles(Directory directory) {
  return directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}
