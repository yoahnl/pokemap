import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/playtest/studio_playtest_view.dart';
import 'package:avelune_studio/platform/playtest/studio_spatial_playtest_view.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets(
    'new game detaches the old lifecycle observer before disposing its runtime',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(_Fixture.create))!;
      addTearDown(fixture.dispose);
      final runtimes = <SpatialExplorationGameSessionRuntime>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StudioPlaytestView(
              session: fixture.session,
              entry: fixture.project.maps.single,
              expectedRevision: fixture.revision,
              port: fixture.port,
              testSession: fixture.saves,
              onClose: () {},
              spatialViewBuilder: (context, playtest, onReady, onError) {
                if (!runtimes.contains(playtest.runtime)) {
                  runtimes.add(playtest.runtime);
                }
                WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
                return StudioSpatialPlaytestView(
                  runtime: playtest.runtime,
                  sceneBuilder: (_) => const SizedBox(),
                  onReady: onReady,
                  onError: onError,
                );
              },
            ),
          ),
        ),
      );
      await _waitFor(
        tester,
        () =>
            runtimes.isNotEmpty &&
            tester
                    .widget<StudioButton>(
                      find.widgetWithText(StudioButton, 'Nouvelle partie'),
                    )
                    .onPressed !=
                null,
      );
      final oldRuntime = runtimes.single;
      await tester.tap(find.text('Nouvelle partie'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _waitFor(
        tester,
        () =>
            runtimes.length == 2 &&
            tester
                    .widget<StudioButton>(
                      find.widgetWithText(StudioButton, 'Nouvelle partie'),
                    )
                    .onPressed !=
                null,
      );
      expect(tester.takeException(), isNull);
      expect(identical(runtimes.last, oldRuntime), isFalse);
      await tester.tap(find.text('Enregistrer le test'));
      await _waitFor(tester, () => fixture.saves.hasSave);
      expect(fixture.saves.hasSave, isTrue);
      await _waitFor(
        tester,
        () =>
            tester
                .widget<StudioButton>(
                  find.widgetWithText(StudioButton, 'Reprendre le test'),
                )
                .onPressed !=
            null,
      );
      await tester.tap(find.text('Reprendre le test'));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _waitFor(
        tester,
        () =>
            runtimes.length == 3 &&
            tester
                    .widget<StudioButton>(
                      find.widgetWithText(StudioButton, 'Nouvelle partie'),
                    )
                    .onPressed !=
                null,
      );
      expect(tester.takeException(), isNull);
      expect(fixture.saves.hasSave, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        for (final runtime in runtimes) {
          await runtime.dispose();
        }
      });
    },
  );
}

Future<void> _waitFor(WidgetTester tester, bool Function() ready) async {
  for (var attempt = 0; attempt < 200; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
    if (ready()) return;
  }
  expect(
    ready(),
    isTrue,
    reason: tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .join(' | '),
  );
}

class _Fixture {
  _Fixture(this.root, this.session, this.project, this.port, this.revision);
  final Directory root;
  final ProjectSession session;
  final ProjectManifest project;
  final LocalMapWorkspaceAdapter port;
  final String revision;
  final saves = StudioPlaytestSession();
  static Future<_Fixture> create() async {
    final root = await Directory.systemTemp.createTemp('surf-lifecycle-');
    final png = image.encodePng(image.Image(width: 32, height: 32));
    await File('${root.path}/hero.png').writeAsBytes(png);
    final artifact = ContentArtifactRef.fromBytes(png, mediaType: 'image/png');
    final blob = File('${root.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(png);
    await File('${root.path}/$assetCatalogStorageKey').writeAsString(
      jsonEncode(
        AssetCatalog(
          records: [
            AssetRecord(
              id: 'hero',
              logicalPath: 'hero.png',
              artifact: artifact,
            ),
          ],
        ).toJson(),
      ),
    );
    final project = ProjectManifest(
      version: ProjectVersion.v9,
      name: 'Lifecycle',
      maps: const [
        ProjectMapEntry(
          id: 'field',
          name: 'Terrain',
          relativePath: 'field.json',
        ),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'unused',
          name: 'Héros',
          relativePath: 'hero.png',
        ),
      ],
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        spatialCamera: SpatialCameraProfile(),
        defaultPlayerCharacterId: 'hero',
      ),
      newGame: const ProjectNewGameConfig(enabled: true, startMapId: 'field'),
      pokemon: const ProjectPokemonConfig(
        enabled: false,
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
      characters: [
        ProjectCharacterEntry(
          id: 'hero',
          name: 'Héros',
          tilesetId: 'unused',
          animations: [
            for (final direction in EntityFacing.values)
              CharacterAnimation(
                state: CharacterAnimationState.walk,
                direction: direction,
                sourceAssetId: 'hero',
                frames: const [
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(
                      x: 0,
                      y: 0,
                      width: 32,
                      height: 32,
                    ),
                    durationMs: 100,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
    final map = MapData(
      version: ProjectVersion.v9,
      id: 'field',
      name: 'Terrain',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    );
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(project.toJson()));
    await File('${root.path}/field.json')
        .writeAsString(jsonEncode(map.toJson()));
    final session = ProjectSession(
      sessionId: root.path,
      name: project.name,
      directoryPath: root.path,
    );
    final port = LocalMapWorkspaceAdapter();
    await port.loadProject(session);
    final revision = (await port.loadMap(
      session,
      project.maps.single,
    )).revision;
    return _Fixture(root, session, project, port, revision);
  }

  Future<void> dispose() async {
    await saves.delete();
    await root.delete(recursive: true);
  }
}
