import 'dart:convert';

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
    'completion picker edits both policies with undo and canonical save/reopen',
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
      final view = CinematicViewState()..inspectorTab = 'document';
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
      final picker = find.byWidgetPredicate(
        (widget) => widget is StudioSelect && widget.label == 'À la fin',
      );
      expect(picker, findsOneWidget);
      expect(tester.widget<StudioSelect>(picker).value, 'keepFinal');
      expect(
        find.text(
          'La pose comprend la position et l’orientation. Une annulation restaure toujours la pose de départ.',
        ),
        findsOneWidget,
      );
      final initial = controller.active!.asset;
      for (final entry in [
        (
          CinematicActorCompletionPolicy.restoreInitial,
          'Restaurer la pose de départ',
        ),
        (CinematicActorCompletionPolicy.keepFinal, 'Conserver la pose'),
      ]) {
        final previous = controller.active!.asset.actorCompletionPolicy;
        await tester.ensureVisible(picker);
        await tester.tap(picker);
        await tester.pumpAndSettle();
        await tester.tap(find.text(entry.$2).last);
        await tester.pumpAndSettle();
        expect(controller.active!.asset.actorCompletionPolicy, entry.$1);
        expect(controller.active!.asset.timeline, initial.timeline);
        expect(controller.active!.asset.stageContext, initial.stageContext);
        controller.undo();
        expect(controller.active!.asset.actorCompletionPolicy, previous);
        controller.redo();
        expect(controller.active!.asset.actorCompletionPolicy, entry.$1);
        expect(
          await tester.runAsync(controller.save),
          isTrue,
          reason: controller.error,
        );
        final reopened = (await tester.runAsync(
          () => fixture.adapter().load('facing-scene'),
        ))!;
        expect(reopened.asset, controller.active!.asset);
        expect(reopened.asset.actorCompletionPolicy, entry.$1);
        await mount();
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
