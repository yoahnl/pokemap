import 'dart:convert';

import 'package:avelune_studio/presentation/features/cinematics/cinematic_map_model.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_map_overlay.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_inspector.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_core/test/fixtures/cinematic_facing_fixture.dart';
import '../support/cinematic_adapter_fixture.dart';

void main() {
  testWidgets(
    'jump preview lifts only the drawn actor and returns to its ground position',
    (tester) async {
      final base = facingCinematic(destinationX: 8, destinationY: 8).copyWith(
        timeline: CinematicTimeline(steps: [facingStep('face', 'left')]),
      );
      final asset = addCinematicTimelineActorJumpStep(
        facingProject(base),
        cinematicId: base.id,
        actorId: 'actor',
        targetId: 'destination',
        heightCells: 1,
      ).cinematic;
      final project = facingProject(asset);
      final map = MapData(
        id: 'room',
        name: 'Room',
        size: const GridSize(width: 16, height: 16),
      );
      final model = CinematicMapModel(asset, project, map);
      final plan = buildCinematicPreviewPlaybackPlan(
        cinematic: asset,
        actorDisplayPreviewModel: model.actors,
        availableMapIds: ['room'],
        stageBounds: model.bounds,
      );
      expect(plan.executableDurationMs, 1000);
      final transport = CinematicPreviewTransport()..install(plan);
      final view = CinematicViewState();
      final visuals = _JumpVisuals();
      addTearDown(() {
        transport.dispose();
        view.dispose();
        visuals.dispose();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              height: 320,
              child: CinematicMapOverlay(
                model: model,
                visuals: visuals,
                view: view,
                transport: transport,
                cell: const Size(20, 20),
                changed: () {},
                onPointMove: (_, _) {},
                beforeSelect: () => true,
              ),
            ),
          ),
        ),
      );
      transport.seek(0);
      await tester.pump();
      final actor = find.byKey(const ValueKey('cinematic-actor-actor'));
      final ground = tester.getTopLeft(actor);
      transport.seek(500);
      await tester.pump();
      final raised = tester.getTopLeft(actor);
      final pose = transport.frame!.actorPoseById('actor')!;
      expect(pose.x, 8);
      expect(pose.y, 8);
      expect(pose.liftCells, 1);
      expect(raised.dx, closeTo(ground.dx, .001));
      expect(raised.dy, closeTo(ground.dy - 20, .001));
      transport.seek(1000);
      await tester.pump();
      expect(tester.getTopLeft(actor), ground);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'jump inspector authors height duration target and facing with safe refusal and save/reopen',
    (tester) async {
      final fixture = (await tester.runAsync(() async {
        final f = await CinematicAdapterFixture.create();
        final map = f.file('maps/room.json');
        await map.parent.create(recursive: true);
        await map.writeAsString(
          jsonEncode(
            MapData(
              id: 'room',
              name: 'Room',
              size: const GridSize(width: 16, height: 16),
            ).toJson(),
          ),
        );
        await f.writeManifest(
          facingProject(facingCinematic(facingMode: null, manual: true)),
        );
        return f;
      }))!;
      late MapWorkspaceController maps;
      late NarrativeWorkspaceController narrative;
      late CinematicWorkspaceController controller;
      await tester.runAsync(() async {
        maps = MapWorkspaceController(fixture.session, fixture.maps);
        await maps.initialize();
        narrative = NarrativeWorkspaceController(
          maps,
          LocalNarrativeAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ),
          () {},
          (_, _) async {},
        );
        controller = CinematicWorkspaceController(
          narrative,
          fixture.adapter(),
          changed: () {},
        );
        await controller.open('facing-scene');
      });
      final jumpId = controller.addJump('actor', 'destination')!;
      final view = CinematicViewState()..selection.add(jumpId);
      addTearDown(() async {
        view.dispose();
        controller.dispose();
        narrative.dispose();
        maps.dispose();
        await fixture.dispose();
      });
      Future<void> mount() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 900,
              child: CinematicInspector(
                controller: controller,
                view: view,
                changed: () {},
                model: null,
                onDialogue: (_) {},
                onLocate: (_) async => null,
                onAdd: (_) {},
              ),
            ),
          ),
        ),
      );
      await mount();
      expect(find.text('Faire sauter un acteur'), findsWidgets);
      final step = controller.active!.asset.timeline.steps.firstWhere(
        (s) => s.id == jumpId,
      );
      expect(isCinematicTimelineActorJumpStep(step), isTrue);
      final height = find.byKey(ValueKey('jump-height-$jumpId'));
      expect(height, findsOneWidget);
      final field = find.descendant(
        of: height,
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(field);
      await tester.enterText(field, '0');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(view.error, contains('hauteur'));
      expect(
        cinematicTimelineActorJumpHeightCellsOf(
          controller.active!.asset.timeline.steps.firstWhere(
            (s) => s.id == jumpId,
          ),
        ),
        .5,
      );
      await tester.enterText(field, '1.25');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(view.error, isNull);
      expect(
        cinematicTimelineActorJumpHeightCellsOf(
          controller.active!.asset.timeline.steps.firstWhere(
            (s) => s.id == jumpId,
          ),
        ),
        1.25,
      );
      final duration = find.descendant(
        of: find.byKey(ValueKey('duration-facing-scene-$jumpId')),
        matching: find.byType(TextField),
      );
      await tester.ensureVisible(duration);
      await tester.enterText(duration, '100');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(
        controller.active!.asset.timeline.steps
            .firstWhere((s) => s.id == jumpId)
            .durationMs,
        1000,
      );
      expect(view.error, contains('durée du saut'));
      await tester.enterText(duration, '1400');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final facing = find.byWidgetPredicate(
        (w) =>
            w is StudioSelect &&
            w.label == 'Orientation pendant le déplacement',
      );
      await tester.ensureVisible(facing);
      await tester.tap(facing);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Conserver l’orientation').last);
      await tester.pumpAndSettle();
      expect(
        cinematicTimelineActorFacingModeOf(
          controller.active!.asset.timeline.steps.firstWhere(
            (s) => s.id == jumpId,
          ),
        ),
        CinematicTimelineActorFacingMode.preserve,
      );
      controller.undo();
      expect(
        cinematicTimelineActorFacingModeOf(
          controller.active!.asset.timeline.steps.firstWhere(
            (s) => s.id == jumpId,
          ),
        ),
        CinematicTimelineActorFacingMode.followMovement,
      );
      controller.redo();
      expect(
        await tester.runAsync(controller.save),
        isTrue,
        reason: controller.error,
      );
      final reopened = (await tester.runAsync(
        () => fixture.adapter().load('facing-scene'),
      ))!;
      expect(reopened.asset, controller.active!.asset);
      expect(
        reopened.asset.timeline.steps
            .firstWhere((s) => s.id == jumpId)
            .durationMs,
        1400,
      );
      expect(
        reopened.asset.stageContext!.manualPaths.single.waypointStagePointIds,
        ['corner'],
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

class _JumpVisuals extends ChangeNotifier implements MapWorkspaceVisuals {
  @override
  Future<void> dispose() async => super.dispose();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
