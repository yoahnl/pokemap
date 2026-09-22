import 'dart:async';

import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_interaction_pane.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';
import '../support/ui05_narrative_fixture.dart';

class HeldNarrativePort implements NarrativePort {
  HeldNarrativePort(this.inner);
  final NarrativePort inner;
  final gate = Completer<void>();
  int reads = 0;

  @override
  Future<NarrativeDialogueSource> readDialogue(
    ProjectDialogueEntry entry,
  ) async {
    reads++;
    await gate.future;
    return inner.readDialogue(entry);
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => inner.publish(publication);
}

Finder get pane => find.byType(NarrativeInteractionPane);

void main() {
  Future<void> openFromMenu(MapHostFixture f, int x, int y) async {
    await f.rightClick(x, y);
    await f.choose('Ouvrir son interaction');
    await pumpIo(f.tester, frames: 10);
  }

  Future<void> backToMap(MapHostFixture f) async {
    await f.tester.tap(find.text('Retour à la carte'));
    await pumpIo(f.tester, frames: 10);
  }

  testWidgets(
    'an interaction never saved reopens from the map with its own draft',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final NarrativeWorkspaceController narrative = await f.narrativeOwner();
      await tester.tap(find.byTooltip('Dessiner une zone d’histoire'));
      await pumpIo(tester, frames: 4);
      await f.drag(3, 11, 5, 13);
      await pumpIo(tester, frames: 12);
      expect(pane, findsOneWidget, reason: 'tracing opened its interaction');

      final session = narrative.active!;
      final interaction = session.current.interaction;
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de l’interaction'),
        'Brume sur le quai',
      );
      await pumpIo(tester, frames: 4);
      expect(session.dirty, isTrue);
      await backToMap(f);

      final sessions = {...narrative.sessions.keys};
      final triggers = f.document.current.triggers.length;
      final disk = await f.disk();
      final view = f.transform;

      for (var round = 0; round < 2; round++) {
        await openFromMenu(f, 4, 12);
        expect(pane, findsOneWidget, reason: 'round $round opened the draft');
        expect(identical(narrative.active, session), isTrue);
        final current = narrative.active!.current.interaction;
        expect(current.id, interaction.id);
        expect(current.dialogueId, interaction.dialogueId);
        expect(current.name, 'Brume sur le quai');
        expect({...narrative.sessions.keys}, sessions, reason: 'no new id');
        await backToMap(f);
        expect(f.document.current.triggers, hasLength(triggers));
        expect(f.transform, view, reason: 'the map keeps its framing');
      }
      expect(await f.disk(), disk, reason: 'opening published nothing');
      expect(f.document.dirty, isTrue, reason: 'the map drafts are kept');
      await f.key(LogicalKeyboardKey.f10, shift: true);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('map-context-target')))
            .data,
        'Zone d’histoire',
        reason: 'the map came back on the zone the author was working on',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'a saved zone interaction opens in its events owner',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final disk = await f.disk();

      await openFromMenu(f, 11, 9);

      final page = tester.widget<EventWorkspacePage>(
        find.byType(EventWorkspacePage),
      );
      expect(page.controller.activeId, Ui05NarrativeFixture.eventId(7));
      expect(await f.disk(), disk);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'a late read never reopens the zone once the author went elsewhere',
    (tester) async {
      late HeldNarrativePort held;
      final f = await MapHostFixture.open(
        tester,
        events: false,
        narrative: (port) => held = HeldNarrativePort(port),
      );

      await openFromMenu(f, 11, 9);
      expect(held.reads, 1, reason: 'the saved dialogue is being read');
      await f.go('Histoire');
      held.gate.complete();
      await pumpIo(tester, frames: 12);

      expect(pane, findsNothing);
      expect(find.byType(NarrativeStoryPane), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'several interactions on one zone offer only those, then open the one',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final narrative = await f.narrativeOwner();
      await narrative.openSource(
        f.document,
        NarrativeEventSourceRef.triggerEnter(f.document.current.id, 'quai'),
        'Retour au quai',
      );
      await pumpIo(tester, frames: 8);
      final second = narrative.active!;
      await f.go('Carte');

      await openFromMenu(f, 11, 9);
      final chooser = find.byType(AlertDialog);
      expect(chooser, findsOneWidget);
      expect(
        find.descendant(of: chooser, matching: find.text('Accueil quai')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: chooser, matching: find.text('Retour au quai')),
        findsOneWidget,
      );
      await tester.tap(
        find.descendant(of: chooser, matching: find.text('Retour au quai')),
      );
      await pumpIo(tester, frames: 12);

      expect(pane, findsOneWidget);
      expect(identical(narrative.active, second), isTrue);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
