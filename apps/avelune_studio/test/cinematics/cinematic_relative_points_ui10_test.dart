import 'dart:convert';

import 'package:avelune_studio/features/cinematics/application/cinematic_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_inspector.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_view_state.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_map_model.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../../../packages/map_core/test/fixtures/cinematic_facing_fixture.dart';
import '../support/cinematic_adapter_fixture.dart';

void main() {
  testWidgets(
    'relative point controls edit save reopen and replay from a new actor origin',
    (tester) async {
      final mapData = MapData(id: 'room', name: 'Room', size: const GridSize(width: 16, height: 16),
        entities: const [MapEntity(id: 'guide', kind: MapEntityKind.npc, pos: GridPos(x: 8, y: 8), npc: MapEntityNpcData())]);
      final base = facingCinematic(manual: true);
      final initial = CinematicAsset.fromJson({...base.toJson(), 'stageContext': {...base.stageContext!.toJson(),
        'actorBindings': [{'actorId': 'actor', 'kind': 'mapEntity', 'mapEntityId': 'guide'}],
        'initialPlacements': [{'actorId': 'actor', 'kind': 'fromMapEntity'}],
      }});
      final fixture = (await tester.runAsync(() async {
        final f = await CinematicAdapterFixture.create();
        final map = f.file('maps/room.json');
        await map.parent.create(recursive: true);
        await map.writeAsString(
          jsonEncode(
            mapData.toJson(),
          ),
        );
        await f.writeManifest(
          facingProject(initial),
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
      final view = CinematicViewState()..selection.add('move');
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
                model: CinematicMapModel(controller.active!.asset, controller.project, mapData),
                onDialogue: (_) {},
                onLocate: (_) async => null,
                onAdd: (_) {},
              ),
            ),
          ),
        ),
      );
      await mount();
      final picker = find.byKey(const ValueKey('cinematic-point-origin-destination'));
      expect(picker, findsOneWidget);
      await tester.ensureVisible(picker);
      await tester.tap(picker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Départ de actor').last);
      await tester.pumpAndSettle();
      expect(controller.active!.asset.stageContext!.stagePoints.last.relativeToActorId, 'actor');
      expect(controller.active!.asset.stageContext!.stagePoints.last.x, 3.5);
      await mount();
      final field = tester.widget<StudioCommitField>(find.byKey(const ValueKey('cinematic-point-x-destination')));
      expect(field.tryCommit!('3'), isTrue, reason: controller.error);
      expect(await tester.runAsync(controller.save), isTrue, reason: controller.error);
      final reopened = (await tester.runAsync(() => fixture.adapter().load('facing-scene')))!;
      expect(reopened.asset.stageContext!.stagePoints.last.relativeToActorId, 'actor');
      expect(reopened.asset.stageContext!.manualPaths.single.waypointStagePointIds, ['corner']);
      final movedMap = mapData.copyWith(entities: [mapData.entities.single.copyWith(pos: const GridPos(x: 4, y: 5))]);
      final movedModel = CinematicMapModel(reopened.asset, controller.project, movedMap);
      final plan = buildCinematicPreviewPlaybackPlan(cinematic: reopened.asset,
        actorDisplayPreviewModel: movedModel.actors, stageBounds: movedModel.bounds, availableMapIds: ['room']);
      final finalPose = plan.frameAt(plan.totalDurationMs).actorPoseById('actor')!;
      expect(finalPose.x, movedModel.actorOrigins['actor']!.x + 3);
      expect(finalPose.y, 5);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
