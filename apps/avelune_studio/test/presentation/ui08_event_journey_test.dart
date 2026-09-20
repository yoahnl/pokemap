import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import '../support/capture_m3_widget.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui08_workspace_harness.dart';
import '../support/ui08_journey_driver.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  testWidgets(
    'UI08 complete source conditions scene publication simulation and returns',
    (tester) async {
      tester.view.physicalSize = const Size(1584, 994);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final f = (await tester.runAsync(
        () => Ui08WorkspaceHarness.create(tester),
      ))!;
      addTearDown(f.dispose);
      await tester.pumpWidget(f.app());
      await pumpIo(tester);
      await ui08Open(tester);
      await ui08Tap(tester, 'PNJ Chef de gare');
      await captureM3Widget(tester, f.captureKey, '01-evenements-composition');
      final initialMapBytes = await tester.runAsync(f.mapBytes);
      final map = f.maps.active!;
      map.commit(map.current.copyWith(name: 'Carte locale à préserver'));
      final mapDraft = map.current;
      await ui08Tap(tester, 'Nouvel événement');
      final name = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(name, 'Bienvenue sur le quai');
      await tester.pump();
      await ui08Tap(tester, 'Créer');
      final controller = ui08Page(tester).controller;
      final createdId = controller.activeId!;
      expect(
        controller.active!.draftOrNull,
        isNotNull,
        reason: controller.error,
      );
      expect(f.events.writes, 0);
      await ui08Tap(tester, 'Entrée de zone');
      final mapEntry = controller.project.maps.first;
      await ui08Select(
        tester,
        'Carte de la source',
        '${mapEntry.name} · ${mapEntry.id}',
      );
      await captureM3Widget(tester, f.captureKey, '02-choix-source-carte');
      await tester.tap(find.byTooltip('Agrandir le contexte'));
      await tester.tap(find.byTooltip('Déplacer l’aperçu'));
      await tester.drag(
        find.byKey(const ValueKey('event-context-viewport')),
        const Offset(-20, 14),
      );
      await tester.pumpAndSettle();
      expect(controller.active!.draftOrNull!.source, isNull);
      await tester.tap(find.byTooltip('Choisir une cible'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('event-target:platform')));
      await pumpIo(tester);
      expect(
        controller.active!.draftOrNull!.source,
        NarrativeEventSourceRef.triggerEnter(mapEntry.id, 'platform'),
      );
      await ui08Tap(tester, 'Conditions');
      await ui08Tap(tester, 'Ajouter une condition');
      await ui08Select(
        tester,
        'État',
        'Laissez-passer obtenu · ${Ui06SceneFixture.passFactId}',
      );
      await ui08Select(tester, 'Valeur attendue', 'Oui');
      await ui08Tap(tester, 'Appliquer la condition');
      expect(controller.active!.draftOrNull!.conditions, hasLength(1));
      await captureM3Widget(tester, f.captureKey, '03-conditions-lisibles');
      await ui08Tap(tester, 'Scène');
      await tester.tap(
        find.byKey(const ValueKey('event-scene:${Ui06SceneFixture.sceneId}')),
      );
      await pumpIo(tester);
      expect(controller.active!.draftOrNull!.sceneId, Ui06SceneFixture.sceneId);
      await ui08Tap(tester, 'Ouvrir la scène');
      expect(find.byType(SceneBuilderPage), findsOneWidget);
      final scene = tester
          .widget<SceneBuilderPage>(find.byType(SceneBuilderPage))
          .controller
          .active!;
      await tester.drag(
        find.byKey(const ValueKey('scene-graph-node-drag-target-start')),
        const Offset(34, 20),
      );
      await tester.pumpAndSettle();
      final sceneDraft = scene.current;
      expect(scene.dirty, true);
      await ui08Tap(tester, 'Événements');
      expect(ui08Page(tester).controller.activeId, createdId);
      expect(controller.dirty, true);
      expect(map.current, same(mapDraft));
      expect(scene.current, same(sceneDraft));
      await captureM3Widget(tester, f.captureKey, '04-retour-scene-brouillons');
      await ui08Tap(tester, 'Options');
      await ui08Select(tester, 'Après avoir joué', 'Peut être rejoué');
      await ui08Tap(tester, 'Configurer l’événement');
      expect(controller.active!.definitionOrNull, isNotNull);
      await ui08Tap(tester, 'Préparer l’activation');
      expect(controller.active!.enabledOrNull, true);
      await ui08Tap(tester, 'Enregistrer');
      expect(controller.error, isNull);
      expect(controller.dirty, false);
      expect(f.events.writes, 1);
      expect(map.current, same(mapDraft));
      expect(scene.current, same(sceneDraft));
      await captureM3Widget(tester, f.captureKey, '05-evenement-configure');
      final reopened = (await tester.runAsync(f.source.readFresh))!;
      expect(
        reopened.eventRegistry!.records.singleWhere((r) => r.id == createdId),
        controller.active,
      );
      expect(await tester.runAsync(f.mapBytes), initialMapBytes);
      await ui08Tap(tester, 'Examiner le mode du projet');
      await ui08Tap(tester, 'Activer le mode mixte');
      expect(
        controller.project.eventRegistry!.mode,
        EventSystemMode.dualRead,
        reason: controller.error,
      );
      await ui08Tap(tester, 'Simulation');
      await ui08Select(tester, 'Laissez-passer obtenu', 'Oui');
      await ui08Tap(tester, 'Simuler');
      expect(find.text('Cet événement est sélectionné'), findsOneWidget);
      await captureM3Widget(tester, f.captureKey, '06-simulation-canonique');
      await ui08Tap(tester, 'Fermer');
      await ui08Tap(tester, 'Déclencheur');
      await ui08Tap(tester, 'Voir sur la carte');
      expect(find.byType(EventWorkspacePage), findsNothing);
      expect(map.current, same(mapDraft));
      await ui08Tap(tester, 'Retour à l’événement');
      expect(ui08Page(tester).controller.activeId, createdId);
      for (final size in [
        const Size(1536, 1024),
        const Size(1440, 900),
        const Size(1280, 800),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      tester.view.physicalSize = const Size(1024, 640);
      await tester.pumpWidget(f.app(textScale: 1.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await captureM3Widget(tester, f.captureKey, '07-compact-texte150');
      expect(map.current, same(mapDraft));
      expect(scene.current, same(sceneDraft));
      await tester.pumpWidget(const SizedBox());
    },
  );
}
