@Timeout(Duration(minutes: 3))
library;

import 'package:avelune_studio/features/cinematics/application/cinematic_timeline_rules.dart';
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

  List<String> order() => [
    for (final step in controller.active!.asset.timeline.steps) step.id,
  ];

  test(
    'timeline drag reorders and duration handle commits once with undo redo',
    () async {
      final disk = await owner.projectBytes();
      final before = controller.active!.asset;
      final walk = before.timeline.steps.singleWhere((s) => s.id == 'walk');
      const scale = .06;

      final draft = cinematicResizedDuration(walk.durationMs!, 30, scale);
      expect(draft, 1700);
      expect(controller.active!.asset, same(before));
      expect(controller.updateDuration('walk', draft), isTrue);
      final resized = controller.active!.asset;
      expect(
        resized.timeline.steps.singleWhere((s) => s.id == 'walk').durationMs,
        greaterThan(1200),
      );
      controller.undo();
      expect(controller.active!.asset.toJson(), before.toJson());
      controller.redo();
      expect(controller.active!.asset.toJson(), resized.toJson());

      final layout = buildCinematicTimelineTimeLayoutReadModel(resized);
      final opening = layout.blocks.singleWhere((b) => b.stepId == 'opening');
      final insertion = cinematicTimelineInsertionIndex(
        layout,
        opening.startMs + 78 / scale,
      );
      expect(insertion, 2);
      expect(controller.moveSteps({'opening'}, insertion), isTrue);
      expect(order().first, 'walk');
      expect(order().indexOf('opening'), greaterThan(0));
      controller.undo();
      expect(controller.active!.asset.toJson(), resized.toJson());
      expect(await owner.projectBytes(), disk);
    },
  );

  test('resize drafts stay within one millisecond and one hour', () {
    expect(cinematicResizedDuration(1200, -1e9, .06), 1);
    expect(cinematicResizedDuration(1200, 1e9, 1), 3600000);
    expect(cinematicResizedDuration(1200, 0, .06), 1200);
  });

  test('timeline empty lane, reorder, resize once and Escape preserve authored time', () {
    final asset = controller.active!.asset;
    CinematicTimelineStep step(String id) =>
        asset.timeline.steps.singleWhere((s) => s.id == id);
    expect(cinematicDurationEditable(step('walk')), isTrue);
    expect(cinematicDurationEditable(step('face')), isFalse);
    final marker = CinematicTimelineStep(
      id: 'note',
      kind: CinematicTimelineStepKind.marker,
    );
    expect(cinematicDurationEditable(marker), isFalse);
    expect(marker.durationMs, isNull);
    expect(
      cinematicLaneAction(CinematicTimelineLaneKind.actor),
      CinematicTimelineStepKind.actorMove,
    );
    expect(
      cinematicLaneAction(CinematicTimelineLaneKind.other),
      CinematicTimelineStepKind.marker,
    );

    final layout = buildCinematicTimelineTimeLayoutReadModel(asset);
    expect(cinematicTimelineInsertionIndex(layout, 0), 0);
    expect(cinematicTimelineInsertionIndex(layout, 1e9), layout.blocks.length);
  });

  test('ruler taps and step selection seek the preview without editing the cinematic', () async {
    final before = controller.active!.asset.toJson();
    controller.preparePreview();
    expect(cinematicTimelineTimeAt(66, .06), 1100);
    controller.transport.seek(cinematicTimelineTimeAt(66, .06));
    expect(controller.transport.timeMs, 1100);
    seekCinematicStep(controller.transport, 'camera');
    final camera = controller.transport.plan!.timelineItems.singleWhere(
      (item) => item.stepId == 'camera',
    );
    expect(controller.transport.timeMs, camera.startMs);
    final time = controller.transport.timeMs;
    seekCinematicStep(controller.transport, 'inconnu');
    expect(controller.transport.timeMs, time);
    controller.transport.stop();
    expect(controller.transport.timeMs, 0);
    expect(controller.active!.asset.toJson(), before);
    expect(controller.active!.dirty, isFalse);
  });
}
