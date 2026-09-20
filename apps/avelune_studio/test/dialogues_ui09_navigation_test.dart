import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_workspace_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_dialogue.dart';
import 'support/m2_ui_fixture.dart';
import 'support/ui05_narrative_fixture.dart';
import 'support/ui06_scene_fixture.dart';
import 'support/ui09_dialogue_harness.dart';
import 'support/ui09_runtime_fixture.dart';

Future<void> activate(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 15);
}

void main() {
  testWidgets(
    'scene opens exact dialogue and returns without losing dirty graph or text',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = (await tester.runAsync(
        () => Ui09DialogueHarness.create(tester),
      ))!;
      final visuals = (await tester.runAsync(
        () =>
            StudioMapResources.load(h.fixture.source.session, h.maps.project!),
      ))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(h.dispose);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: RepaintBoundary(
            key: h.captureKey,
            child: MapWorkspaceScreen(
              controller: h.maps,
              loadVisuals: (_, _) async => visuals,
              narrativePort: Ui05NarrativePort(
                LocalNarrativeAdapter(
                  session: h.fixture.source.session,
                  mapAdapter: h.fixture.maps,
                ),
                tester,
              ),
              scenePort: h.fixture.scenes,
              dialoguePort: h.port,
              onClose: () async {},
              registerExitGuard: (_) {},
              runtimeBuilder: (_, _, _) => const SizedBox(),
            ),
          ),
        ),
      );
      await pumpIo(tester);
      await activate(
        tester,
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Histoire'),
        ),
      );
      await activate(tester, find.text('Scènes').first);
      final scenePage = tester.widget<SceneBuilderPage>(
        find.byType(SceneBuilderPage),
      );
      expect(h.fixture.dirtyConsumer(scenePage.controller), isTrue);
      final state = scenePage.views.forScene(Ui06SceneFixture.sceneId);
      state.nodeId = 'conversation';
      scenePage.controller.changed();
      await pumpIo(tester);
      final before = scenePage.controller.active!.current;
      await activate(tester, find.text('Ouvrir le dialogue'));
      final page = tester.widget<DialogueWorkspacePage>(
        find.byType(DialogueWorkspacePage),
      );
      expect(page.controller.activeId, ui09DialogueId);
      expect(page.controller.active!.startNode, 'Accueil');
      final line = page.controller.active!.document.nodes.first.steps
          .whereType<DeLineStep>()
          .first;
      await activate(tester, find.byKey(ValueKey('dialogue-row-${line.id}')));
      final field = find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is StudioCommitField && w.label == 'Texte',
        ),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'Conversation encore en brouillon.');
      await activate(tester, find.text('Retour à la scène'));
      expect(find.byType(SceneBuilderPage), findsOneWidget);
      expect(scenePage.controller.active!.current, before);
      expect(scenePage.controller.dirty, isTrue);
      await h.capture(tester, '05-retour-scene-brouillon');
      expect(
        page.controller.active!.source,
        contains('Conversation encore en brouillon.'),
      );
      await activate(tester, find.text('Ouvrir le dialogue'));
      expect(
        page.controller.active!.source,
        contains('Conversation encore en brouillon.'),
      );
      expect(page.views.forDialogue(ui09DialogueId).stepId, line.id);
      expect(h.port.writes, 0);
      expect(tester.takeException(), isNull);
    },
  );
}
