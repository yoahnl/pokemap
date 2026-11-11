import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/application/scene_workspace_controller.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_action_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_resource_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m2_ui_fixture.dart';
import '../support/ui05_narrative_fixture.dart';
import '../support/ui05_story_backend_fixture.dart';

void main() {
  test(
    'scene owner still creates saves and cold reopens a native draft',
    () async {
      final fixture = await createUi05StoryBackend();
      addTearDown(() => fixture.directory.delete(recursive: true));
      final maps = MapWorkspaceController(fixture.session, fixture.maps);
      addTearDown(maps.dispose);
      await maps.initialize();
      final scenes = SceneWorkspaceController(
        maps,
        LocalSceneAdapter(session: fixture.session, mapAdapter: fixture.maps),
        changed: () {},
      );
      addTearDown(scenes.dispose);
      final previous = scenes.scenes.first;
      expect(scenes.open(previous.id), isTrue);
      final count = scenes.scenes.length;
      final created = scenes.create('Arrivée du train')!;
      final id = created.current.id;
      expect(id, isNot(previous.id));
      expect(scenes.scenes, hasLength(count + 1));
      expect(created.dirty, isTrue);
      expect(await scenes.save(), isTrue, reason: scenes.error);
      expect(created.dirty, isFalse);
      final reopened = await LocalMapWorkspaceAdapter().loadProject(
        fixture.session,
      );
      expect(
        reopened.scenes.singleWhere((scene) => scene.id == id),
        created.current,
      );
      expect(
        reopened.scenes.singleWhere((scene) => scene.id == previous.id),
        previous,
      );
    },
  );

  testWidgets(
    'large story collections keep the overview bounded and searchable',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => Ui05NarrativeFixture.create(tester, extraStories: 1000),
      ))!;
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app(tester, withOwners: true));
      await pumpIo(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Histoire'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Histoires du projet · 1002'), findsOneWidget);
      expect(find.byType(StudioResourceCard), findsNWidgets(6));
      expect(fixture.port.artworkReads, lessThanOrEqualTo(12));
      expect(fixture.port.dialogueReads, 0);
      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher dans Histoire'),
        'Collection',
      );
      await tester.pumpAndSettle();
      expect(find.text('Résultats · 1000'), findsOneWidget);
      expect(find.text('Collection 999'), findsNothing);
      expect(
        find.byKey(const ValueKey('overview-result-Histoire-collection-999')),
        findsNothing,
      );
      final overview = tester.widget<NarrativeStoryPane>(
        find.byType(NarrativeStoryPane),
      );
      final scroll = overview.viewState.resultsScroll;
      expect(find.byType(StudioActionCard).evaluate().length, lessThan(20));
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('overview-result-Histoire-collection-999')),
        findsOneWidget,
      );
      expect(find.byType(StudioActionCard).evaluate().length, lessThan(20));
      final offset = scroll.offset;
      await tester.tap(
        find.byKey(const ValueKey('overview-result-Histoire-collection-999')),
      );
      await tester.pumpAndSettle();
      expect(overview.storyOwner!.activeId, 'collection-999');
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Histoire'),
        ),
      );
      await tester.pumpAndSettle();
      expect(scroll.offset, offset);
      expect(find.text('Résultats · 1000'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('overview-result-Histoire-collection-999')),
        findsOneWidget,
      );
      expect(fixture.port.dialogueReads, 0);
      expect(fixture.port.artworkReads, lessThanOrEqualTo(12));
    },
  );

  testWidgets(
    'filter leaves a neutral detail until a visible story is selected',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => Ui05NarrativeFixture.create(tester),
      ))!;
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app(tester, withOwners: true));
      await pumpIo(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Histoire'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.widgetWithText(StudioButton, 'Voir tous les documents'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher dans Histoire'),
        'Les traces du jardin',
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Sélectionnez une histoire correspondante'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('story-garden-traces')));
      await tester.pumpAndSettle();
      expect(find.text('Une piste discrète'), findsWidgets);
    },
  );

  testWidgets(
    'overview keeps scene creation unavailable and creates an event through its owner',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => Ui05NarrativeFixture.create(tester),
      ))!;
      addTearDown(fixture.dispose);
      final before = await tester.runAsync(fixture.diskSnapshot);
      await tester.pumpWidget(fixture.app(tester, withOwners: true));
      await pumpIo(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Histoire'),
        ),
      );
      await tester.pumpAndSettle();
      final narrative = tester.widget<NarrativeStoryPane>(
        find.byType(NarrativeStoryPane),
      );
      final scenesBefore = narrative.sceneOwner!.scenes.length;
      final eventsBefore = narrative.eventOwner!.records.length;
      final previousSceneId = narrative.sceneOwner!.scenes.first.id;
      final previousEventId = narrative.eventOwner!.records.first.id;
      expect(narrative.sceneOwner!.open(previousSceneId), isTrue);
      expect(narrative.eventOwner!.open(previousEventId), isTrue);
      await tester.pumpAndSettle();
      final createScene = find.widgetWithText(
        StudioActionCard,
        'Nouvelle scène',
      );
      expect(tester.widget<StudioActionCard>(createScene).onPressed, isNull);
      await tester.tap(createScene);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(narrative.sceneOwner!.scenes.length, scenesBefore);
      expect(narrative.sceneOwner!.active?.current.id, previousSceneId);
      expect(await tester.runAsync(fixture.diskSnapshot), before);
      await tester.tap(
        find.widgetWithText(StudioActionCard, 'Nouvel événement'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Événement annulé');
      await tester.tap(find.widgetWithText(StudioButton, 'Annuler'));
      await tester.pumpAndSettle();
      expect(narrative.eventOwner!.records.length, eventsBefore);
      expect(narrative.eventOwner!.activeId, previousEventId);
      await tester.tap(
        find.widgetWithText(StudioActionCard, 'Nouvel événement'),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Départ du train');
      await tester.pump();
      await tester.tap(find.widgetWithText(StudioButton, 'Créer'));
      await pumpIoUntil(
        tester,
        () =>
            find.byType(EventWorkspacePage).evaluate().isNotEmpty ||
            narrative.eventOwner!.error != null,
        maxFrames: 500,
      );
      expect(narrative.eventOwner!.error, isNull);
      expect(find.byType(EventWorkspacePage), findsOneWidget);
      final event = tester.widget<EventWorkspacePage>(
        find.byType(EventWorkspacePage),
      );
      expect(event.controller.active?.draftOrNull?.name, 'Départ du train');
      expect(event.controller.dirty, isTrue);
      final eventId = event.controller.activeId!;
      expect(eventId, isNot(previousEventId));
      expect(
        event.controller.records.where((item) => item.id == eventId),
        hasLength(1),
      );
      expect(await tester.runAsync(() => event.controller.saveAll()), isTrue);
      await pumpIo(tester);
      final reopened = LocalMapWorkspaceAdapter();
      final manifest = (await tester.runAsync(
        () => reopened.loadProject(fixture.source.session),
      ))!;
      expect(manifest.scenes, fixture.controller.project!.scenes);
      expect(
        manifest.eventRegistry!.records
            .singleWhere((item) => item.id == eventId)
            .draftOrNull
            ?.name,
        'Départ du train',
      );
      expect(fixture.port.publications, 0);
      expect(
        await tester.runAsync(fixture.diskSnapshot),
        isNot(equals(before)),
      );
    },
  );
}
