@Timeout(Duration(minutes: 3))
library;

import 'package:avelune_studio/features/cinematics/application/cinematic_inspector_rules.dart';
import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_workspace_owner_fixture.dart';

void main() {
  late CinematicWorkspaceOwnerFixture owner;
  late CinematicWorkspaceController controller;
  setUp(() async {
    owner = await CinematicWorkspaceOwnerFixture.create();
    controller = owner.controller;
    await owner.open();
  });
  tearDown(() => owner.dispose());

  CinematicAsset asset() => controller.active!.asset;
  CinematicStagePoint point(String id) =>
      asset().stageContext!.stagePoints.singleWhere((p) => p.id == id);

  ProjectManifest withDimension(ProjectDimension dimension) => controller
      .project
      .copyWith(settings: controller.project.settings.copyWith(dimension: dimension));

  test('an unknown inspector tab falls back to the properties tab', () {
    for (final tab in cinematicInspectorTabIds) {
      expect(cinematicInspectorTab(tab), tab);
    }
    expect(cinematicInspectorTab('actions'), 'properties');
    expect(cinematicInspectorTab(''), 'properties');
  });

  test('the actor crossing option is only offered on 3D projects', () {
    expect(cinematicCrossingEditable(withDimension(ProjectDimension.threeD)), isTrue);
    expect(cinematicCrossingEditable(withDimension(ProjectDimension.twoD)), isFalse);
  });

  test('command steps only offer project media of their own kind', () {
    final project = controller.project.copyWith(
      cinematicMediaAssets: [
        for (final (id, kind) in [
          ('pas', CinematicMediaAssetKind.sound),
          ('theme', CinematicMediaAssetKind.music),
          ('eclair', CinematicMediaAssetKind.cinematicFx),
          ('cloche', CinematicMediaAssetKind.sound),
        ])
          CinematicMediaAsset(
            id: id,
            label: id,
            kind: kind,
            relativePath: 'audio/$id.ogg',
          ),
      ],
    );
    List<String> choices(CinematicTimelineStepKind kind) => [
      for (final media in cinematicCommandMediaChoices(
        project,
        CinematicTimelineStep(id: 'step', kind: kind),
      ))
        media.id,
    ];
    expect(choices(CinematicTimelineStepKind.sound), ['pas', 'cloche']);
    expect(choices(CinematicTimelineStepKind.music), ['theme']);
    expect(choices(CinematicTimelineStepKind.fx), ['eclair']);
    expect(choices(CinematicTimelineStepKind.shake), isEmpty);
    expect(cinematicCommandMediaKind(CinematicTimelineStepKind.wait), isNull);
  });

  test(
    'a typed stage point coordinate replaces one axis and is saved',
    () async {
      final arrival = point('arrival');
      expect(cinematicStagePointWithAxis(arrival, 'x', 'loin'), isNull);
      expect(cinematicStagePointWithAxis(arrival, 'x', 'Infinity'), isNull);
      expect(cinematicStagePointWithAxis(arrival, 'x', '1,5'), isNull);
      final moved = cinematicStagePointWithAxis(arrival, 'x', '11.5')!;
      expect((moved.x, moved.y, moved.label), (11.5, 9, arrival.label));
      expect(cinematicStagePointWithAxis(arrival, 'y', '3')!.x, 13);

      expect(controller.setStagePoint(moved), isTrue, reason: controller.error);
      expect(point('arrival').x, 11.5);
      expect(await controller.save(), isTrue, reason: controller.error);
      final saved = (await owner.reread()).stageContext!.stagePoints
          .singleWhere((p) => p.id == 'arrival');
      expect((saved.x, saved.y), (11.5, 9));
    },
  );

  test(
    'waypoints move up one place or leave the path without touching the source list',
    () async {
      final size = (await owner.loadMap('jardin')).size;
      for (final x in [3.0, 4.0, 5.0]) {
        expect(
          controller.appendWaypoint(
            'walk',
            x,
            4,
            width: size.width,
            height: size.height,
          ),
          isTrue,
          reason: controller.error,
        );
      }
      List<String> ids() => asset().stageContext!.manualPaths
          .singleWhere((p) => p.ownerActorMoveStepId == 'walk')
          .waypointStagePointIds;
      final original = ids();
      final [a, b, c] = original;

      expect(controller.setManualPath('walk', cinematicWaypointsMovedUp(original, 2)), isTrue);
      expect(ids(), [a, c, b]);
      expect(original, [a, b, c]);

      expect(controller.setManualPath('walk', cinematicWaypointsWithout(ids(), 0)), isTrue);
      expect(ids(), [c, b]);
      expect(await controller.save(), isTrue, reason: controller.error);
      expect(
        (await owner.reread()).stageContext!.manualPaths
            .singleWhere((p) => p.ownerActorMoveStepId == 'walk')
            .waypointStagePointIds,
        [c, b],
      );
    },
  );
}
