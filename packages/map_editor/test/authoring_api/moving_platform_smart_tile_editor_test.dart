import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

import '../../../map_gameplay/test/support/moving_platform_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Studio open save and cold reopen preserve mobile controls and fine terrain',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'platform-editor-lifecycle-',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final fixture = MovingPlatformFixture(
        smartTerrain: true,
        preciseTerrain: true,
      );
      final recorder = ui.PictureRecorder();
      ui.Canvas(
        recorder,
      ).drawRect(const ui.Rect.fromLTWH(0, 0, 32, 64), ui.Paint());
      final image = await recorder.endRecording().toImage(32, 64);
      try {
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${root.path}/tiles.png',
        ).writeAsBytes(png!.buffer.asUint8List());
      } finally {
        image.dispose();
      }
      final definition = MovingPlatformDefinition.fromJson({
        ...fixture.definition.toJson(),
        'controls': [
          {
            'id': 'turn',
            'cell': {'x': 0, 'y': 0},
            'motion': 'rotateClockwise',
          },
        ],
      });
      final project = fixture.project.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: fixture.project.smartTileCatalog.materials,
          presets: [
            for (final preset in fixture.project.smartTileCatalog.presets)
              preset.copyWith(
                coverageProfile: const SmartTileCoverageProfile(
                  mode: SmartTileCoverageMode.explicit,
                  requiredScenarios: [
                    SmartTileCoverageScenario(
                      id: 'lava',
                      centerMaterialId: 'lava',
                    ),
                  ],
                ),
              ),
          ],
        ),
        elementCategories: const [
          ProjectElementCategory(id: 'platform', name: 'Platforms'),
        ],
        maps: const [
          ProjectMapEntry(
            id: 'gym',
            name: 'Gym',
            relativePath: 'maps/gym.json',
          ),
        ],
      );
      final map = fixture.map.copyWith(movingPlatforms: [definition]);
      final manifestPath = '${root.path}/project.json';
      final mapPath = '${root.path}/maps/gym.json';
      final projectRepository = FileProjectRepository();
      final mapRepository = FileMapRepository();
      await projectRepository.saveProject(project, manifestPath);
      await mapRepository.saveMap(
        map,
        mapPath,
        projectDialogueContext: project,
      );
      final manifestBefore = await File(manifestPath).readAsBytes();
      for (var opening = 0; opening < 2; opening++) {
        final container = ProviderContainer();
        final keepAlive = container.listen(editorNotifierProvider, (_, _) {});
        try {
          final notifier = container.read(editorNotifierProvider.notifier)
            ..state = EditorState(
              projectRootPath: root.path,
              project: await projectRepository.loadProject(manifestPath),
            );
          expect(
            await notifier.activateMap('maps/gym.json'),
            MapActivationOutcome.activated,
            reason: notifier.state.errorMessage,
          );
          expect(notifier.state.activeMap!.movingPlatforms, [definition]);
          if (opening == 0) {
            notifier.updateMapMetadata(
              notifier.state.activeMap!.mapMetadata.copyWith(
                displayName: 'Edited in Studio',
              ),
            );
            expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
            expect(notifier.state.isDirty, isFalse);
          } else {
            expect(
              notifier.state.activeMap!.mapMetadata.displayName,
              'Edited in Studio',
            );
            expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
          }
          expect(notifier.state.errorMessage, isNull);
          expect(notifier.state.activeMap!.layers, map.layers);
          expect(notifier.state.activeMap!.placedElements, map.placedElements);
        } finally {
          keepAlive.close();
          container.dispose();
        }
      }
      expect((await mapRepository.loadMap(mapPath)).movingPlatforms, [
        definition,
      ]);
      expect(await File(manifestPath).readAsBytes(), manifestBefore);
    },
  );

  test(
    'editor publishes Smart Tile platform support through the canonical API',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'platform-smart-editor-',
      );
      addTearDown(() => root.delete(recursive: true));
      final fixture = MovingPlatformFixture(
        smartTerrain: true,
        preciseTerrain: true,
      );
      final definition = MovingPlatformDefinition.fromJson({
        ...fixture.definition.toJson(),
        'controls': [
          {
            'id': 'turn',
            'cell': {'x': 0, 'y': 0},
            'motion': 'rotateClockwise',
          },
        ],
      });
      final project = fixture.project.copyWith(
        maps: const [
          ProjectMapEntry(id: 'gym', name: 'Gym', relativePath: 'gym.json'),
        ],
      );
      final map = fixture.map.copyWith(movingPlatforms: const []);
      final projectFile = File('${root.path}/project.json');
      final mapFile = File('${root.path}/gym.json');
      await projectFile.writeAsString(jsonEncode(project.toJson()));
      await mapFile.writeAsString(jsonEncode(map.toJson()));
      const reader = LocalProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: _RootLocator(root.path),
      );
      addTearDown(mutations.closeAll);
      addTearDown(queries.closeAll);
      final opened = await queries.open(root.path);
      final before = await mapFile.readAsBytes();
      final plan = await mutations.plan(
        root.path,
        actionId: 'map.platform.upsert',
        parameters: {'mapId': 'gym', 'platform': definition.toJson()},
        idempotencyKey: 'smart-platform',
        requestId: 'smart-platform',
        expectedRevision: opened.snapshotRevision,
      );
      expect(await mapFile.readAsBytes(), before);
      final result = await mutations.apply(plan, operationId: 'smart-platform');
      expect(result.receipt.status, AuthoringReceiptStatus.applied);
      final saved = MapData.fromJson(jsonDecode(await mapFile.readAsString()));
      expect(saved.movingPlatforms.single.toJson(), definition.toJson());
      expect(saved.layers, map.layers);
      expect(saved.placedElements, map.placedElements);
      expect(jsonDecode(await projectFile.readAsString()), project.toJson());
    },
  );
}

final class _RootLocator implements EditorProjectRootLocator {
  const _RootLocator(this.root);
  final String root;
  @override
  Future<String> locateForResource(String resourcePath) async => root;
}
