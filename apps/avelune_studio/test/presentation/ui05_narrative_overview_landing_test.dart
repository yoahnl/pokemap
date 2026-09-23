import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/m2_ui_fixture.dart';
import '../support/ui05_narrative_fixture.dart';

void main() {
  testWidgets('filtered library clears only hidden consultation selection', (
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
    final narrative = tester
        .widget<NarrativeStoryPane>(find.byType(NarrativeStoryPane))
        .controller;
    await fixture.seedLocalDraft(narrative);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(StudioButton, 'Voir tous les documents'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Interactions').first);
    await tester.pumpAndSettle();
    final dirtyId = Ui05NarrativeFixture.eventId(2);
    final session = narrative.sessions[dirtyId]!;
    await tester.tap(find.byKey(ValueKey('interaction-$dirtyId')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('detail-$dirtyId')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-filter-null')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clairière').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Sélectionnez un élément'), findsOneWidget);
    expect(find.byKey(ValueKey('detail-$dirtyId')), findsNothing);
    expect(find.text('Reprendre le brouillon'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('map-filter-clairiere')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toutes les cartes').last);
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('detail-$dirtyId')), findsNothing);
    await tester.tap(find.byKey(ValueKey('interaction-$dirtyId')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('detail-$dirtyId')), findsOneWidget);
    final search = find.widgetWithText(TextField, 'Rechercher dans Histoire');
    await tester.enterText(search, 'aucun résultat pour cette recherche');
    await tester.pumpAndSettle();
    expect(find.textContaining('Sélectionnez un élément'), findsOneWidget);
    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('interaction-${Ui05NarrativeFixture.eventId(1)}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brouillons uniquement'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sélectionnez un élément'), findsOneWidget);
    await tester.tap(find.byKey(ValueKey('interaction-$dirtyId')));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('detail-$dirtyId')), findsOneWidget);
    await tester.tap(find.text('Brouillons uniquement'));
    await tester.pumpAndSettle();
    expect(find.byKey(ValueKey('detail-$dirtyId')), findsOneWidget);
    expect(narrative.sessions[dirtyId], same(session));
    expect(session.dirty, isTrue);
    expect(fixture.port.publications, 0);
    expect(await tester.runAsync(fixture.diskSnapshot), before);
  });

  testWidgets(
    'history map shortcut disarms placement and eraser before canvas input',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => Ui05NarrativeFixture.create(tester),
      ))!;
      addTearDown(fixture.dispose);
      final document = fixture.controller.active!;
      final project = fixture.controller.project!;
      final decor = project.elements.firstWhere((entry) => entry.id == 'arbre');
      final placed = MapEditingCommands(
        document,
        project,
      ).place(decor, const GridPos(x: 4, y: 4))!;
      await tester.pumpWidget(fixture.app(tester, withOwners: true));
      await pumpIo(tester);
      final view = tester
          .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
          .view!;
      final matrix = view.transform.value.clone();
      final before = document.current;
      final undoCount = document.undoCount;
      view.brush = decor;
      view.tool = StudioMapTool.place;
      view.armMove(
        MapSelectionTarget(
          mapId: document.current.id,
          family: MapSelectionFamily.decor,
          id: placed,
        ),
        'Déplacer le décor',
      );
      Future<void> openHistory() async {
        await tester.tap(
          find.descendant(
            of: find.byType(StudioPrimaryNavigation),
            matching: find.byTooltip('Histoire'),
          ),
        );
        await tester.pumpAndSettle();
      }

      Future<void> selectDecor() async {
        final canvas = tester.renderObject<RenderBox>(
          find.byKey(const ValueKey('map-canvas')),
        );
        final settings = project.settings;
        await tester.tapAt(
          canvas.localToGlobal(
            Offset(
              4.4 * settings.tileWidth * settings.displayScale,
              4.4 * settings.tileHeight * settings.displayScale,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          view.selectedFor(document.current.id, MapSelectionFamily.decor),
          placed,
        );
        expect(document.current, same(before));
        expect(document.undoCount, undoCount);
        expect(view.transform.value, matrix);
      }

      await openHistory();
      await tester.tap(
        find.byKey(ValueKey('overview-map-${document.current.id}')),
      );
      await pumpIo(tester);
      expect(view.tool, StudioMapTool.select);
      expect(view.pendingMove, isNull);
      await selectDecor();
      view.tool = StudioMapTool.erase;
      await openHistory();
      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher dans Histoire'),
        project.maps.first.name,
      );
      await tester.pumpAndSettle();
      final results = tester
          .widget<NarrativeStoryPane>(find.byType(NarrativeStoryPane))
          .viewState
          .resultsScroll;
      results.jumpTo(results.position.maxScrollExtent);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(ValueKey('overview-result-Carte-${document.current.id}')),
      );
      await pumpIo(tester);
      expect(view.tool, StudioMapTool.select);
      await selectDecor();
      expect(fixture.port.publications, 0);
    },
  );
}
