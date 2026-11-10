import 'dart:async';

import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/narrative/application/narrative_editing.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/dialogue_draft.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/neutral_map_host_fixture.dart';
import '../support/real_test_io.dart';

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

WorkspaceNavigationSession navigationFor(
  NeutralMapHostFixture fixture, {
  NarrativeWorkspaceController? narrative,
  bool events = true,
}) => WorkspaceNavigationSession(
  controller: fixture.maps,
  isActive: () => !fixture.maps.isDisposed,
  changed: fixture.maps.notify,
  narrative: () => narrative ?? fixture.sessions.narrative,
  events: events ? () => fixture.sessions.events : null,
  mapView: () => fixture.nativeView,
);

Future<void> openZone(
  NeutralMapHostFixture fixture,
  WorkspaceNavigationSession navigation,
  String triggerId, {
  Future<String?> Function(Map<String, String>)? choose,
}) async {
  await RealTestIo.run(
    fixture.tester,
    () => navigation.openExistingStoryZone(
      fixture.document,
      fixture.document.current.triggers.singleWhere((e) => e.id == triggerId),
      choose: choose ?? (_) async => throw StateError('Unexpected choice'),
    ),
  );
  await fixture.pump();
}

Future<String> drawZone(NeutralMapHostFixture fixture) async {
  fixture.nativeView.tool = StudioMapTool.zone;
  fixture.maps.notify();
  await fixture.pump();
  await fixture.drag(3, 11, 5, 13);
  final interaction = fixture.sessions.narrative!.active!.current.interaction;
  return interaction.source.toJson()['triggerId'] as String;
}

void main() {
  testWidgets('an interaction never saved reopens from its own native draft', (
    tester,
  ) async {
    final f = await NeutralMapHostFixture.open(tester);
    final narrative = await f.narrativeOwner();
    final navigation = navigationFor(f);
    final triggerId = await drawZone(f);
    final session = narrative.active!;
    final interaction = session.current.interaction;
    session.change(interaction: interaction.revise(name: 'Brume sur le quai'));
    final sessions = {...narrative.sessions.keys};
    final triggers = f.document.current.triggers;
    final disk = await f.disk();
    final framing = f.nativeView.transform.value.clone();
    f.nativeView.select(f.document, MapSelectionFamily.trigger, triggerId);
    for (var round = 0; round < 2; round++) {
      await openZone(f, navigation, triggerId);
      expect(navigation.space, WorkspaceSpace.interaction);
      expect(narrative.active, same(session));
      expect(narrative.active!.current.interaction.id, interaction.id);
      expect(
        narrative.active!.current.interaction.dialogueId,
        interaction.dialogueId,
      );
      expect(narrative.active!.current.interaction.name, 'Brume sur le quai');
      expect({...narrative.sessions.keys}, sessions);
      navigation.show(WorkspaceSpace.map);
      expect(f.document.current.triggers, triggers);
      expect(f.nativeView.transform.value, framing);
    }
    expect(await f.disk(), disk);
    expect(f.document.dirty, isTrue);
    expect(
      f.nativeView.selectedFor(
        f.document.current.id,
        MapSelectionFamily.trigger,
      ),
      triggerId,
    );
  });

  testWidgets('a saved interaction edited again reopens its simplified draft', (
    tester,
  ) async {
    final f = await NeutralMapHostFixture.open(tester);
    final narrative = await f.narrativeOwner();
    final navigation = navigationFor(f);
    final triggerId = await drawZone(f);
    final session = narrative.active!;
    final id = session.current.interaction.id;
    final dialogue = session.current.dialogue;
    session.change(
      interaction: session.current.interaction.revise(name: 'Première version'),
      dialogue: dialogue.copyWith(
        branches: [
          dialogue.branches.first.copyWith(
            lines: [const DialogueLineDraft(text: 'Bienvenue au quai.')],
          ),
        ],
      ),
    );
    expect(
      await RealTestIo.run(tester, () => narrative.save(document: f.document)),
      isTrue,
      reason: narrative.error ?? narrative.publicationError,
    );
    expect(session.dirty, isFalse);
    expect(
      narrative.project.eventRegistry!.records.any((r) => r.id == id),
      isTrue,
    );
    session.change(
      interaction: session.current.interaction.revise(name: 'Version en cours'),
    );
    expect(session.dirty, isTrue);
    final disk = await f.disk();
    await openZone(f, navigation, triggerId);
    expect(navigation.space, WorkspaceSpace.interaction);
    expect(narrative.active, same(session));
    expect(narrative.active!.current.interaction.id, id);
    expect(narrative.active!.current.interaction.name, 'Version en cours');
    expect(await f.disk(), disk);
  });

  testWidgets('a saved zone interaction opens its events owner', (
    tester,
  ) async {
    final f = await NeutralMapHostFixture.open(tester);
    final events = await f.eventOwner();
    final navigation = navigationFor(f);
    final disk = await f.disk();
    final id = navigation
        .interactionsOnSource(f.document.current.id, 'quai')
        .keys
        .single;
    await openZone(f, navigation, 'quai');
    expect(navigation.space, WorkspaceSpace.events);
    expect(events.activeId, id);
    expect(navigation.eventOrigin, WorkspaceSpace.map);
    expect(navigation.eventFilterMapId, f.document.current.id);
    navigation.show(WorkspaceSpace.story);
    navigation.eventFilterMapId = 'retained-map-filter';
    await RealTestIo.run(tester, () => navigation.openEvents(id));
    expect(navigation.eventOrigin, WorkspaceSpace.story);
    expect(navigation.eventFilterMapId, 'retained-map-filter');
    await RealTestIo.run(
      tester,
      () => navigation.openEvents(id, filterSource: true),
    );
    expect(navigation.eventFilterMapId, f.document.current.id);
    expect(await f.disk(), disk);
  });

  testWidgets('a late read cannot reopen a zone after navigation', (
    tester,
  ) async {
    final f = await NeutralMapHostFixture.open(tester);
    final held = (await tester.runAsync(
      () async => HeldNarrativePort(
        LocalNarrativeAdapter(
          session: f.maps.session,
          mapAdapter: f.source.maps,
        ),
      ),
    ))!;
    final narrative = NarrativeWorkspaceController(
      f.maps,
      held,
      f.maps.notify,
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final navigation = navigationFor(f, narrative: narrative, events: false);
    late Future<void> opening;
    await tester.runAsync(() async {
      opening = navigation.openExistingStoryZone(
        f.document,
        f.document.current.triggers.singleWhere((e) => e.id == 'quai'),
        choose: (_) async => throw StateError('Unexpected choice'),
      );
      for (var index = 0; index < 200 && held.reads == 0; index++) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    });
    expect(held.reads, 1);
    navigation.show(WorkspaceSpace.story);
    await tester.runAsync(() async {
      held.gate.complete();
      await opening;
    });
    await f.pump();
    expect(navigation.space, WorkspaceSpace.story);
  });

  testWidgets(
    'one zone offers only its exact interactions and opens the chosen draft',
    (tester) async {
      final f = await NeutralMapHostFixture.open(tester);
      final narrative = await f.narrativeOwner();
      await f.eventOwner();
      final navigation = navigationFor(f);
      await RealTestIo.run(
        tester,
        () => narrative.openSource(
          f.document,
          NarrativeEventSourceRef.triggerEnter(f.document.current.id, 'quai'),
          'Retour au quai',
        ),
      );
      final second = narrative.active!;
      final sessions = {...narrative.sessions.keys};
      final disk = await f.disk();
      await openZone(
        f,
        navigation,
        'quai',
        choose: (found) async {
          expect(found, hasLength(2));
          expect(found.values, containsAll(['Accueil quai', 'Retour au quai']));
          return second.current.interaction.id;
        },
      );
      expect(navigation.space, WorkspaceSpace.interaction);
      expect(narrative.active, same(second));
      expect({...narrative.sessions.keys}, sessions);
      expect(await f.disk(), disk);
    },
  );

  testWidgets(
    'a zone without an interaction refuses without creating an identity',
    (tester) async {
      final f = await NeutralMapHostFixture.open(tester);
      final narrative = await f.narrativeOwner();
      final navigation = navigationFor(f);
      final sessions = {...narrative.sessions.keys};
      final disk = await f.disk();
      await RealTestIo.run(
        tester,
        () => navigation.openExistingStoryZone(
          f.document,
          const MapTrigger(
            id: 'unbound',
            name: 'Sans interaction',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 1, y: 1),
              size: GridSize(width: 1, height: 1),
            ),
          ),
          choose: (_) async => throw StateError('Unexpected choice'),
        ),
      );
      expect(f.document.error, contains('Aucune interaction'));
      expect(navigation.space, WorkspaceSpace.map);
      expect({...narrative.sessions.keys}, sessions);
      expect(await f.disk(), disk);
    },
  );
}
