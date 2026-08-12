import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/personalization_hub.dart';

void main() {
  testWidgets('previews a replacing preset before one confirmed mutation', (
    tester,
  ) async {
    final previews = <ProjectPresentationProfile?>[];
    final commits = <ProjectPresentationProfile>[];
    const profile = ProjectPresentationProfile(
      dialogue: ProjectDialoguePresentationProfile(
        placement: ProjectDialoguePlacement.top,
      ),
    );
    await tester.pumpWidget(
      _app(
        PersonalizationSceneActions(
          scene: PersonalizationStudioScene.dialogue,
          profile: profile,
          onPreviewChanged: previews.add,
          onProfileChanged: commits.add,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('scene-preset-dialogue-bottom')),
    );
    await tester.pump();

    expect(previews, hasLength(1));
    expect(commits, isEmpty);
    expect(
      find.byKey(const ValueKey<String>('scene-preset-confirmation')),
      findsOneWidget,
    );
    expect(find.textContaining('dialogue, layouts.dialogue'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('scene-preset-apply')));
    await tester.pump();

    expect(commits, hasLength(1));
    expect(previews.last, isNull);
    expect(commits.single.dialogue?.placement, ProjectDialoguePlacement.bottom);
  });

  testWidgets('cancels a preset preview without a mutation', (tester) async {
    final previews = <ProjectPresentationProfile?>[];
    final commits = <ProjectPresentationProfile>[];
    const profile = ProjectPresentationProfile();
    await tester.pumpWidget(
      _app(
        PersonalizationSceneActions(
          scene: PersonalizationStudioScene.pause,
          profile: profile,
          onPreviewChanged: previews.add,
          onProfileChanged: commits.add,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('scene-preset-pause-sidebar')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('scene-preset-cancel')));
    await tester.pump();

    expect(commits, isEmpty);
    expect(previews.last, isNull);
    expect(
      find.byKey(const ValueKey<String>('scene-preset-confirmation')),
      findsNothing,
    );
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: ThemeData.dark(),
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 800, child: child)),
  ),
);
