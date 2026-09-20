import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_overview_detail.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_interaction_pane.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/capture_m3_widget.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui05_narrative_fixture.dart';

void main() {
  testWidgets('UI05 story overview reads canonical fixture without mutations', (
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
    expect(narrative.stories, hasLength(2));
    expect(narrative.sessions, isEmpty);
    expect(fixture.port.dialogueReads, 0);
    expect(fixture.port.publications, 0);
    expect(fixture.controller.documents, hasLength(1));
    expect(await tester.runAsync(fixture.diskSnapshot), before);
    await captureM3Widget(tester, fixture.captureKey, '01-histoire-structuree');
    final unlinked = find.byKey(const ValueKey('step-unlinked'));
    if (unlinked.evaluate().isEmpty) {
      await tester.tap(find.text('Sur le quai'));
      await tester.pump();
    }
    await tester.ensureVisible(unlinked);
    await tester.tap(unlinked);
    await tester.pump();
    expect(find.textContaining('Aucun lien'), findsWidgets);
    expect(narrative.sessions, isEmpty);
    expect(fixture.port.dialogueReads, 0);
    await tester.tap(find.text('Interactions').first);
    await tester.pump();
    final search = find.widgetWithText(TextField, 'Rechercher dans Histoire');
    await tester.enterText(search, 'Mame');
    await tester.pumpAndSettle();
    for (final number in [1, 7, 100]) {
      expect(
        find.byKey(
          ValueKey('interaction-${Ui05NarrativeFixture.eventId(number)}'),
        ),
        findsOneWidget,
      );
    }
    await tester.tap(find.byKey(const ValueKey('map-filter-null')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clairière').last);
    await tester.pumpAndSettle();
    expect(find.text('Interactions (1)'), findsOneWidget);
    expect(
      find.byKey(ValueKey('interaction-${Ui05NarrativeFixture.eventId(100)}')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('interaction-${Ui05NarrativeFixture.eventId(1)}')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('map-filter-clairiere')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toutes les cartes').last);
    await tester.pumpAndSettle();
    expect(find.text('Interactions (3)'), findsOneWidget);
    await tester.tap(
      find.byKey(ValueKey('interaction-${Ui05NarrativeFixture.eventId(1)}')),
    );
    await tester.pump();
    expect(narrative.sessions, isEmpty);
    expect(fixture.controller.documents, hasLength(1));
    await captureM3Widget(
      tester,
      fixture.captureKey,
      '02-interactions-homonymes',
    );
    await fixture.seedLocalDraft(narrative);
    await pumpIo(tester);
    final edit = narrative.sessions[Ui05NarrativeFixture.eventId(2)]!;
    final draft = edit.current;
    final document = edit.document;
    final dirtyMap = document.current;
    final view = tester
        .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
        .view!;
    final transform = view.transform.value.clone();
    for (final number in [1, 7, 100]) {
      final id = Ui05NarrativeFixture.eventId(number);
      await tester.tap(find.byKey(ValueKey('interaction-$id')));
      await tester.pump();
      await _tapDetailAction(tester, 'Ouvrir l’éditeur');
      await pumpIo(tester);
      expect(find.byType(NarrativeInteractionPane), findsOneWidget);
      expect(narrative.active!.current.interaction.id, id);
      expect(
        narrative.active!.document.current.id,
        number == 100 ? 'clairiere' : 'jardin',
      );
      await tester.tap(find.text('Retour à Histoire'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(search).controller!.text, 'Mame');
      expect(edit.current, same(draft));
      expect(document.current, same(dirtyMap));
      expect(view.transform.value, transform);
    }
    await tester.tap(
      find.byKey(ValueKey('interaction-${Ui05NarrativeFixture.eventId(1)}')),
    );
    await tester.pump();
    await _tapDetailAction(tester, 'Voir sur la carte');
    await pumpIo(tester);
    final layout = tester.widget<MapWorkspaceLayout>(
      find.byType(MapWorkspaceLayout),
    );
    expect(layout.activeSpace, 'map');
    expect(layout.view!.selectedEntityId, 'chief');
    expect(layout.view!.tool, StudioMapTool.select);
    expect(fixture.controller.active, same(document));
    expect(document.current, same(dirtyMap));
    expect(document.canUndo, isTrue);
    await captureM3Widget(tester, fixture.captureKey, '05-retour-carte-source');
    await tester.tap(
      find.descendant(
        of: find.byType(StudioPrimaryNavigation),
        matching: find.byTooltip('Histoire'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, 'Mame');
    await tester.enterText(search, 'Voyageuse');
    await tester.pump();
    await tester.tap(
      find.byKey(ValueKey('interaction-${Ui05NarrativeFixture.eventId(2)}')),
    );
    await tester.pump();
    await _showDetailAction(tester, 'Reprendre le brouillon');
    expect(find.text('Reprendre le brouillon'), findsOneWidget);
    await captureM3Widget(tester, fixture.captureKey, '03-brouillon-local');
    await tester.enterText(search, 'signal');
    await tester.pump();
    final advanced = find.byKey(
      ValueKey('interaction-${Ui05NarrativeFixture.eventId(101)}'),
    );
    await tester.tap(advanced);
    await tester.pump();
    expect(find.text('Ouvrir l’éditeur'), findsNothing);
    final reads = fixture.port.dialogueReads;
    final sessions = Map.of(narrative.sessions);
    for (final width in [1440.0, 1280.0, 1024.0]) {
      tester.view.physicalSize = Size(
        width,
        width == 1024
            ? 640
            : width == 1280
            ? 800
            : 900,
      );
      await tester.pumpWidget(
        fixture.app(tester, textScale: width == 1024 ? 1.5 : 1),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    if (advanced.evaluate().isNotEmpty) {
      await tester.tap(advanced);
      await tester.pumpAndSettle();
    }
    await captureM3Widget(tester, fixture.captureKey, '04-compact-150');
    final back = find.text('Retour à la liste');
    if (back.evaluate().isNotEmpty) {
      await tester.tap(back);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('Actions Histoire'));
    await tester.pumpAndSettle();
    expect(find.text('Créer une histoire'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    await tester.enterText(search, 'aucune correspondance');
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(document.current, same(dirtyMap));
    expect(edit.current, same(draft));
    expect(narrative.sessions, sessions);
    expect(fixture.port.dialogueReads, reads);
    expect(fixture.port.publications, 0);
    expect(await tester.runAsync(fixture.diskSnapshot), before);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}

Future<void> _showDetailAction(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    160,
    scrollable: find
        .descendant(
          of: find.byType(NarrativeOverviewDetail),
          matching: find.byType(Scrollable),
        )
        .first,
  );
}

Future<void> _tapDetailAction(WidgetTester tester, String label) async {
  await _showDetailAction(tester, label);
  await tester.tap(find.text(label));
}
