import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m2_ui_fixture.dart';
import '../support/ui05_narrative_fixture.dart';

void main() {
  testWidgets(
    'UI05 cancelled creation is inert and explicit save survives fresh reopen',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => Ui05NarrativeFixture.create(tester),
      ))!;
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app(tester));
      await pumpIo(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Histoire'),
        ),
      );
      await tester.pumpAndSettle();
      final narrative = tester
          .widget<NarrativeStoryPane>(find.byType(NarrativeStoryPane))
          .controller;
      final before = await tester.runAsync(fixture.diskSnapshot);
      final originalStories = {
        for (final story in narrative.stories) story.id: story.toJson(),
      };
      final originalFacts = {
        for (final fact in narrative.facts) fact.id: fact.toJson(),
      };
      final originalEvents = narrative.project.eventRegistry!.toJson();

      Future<void> tap(String label) async {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      Future<void> enter(String value) async {
        await tester.enterText(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.byType(TextField),
          ),
          value,
        );
        await tester.pump();
      }

      await tap('Créer une histoire');
      await enter('   ');
      expect(
        tester
            .widget<StudioButton>(find.widgetWithText(StudioButton, 'Créer'))
            .onPressed,
        isNull,
      );
      await tap('Annuler');
      await tap('Créer une histoire');
      await enter('Histoire abandonnée');
      await tap('Créer');
      await enter('Étape abandonnée');
      await tap('Annuler');
      await tap('Créer un état');
      await enter('État abandonné');
      await tap('Annuler');
      expect(narrative.pendingStories, isEmpty);
      expect(narrative.pendingFacts, isEmpty);
      expect(narrative.sessions, isEmpty);
      expect(await tester.runAsync(fixture.diskSnapshot), before);

      await tap('Créer une histoire');
      await enter('La visite du quai');
      await tap('Créer');
      await enter('Retrouver la voyageuse\nObserver les signaux');
      await tap('Créer');
      await tap('Créer un état');
      await enter('Signal aperçu');
      await tap('Créer');
      final createdStory = narrative.pendingStories.values.single;
      final createdFact = narrative.pendingFacts.values.single;
      final document = fixture.controller.active!;
      document.commit(
        document.current.copyWith(name: 'Carte modifiée avec l’histoire'),
      );
      final dirtyMap = document.current;
      expect(fixture.port.publications, 0);
      expect(await tester.runAsync(fixture.diskSnapshot), before);
      expect(
        find.text(
          'Enregistre les histoires, interactions et cartes ouvertes modifiées.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Enregistrer les modifications'));
      await pumpIo(tester, frames: 50);
      expect(narrative.publicationError, isNull);
      expect(narrative.pendingStories, isEmpty);
      expect(narrative.pendingFacts, isEmpty);
      expect(document.dirty, isFalse);
      expect(fixture.port.publications, 1);
      expect(fixture.port.dialogueReads, 0);
      final reopened = LocalMapWorkspaceAdapter();
      final manifest = (await tester.runAsync(
        () => reopened.loadProject(fixture.source.session),
      ))!;
      expect(
        manifest.storylines
            .singleWhere((story) => story.id == createdStory.id)
            .toJson(),
        createdStory.toJson(),
      );
      expect(
        manifest.facts
            .singleWhere((fact) => fact.id == createdFact.id)
            .toJson(),
        createdFact.toJson(),
      );
      for (final entry in originalStories.entries) {
        expect(
          manifest.storylines
              .singleWhere((story) => story.id == entry.key)
              .toJson(),
          entry.value,
        );
      }
      for (final entry in originalFacts.entries) {
        expect(
          manifest.facts.singleWhere((fact) => fact.id == entry.key).toJson(),
          entry.value,
        );
      }
      expect(manifest.eventRegistry!.toJson(), originalEvents);
      final map = await tester.runAsync(
        () => reopened.loadMap(
          fixture.source.session,
          manifest.maps.firstWhere((map) => map.id == document.current.id),
        ),
      );
      expect(map!.map, dirtyMap);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
