import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/stories/story_progression_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_action_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_resource_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m2_ui_fixture.dart';
import '../support/ui05_narrative_fixture.dart';

void main() {
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
      final scroll = tester
          .widget<NarrativeStoryPane>(find.byType(NarrativeStoryPane))
          .viewState
          .resultsScroll;
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
      expect(
        tester
            .widget<StoryProgressionPage>(find.byType(StoryProgressionPage))
            .controller
            .activeId,
        'collection-999',
      );
      await tester.tap(find.widgetWithText(StudioButton, 'Histoire').last);
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

  testWidgets('overview creates a scene and an event through their owners', (
    tester,
  ) async {
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
    await tester.tap(find.widgetWithText(StudioActionCard, 'Nouvelle scène'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Scène annulée');
    await tester.tap(find.widgetWithText(StudioButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(narrative.sceneOwner!.scenes.length, scenesBefore);
    expect(narrative.sceneOwner!.active?.current.id, previousSceneId);
    await tester.tap(find.widgetWithText(StudioActionCard, 'Nouvelle scène'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Scène du quai');
    await tester.pump();
    await tester.tap(find.widgetWithText(StudioButton, 'Créer'));
    await tester.pumpAndSettle();
    final scene = tester.widget<SceneBuilderPage>(
      find.byType(SceneBuilderPage),
    );
    expect(scene.controller.active?.current.name, 'Scène du quai');
    expect(scene.controller.active?.dirty, isTrue);
    final sceneId = scene.controller.active!.current.id;
    expect(sceneId, isNot(previousSceneId));
    expect(
      scene.controller.scenes.where((item) => item.id == sceneId),
      hasLength(1),
    );
    expect(await tester.runAsync(() => scene.controller.save()), isTrue);
    await pumpIo(tester);
    await tester.tap(find.text('Histoire').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(StudioActionCard, 'Nouvel événement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Événement annulé');
    await tester.tap(find.widgetWithText(StudioButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(narrative.eventOwner!.records.length, eventsBefore);
    expect(narrative.eventOwner!.activeId, previousEventId);
    await tester.tap(find.widgetWithText(StudioActionCard, 'Nouvel événement'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Départ du train');
    await tester.pump();
    await tester.tap(find.widgetWithText(StudioButton, 'Créer'));
    await pumpIo(tester);
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
    expect(
      manifest.scenes.singleWhere((item) => item.id == sceneId).name,
      'Scène du quai',
    );
    expect(
      manifest.eventRegistry!.records
          .singleWhere((item) => item.id == eventId)
          .draftOrNull
          ?.name,
      'Départ du train',
    );
    expect(fixture.port.publications, 0);
    expect(await tester.runAsync(fixture.diskSnapshot), isNot(equals(before)));
  });
}
