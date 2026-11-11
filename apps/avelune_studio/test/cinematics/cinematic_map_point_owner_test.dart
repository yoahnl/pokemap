@Timeout(Duration(minutes: 3))
library;

import 'package:avelune_studio/features/cinematics/application/cinematic_map_point.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_workspace_owner_fixture.dart';

void main() {
  late CinematicWorkspaceOwnerFixture owner;
  late CinematicWorkspaceController controller;
  late int width, height;
  setUp(() async {
    owner = await CinematicWorkspaceOwnerFixture.create();
    controller = owner.controller;
    await owner.open();
    final map = await owner.loadMap('jardin');
    width = map.size.width;
    height = map.size.height;
  });
  tearDown(() => owner.dispose());

  CinematicAsset asset() => controller.active!.asset;

  CinematicMapPointOutcome? click(
    CinematicMapMode mode,
    double x,
    double y, {
    String? stepId,
    String? actorId,
  }) => controller.applyMapPoint(
    mode: mode,
    stepId: stepId,
    actorId: actorId,
    x: x,
    y: y,
    width: width,
    height: height,
  );

  CinematicStagePoint point(String id) =>
      asset().stageContext!.stagePoints.singleWhere((p) => p.id == id);

  test('select and pan ignore clicks and an outside click edits nothing', () {
    final before = asset();
    expect(click(CinematicMapMode.select, 2, 2, stepId: 'walk'), isNull);
    expect(click(CinematicMapMode.pan, 2, 2, stepId: 'walk'), isNull);
    for (final (x, y) in [(-1.0, 2.0), (2.0, -1.0), (width * 1.0, 2.0), (2.0, height * 1.0)]) {
      final outcome = click(CinematicMapMode.destination, x, y, stepId: 'walk');
      expect(outcome?.mode, CinematicMapMode.destination);
      expect(outcome?.error, cinematicMapPointOutsideError);
    }
    expect(asset(), same(before));
  });

  test(
    'a destination click gives the move its own stage point and returns to select',
    () async {
      final outcome = click(CinematicMapMode.destination, 3, 4, stepId: 'walk');
      expect(outcome?.mode, CinematicMapMode.select);
      expect(outcome?.error, isNull);
      final walk = asset().timeline.steps.singleWhere((s) => s.id == 'walk');
      expect(walk.targetId, isNot('destination'));
      final binding = asset().stageContext!.movementTargetBindings.singleWhere(
        (b) => b.targetId == walk.targetId,
      );
      expect((point(binding.sourceId!).x, point(binding.sourceId!).y), (3, 4));
      expect(point('arrival').x, 13);

      expect(await controller.save(), isTrue, reason: controller.error);
      final saved = await owner.reread();
      expect(
        saved.timeline.steps.singleWhere((s) => s.id == 'walk').targetId,
        walk.targetId,
      );
    },
  );

  test('a refused destination keeps the destination mode', () {
    final before = asset();
    final outcome = click(CinematicMapMode.destination, 3, 4, stepId: 'face');
    expect(outcome?.mode, CinematicMapMode.destination);
    expect(outcome?.error, isNull);
    expect(controller.error, contains('déplacement'));
    expect(asset(), same(before));

    final idle = click(CinematicMapMode.destination, 3, 4);
    expect(idle?.mode, CinematicMapMode.destination);
    expect(asset(), same(before));
  });

  test(
    'a placement click stages the actor and path clicks append waypoints in path mode',
    () {
      final placed = click(CinematicMapMode.placement, 3, 5, actorId: 'chief');
      expect(placed?.mode, CinematicMapMode.select);
      final placement = asset().stageContext!.initialPlacements.singleWhere(
        (p) => p.actorId == 'chief',
      );
      expect(placement.kind, CinematicActorInitialPlacementKind.stagePoint);
      expect(
        (point(placement.stagePointId!).x, point(placement.stagePointId!).y),
        (3, 5),
      );

      expect(
        click(CinematicMapMode.path, 4, 4, stepId: 'walk')?.mode,
        CinematicMapMode.path,
      );
      expect(
        click(CinematicMapMode.path, 5, 4, stepId: 'walk')?.mode,
        CinematicMapMode.path,
      );
      final path = asset().stageContext!.manualPaths.singleWhere(
        (p) => p.ownerActorMoveStepId == 'walk',
      );
      expect([
        for (final id in path.waypointStagePointIds) (point(id).x, point(id).y),
      ], [(4, 4), (5, 4)]);
    },
  );
}
