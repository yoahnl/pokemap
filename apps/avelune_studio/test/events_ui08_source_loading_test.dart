import 'dart:async';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/events/event_map_loader.dart';
import 'package:avelune_studio/presentation/features/events/event_source_identity.dart';
import 'package:avelune_studio/presentation/features/events/event_trigger_panel.dart';
import 'package:avelune_studio/presentation/features/events/event_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'support/event_backend_fixture.dart';
import 'support/map_workspace_fixture.dart';
import 'support/ui06_scene_fixture.dart';

void main() {
  testWidgets(
    'switch A to delayed B removes all stale clickable targets until B loads',
    (tester) async {
      final f = (await tester.runAsync(EventBackendFixture.create))!;
      addTearDown(f.dispose);
      final port = WorkspaceMemoryPort();
      for (final id in ['a', 'b']) {
        port.saved[id] = workspaceMap(id).copyWith(
          entities: [
            MapEntity(
              id: 'chief',
              name: 'Chef $id',
              kind: MapEntityKind.npc,
              pos: const GridPos(x: 3, y: 3),
            ),
          ],
        );
      }
      final workspace = MapWorkspaceController(workspaceSession, port);
      await workspace.initialize();
      final record = NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: Ui06SceneFixture.eventId,
          name: 'Rencontre',
          source: NarrativeEventSourceRef.entityInteract('a', 'chief'),
          conditions: const [],
          priority: 0,
          order: 0,
        ),
      );
      workspace.project = workspace.project!.copyWith(
        eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.legacyOnly,
          records: [record],
          legacyClaims: const [],
        ),
      );
      final narrative = NarrativeWorkspaceController(
        workspace,
        f.narrative.port,
        () {},
        (_, _) async {},
      );
      final events = EventWorkspaceController(
        narrative,
        f.port,
        changed: () {},
      );
      await events.prepare();
      events.open(record.id);
      final loader = _DelayedPreviewLoader(workspace, port.saved);
      final view = EventViewState();
      addTearDown(() {
        events.dispose();
        narrative.dispose();
        workspace.dispose();
        view.dispose();
      });
      tester.view.physicalSize = const Size(1200, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: EventTriggerPanel(
              controller: events,
              record: record,
              loader: loader,
              visuals: WorkspaceTestVisuals(),
              view: view,
              onLocate: (_) {},
              onProducer: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Interaction du joueur'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-target:chief')), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jardin · b').last);
      await tester.pumpAndSettle();
      expect(find.text('Chargement de la carte…'), findsOneWidget);
      expect(find.byKey(const ValueKey('event-target:chief')), findsNothing);
      expect(
        events.record(record.id)!.source,
        NarrativeEventSourceRef.entityInteract('a', 'chief'),
      );
      loader.release.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-target:chief')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('event-target:chief')));
      await tester.pumpAndSettle();
      expect(
        events.record(record.id)!.source,
        NarrativeEventSourceRef.entityInteract('b', 'chief'),
      );
      expect(workspace.active!.current.id, 'a');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('source identity does not show homonymous A while B is loading', (
    tester,
  ) async {
    final workspace = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    await workspace.initialize();
    addTearDown(workspace.dispose);
    final loader = _DelayedPreviewLoader(workspace, {
      for (final id in ['a', 'b'])
        id: workspaceMap(id).copyWith(
          entities: [
            MapEntity(
              id: 'chief',
              name: 'Chef $id',
              kind: MapEntityKind.npc,
              pos: const GridPos(x: 3, y: 3),
            ),
          ],
        ),
    });
    Widget page(String id) => MaterialApp(
      home: Scaffold(
        body: EventSourceIdentity(
          source: NarrativeEventSourceRef.entityInteract(id, 'chief'),
          loader: loader,
        ),
      ),
    );
    await tester.pumpWidget(page('a'));
    await tester.pumpAndSettle();
    expect(find.text('Chef a'), findsOneWidget);
    await tester.pumpWidget(page('b'));
    await tester.pump();
    expect(find.text('Chef a'), findsNothing);
    expect(find.text('Chargement de la source…'), findsOneWidget);
    loader.release.complete();
    await tester.pumpAndSettle();
    expect(find.text('Chef b'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

class _DelayedPreviewLoader extends EventMapLoader {
  _DelayedPreviewLoader(super.workspace, this.maps);
  final Map<String, MapData> maps;
  final release = Completer<void>();
  @override
  Future<MapData> load(String id) async {
    if (id == 'b') await release.future;
    return maps[id]!;
  }
}
