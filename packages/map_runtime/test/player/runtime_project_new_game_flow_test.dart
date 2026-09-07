import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
