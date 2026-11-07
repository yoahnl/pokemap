import 'package:avelune_studio/presentation/features/stories/story_library_panel.dart';
import 'package:avelune_studio/presentation/features/stories/story_metadata_fields.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final stories = [
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Aventure',
      chapters: [
        StorylineChapter(
          id: 'departure',
          title: 'Départ du bourg',
          order: 0,
          steps: [
            StorylineStep(
              id: 'got_dex',
              title: 'Recevoir le Pokédex',
              order: 0,
            ),
          ],
        ),
      ],
    ),
    StorylineAsset(
      id: 'side',
      type: StorylineType.sideQuest,
      title: 'Le phare',
      chapters: [
        StorylineChapter(
          id: 'lighthouse',
          title: 'Rallumer le phare',
          order: 0,
          steps: [StorylineStep(id: 'oil', title: 'Trouver l’huile', order: 0)],
        ),
      ],
    ),
  ];

  Future<TextEditingController> pump(WidgetTester tester) async {
    final search = TextEditingController();
    addTearDown(search.dispose);
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => StoryLibraryPanel(
              stories: stories,
              activeId: null,
              search: search,
              type: null,
              dirtyIds: const {},
              onSearch: () => setState(() {}),
              onType: (_) {},
              onOpen: (_) {},
              onCreate: () {},
            ),
          ),
        ),
      ),
    );
    return search;
  }

  testWidgets('the story library finds a story through its steps', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'pokédex');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-library-main')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-library-side')), findsNothing);
    final choice = tester.widget<StudioChoice>(
      find.byKey(const ValueKey('story-library-main')),
    );
    expect(choice.subtitle, contains('Étape : Recevoir le Pokédex'));
    expect(choice.subtitle, contains('Départ du bourg'));
  });

  testWidgets('the story library finds a story through its chapters', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'rallumer');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-library-side')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-library-main')), findsNothing);
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('story-library-side')),
          )
          .subtitle,
      contains('Chapitre : Rallumer le phare'),
    );
  });

  test('a step condition names a fact through its runtime flag', () {
    final project = ProjectManifest(
      name: 'Exemple',
      maps: const [],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(
          id: 'rival_seen',
          label: 'Rival rencontré',
          legacyFlagName: 'rival_flag',
        ),
      ],
    );
    expect(
      storyConditionText(
        ScriptCondition(
          type: ScriptConditionType.flagIsSet,
          params: const {ScriptConditionParams.flagName: 'rival_flag'},
        ),
        project,
      ),
      'Rival rencontré = Oui',
    );
    expect(
      storyConditionText(
        ScriptCondition(
          type: ScriptConditionType.flagIsUnset,
          params: const {ScriptConditionParams.flagName: 'ghost'},
        ),
        project,
      ),
      'État introuvable conservé : ghost = Non',
    );
  });
}
