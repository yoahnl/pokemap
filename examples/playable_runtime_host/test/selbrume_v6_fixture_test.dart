import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('ITM-103 strict decoder still refuses a Selbrume V2 manifest', () async {
    final projectFile = File(
      p.join(_repositoryRoot().path, 'selbrume', 'project.json'),
    );
    final rawProject =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;

    expect(
      () => ProjectManifest.fromJson(<String, dynamic>{
        ...rawProject,
        'version': 'v2',
      }),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('smart_tile_v6_project_required'),
        ),
      ),
    );
  });

  test(
    'ITM-103 Selbrume is a strict V7 project with V6 maps',
    () async {
      final projectRoot = p.join(_repositoryRoot().path, 'selbrume');
      final projectFile = File(p.join(projectRoot, 'project.json'));
      final rawProject =
          jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;

      expect(rawProject['version'], 'v7');
      for (final field in const <String>[
        'terrainCategories',
        'pathCategories',
        'terrainPresets',
        'pathPresets',
        'pathPatternPresets',
        'surfaceCatalog',
      ]) {
        expect(rawProject.containsKey(field), isFalse, reason: field);
      }
      final rawInitialBag =
          ((rawProject['newGame'] as Map<String, dynamic>)['initialBag']
                  as List<dynamic>)
              .cast<Map<String, dynamic>>();
      expect(
        rawInitialBag,
        everyElement(
          predicate<Map<String, dynamic>>(
            (entry) => entry.keys.toSet().difference(<String>{
              'itemId',
              'quantity',
            }).isEmpty,
          ),
        ),
      );

      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
        allowedRootPaths: <String>[projectRoot],
        fileReader: reader,
      );
      final handles = WorkspaceHandleStore(
        tokenFactory: (prefix) => '${prefix}itm103',
      );
      final opened = await ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ).openProject(projectRoot);
      addTearDown(() => handles.closeWorkspace(opened.workspaceHandle));

      final snapshot = await ProjectSnapshotLoader(
        handles: handles,
      ).load(opened.projectHandle);
      final project = snapshot.manifest;

      ProjectValidator.validate(project);
      expect(project.version, ProjectVersion.v7);
      expect(project.maps, hasLength(10));
      expect(project.dialogues, hasLength(24));
      expect(project.scenarios, hasLength(3));
      expect(
        project.shops.map((shop) => shop.id),
        contains('shop_port_supplies'),
      );
      expect(project.facts, hasLength(49));
      expect(project.worldRules, hasLength(34));
      expect(snapshot.maps, hasLength(10));
      expect(
        snapshot.maps.expand((map) => map.layers).whereType<SmartTileLayer>(),
        hasLength(22),
      );
      expect(
        snapshot.maps.fold<int>(0, (total, map) => total + map.warps.length),
        10,
      );
      expect(
        snapshot.maps.fold<int>(0, (total, map) => total + map.entities.length),
        43,
      );
      expect(
        snapshot.maps.fold<int>(0, (total, map) => total + map.triggers.length),
        21,
      );
      for (final map in snapshot.maps) {
        final rawMap =
            jsonDecode(
                  await File(
                    p.join(
                      projectRoot,
                      project.maps
                          .singleWhere((entry) => entry.id == map.id)
                          .relativePath,
                    ),
                  ).readAsString(),
                )
                as Map<String, dynamic>;
        expect(rawMap['version'], 'v6');
        for (final layer
            in (rawMap['layers'] as List<dynamic>)
                .cast<Map<String, dynamic>>()) {
          expect(
            layer['runtimeType'],
            isNot(anyOf('terrain', 'path', 'surface')),
          );
          if (layer['runtimeType'] == 'tile') {
            expect(layer.containsKey('tiles'), isFalse);
            expect(layer.containsKey('tilesetId'), isFalse);
          }
        }
        MapValidator.validate(map, projectDialogueContext: project);
        expect(map.version, ProjectVersion.v6);
        expect(
          map.layers.map((layer) => layer.runtimeType),
          isNot(contains(anyOf('terrain', 'path', 'surface'))),
        );
      }
      for (final mapEntry in project.maps) {
        final bundle = await loadRuntimeMapBundle(
          projectFilePath: projectFile.path,
          mapId: mapEntry.id,
          preloadedManifest: project,
        );
        expect(bundle.map.id, mapEntry.id);
        for (final path in bundle.tilesetAbsolutePathsById.values) {
          expect(File(path).existsSync(), isTrue, reason: path);
        }
        for (final path
            in bundle.characterAnimationAbsolutePathsByAssetId.values) {
          expect(File(path).existsSync(), isTrue, reason: path);
        }
      }

      final itemCatalog = snapshot.itemCatalog;
      expect(itemCatalog, isNotNull);
      expect(itemCatalog!.schemaVersion, 1);
      expect(
        itemCatalog.entries.map((entry) => entry.id),
        containsAll(<String>[
          'antidote',
          'basement-key',
          'pearl',
          'poke-ball',
          'potion',
          'rare-candy',
          'super-potion',
        ]),
      );
      final itemReferences = buildProjectItemReferenceIndex(
        project: project,
        maps: snapshot.maps,
        itemCatalog: itemCatalog,
      );
      expect(
        itemReferences.referencedItemIds.difference(
          itemCatalog.entries.map((entry) => entry.id).toSet(),
        ),
        isEmpty,
      );
      final rawCatalog =
          jsonDecode(
                await File(
                  p.join(projectRoot, project.pokemon.catalogFiles['items']!),
                ).readAsString(),
              )
              as Map<String, dynamic>;
      expect(rawCatalog.keys.toSet(), <String>{'schemaVersion', 'entries'});
      expect(
        (rawCatalog['entries'] as List<dynamic>).cast<Map<String, dynamic>>(),
        everyElement(
          predicate<Map<String, dynamic>>(
            (entry) => !entry.containsKey('categoryId'),
          ),
        ),
      );

      final exportedProject = ProjectManifest.fromJson(
        jsonDecode(jsonEncode(project.toJson())) as Map<String, dynamic>,
      );
      expect(exportedProject.version, ProjectVersion.v7);
      expect(
        exportedProject.maps.map((entry) => entry.id),
        orderedEquals(project.maps.map((entry) => entry.id)),
      );
      for (final map in snapshot.maps) {
        final exportedMap = MapData.fromJson(
          jsonDecode(jsonEncode(map.toJson())) as Map<String, dynamic>,
        );
        expect(exportedMap.version, ProjectVersion.v6);
        expect(exportedMap.warps, map.warps);
        expect(exportedMap.entities, map.entities);
        expect(exportedMap.triggers, map.triggers);
      }
    },
  );
}

Directory _repositoryRoot() {
  var current = Directory.current.absolute;
  while (current.parent.path != current.path) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        File(p.join(current.path, 'selbrume', 'project.json')).existsSync()) {
      return current;
    }
    current = current.parent;
  }
  throw StateError('pokemonProject repository root not found.');
}
