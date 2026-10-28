import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('runtime keeps a black backdrop and stable model source', (
    tester,
  ) async {
    late Directory directory;
    late SpatialExplorationSession session;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('spatial-view-');
      final path = '${directory.path}/hero.png';
      await File(path)
          .writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
      session = await SpatialExplorationSession.load(
        RuntimeMapBundle(
          exteriorDecoration: MapExteriorDecoration(
            mapId: 'field',
            playableWidth: 8,
            playableDepth: 8,
            west: 2,
          ),
          spatialAtmosphereSettings: SpatialAtmosphereSettings(
            waterAnimated: true,
            windowsLit: true,
            fireflies: true,
            waterStrength: .6,
            waterTargets: [
              SpatialAtmosphereMaterialTarget.groundTileset("river"),
            ],
          ),
          manifest: ProjectManifest(
            version: ProjectVersion.v9,
            name: 'View',
            settings: const ProjectSettings(
              dimension: ProjectDimension.threeD,
              defaultPlayerCharacterId: 'hero',
            ),
            maps: const [],
            tilesets: const [],
            characters: [
              ProjectCharacterEntry(
                id: 'hero',
                name: 'Hero',
                tilesetId: 'unused',
                animations: [
                  for (final facing in EntityFacing.values)
                    CharacterAnimation(
                      state: CharacterAnimationState.walk,
                      direction: facing,
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
          ),
          map: MapData(
            version: ProjectVersion.v9,
            id: 'field',
            name: 'Field',
            size: const GridSize(width: 8, height: 8),
            spatialScene: MapSpatialScene(width: 8, depth: 8),
          ),
          projectRootDirectory: directory.path,
          tilesetAbsolutePathsById: const {},
          characterAnimationAbsolutePathsByAssetId: {'hero': path},
        ),
      );
    });
    Widget app(Brightness brightness) => MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: SpatialExplorationView(session: session),
    );
    expect(session.prepareNativeDoorDestination, isNull);
    await tester.pumpWidget(app(Brightness.light));
    final preparation = session.prepareNativeDoorDestination;
    expect(preparation, isNotNull);
    final before = tester.widget<SpatialSceneView>(
      find.byType(SpatialSceneView),
    );
    expect(before.background, Colors.black);
    expect(before.controller.waterAnimated, isTrue);
    expect(before.controller.windowsLit, isTrue);
    expect(before.controller.fireflies, isTrue);
    expect(before.controller.atmosphereProfile.waterStrength, .6);
    final atmosphereProfile = before.controller.atmosphereProfile;
    expect(before.presentationElapsedSeconds?.call(), 0);
    session.frames(.5);
    expect(before.presentationElapsedSeconds?.call(), .5);
    session.setLifecyclePaused(true);
    session.frames(.5);
    expect(before.presentationElapsedSeconds?.call(), .5);
    session.setLifecyclePaused(false);
    session.frames(.5);
    expect(before.presentationElapsedSeconds?.call(), 1);
    await tester.pumpWidget(app(Brightness.dark));
    final after = tester.widget<SpatialSceneView>(
      find.byType(SpatialSceneView),
    );
    expect(after.loadModel, before.loadModel);
    expect(
      after.decorations.single.loadModel,
      before.decorations.single.loadModel,
    );
    expect(
      after.decorations.single.loadGroundImage,
      before.decorations.single.loadGroundImage,
    );
    expect(after.controller.atmosphereProfile, same(atmosphereProfile));
    expect(after.background, Colors.black);
    expect(session.prepareNativeDoorDestination, preparation);
    session.graphics.value = const RuntimeGraphicsPreferences(
      renderScalePercent: 75,
      depthOfField: false,
      shadows: false,
      ambientAnimation: false,
    );
    await tester.pump();
    final reduced = tester.widget<SpatialSceneView>(
      find.byType(SpatialSceneView),
    );
    expect(reduced.renderResolutionScale, .75);
    expect(reduced.controller.shadowsEnabled, isFalse);
    expect(reduced.controller.depthOfFieldEnabled, isFalse);
    expect(reduced.controller.waterAnimated, isFalse);
    expect(reduced.controller.windowsLit, isFalse);
    expect(reduced.controller.fireflies, isFalse);
    session.graphics.value = const RuntimeGraphicsPreferences();
    await tester.pump();
    final restored = tester.widget<SpatialSceneView>(
      find.byType(SpatialSceneView),
    );
    expect(restored.renderResolutionScale, 1);
    expect(restored.controller.shadowsEnabled, isTrue);
    expect(restored.controller.waterAnimated, isTrue);
    expect(restored.controller.windowsLit, isTrue);
    expect(restored.controller.fireflies, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(session.prepareNativeDoorDestination, isNull);
    session.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}
