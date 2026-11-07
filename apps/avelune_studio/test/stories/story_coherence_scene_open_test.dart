import 'package:avelune_studio/presentation/features/stories/story_coherence_dialog.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scene_canvas_test_harness.dart';

void main() {
  testWidgets('a coherence problem on a scene opens that scene', (
    tester,
  ) async {
    final scene = SceneCanvasTestHarness().scene;
    final story = StorylineAsset(
      id: 'main',
      title: 'Le départ',
      type: StorylineType.main,
      chapters: [
        StorylineChapter(
          id: 'chapter',
          order: 0,
          title: 'Chapitre',
          steps: [
            StorylineStep(
              id: 'step',
              title: 'Étape',
              order: 0,
              sceneLinkIds: [scene.id],
            ),
          ],
        ),
      ],
    );
    final project = ProjectManifest(
      name: 'Cohérence',
      maps: const [],
      tilesets: const [],
      scenes: [scene],
      storylines: [story],
    );
    final linked = diagnoseStorylineSceneLinks(project: project).diagnostics
        .where((diagnostic) => diagnostic.sceneId == scene.id);
    expect(linked, isNotEmpty);
    final opened = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showStoryCoherence(
                context,
                project,
                story.id,
                onOpenScene: opened.add,
              ),
              child: const Text('Vérifier'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Vérifier'));
    await tester.pumpAndSettle();
    final open = find.text('Ouvrir la scène ${scene.name}');
    expect(open, findsWidgets);
    await tester.tap(open.first);
    await tester.pumpAndSettle();
    expect(opened, [scene.id]);
    expect(find.text('Cohérence de l’histoire'), findsNothing);
  });
}
