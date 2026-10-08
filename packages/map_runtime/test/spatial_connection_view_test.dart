import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('runtime keeps a black backdrop and stable model source',
      (tester) async {
    late Directory directory;
    late SpatialExplorationSession session;
    await tester.runAsync(() async {
      directory = await Directory.systemTemp.createTemp('spatial-view-');
      final path = '${directory.path}/hero.png';
      await File(path)
          .writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
      session = await SpatialExplorationSession.load(RuntimeMapBundle(
          manifest: ProjectManifest(
              version: ProjectVersion.v9,
              name: 'View',
              settings: const ProjectSettings(
                  dimension: ProjectDimension.threeD,
                  defaultPlayerCharacterId: 'hero'),
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
                                      x: 0, y: 0, width: 32, height: 32),
                                  durationMs: 100)
                            ])
                    ])
              ]),
          map: MapData(
              version: ProjectVersion.v9,
              id: 'field',
              name: 'Field',
              size: const GridSize(width: 8, height: 8),
              spatialScene: MapSpatialScene(width: 8, depth: 8)),
          projectRootDirectory: directory.path,
          tilesetAbsolutePathsById: const {},
          characterAnimationAbsolutePathsByAssetId: {'hero': path}));
    });
    Widget app(Brightness brightness) => MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: SpatialExplorationView(session: session));
    await tester.pumpWidget(app(Brightness.light));
    final before =
        tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(before.background, Colors.black);
    await tester.pumpWidget(app(Brightness.dark));
    final after =
        tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
    expect(after.loadModel, before.loadModel);
    expect(after.background, Colors.black);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    await tester.runAsync(() => directory.delete(recursive: true));
  });
}
