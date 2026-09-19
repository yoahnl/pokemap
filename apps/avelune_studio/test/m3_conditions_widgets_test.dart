import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/dialogue_editing_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_interaction_pane.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'support/capture_m3_widget.dart';
import 'support/load_desktop_capture_fonts.dart';
import 'support/m3_story_fixture.dart';

void main() {
  testWidgets(
    'real conditions and ordered sequence stay editable at enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late M3StoryFixture fixture;
      late MapWorkspaceController workspace;
      late NarrativeWorkspaceController narrative;
      late StudioMapResources visuals;
      final changes = ValueNotifier(0);
      await tester.runAsync(() async {
        await loadDesktopCaptureFonts();
        fixture = await M3StoryFixture.create();
        workspace = MapWorkspaceController(fixture.session, fixture.maps);
        await workspace.initialize();
        visuals = await StudioMapResources.load(
          fixture.session,
          workspace.project!,
        );
        narrative = NarrativeWorkspaceController(
          workspace,
          LocalNarrativeAdapter(
            session: fixture.session,
            mapAdapter: fixture.maps,
          ),
          () => changes.value++,
          (project, paths) =>
              visuals.updateCatalog(project, changedRelativePaths: paths),
        );
        final record = workspace.project!.eventRegistry!.records.firstWhere(
          (r) => r.definitionOrNull!.name == 'Autoriser le départ',
        );
        await narrative.openRecord(record);
      });
      addTearDown(() async {
        changes.dispose();
        workspace.dispose();
        await visuals.dispose();
        await fixture.directory.delete(recursive: true);
      });
      final capture = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: RepaintBoundary(
            key: capture,
            child: Scaffold(
              body: ValueListenableBuilder<int>(
                valueListenable: changes,
                builder: (_, _, _) => MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: NarrativeInteractionPane(
                    controller: narrative,
                    visuals: visuals,
                    onBack: () {},
                    onTest: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Conditions et répétition'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final fields = tester.widgetList<DropdownButton<String>>(
        find.byType(DropdownButton<String>),
      );
      expect(
        fields.any(
          (field) => field.items!.any((item) => item.value == 'visited'),
        ),
        isTrue,
      );
      final before = narrative
          .active!
          .current
          .interaction
          .conditions
          .first
          .expectedNarrativeValue;
      await tester.ensureVisible(find.text('est activé').first);
      await tester.tap(find.text('est activé').first);
      await tester.pump();
      expect(
        narrative
            .active!
            .current
            .interaction
            .conditions
            .first
            .expectedNarrativeValue,
        isNot(before),
      );
      narrative.active!.restore(redo: false);
      narrative.changed();
      await tester.pump();
      await tester.ensureVisible(find.text('Après la conversation'));
      await tester.tap(find.text('Après la conversation'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        narrative.active!.current.interaction.steps.first.kind,
        NarrativeSequenceKind.facing,
      );
      await tester.ensureVisible(find.byTooltip('Descendre l’action').first);
      await tester.tap(find.byTooltip('Descendre l’action').first);
      await tester.pump();
      expect(
        narrative.active!.current.interaction.steps.first.kind,
        NarrativeSequenceKind.wait,
      );
      narrative.active!.restore(redo: false);
      narrative.changed();
      await tester.pump();
      tester.view.physicalSize = const Size(1120, 900);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Conditions et répétition'));
      await tester.pumpAndSettle();
      await captureM3Widget(tester, capture, '04-conditions-sequence');
      expect(tester.takeException(), isNull);
      final editor = DialogueEditingController(
        narrative.active!,
        narrative.changed,
      );
      editor.addChoice();
      final outcome = editor.branch.choices.last.outcomeId!;
      expect(narrative.active!.current.interaction.branches[outcome], isEmpty);
      expect(
        narrative.active!.current.interaction
            .project()
            .scene
            .graph
            .nodes
            .where((node) => node.payload is SceneYarnDialoguePayload)
            .first
            .payload,
        isA<SceneYarnDialoguePayload>().having(
          (payload) => payload.expectedOutcomes,
          'outcomes',
          contains(outcome),
        ),
      );
      final source = narrative.active!.current.interaction.source;
      final greatest = narrative.project.eventRegistry!.records
          .where((record) => record.definitionOrNull?.source == source)
          .map((record) => record.definitionOrNull!.order)
          .reduce((a, b) => a > b ? a : b);
      await narrative.openSource(workspace.active!, source, 'Variante');
      expect(narrative.active!.current.interaction.order, greatest + 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
