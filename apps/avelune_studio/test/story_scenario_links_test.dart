import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/stories/story_scenario_links.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'support/story_backend_fixture.dart';
import 'support/story_canvas_test_harness.dart';

void main() {
  late StoryBackendFixture fixture;
  late StoryWorkspaceController controller;
  setUp(() async {
    final source = storyCanvasProject();
    fixture = await StoryBackendFixture.create(
      stories: source.storylines,
      facts: source.facts,
    );
    fixture.workspace.project = fixture.workspace.project!.copyWith(
      scenarios: source.scenarios,
    );
    controller = fixture.attach()..open('main');
  });
  tearDown(() => fixture.dispose());
  Future<void> mount(WidgetTester tester, {double scale = 1}) =>
      tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SizedBox(
                  width: 310,
                  child: StoryScenarioLinks(
                    key: UniqueKey(),
                    controller: controller,
                    storyId: 'main',
                    chapterId: 'chapter0',
                    stepId: 'step0_0',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  testWidgets(
    'role change preserves metadata, outcomes and existing effects at 150 percent text',
    (tester) async {
      final original = controller.active!;
      final link = StorylineSceneLink.fromJson({
        ...original.sceneLinks.single.toJson(),
        'metadata': {'future': 'keep'},
        'authorNotes': 'Conserver',
      });
      controller.apply(
        updateStoryline(
          controller.project,
          storylineId: 'main',
          storyline: original.copyWith(sceneLinks: [link]),
        ),
      );
      await mount(tester, scale: 1.5);
      await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Branche').last);
      await tester.pumpAndSettle();
      final updated = controller.active!.sceneLinks.single;
      expect(updated.role, StorylineSceneLinkRole.branch);
      expect(updated.metadata, link.metadata);
      expect(updated.authorNotes, link.authorNotes);
      expect(updated.outcomeLinks, link.outcomeLinks);
      expect(tester.takeException(), isNull);
      final remove = tester.widget<StudioButton>(
        find.ancestor(
          of: find.text('Retirer cette association'),
          matching: find.byType(StudioButton),
        ),
      );
      expect(remove.onPressed, isNull);
    },
  );
  testWidgets(
    'association starts with real declared sources and no fabricated effects',
    (tester) async {
      controller.apply(
        updateStoryline(
          controller.project,
          storylineId: 'main',
          storyline: controller.active!.copyWith(sceneLinks: []),
        ),
      );
      await mount(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rencontre · scenario').last);
      await tester.pumpAndSettle();
      final link = controller.active!.sceneLinks.single;
      expect(link.sceneRef!.targetId, 'scenario');
      expect(link.expectedOutcomeIds, ['accepted']);
      expect(link.outcomeLinks, isEmpty);
      await mount(tester);
      await tester.ensureVisible(find.text('Retirer cette association'));
      await tester.tap(find.text('Retirer cette association'));
      await tester.pump();
      expect(controller.active!.sceneLinks, isEmpty);
    },
  );
}
