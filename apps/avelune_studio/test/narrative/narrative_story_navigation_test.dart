import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_overview_view_state.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'dialogue_draft_codec_test.dart' show dialogueFixture;

void main() {
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController controller;
  late InteractionEditSession edit;
  late NarrativeOverviewViewState view;
  late WorkspaceMemoryPort mapPort;
  late _Port narrativePort;
  var opened = 0;
  setUp(() async {
    mapPort = WorkspaceMemoryPort();
    narrativePort = _Port();
    maps = MapWorkspaceController(workspaceSession, mapPort);
    view = NarrativeOverviewViewState();
    await maps.initialize();
    controller = NarrativeWorkspaceController(
      maps,
      narrativePort,
      () {},
      (_, _) async {},
    );
    edit = InteractionEditSession(
      document: maps.active!,
      dialogue: dialogueFixture(),
      interaction: NarrativeInteractionDraft(
        id: 'evt_00000000-0000-7000-8000-000000000001',
        name: 'Le chef de gare',
        mapId: 'a',
        source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
        dialogueId: 'station',
        steps: [
          const NarrativeSequenceStep(
            kind: NarrativeSequenceKind.completeStep,
            targetId: 'arrival',
          ),
        ],
      ),
    );
    controller.sessions[edit.current.interaction.id] = edit;
    controller.active = edit;
    opened = 0;
  });
  tearDown(() {
    maps.dispose();
    view.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1536, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: NarrativeStoryPane(
            controller: controller,
            viewState: view,
            onOpen: (id) async {
              final local = controller.sessions[id];
              final success = local == null
                  ? await controller.openRecord(
                      maps.project!.eventRegistry!.records.firstWhere(
                        (record) => record.id == id,
                      ),
                    )
                  : await controller.openSession(local);
              if (success) opened++;
              return success ? null : controller.error;
            },
            onLocate: (_) async => null,
            onCreateInteraction: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('advanced record never opens previous interaction', (
    tester,
  ) async {
    final projection = NarrativeInteractionDraft(
      id: 'evt_00000000-0000-7000-8000-000000000002',
      name: 'Avancée',
      mapId: 'a',
      source: NarrativeEventSourceRef.mapEnter('a'),
      dialogueId: 'station',
      conditions: [
        NarrativeEventCondition.narrativeEventConsumed(
          edit.current.interaction.id,
          true,
        ),
      ],
    ).project();
    final record = projection.event;
    maps.project = maps.project!.copyWith(
      scenes: [projection.scene],
      dialogues: [edit.current.dialogue.entry],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [record],
        legacyClaims: [],
      ),
    );
    await pump(tester);
    await tester.tap(find.byKey(ValueKey('interaction-${record.id}')));
    await tester.pumpAndSettle();
    expect(opened, 0);
    expect(controller.active, same(edit));
    expect(controller.error, isNull);
    expect(find.text('Ouvrir l’éditeur'), findsNothing);
    expect(
      find.textContaining('Interaction avancée · consultation seule'),
      findsOneWidget,
    );
    expect(controller.sessions.values, contains(edit));
  });

  testWidgets(
    'story selection is read only and explicit action opens linked draft',
    (tester) async {
      controller.pendingStories['journey'] = createStudioStoryline(
        id: 'journey',
        title: 'Le voyage',
        steps: {'arrival': 'Arriver en gare'},
      );
      await maps.activate(workspaceEntries.last);
      expect(maps.active!.current.id, 'b');
      await pump(tester);
      await tester.tap(find.text('Arriver en gare'));
      await tester.pumpAndSettle();
      expect(opened, 0);
      expect(maps.active!.current.id, 'b');
      await tester.tap(find.text('Le chef de gare'));
      await tester.pump();
      expect(opened, 0);
      expect(maps.active!.current.id, 'b');
      await tester.ensureVisible(find.text('Reprendre le brouillon'));
      await tester.tap(find.text('Reprendre le brouillon'));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(controller.active, same(edit));
      expect(maps.active, same(edit.document));
    },
  );

  testWidgets('long stories only mount visible step rows', (tester) async {
    controller.pendingStories['long'] = createStudioStoryline(
      id: 'long',
      title: 'Longue histoire',
      steps: {for (var i = 0; i < 1000; i++) 'step_$i': 'Étape $i'},
    );
    await pump(tester);
    expect(find.text('Étape 0'), findsOneWidget);
    expect(find.text('Étape 999'), findsNothing);
    expect(find.byType(StudioChoice).evaluate().length, lessThan(30));
    view.scroll.jumpTo(view.scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Étape 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '1000 interactions mount only visible rows without extra source reads',
    (tester) async {
      controller.sessions.clear();
      controller.active = null;
      String id(int index) =>
          'evt_00000000-0000-7000-8000-${(1000 + index).toString().padLeft(12, '0')}';
      maps.project = maps.project!.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: [
            for (var i = 0; i < 1000; i++)
              NarrativeEventRecord.draft(
                NarrativeEventDraft(
                  id: id(i),
                  name: 'Même rencontre',
                  source: NarrativeEventSourceRef.entityInteract(
                    i.isEven ? 'a' : 'b',
                    'source_$i',
                  ),
                  conditions: [],
                  priority: 0,
                  order: i,
                ),
              ),
          ],
          legacyClaims: [],
        ),
      );
      final reads = mapPort.reads;
      await pump(tester);
      expect(find.text('Interactions (1000)'), findsOneWidget);
      expect(
        find.text('Aucune histoire structurée pour le moment'),
        findsOneWidget,
      );
      Finder rows() => find.byWidgetPredicate(
        (widget) =>
            widget is StudioChoice &&
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith('interaction-'),
      );
      expect(rows().evaluate().length, inExclusiveRange(0, 30));
      expect(find.byKey(ValueKey('interaction-${id(999)}')), findsNothing);
      for (var attempt = 0; attempt < 3; attempt++) {
        view.scroll.jumpTo(view.scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(ValueKey('interaction-${id(999)}')), findsOneWidget);
      expect(find.byKey(ValueKey('interaction-${id(0)}')), findsNothing);
      expect(rows().evaluate().length, lessThan(30));
      await tester.enterText(
        find.widgetWithText(TextField, 'Rechercher dans Histoire'),
        'source_999',
      );
      await tester.pumpAndSettle();
      expect(find.text('Interactions (1)'), findsOneWidget);
      await tester.tap(find.byKey(ValueKey('interaction-${id(999)}')));
      await tester.pumpAndSettle();
      expect(view.interactionId, id(999));
      expect(narrativePort.reads, 0);
      expect(narrativePort.writes, 0);
      expect(mapPort.reads, reads);
      expect(mapPort.writes, 0);
      expect(maps.documents, hasLength(1));
      expect(controller.sessions, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'new source variant ranks above existing conditional and fallback drafts',
    () async {
      edit.change(interaction: edit.current.interaction.revise(priority: 4));
      await controller.openSource(
        maps.active!,
        edit.current.interaction.source,
        'Après l’aide',
      );
      expect(controller.active!.current.interaction.priority, 5);
      expect(controller.active!.current.interaction.order, 1);
      expect(controller.sessions, hasLength(2));
    },
  );
}

class _Port implements NarrativePort {
  int reads = 0, writes = 0;
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) {
    reads++;
    throw UnimplementedError();
  }

  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) {
    writes++;
    throw UnimplementedError();
  }
}
