import 'dart:io';

import 'package:avelune_studio/features/cinematics/data/local_cinematic_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_overview.dart';
import 'package:avelune_studio/presentation/features/cinematics/cinematic_workspace_page.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_overview_landing.dart';
import 'package:avelune_studio/presentation/features/stories/story_progression_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_action_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m2_ui_fixture.dart';
import '../support/ui07_story_fixture.dart';
import '../support/ui08_workspace_harness.dart';
import '../support/ui10_widget_port.dart';

Future<Map<String, String>> _tree(Directory root) async => {
  for (final file in root.listSync(recursive: true).whereType<File>())
    file.path.substring(root.path.length): String.fromCharCodes(
      await file.readAsBytes(),
    ),
};

Future<void> _openStory(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(StudioPrimaryNavigation),
      matching: find.byTooltip('Histoire'),
    ),
  );
  await pumpIo(tester, frames: 12);
  expect(find.byType(NarrativeOverviewLanding), findsOneWidget);
}

Future<void> _start(WidgetTester tester, String intent) async {
  final button = find.byKey(ValueKey('narrative-intent-start-$intent'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await pumpIo(tester, frames: 15);
}

void main() {
  testWidgets(
    'UX-22 intent entries open the existing editors and create nothing implicitly',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final workspace = (await tester.runAsync(
        () => Ui08WorkspaceHarness.create(tester),
      ))!;
      final cinematics = Ui10WidgetPort(
        LocalCinematicAdapter(
          session: workspace.source.session,
          mapAdapter: workspace.source.maps,
        ),
        tester,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(workspace.dispose);
      });
      final before = (await tester.runAsync(
        () => _tree(workspace.source.directory),
      ))!;
      await tester.pumpWidget(workspace.app(cinematicPort: cinematics));
      await pumpIo(tester);
      await _openStory(tester);

      expect(find.text('Qu’aimeriez-vous créer ?'), findsOneWidget);
      for (final title in [
        'Faire parler un personnage',
        'Déclencher une scène en entrant',
        'Créer une quête',
        'Mettre en scène un déplacement',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      for (final direct in [
        'Nouvelle histoire',
        'Nouvelle scène',
        'Nouvel événement',
        'Cinématiques sur carte',
        'Cinématiques de présentation',
        'Vérification narrative',
      ]) {
        expect(find.widgetWithText(StudioActionCard, direct), findsOneWidget);
      }
      expect(find.text('Histoires du projet · 2'), findsOneWidget);
      expect(find.textContaining('Indisponible'), findsNothing);

      await _start(tester, 'movement');
      final cinematicPage = tester.widget<CinematicWorkspacePage>(
        find.byType(CinematicWorkspacePage),
      );
      expect(cinematicPage.controller.activeId, isNull);
      expect(cinematicPage.controller.dirty, isFalse);
      await _openStory(tester);

      await _start(tester, 'scene-on-enter');
      final eventPage = tester.widget<EventWorkspacePage>(
        find.byType(EventWorkspacePage),
      );
      expect(eventPage.controller.activeId, isNull);
      expect(eventPage.controller.dirty, isFalse);
      await _openStory(tester);

      await _start(tester, 'character-talk');
      expect(
        tester
            .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
            .activeSpace,
        'map',
      );
      expect(
        find.text(
          'Choisissez un personnage sur la carte ou tracez une zone avec l’outil Zone.',
        ),
        findsOneWidget,
      );
      expect(workspace.maps.active?.dirty, isFalse);
      await _openStory(tester);

      expect(
        (await tester.runAsync(() => _tree(workspace.source.directory)))!,
        before,
      );
      expect(workspace.narrative.publications, 0);

      await _start(tester, 'quest');
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        tester
            .widget<StudioSelect>(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(StudioSelect),
              ),
            )
            .value,
        StorylineType.sideQuest.name,
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Annuler'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(StoryProgressionPage), findsNothing);
      expect(find.text('Histoires du projet · 2'), findsOneWidget);

      await _start(tester, 'quest');
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Retrouver le chat',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(StudioButton, 'Créer'));
      await pumpIo(tester, frames: 12);
      final progression = tester.widget<StoryProgressionPage>(
        find.byType(StoryProgressionPage),
      );
      expect(progression.controller.active?.title, 'Retrouver le chat');
      expect(progression.controller.active?.type, StorylineType.sideQuest);
      expect(progression.controller.stories, hasLength(3));

      expect(workspace.narrative.publications, 0);
    },
  );

  testWidgets(
    'UX-23.3 the story synthesis opens each story graph and keeps the cards',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final workspace = (await tester.runAsync(
        () => Ui08WorkspaceHarness.create(tester),
      ))!;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        await tester.runAsync(workspace.dispose);
      });
      final before = (await tester.runAsync(
        () => _tree(workspace.source.directory),
      ))!;
      await tester.pumpWidget(workspace.app());
      await pumpIo(tester);
      await _openStory(tester);

      final synthesis = find.byKey(const ValueKey('narrative-story-synthesis'));
      expect(find.text('Synthèse des histoires · 2'), findsOneWidget);
      for (final header in ['Chapitres', 'Étapes', 'Scènes liées']) {
        expect(
          find.descendant(of: synthesis, matching: find.text(header)),
          findsOneWidget,
        );
      }
      final side = find.byKey(
        const ValueKey('narrative-synthesis-${Ui07StoryFixture.sideId}'),
      );
      expect(
        find.descendant(of: side, matching: find.text('Secondaire')),
        findsOneWidget,
      );
      final main = find.byKey(
        const ValueKey('narrative-synthesis-${Ui07StoryFixture.mainId}'),
      );
      final story = Ui07StoryFixture.mainStory();
      expect(
        find.descendant(
          of: main,
          matching: find.text('${story.chapters.length}'),
        ),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: main,
          matching: find.text(
            '${story.chapters.expand((chapter) => chapter.steps).length}',
          ),
        ),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('overview-story-${Ui07StoryFixture.mainId}')),
        findsOneWidget,
      );

      await tester.ensureVisible(side);
      await tester.tap(side);
      await pumpIo(tester, frames: 12);
      final opened = tester.widget<StoryProgressionPage>(
        find.byType(StoryProgressionPage),
      );
      expect(opened.controller.activeId, Ui07StoryFixture.sideId);
      expect(opened.controller.dirty, isFalse);

      await _openStory(tester);
      await tester.ensureVisible(main);
      await tester.tap(main);
      await pumpIo(tester, frames: 12);
      expect(
        tester
            .widget<StoryProgressionPage>(find.byType(StoryProgressionPage))
            .controller
            .activeId,
        Ui07StoryFixture.mainId,
      );
      expect(
        (await tester.runAsync(() => _tree(workspace.source.directory)))!,
        before,
      );
      expect(workspace.narrative.publications, 0);
    },
  );

  testWidgets(
    'an intent whose editor is not loaded stays disabled and says so',
    (tester) async {
      tester.view.physicalSize = const Size(1500, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final search = TextEditingController();
      final scroll = ScrollController();
      addTearDown(search.dispose);
      addTearDown(scroll.dispose);
      var talks = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: NarrativeOverviewLanding(
              overview: NarrativeOverview(
                stories: const [],
                facts: const [],
                interactions: const [],
                stepsById: const {},
                stepLinks: const {},
                factLinks: const {},
                dirtyCount: 0,
              ),
              project: ProjectManifest(
                name: 'Recette',
                tilesets: const [],
                maps: const [],
              ),
              scenes: const [],
              dialogues: const [],
              events: const [],
              search: search,
              onSearch: (_) {},
              resultsScroll: scroll,
              onLibrary: () {},
              onCreateStory: null,
              onCreateScene: null,
              onCreateEvent: null,
              onCreateInteraction: () => talks++,
              onProgression: null,
              onScenes: null,
              onEvents: null,
              onVerification: null,
              onOpenStory: (_) {},
              onOpenStep: (_, _) {},
              onOpenScene: null,
              onOpenInteraction: (_) {},
              onOpenDialogue: null,
              onOpenEvent: null,
              onOpenMap: null,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      StudioButton start(String id) => tester.widget<StudioButton>(
        find.byKey(ValueKey('narrative-intent-start-$id')),
      );
      expect(start('character-talk').onPressed, isNotNull);
      for (final id in ['scene-on-enter', 'quest', 'movement']) {
        expect(start(id).onPressed, isNull);
      }
      expect(
        find.text(
          'Indisponible : cet éditeur n’est pas chargé pour ce projet.',
        ),
        findsNWidgets(3),
      );
      expect(find.text('Synthèse des histoires · 0'), findsOneWidget);
      expect(
        find.text('Aucune histoire à résumer pour le moment.'),
        findsOneWidget,
      );
      expect(find.text('Ouvrir les graphes'), findsNothing);
      await tester.tap(
        find.byKey(const ValueKey('narrative-intent-start-character-talk')),
      );
      await tester.pump();
      expect(talks, 1);
    },
  );
}
