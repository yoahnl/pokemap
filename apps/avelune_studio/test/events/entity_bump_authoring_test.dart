import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/features/events/event_source_identity.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';

import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/presentation/features/events/event_context_map.dart';

import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/events/event_map_loader.dart';
import 'package:avelune_studio/presentation/features/events/event_trigger_panel.dart';
import 'package:avelune_studio/presentation/features/events/event_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/event_backend_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  testWidgets(
    'guided Event source offers player contact separately from interaction',
    (tester) async {
      final f = (await tester.runAsync(EventBackendFixture.create))!;
      addTearDown(f.dispose);
      final events = f.attach();
      await tester.runAsync(events.prepare);
      final record = events.record(Ui06SceneFixture.eventId)!;
      final view = EventViewState();
      addTearDown(view.dispose);
      tester.view.physicalSize = const Size(1200, 900);
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
              loader: EventMapLoader(f.workspace),
              visuals: WorkspaceTestVisuals(),
              view: view,
              onLocate: (_) {},
              onProducer: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Interaction du joueur'), findsOneWidget);
      expect(find.text('Contact du joueur'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final available in [true, false]) {
    testWidgets(
      'contact source identity preserves the NPC and availability=$available',
      (tester) async {
        final port = WorkspaceMemoryPort();
        port.saved['a'] = workspaceMap('a')
            .copyWith(entities: [_npc.copyWith(blocksMovement: available)]);
        final workspace = MapWorkspaceController(workspaceSession, port);
        await workspace.initialize();
        workspace.project = _project;
        addTearDown(workspace.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: EventSourceIdentity(
                source: NarrativeEventSourceRef.entityBump('a', 'chief'),
                loader: EventMapLoader(workspace),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text(
            available
                ? 'Chef original'
                : 'Source indisponible · personnage à réparer',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'contact target emits its exact kind while interaction remains separate',
    (tester) async {
      NarrativeEventSourceRef? selected;
      final transform = TransformationController();
      addTearDown(transform.dispose);
      final map = workspaceMap('a').copyWith(entities: [_npc]);
      Future<void> show(NarrativeEventSourceKind kind) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: EventContextMap(
                key: ValueKey(kind),
                map: map,
                project: _project,
                visuals: WorkspaceTestVisuals(),
                transform: transform,
                chooseKind: kind,
                onChoose: (value) => selected = value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(NarrativeEventSourceKind.entityBump);
      expect(find.byKey(const ValueKey('event-target:chief')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('event-target:chief')));
      expect(selected, NarrativeEventSourceRef.entityBump('a', 'chief'));
      await show(NarrativeEventSourceKind.entityInteract);
      await tester.tap(find.byKey(const ValueKey('event-target:chief')));
      expect(selected, NarrativeEventSourceRef.entityInteract('a', 'chief'));
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final invalid in [
    'nonblocking',
    'sign',
    'ghost',
    'duplicate',
    'character-duplicate',
    'map-duplicate',
    'threeD',
  ]) {
    testWidgets('contact picker refuses $invalid native target', (
      tester,
    ) async {
      final transform = TransformationController();
      addTearDown(transform.dispose);
      final entities = switch (invalid) {
        'nonblocking' => [_npc.copyWith(blocksMovement: false)],
        'sign' => [
          const MapEntity(
            id: 'chief',
            kind: MapEntityKind.sign,
            pos: GridPos(x: 3, y: 3),
          ),
        ],
        'ghost' => [
          const MapEntity(
            id: 'chief',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 3),
          ),
        ],
        'duplicate' => [_npc, _npc],
        _ => [_npc],
      };
      final project = _project.copyWith(
        characters: invalid == 'character-duplicate'
            ? [_character, _character]
            : [_character],
        maps: invalid == 'map-duplicate'
            ? [workspaceEntries.first, workspaceEntries.first]
            : workspaceEntries,
        settings: ProjectSettings(
          dimension: invalid == 'threeD'
              ? ProjectDimension.threeD
              : ProjectDimension.twoD,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: EventContextMap(
              map: workspaceMap('a').copyWith(entities: entities),
              project: project,
              visuals: WorkspaceTestVisuals(),
              transform: transform,
              chooseKind: NarrativeEventSourceKind.entityBump,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-target:chief')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'contact selection rejects an old map callback while the next map loads',
    (tester) async {
      final f = (await tester.runAsync(EventBackendFixture.create))!;
      addTearDown(f.dispose);
      final port = WorkspaceMemoryPort();
      for (final id in ['a', 'b']) {
        port.saved[id] = workspaceMap(id)
            .copyWith(entities: [_npc.copyWith(name: 'Chef $id')]);
      }
      final workspace = MapWorkspaceController(workspaceSession, port);
      await workspace.initialize();
      final original = NarrativeEventSourceRef.entityInteract('a', 'chief');
      final record = NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: Ui06SceneFixture.eventId,
          name: 'Contact',
          source: original,
          conditions: const [],
          priority: 0,
          order: 0,
        ),
      );
      workspace.project = _project.copyWith(
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
      final view = EventViewState();
      final loader = _DelayedLoader(workspace, port.saved);
      addTearDown(() {
        events.dispose();
        narrative.dispose();
        workspace.dispose();
        view.dispose();
      });
      tester.view.physicalSize = const Size(1200, 900);
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
      await tester.tap(find.text('Contact du joueur'));
      await tester.pumpAndSettle();
      final stale = tester
          .widget<GestureDetector>(
            find.byKey(const ValueKey('event-target:chief')),
          )
          .onTap!;
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jardin · b').last);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('event-target:chief')), findsNothing);
      stale();
      await tester.pump();
      expect(events.record(record.id)!.source, original);
      loader.release.complete();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('event-target:chief')));
      await tester.pumpAndSettle();
      expect(
        events.record(record.id)!.source,
        NarrativeEventSourceRef.entityBump('b', 'chief'),
      );
      expect(workspace.active!.current.id, 'a');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'modern event page creates a contact draft and saves through the canonical port',
    (tester) async {
      final f = (await tester.runAsync(_backend))!;
      addTearDown(f.dispose);
      final events = f.attach();
      await tester.runAsync(() => events.prepare());
      final view = EventViewState();
      addTearDown(view.dispose);
      tester.view.physicalSize = const Size(1584, 994);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: EventWorkspacePage(
              controller: events,
              view: view,
              loader: EventMapLoader(f.workspace),
              visuals: WorkspaceTestVisuals(),
              onBack: () {},
              onScene: (_) async => null,
              onLocate: (_) async => null,
              onTest: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nouvel événement').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        ),
        'Contact créé',
      );
      await tester.pump();
      await tester.tap(find.text('Créer'));
      await _io(tester);
      final created = events.active!;
      expect(created.draftOrNull, isNotNull);
      await tester.tap(find.text('Contact du joueur'));
      await _io(tester);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      final entry = f.workspace.project!.maps.first;
      await tester.tap(find.text('${entry.name} · ${entry.id}').last);
      await _io(tester);
      await tester.tap(find.byKey(const ValueKey('event-target:chief')));
      await _io(tester);
      final source = NarrativeEventSourceRef.entityBump(entry.id, 'chief');
      expect(events.record(created.id)!.source, source);
      final save = tester
          .widget<StudioButton>(
            find
                .ancestor(
                  of: find.text('Enregistrer').first,
                  matching: find.byType(StudioButton),
                )
                .first,
          )
          .onPressed;
      expect(save, isNotNull);
      await tester.runAsync(() => (save as Future<void> Function())());
      await _io(tester);
      expect(
        events.dirty,
        isFalse,
        reason: 'busy=${events.busy} error=${events.error}',
      );
      final fresh = await tester.runAsync(f.readFresh);
      expect(
        fresh!.eventRegistry!.records
            .singleWhere((r) => r.id == created.id)
            .source,
        source,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('modern creation and editing publish contact identity through canonical API and cold reopen', () async {
    final f = await _backend();
    addTearDown(f.dispose);
    final c = f.attach();
    expect(await c.prepare(), isTrue, reason: c.error);
    final map = f.workspace.active!;
    final mapBefore = map.current;
    final projectBefore = await f.readFresh();
    final source = NarrativeEventSourceRef.entityBump(map.current.id, 'chief');
    final created = c.create('Contact original', source: source);
    expect(created, isNotNull, reason: c.error);
    expect(
      c.setScene(created!.id, Ui06SceneFixture.sceneId),
      isTrue,
      reason: c.error,
    );
    expect(c.setReuse(created.id, NarrativeEventReusePolicy.reusable), isTrue);
    expect(c.configure(created.id), isTrue, reason: c.error);
    expect(c.setEnabled(created.id, true), isTrue, reason: c.error);
    expect(
      c.setSource(Ui06SceneFixture.eventId, source),
      isTrue,
      reason: c.error,
    );
    expect(await c.save(), isTrue, reason: c.error);
    final fresh = await f.readFresh();
    expect(
      fresh.eventRegistry!.records
          .singleWhere((r) => r.id == created.id)
          .source,
      source,
    );
    expect(
      fresh.eventRegistry!.records
          .singleWhere((r) => r.id == Ui06SceneFixture.eventId)
          .source,
      source,
    );
    expect(fresh.scenes, projectBefore.scenes);
    expect(map.current, mapBefore);
    c.dispose();
    final maps = LocalMapWorkspaceAdapter();
    final workspace = MapWorkspaceController(f.source.session, maps);
    await workspace.initialize();
    final narrative = NarrativeWorkspaceController(
      workspace,
      LocalNarrativeAdapter(session: f.source.session, mapAdapter: maps),
      () {},
      (_, _) async {},
    );
    final reopened = EventWorkspaceController(
      narrative,
      LocalEventAdapter(session: f.source.session, mapAdapter: maps),
      changed: () {},
    );
    addTearDown(() {
      reopened.dispose();
      narrative.dispose();
      workspace.dispose();
    });
    expect(await reopened.prepare(), isTrue, reason: reopened.error);
    final loaded = reopened.project;
    expect(
      loaded.eventRegistry!.records
          .singleWhere((r) => r.id == created.id)
          .source!
          .toJson(),
      {'kind': 'entityBump', 'mapId': map.current.id, 'entityId': 'chief'},
    );
  });

  test('modern contact replacement refuses unavailable owners without changing the stored source', () async {
    final f = await _backend();
    addTearDown(f.dispose);
    final c = f.attach();
    await c.prepare();
    final original = c.record(Ui06SceneFixture.eventId)!.source;
    final map = f.workspace.active!;
    for (final entities in <List<MapEntity>>[
      [],
      [_npc.copyWith(blocksMovement: false)],
      [_npc, _npc],
      [
        const MapEntity(
          id: 'chief',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 3, y: 3),
        ),
      ],
    ]) {
      map.commit(map.current.copyWith(entities: entities));
      expect(
        c.setSource(
          Ui06SceneFixture.eventId,
          NarrativeEventSourceRef.entityBump(map.current.id, 'chief'),
        ),
        isFalse,
      );
      expect(c.record(Ui06SceneFixture.eventId)!.source, original);
    }
    expect(
      c.setSource(
        Ui06SceneFixture.eventId,
        NarrativeEventSourceRef.entityBump('missing', 'chief'),
      ),
      isFalse,
    );
    expect(c.record(Ui06SceneFixture.eventId)!.source, original);
  });
}

const _character = ProjectCharacterEntry(
  id: 'contact-character',
  name: 'Original contact actor',
  tilesetId: 'atlas',
);
const _npc = MapEntity(
  id: 'chief',
  name: 'Chef original',
  kind: MapEntityKind.npc,
  pos: GridPos(x: 3, y: 3),
  npc: MapEntityNpcData(characterId: 'contact-character'),
);
final _project = workspaceProject.copyWith(characters: [_character]);

Future<_ContactBackend> _backend() async {
  final source = await Ui06SceneFixture.create();
  final projectFile = File('${source.directory.path}/project.json');
  final original = ProjectManifest.fromJson(
    jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
  );
  final project = original.copyWith(
    characters: [_character.copyWith(tilesetId: original.tilesets.first.id)],
  );
  await projectFile.writeAsString(jsonEncode(project.toJson()));
  final maps = LocalMapWorkspaceAdapter();
  await maps.loadProject(source.session);
  final base = await maps.loadMap(source.session, project.maps.first);
  await maps.saveMap(source.session, base, base.map.copyWith(entities: [_npc]));
  final workspace = MapWorkspaceController(source.session, maps);
  await workspace.initialize();
  return _ContactBackend(source, workspace, maps);
}

class _ContactBackend {
  _ContactBackend(this.source, this.workspace, LocalMapWorkspaceAdapter maps) {
    narrative = NarrativeWorkspaceController(
      workspace,
      LocalNarrativeAdapter(session: source.session, mapAdapter: maps),
      () {},
      (_, _) async {},
    );
    port = LocalEventAdapter(session: source.session, mapAdapter: maps);
  }
  final Ui06SceneFixture source;
  final MapWorkspaceController workspace;
  late final NarrativeWorkspaceController narrative;
  late final LocalEventAdapter port;
  EventWorkspaceController? controller;
  EventWorkspaceController attach() =>
      controller = EventWorkspaceController(narrative, port, changed: () {});
  Future<ProjectManifest> readFresh() =>
      LocalMapWorkspaceAdapter().loadProject(source.session);
  Future<void> dispose() async {
    controller?.dispose();
    narrative.dispose();
    workspace.dispose();
    await source.dispose();
  }
}

class _DelayedLoader extends EventMapLoader {
  _DelayedLoader(super.workspace, this.maps);
  final Map<String, MapData> maps;
  final release = Completer<void>();
  @override
  Future<MapData> load(String id) async {
    if (id == 'b') await release.future;
    return maps[id]!;
  }
}

Future<void> _io(WidgetTester tester) async {
  for (var index = 0; index < 8; index++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}
