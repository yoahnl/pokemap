import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('the mounted field motion composes its model pose then hands off to saved position', () async {
    final root = await Directory.systemTemp.createTemp('spatial-field-motion-');
    addTearDown(() => root.delete(recursive: true));
    final path = '${root.path}/hero.png';
    await File(path)
        .writeAsBytes(img.encodePng(img.Image(width: 32, height: 32)));
    final character = ProjectCharacterEntry(
      id: 'hero',
      name: 'Hero',
      tilesetId: 'unused',
      animations: [
        for (final facing in EntityFacing.values)
          for (final state in [
            CharacterAnimationState.walk,
            CharacterAnimationState.push,
          ])
            CharacterAnimation(
              state: state,
              direction: facing,
              sourceAssetId: 'hero',
              frames: const [
                CharacterAnimationFrame(
                  source: TilesetSourceRect(x: 0, y: 0, width: 32, height: 32),
                  durationMs: 100,
                ),
              ],
            ),
      ],
    );
    final model = ProjectModel3dEntry(
      id: 'rock',
      name: 'Rock',
      sourceAssetId: 'rock-source',
      relativePath: 'assets/models3d/rock.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: -.3, y: 0, z: -.3),
          max: Model3dVector3(x: .3, y: 1, z: .3),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );
    final map = MapData(
      id: 'field',
      name: 'Field',
      version: ProjectVersion.v9,
      size: const GridSize(width: 8, height: 8),
      entities: const [
        MapEntity(
          id: 'rock',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 2, y: 1),
          fieldObstacle: MapEntityFieldObstacleData(
            kind: FieldObstacleKind.strengthBoulder,
          ),
        ),
      ],
      spatialScene: MapSpatialScene(
        width: 8,
        depth: 8,
        instances: [
          SpatialModelInstance(
            id: 'rock-instance',
            modelId: 'rock',
            entityId: 'rock',
            position: Model3dVector3(x: 2.5, y: 0, z: 1.5),
          ),
        ],
      ),
    );
    var state = GameState(
      saveId: 'motion',
      currentMapId: 'field',
      playerPosition: const GridPos(x: 1, y: 1),
      playerSpatialPosition: PlayerSpatialPosition(x: 1.5, z: 1.5),
      mapInstanceWorldState: MapInstanceWorldState(
        instancesByMapId: {'field': MapInstanceRuntimeState(instanceId: 'one')},
      ),
    );
    final bundle = RuntimeMapBundle(
      manifest: ProjectManifest(
        name: 'Motion',
        version: ProjectVersion.v9,
        maps: const [],
        tilesets: const [],
        settings: const ProjectSettings(
          dimension: ProjectDimension.threeD,
          defaultPlayerCharacterId: 'hero',
        ),
        characters: [character],
        models3d: [model],
      ),
      map: map,
      projectRootDirectory: root.path,
      tilesetAbsolutePathsById: const {},
      characterAnimationAbsolutePathsByAssetId: {'hero': path},
    );
    final session = await SpatialExplorationSession.load(
      bundle,
      spatialArrival: state.playerSpatialPosition,
      presentationStateProvider: () => state,
      worldStateProvider: () => state.spatialWorldState,
    );
    addTearDown(session.dispose);
    final source = state.spatialWorldState;
    final moved = session.presentFieldMotion(
      ability: FieldAbility.strength,
      from: state.playerSpatialPosition!,
      to: PlayerSpatialPosition(x: 2.5, z: 1.5),
      facing: EntityFacing.east,
      durationMs: 250,
      modelInstanceId: 'rock-instance',
      modelDeltaX: 1,
    );
    session.frame(.1);
    expect(session.movement.x, closeTo((1.9 * 16).round() / 16, .000001));
    expect(session.movement.facing, EntityFacing.east);
    expect(
      session.modelRuntimeState('field', 'rock-instance')!.translationX,
      closeTo(.4, .000001),
    );
    session.frame(.15);
    expect(await moved, isTrue);
    expect(session.fieldMotionActive, isTrue);
    state = state.copyWith(
      playerPosition: const GridPos(x: 2, y: 1),
      playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 1.5),
      mapInstanceWorldState: state.mapInstanceWorldState.moveFieldObstacle(
        state.mapInstanceWorldState.instanceRef('field')!,
        'rock',
        const GridPos(x: 3, y: 1),
      ),
    );
    session.finishFieldMotion(committed: true);
    expect(
      session.modelRuntimeState('field', 'rock-instance')!.translationX,
      1,
    );
    expect(session.movement.canTraverseActor(1.5, 1.5, 2.5, 1.5), isTrue);
    expect(session.movement.canTraverseActor(2.5, 1.5, 3.5, 1.5), isFalse);
    expect(state.spatialWorldState, same(source));
    expect(map.spatialScene!.instances.single.position.x, 2.5);
    final reopened = await SpatialExplorationSession.load(
      bundle,
      spatialArrival: state.playerSpatialPosition,
      presentationStateProvider: () => state,
      worldStateProvider: () => state.spatialWorldState,
    );
    addTearDown(reopened.dispose);
    expect(reopened.movement.isPositionTraversable, isTrue);
    expect(reopened.movement.canTraverseActor(1.5, 1.5, 2.5, 1.5), isTrue);
    expect(reopened.movement.canTraverseActor(2.5, 1.5, 3.5, 1.5), isFalse);
    final cancelled = reopened.presentFieldMotion(
      ability: FieldAbility.strength,
      from: state.playerSpatialPosition!,
      to: PlayerSpatialPosition(x: 3.5, z: 1.5),
      facing: EntityFacing.east,
      durationMs: 250,
      modelInstanceId: 'rock-instance',
      modelDeltaX: 1,
    );
    reopened.frame(.1);
    expect(reopened.movement.x, greaterThan(2.5));
    reopened.cancelFieldAction();
    expect(await cancelled, isFalse);
    expect(reopened.movement.x, 2.5);
    expect(
      reopened.modelRuntimeState('field', 'rock-instance')!.translationX,
      1,
    );
  });
}
