import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final portable in [false, true]) {
    for (final changeUnusedResource in [false, true]) {
      test(
        'map-scoped catalog keeps full publication guard, portable=$portable, changed=$changeUnusedResource',
        () async {
          final directory = await Directory.systemTemp.createTemp(
            'new-game-catalog-',
          );
          addTearDown(() => directory.delete(recursive: true));
          const used = ProjectTilesetEntry(
            id: 'used',
            name: 'Used',
            relativePath: 'used.png',
          );
          const unused = ProjectTilesetEntry(
            id: 'unused',
            name: 'Unused',
            relativePath: 'unused.png',
          );
          final project = ProjectManifest(
            name: 'Catalog new game',
            maps: const [
              ProjectMapEntry(
                id: 'start',
                name: 'Start',
                relativePath: 'start.json',
              ),
            ],
            tilesets: const [used, unused],
            newGame: const ProjectNewGameConfig(
              enabled: true,
              startMapId: 'start',
            ),
          );
          final map = MapData(
            id: 'start',
            name: 'Start',
            size: GridSize(width: 4, height: 4),
            tilesetId: 'used',
            layers: [
              TileLayer(
                id: 'ground',
                name: 'Ground',
                palette: const [
                  TileLayerPaletteEntry(tilesetId: 'used', localTileId: 0),
                ],
                cells: List.filled(16, 0),
              ),
            ],
          );
          final projectFile = File('${directory.path}/project.json');
          await _writeProject(projectFile, project, portable: portable);
          final originalBytes = await projectFile.readAsBytes();
          await File('${directory.path}/start.json')
              .writeAsString(jsonEncode(map.toJson()));
          var imageLoaderCalled = false;
          final preloader = RuntimeInitialMapPreloader(
            projectFilePath: () async => projectFile.path,
            loadSave: (_) async => null,
            tilesetImageLoader:
                (
                  paths, {
                  transparentColorByTilesetId = const {},
                  onProgress,
                }) async {
                  imageLoaderCalled = true;
                  expect(paths.keys, ['used']);
                  if (changeUnusedResource) {
                    await _writeProject(
                      projectFile,
                      project.copyWith(
                        tilesets: [
                          used,
                          unused.copyWith(name: 'Unused changed'),
                        ],
                      ),
                      portable: portable,
                    );
                  }
                  return {};
                },
          );
          final flow = RuntimeProjectNewGameFlowPort(
            projectFilePath: () async => projectFile.path,
            initialMapPreloader: preloader,
          );
          addTearDown(flow.clear);
          if (changeUnusedResource) {
            await expectLater(
              flow.prepare(),
              throwsA(
                isA<RuntimeNewGameException>().having(
                  (error) => error.code,
                  'code',
                  'new_game.project_changed',
                ),
              ),
            );
          } else {
            final prepared = await flow.prepare();
            expect(prepared.project.tilesets.map((entry) => entry.id), ['used']);
            expect(
              await flow.readCurrentProjectRevision(),
              prepared.projectRevision,
            );
            expect(await projectFile.readAsBytes(), originalBytes);
          }
          expect(imageLoaderCalled, isTrue);
        },
      );
    }
  }

  final publishedProject = Platform.environment['AVELUNE_NEW_GAME_PROJECT'];
  if (publishedProject != null) {
    test('published native project prepares without changing source bytes', () async {
      final file = File('$publishedProject/project.json');
      final before = await file.readAsBytes();
      final source = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(before)) as Map<String, dynamic>,
      );
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => file.path,
        loadSave: (_) async => null,
        tilesetImageLoader: (
          paths, {
          transparentColorByTilesetId = const {},
          onProgress,
        }) async => {},
      );
      final flow = RuntimeProjectNewGameFlowPort(
        projectFilePath: () async => file.path,
        initialMapPreloader: preloader,
      );
      addTearDown(flow.clear);
      await preloader.preloadInitialMap(
        const RuntimeInitialMapPreloadRequest.newGame(),
      );
      final view = preloader.preparedNewGameBundle(projectFilePath: file.path)!;
      expect(
        view.manifest.tilesets.length,
        lessThanOrEqualTo(source.tilesets.length),
      );
      expect(
        view.manifest.elements.length,
        lessThanOrEqualTo(source.elements.length),
      );
      expect(await view.projectCatalog!.isCurrentPublication(), isTrue);
      final prepared = await flow.prepare();
      expect(await flow.readCurrentProjectRevision(), prepared.projectRevision);
      expect(await file.readAsBytes(), before);
    });
  }

  for (final changeProject in [false, true]) {
    test('normalization preserves new game revision, changed=$changeProject',
        () async {
      final directory = await Directory.systemTemp.createTemp('new-game-flow-');
      addTearDown(() => directory.delete(recursive: true));
      final source =
          File('test/fixtures/p3_scenario_runtime_golden_path/project.json');
      final base = ProjectManifest.fromJson(
        jsonDecode(await source.readAsString()) as Map<String, dynamic>,
      );
      final project = base.copyWith(
        elementCategories: const [
          ProjectElementCategory(id: 'props', name: 'Props')
        ],
        tilesets: const [
          ProjectTilesetEntry(
              id: 'props', name: 'Props', relativePath: 'assets/props.png')
        ],
        newGame: const ProjectNewGameConfig(
            enabled: true, startMapId: 'p3_test_map'),
        elements: [
          ProjectElementEntry(
            id: 'bench',
            name: 'Bench',
            categoryId: 'props',
            tilesetId: 'props',
            frames: const [
              TilesetVisualFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 1)),
            ],
            collisionProfile: const ElementCollisionProfile(
              source: ElementCollisionProfileSource.manual,
              shapeCells: [GridPos(x: 1, y: 0), GridPos(x: 0, y: 0)],
              cells: [GridPos(x: 1, y: 0), GridPos(x: 0, y: 0)],
            ),
          ),
        ],
      );
      final projectFile = File('${directory.path}/project.json');
      final originalBytes = utf8.encode(jsonEncode(project.toJson()));
      await projectFile.writeAsBytes(originalBytes);
      final mapFile =
          File('${directory.path}/${project.maps.single.relativePath}');
      await mapFile.parent.create(recursive: true);
      final map = MapData.fromJson(jsonDecode(await File(
        'test/fixtures/p3_scenario_runtime_golden_path/${project.maps.single.relativePath}',
      ).readAsString()) as Map<String, dynamic>);
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      final preloader = RuntimeInitialMapPreloader(
        projectFilePath: () async => projectFile.path,
        loadSave: (_) async => null,
        bundleLoader: (
            {required projectFilePath,
            required mapId,
            required preloadedManifest}) async {
          expect(
              preloadedManifest.elements.single.collisionProfile!.cells.first.x,
              0);
          if (changeProject) {
            await projectFile.writeAsString(
                jsonEncode(project.copyWith(name: 'Changed').toJson()));
          }
          return RuntimeMapBundle(
            manifest: preloadedManifest,
            map: map,
            projectRootDirectory: directory.path,
            tilesetAbsolutePathsById: {},
          );
        },
        tilesetImageLoader: (paths,
                {transparentColorByTilesetId = const {}, onProgress}) async =>
            {},
      );
      final flow = RuntimeProjectNewGameFlowPort(
        projectFilePath: () async => projectFile.path,
        initialMapPreloader: preloader,
      );
      addTearDown(flow.clear);
      if (changeProject) {
        await expectLater(
            flow.prepare(),
            throwsA(isA<RuntimeNewGameException>().having(
                (error) => error.code, 'code', 'new_game.project_changed')));
      } else {
        final result = await flow.prepare();
        expect(result.startMap, map);
        expect(await flow.readCurrentProjectRevision(), result.projectRevision);
        expect(await projectFile.readAsBytes(), originalBytes);
      }
    });
  }
}

Future<void> _writeProject(
  File file,
  ProjectManifest project, {
  required bool portable,
}) async {
  if (!portable) {
    await file.writeAsString(jsonEncode(project.toJson()));
    return;
  }
  final publication = PortableCatalogPublication.encodeProject(project);
  final objects = Directory('${file.parent.path}/catalog/objects');
  await objects.create(recursive: true);
  for (final entry in publication.storage.objects.entries) {
    await File('${objects.path}/${entry.key}.json').writeAsBytes(entry.value);
  }
  await file.writeAsString(jsonEncode(publication.descriptor));
}
