import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/interaction_edit_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'dialogue_draft_codec_test.dart' show dialogueFixture;

void main() {
  late MapWorkspaceController maps;
  late NarrativeWorkspaceController controller;
  late InteractionEditSession edit;
  var opened = 0;
  setUp(() async {
    maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
    await maps.initialize();
    controller = NarrativeWorkspaceController(
      maps,
      _Port(),
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
  tearDown(() => maps.dispose());

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: NarrativeStoryPane(
          controller: controller,
          onOpen: () => opened++,
        ),
      ),
    ),
  );

  testWidgets('advanced record never opens previous interaction', (
    tester,
  ) async {
    final record = NarrativeEventRecord.draft(
      NarrativeEventDraft(
        id: 'evt_00000000-0000-7000-8000-000000000002',
        name: 'Avancée',
        source: NarrativeEventSourceRef.entityInteract('a', 'other'),
        conditions: [],
        priority: 0,
        order: 0,
      ),
    );
    maps.project = maps.project!.copyWith(
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: [record],
        legacyClaims: [],
      ),
    );
    await pump(tester);
    await tester.tap(find.text('Interaction avancée'));
    await tester.pumpAndSettle();
    expect(opened, 0);
    expect(controller.active, isNull);
    expect(controller.error, contains('avancée'));
    expect(controller.sessions.values, contains(edit));
  });

  testWidgets('story step opens linked draft and restores its map', (
    tester,
  ) async {
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
    expect(opened, 1);
    expect(controller.active, same(edit));
    expect(maps.active, same(edit.document));
  });

  testWidgets('long stories only mount visible step rows', (tester) async {
    controller.pendingStories['long'] = createStudioStoryline(
      id: 'long',
      title: 'Longue histoire',
      steps: {for (var i = 0; i < 1000; i++) 'step_$i': 'Étape $i'},
    );
    await pump(tester);
    expect(find.text('Étape 0'), findsOneWidget);
    expect(find.text('Étape 999'), findsNothing);
    expect(find.byType(ListTile).evaluate().length, lessThan(30));
    final list = tester.state<ScrollableState>(find.byType(Scrollable).first);
    list.position.jumpTo(list.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.text('Étape 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });

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
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw UnimplementedError();
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) => throw UnimplementedError();
}
