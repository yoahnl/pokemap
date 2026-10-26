import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final resource in ['ground', 'model']) {
    testWidgets(
      'a retained $resource job keeps its owning bundle after A to B',
      (tester) async {
        late Directory root;
        late RuntimeMapBundle a, b;
        late SpatialExplorationSession session;
        await tester.runAsync(() async {
          root = await Directory.systemTemp.createTemp('spatial-loader-owner-');
          final image = '${root.path}/actor.png';
          await File(image)
              .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
          final actor = ProjectCharacterEntry(
            id: 'actor',
            name: 'Actor',
            tilesetId: 'unused',
            animations: [
              for (final direction in EntityFacing.values)
                for (final state in [
                  CharacterAnimationState.idle,
                  CharacterAnimationState.walk,
                ])
                  CharacterAnimation(
                    state: state,
                    direction: direction,
                    sourceAssetId: 'actor',
                    frames: [
                      CharacterAnimationFrame(
                        source: const TilesetSourceRect(
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
          );
          Future<RuntimeMapBundle> bundle(String id, int marker) async {
            await File('${root.path}/$id.png').writeAsBytes([marker]);
            final modelFile = File(
              '${root.path}/assets/models3d/model-$id.glb',
            );
            await modelFile.parent.create(recursive: true);
            await modelFile.writeAsBytes([marker, marker]);
            return RuntimeMapBundle(
              manifest: ProjectManifest(
                name: id,
                maps: const [],
                tilesets: const [],
                settings: const ProjectSettings(
                  dimension: ProjectDimension.threeD,
                  defaultPlayerCharacterId: 'actor',
                ),
                characters: [actor],
                models3d: [
                  ProjectModel3dEntry(
                    id: 'model-$id',
                    name: id,
                    sourceAssetId: 'source-$id',
                    relativePath: 'assets/models3d/model-$id.glb',
                    inspection: Model3dInspection(
                      bounds: Model3dBounds(
                        min: Model3dVector3.zero,
                        max: Model3dVector3(x: 1, y: 1, z: 1),
                      ),
                      meshCount: 1,
                      triangleCount: 1,
                    ),
                  ),
                ],
              ),
              map: MapData(
                id: id,
                name: id,
                size: const GridSize(width: 8, height: 8),
                spatialScene: MapSpatialScene(width: 8, depth: 8),
              ),
              projectRootDirectory: root.path,
              tilesetAbsolutePathsById: {'image-$id': '${root.path}/$id.png'},
              characterAnimationAbsolutePathsByAssetId: {'actor': image},
              resourceBudget: RuntimeResourceBudget(
                profile: RuntimeResourceProfile(
                  maximumEncodedBytes: id == 'a' ? 1024 : 2048,
                ),
              ),
            );
          }

          a = await bundle('a', 11);
          b = await bundle('b', 22);
          session = await SpatialExplorationSession.load(a);
        });
        addTearDown(() => root.delete(recursive: true));
        addTearDown(session.dispose);
        addTearDown(b.resourceBudget.dispose);
        await tester.pumpWidget(
          MaterialApp(home: SpatialExplorationView(session: session)),
        );
        final previous = tester.widget<SpatialSceneView>(
          find.byType(SpatialSceneView),
        );
        Future<Uint8List> bytes(SpatialSceneView view, String id) =>
            resource == 'ground'
            ? view.loadGroundImage!('image-$id')
            : view.loadModel('model-$id');
        expect(
          await tester.runAsync(() => bytes(previous, 'a')),
          resource == 'ground' ? [11] : [11, 11],
        );

        session.bundle = b;
        session.mapRevision.value++;
        await tester.pump();
        final current = tester.widget<SpatialSceneView>(
          find.byType(SpatialSceneView),
        );

        expect(
          await tester.runAsync(() => bytes(previous, 'a')),
          resource == 'ground' ? [11] : [11, 11],
        );
        expect(
          await tester.runAsync(() => bytes(current, 'b')),
          resource == 'ground' ? [22] : [22, 22],
        );
        await expectLater(bytes(current, 'a'), throwsStateError);
        await expectLater(bytes(previous, 'b'), throwsStateError);
        expect(current.groundProject, same(b.manifest));
        expect(current.resourceBudget, same(b.resourceBudget));
        expect(b.tilesetAbsolutePathsById.keys, ['image-b']);
        expect(b.manifest.models3d.map((model) => model.id), ['model-b']);
        await tester.runAsync(() async {
          final path = resource == 'ground'
              ? a.tilesetAbsolutePathsById['image-a']!
              : '${root.path}/assets/models3d/model-a.glb';
          await File(path).writeAsBytes(Uint8List(1025));
          await expectLater(
            bytes(previous, 'a'),
            throwsA(
              isA<RuntimeResourceAdmissionException>().having(
                (error) => error.reason,
                'reason',
                'encoded_bytes',
              ),
            ),
          );
        });
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
