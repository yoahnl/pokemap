import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';
import 'spatial_field_traversal_action_test.dart' as fixture;

void main() {
  test('reset discards the height permission of a later Cascade segment', () {
    final map = fixture.traversalMap(steep: true);
    var state = fixture.traversalReady();
    final ticket = fixture.ticket(map, state)!;
    final controller = SpatialMovementController.fromMap(map: map, models: const [],
      spatialArrival: state.playerSpatialPosition);
    controller.setPaused(true);
    final first = fixture.plan(ticket, map, state)!;
    controller.setNativeTraversalPose(x: first.to.x, z: first.to.z,
      facing: EntityFacing.east, moving: false, animationSeconds: 0, fieldTraversalStep: first);
    state = (commitSpatialFieldTraversalStep(step: first, map: map, gameState: state,
      models: const [], currentStateRevision: 4) as SpatialFieldTraversalApplied).gameState;
    final second = fixture.plan(ticket, map, state, index: 1, revision: 5)!;
    controller.setNativeTraversalPose(x: 3, z: 1.5,
      facing: EntityFacing.east, moving: true, animationSeconds: .125, fieldTraversalStep: second);
    expect(controller.groundY, 1.5);
    controller.reset();
    expect(controller.x, 1.5);
    expect(controller.groundY, 0);
  });
  for (final whirlpool in [false, true]) {
    test('${whirlpool ? 'Whirlpool' : 'Waterfall'} blocks its body for ordinary spatial actors', () {
      final zone = MapGameplayZone(id: 'route', name: 'Route', kind: GameplayZoneKind.fieldAction,
        area: const MapRect(pos: GridPos(x: 1, y: 2), size: GridSize(width: 3, height: 1)),
        fieldAction: whirlpool ? const FieldActionZonePayload(actionKind: FieldActionZoneKind.whirlpool,
          whirlpool: WhirlpoolZonePayload(entry: GridPos(x: 0, y: 0), path: [GridPos(x: 1, y: 0)],
            exit: GridPos(x: 2, y: 0), direction: MapConnectionDirection.east)) :
          const FieldActionZonePayload(actionKind: FieldActionZoneKind.waterfall,
            waterfall: WaterfallZonePayload(entry: GridPos(x: 0, y: 0), path: [GridPos(x: 1, y: 0)],
              exit: GridPos(x: 2, y: 0), direction: MapConnectionDirection.east)));
      final map = MapData(id: 'field', name: 'Field', version: ProjectVersion.v9,
        size: const GridSize(width: 6, height: 6), gameplayZones: [zone],
        spatialScene: MapSpatialScene(width: 6, depth: 6));
      final controller = SpatialMovementController.fromMap(map: map, models: const [],
        spatialArrival: PlayerSpatialPosition(x: 1.5, z: 2.5),
        initialMovementMode: MovementMode.surf, waterPredicate: (x, z) => true);
      expect(controller.canTraverseActor(.5, 2.5, 1.5, 2.5), isTrue);
      expect(controller.canTraverseActor(3.5, 2.5, 4.5, 2.5), isTrue);
      expect(controller.canTraverseActor(1.5, 2.5, 2.5, 2.5), isFalse);
      expect(controller.canTraverseActor(2.5, 1.5, 2.5, 2.5), isFalse);
      controller.setInput(x: 1, z: 0, run: false);
      controller.update(1);
      expect(controller.x, lessThan(2));
      expect(() => SpatialMovementController.fromMap(map: map, models: const [],
        spatialArrival: PlayerSpatialPosition(x: 2.5, z: 2.5)), throwsStateError);
    });
  }
}
