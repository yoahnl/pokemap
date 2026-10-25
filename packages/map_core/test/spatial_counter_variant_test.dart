import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'spatial presentation keeps authored counter sides after save and projection',
    () {
      final entity = MapEntity(
        id: 'clerk',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 2, y: 2),
        presentation: MapEntityPresentation(
          variants: [
            MapEntityPresentationVariant(
              id: 'counter',
              blocksMovement: true,
              condition: NarrativeEventConditionExpression.all([]),
              counterInteractionSides: [EntityFacing.east],
            ),
          ],
        ),
      );
      final reopened = MapEntity.fromJson(entity.toJson());
      final map = MapData(
        id: 'field',
        name: 'Field',
        size: GridSize(width: 8, height: 8),
        spatialScene: MapSpatialScene(width: 8, depth: 8),
        entities: [reopened],
      );
      const project = ProjectManifest(
        name: 'Counter',
        maps: [],
        tilesets: [],
        settings: ProjectSettings(dimension: ProjectDimension.threeD),
      );
      expect(
        validateMapEntityPresentation(
          project: project,
          map: map,
          entity: reopened,
        ),
        isEmpty,
      );
      final active = projectMapEntityPresentation(
        project: project,
        map: map,
        entity: reopened,
        gameState: GameState(saveId: 'save'),
      );
      expect(active!.counterInteractionSides, [EntityFacing.east]);
    },
  );
}
