import 'dart:io';
import 'package:avelune_studio/features/narrative/application/narrative_interaction_reader.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/scenes/data/local_scene_adapter.dart';
import 'package:avelune_studio/features/scenes/domain/scene_port.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_overview_detail.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui05_narrative_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  testWidgets(
    'UI06 advanced interaction opens exact scene and draft survives navigation and refused close',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(Ui06SceneFixture.create))!;
      addTearDown(fixture.dispose);
      final localScenes = LocalSceneAdapter(
        session: fixture.session,
        mapAdapter: fixture.maps,
      );
      final decoy = createSceneDraftInProject(
        fixture.manifest,
        name: fixture.scene.name,
      ).createdScene;
      await tester.runAsync(
        () => localScenes.publishScene(base: null, current: decoy),
      );
      final maps = WidgetMapController(fixture.session, fixture.maps, tester);
      addTearDown(maps.dispose);
      await tester.runAsync(maps.initialize);
      final visuals = (await tester.runAsync(
        () => StudioMapResources.load(fixture.session, maps.project!),
      ))!;
      final narrative = Ui05NarrativePort(
        LocalNarrativeAdapter(
          session: fixture.session,
          mapAdapter: fixture.maps,
        ),
        tester,
      );
      final scenes = _WidgetScenePort(localScenes, tester);
      var closes = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: MapWorkspaceScreen(
            controller: maps,
            loadVisuals: (_, _) async => visuals,
            narrativePort: narrative,
            scenePort: scenes,
            runtimeBuilder: (_, _, _) => const SizedBox(),
            onClose: () async {
              closes++;
            },
            registerExitGuard: (_) {},
          ),
        ),
      );
      await pumpIo(tester);
      final map = maps.active!;
      map.commit(map.current.copyWith(name: 'Carte en préparation'));
      final mapDraft = map.current;
      final mapFile = File(
        '${fixture.directory.path}/${maps.project!.maps.first.relativePath}',
      );
      final mapBytes = await tester.runAsync(mapFile.readAsBytes);
      await _navigate(tester, 'Histoire');
      await tester.tap(find.text('Scènes').first);
      await tester.pumpAndSettle();
      expect(find.byType(SceneBuilderPage), findsOneWidget);
      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is StudioChoice &&
              widget.label == decoy.name &&
              widget.subtitle == '2 blocs',
        ),
      );
      await tester.pumpAndSettle();
      var page = tester.widget<SceneBuilderPage>(find.byType(SceneBuilderPage));
      expect(page.controller.active!.current.id, decoy.id);
      await _navigate(tester, 'Histoire');
      await tester.tap(find.text('Interactions').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('interaction-${Ui06SceneFixture.eventId}')),
      );
      await tester.pump();
      final record = maps.project!.eventRegistry!.records.single;
      expect(readStudioInteraction(record, maps.project!), isNull);
      expect(find.text('Ouvrir l’éditeur'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Ouvrir la scène'),
        160,
        scrollable: find
            .descendant(
              of: find.byType(NarrativeOverviewDetail),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Ouvrir la scène'));
      await tester.pumpAndSettle();
      page = tester.widget<SceneBuilderPage>(find.byType(SceneBuilderPage));
      final controller = page.controller;
      final edit = controller.active!;
      expect(edit.current.id, Ui06SceneFixture.sceneId);
      expect(edit.current, fixture.scene);
      expect(
        controller.sessions.keys,
        containsAll([decoy.id, fixture.scene.id]),
      );
      expect(narrative.dialogueReads, 0);
      expect(narrative.publications, 0);
      await tester.drag(
        find.byKey(const ValueKey('scene-graph-node-drag-target-start')),
        const Offset(45, 30),
      );
      await tester.pumpAndSettle();
      expect(edit.dirty, isTrue);
      expect(edit.undoCount, 1);
      final graphDraft = edit.current;
      final view = page.views.forScene(fixture.scene.id);
      final pan = view.viewport.pan;
      final zoom = view.viewport.zoom;
      await _navigate(tester, 'Carte');
      expect(find.byType(SceneBuilderPage), findsNothing);
      expect(map.current, same(mapDraft));
      await _navigate(tester, 'Histoire');
      await tester.tap(find.text('Scènes').first);
      await tester.pumpAndSettle();
      page = tester.widget<SceneBuilderPage>(find.byType(SceneBuilderPage));
      expect(page.controller.active, same(edit));
      expect(edit.current, same(graphDraft));
      expect(page.views.forScene(fixture.scene.id), same(view));
      expect(view.viewport.pan, pan);
      expect(view.viewport.zoom, zoom);
      await _navigate(tester, 'Carte');
      await _closeChoice(tester, 'Annuler');
      expect(closes, 0);
      expect(edit.current, same(graphDraft));
      expect(edit.dirty, isTrue);
      expect(map.current, same(mapDraft));
      final projectFile = File('${fixture.directory.path}/project.json');
      final external =
          '${(await tester.runAsync(projectFile.readAsString))!}\n';
      await tester.runAsync(() => projectFile.writeAsString(external));
      await _closeChoice(tester, 'Enregistrer');
      await pumpIo(tester);
      expect(scenes.publications, 1);
      expect(closes, 0);
      expect(edit.error, isNotNull);
      expect(edit.current, same(graphDraft));
      expect(edit.dirty, isTrue);
      expect(edit.undoCount, 1);
      expect(map.current, same(mapDraft));
      expect(map.dirty, isTrue);
      expect(await tester.runAsync(mapFile.readAsBytes), mapBytes);
      expect(await tester.runAsync(projectFile.readAsString), external);
      expect(narrative.publications, 0);
      await _navigate(tester, 'Histoire');
      await tester.tap(find.text('Scènes').first);
      await tester.pumpAndSettle();
      expect(find.text(edit.error!), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

Future<void> _navigate(WidgetTester tester, String label) async {
  final inScene =
      label == 'Histoire' &&
      find.byType(SceneBuilderPage).evaluate().isNotEmpty;
  await tester.tap(
    find.descendant(
      of: find.byType(inScene ? SceneBuilderPage : StudioPrimaryNavigation),
      matching: inScene ? find.text('Histoire') : find.byTooltip(label),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _closeChoice(WidgetTester tester, String label) async {
  await tester.tap(find.byKey(const ValueKey('Fermer le projet')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(AlertDialog), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

class _WidgetScenePort implements ScenePort {
  _WidgetScenePort(this.port, this.tester);
  final ScenePort port;
  final WidgetTester tester;
  int publications = 0;
  @override
  Future<ScenePublicationReceipt> publishScene({
    required SceneAsset? base,
    required SceneAsset current,
  }) async {
    publications++;
    final operation = tester.runAsync(() async {
      try {
        return (await port.publishScene(base: base, current: current), null);
      } catch (error) {
        return (null, error);
      }
    });
    WidgetResourcePort.pending = operation;
    try {
      final result = (await operation)!;
      if (result.$2 case final error?) throw error;
      return result.$1!;
    } finally {
      if (identical(WidgetResourcePort.pending, operation)) {
        WidgetResourcePort.pending = null;
      }
    }
  }
}
