import 'dart:async';

import 'package:avelune_studio/features/events/application/event_map_loader.dart';
import 'package:avelune_studio/features/events/application/event_source_selection_session.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/event_backend_fixture.dart';
import '../support/map_workspace_fixture.dart';
import '../support/ui06_scene_fixture.dart';

void main() {
  test(
    'consulting another map preserves source active map and saved map bytes',
    () async {
      final h = await _Harness.create();
      addTearDown(h.dispose);
      await h.selection.pendingMap;
      final active = h.workspace.active;
      final saved = h.savedMaps;
      h.selection.selectMap('b');
      await h.selection.pendingMap;
      expect(h.selection.mapId, 'b');
      expect(h.selection.map!.entities.single.name, 'Chef b');
      expect(h.selection.choosing, isNull);
      expect(
        h.selection.accept(
          NarrativeEventSourceRef.entityInteract('b', 'chief'),
        ),
        isFalse,
      );
      expect(h.events.record(h.record.id)!.source, h.record.source);
      expect(h.events.dirty, isFalse);
      expect(h.workspace.active, same(active));
      expect(h.workspace.active!.current.id, 'a');
      expect(h.savedMaps, saved);
      expect(h.port.writes, 0);
    },
  );

  test('A to delayed B removes stale targets and accepts the exact B identity only after loading', () async {
    final h = await _Harness.create(gatedMaps: {'b'});
    addTearDown(h.dispose);
    await h.selection.pendingMap;
    final active = h.workspace.active;
    final saved = h.savedMaps;
    expect(
      await h.selection.choose(NarrativeEventSourceKind.entityInteract),
      isTrue,
    );
    h.selection.selectMap('b');
    final loading = h.selection.pendingMap!;
    expect(h.selection.mapId, 'b');
    expect(h.selection.map, isNull);
    expect(
      h.selection.accept(NarrativeEventSourceRef.entityInteract('a', 'chief')),
      isFalse,
    );
    expect(
      h.selection.accept(NarrativeEventSourceRef.entityInteract('b', 'chief')),
      isFalse,
    );
    expect(h.events.record(h.record.id)!.source, h.record.source);
    h.loader.gates['b']!.complete(h.port.saved['b']!);
    await loading;
    expect(h.selection.map!.entities.single.name, 'Chef b');
    expect(
      h.selection.accept(NarrativeEventSourceRef.triggerEnter('b', 'chief')),
      isFalse,
    );
    expect(
      h.selection.accept(NarrativeEventSourceRef.entityInteract('b', 'chief')),
      isTrue,
      reason: h.events.error,
    );
    expect(
      h.events.record(h.record.id)!.source,
      NarrativeEventSourceRef.entityInteract('b', 'chief'),
    );
    expect(h.selection.choosing, isNull);
    expect(h.events.dirty, isTrue);
    expect(h.workspace.active, same(active));
    expect(h.workspace.active!.current.id, 'a');
    expect(h.savedMaps, saved);
    expect(h.port.writes, 0);
  });

  test('a late A response cannot replace the ready B preview', () async {
    final h = await _Harness.create(gatedMaps: {'a', 'b'});
    addTearDown(h.dispose);
    final old = h.selection.pendingMap!;
    h.selection.selectMap('b');
    final latest = h.selection.pendingMap!;
    h.loader.gates['b']!.complete(h.port.saved['b']!);
    await latest;
    final ready = h.selection.map;
    final changes = h.changes;
    h.loader.gates['a']!.complete(h.port.saved['a']!);
    await old;
    expect(h.selection.mapId, 'b');
    expect(h.selection.map, same(ready));
    expect(h.selection.map!.entities.single.name, 'Chef b');
    expect(h.changes, changes);
    expect(h.events.record(h.record.id)!.source, h.record.source);
    expect(h.workspace.active!.current.id, 'a');
  });

  test('rebinding after the old workspace closes ignores its pending read and uses the new controller', () async {
    final old = await _Harness.create(gatedMaps: {'a'});
    addTearDown(old.dispose);
    final next = await _Harness.create();
    addTearDown(next.dispose);
    await next.selection.pendingMap;
    final previousRead = old.selection.pendingMap!;
    old.workspace.dispose();
    old.selection.configure(
      controller: next.events,
      loader: next.loader,
      record: next.record,
    );
    expect(old.selection.controller, same(next.events));
    await old.selection.pendingMap;
    final ready = old.selection.map;
    final changes = old.changes;
    old.loader.gates['a']!.complete(old.port.saved['a']!);
    await previousRead;
    expect(old.selection.map, same(ready));
    expect(old.changes, changes);
    expect(
      await old.selection.choose(NarrativeEventSourceKind.entityInteract),
      isTrue,
    );
    old.selection.selectMap('b');
    await old.selection.pendingMap;
    expect(
      old.selection.accept(
        NarrativeEventSourceRef.entityInteract('b', 'chief'),
      ),
      isTrue,
      reason: next.events.error,
    );
    expect(
      next.events.record(next.record.id)!.source,
      NarrativeEventSourceRef.entityInteract('b', 'chief'),
    );
    expect(old.events.record(old.record.id)!.source, old.record.source);
    expect(next.workspace.active!.current.id, 'a');
    expect(old.port.writes, 0);
    expect(next.port.writes, 0);
  });

  test('cancelling selection restores the recorded map and invalidates its pending preview', () async {
    final h = await _Harness.create(gatedMaps: {'b'});
    addTearDown(h.dispose);
    await h.selection.pendingMap;
    expect(
      await h.selection.choose(NarrativeEventSourceKind.entityInteract),
      isTrue,
    );
    h.selection.selectMap('b');
    final old = h.selection.pendingMap!;
    h.selection.cancel();
    await h.selection.pendingMap;
    expect(h.selection.mapId, 'a');
    expect(h.selection.map!.entities.single.name, 'Chef a');
    expect(h.selection.choosing, isNull);
    h.loader.gates['b']!.complete(h.port.saved['b']!);
    await old;
    expect(h.selection.map!.id, 'a');
    expect(h.events.record(h.record.id)!.source, h.record.source);
    expect(h.events.dirty, isFalse);
  });

  test('a cancelled or superseded outcome request cannot replace a newer source choice', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    await h.selection.pendingMap;
    for (final cancel in [false, true]) {
      final result = Completer<NarrativeOutcomeRef?>();
      final started = Completer<void>();
      final pending = h.selection.choose(
        NarrativeEventSourceKind.outcomeReceived,
        chooseOutcome: () {
          started.complete();
          return result.future;
        },
      );
      await started.future;
      if (cancel) {
        h.selection.cancel();
      } else {
        expect(
          await h.selection.choose(NarrativeEventSourceKind.entityInteract),
          isTrue,
        );
      }
      result.complete(_outcome());
      expect(await pending, isFalse);
      expect(
        h.selection.choosing,
        cancel ? isNull : NarrativeEventSourceKind.entityInteract,
      );
      expect(h.events.record(h.record.id)!.source, h.record.source);
      expect(h.events.dirty, isFalse);
    }
  });

  test('changing the event identity invalidates a pending choice even on the same map', () async {
    final h = await _Harness.create();
    addTearDown(h.dispose);
    await h.selection.pendingMap;
    final result = Completer<NarrativeOutcomeRef?>();
    final started = Completer<void>();
    final pending = h.selection.choose(
      NarrativeEventSourceKind.outcomeReceived,
      chooseOutcome: () {
        started.complete();
        return result.future;
      },
    );
    await started.future;
    final other = h.events.create('Autre événement', source: h.record.source)!;
    h.selection.configure(
      controller: h.events,
      loader: h.loader,
      record: other,
    );
    result.complete(_outcome());
    expect(await pending, isFalse);
    expect(h.selection.recordId, other.id);
    expect(h.selection.choosing, isNull);
    expect(h.events.record(h.record.id)!.source, h.record.source);
    expect(h.events.record(other.id)!.source, h.record.source);
  });

  test('cancelling during preparation prevents a late choosing mode', () async {
    final h = await _Harness.create(gatedMaps: {'b'});
    addTearDown(h.dispose);
    await h.selection.pendingMap;
    h.selection.selectMap('b');
    final preview = h.selection.pendingMap!;
    h.port.delayedId = 'b';
    h.port.releaseGate = Completer<void>();
    h.port.started = Completer<void>();
    final pending = h.selection.choose(NarrativeEventSourceKind.entityInteract);
    await h.port.started!.future;
    h.selection.cancel();
    h.port.releaseGate!.complete();
    expect(await pending, isFalse);
    h.loader.gates['b']!.complete(h.port.saved['b']!);
    await preview;
    expect(h.selection.choosing, isNull);
    expect(h.selection.mapId, 'a');
    expect(h.events.record(h.record.id)!.source, h.record.source);
  });

  test(
    'disposal invalidates pending map reads and prevents new source operations',
    () async {
      final h = await _Harness.create(gatedMaps: {'b'});
      addTearDown(h.dispose);
      await h.selection.pendingMap;
      h.selection.selectMap('b');
      final pending = h.selection.pendingMap!;
      final changes = h.changes;
      h.selection.dispose();
      h.loader.gates['b']!.complete(h.port.saved['b']!);
      await pending;
      expect(h.selection.map, isNull);
      expect(h.changes, changes);
      expect(
        await h.selection.choose(NarrativeEventSourceKind.entityInteract),
        isFalse,
      );
      expect(
        h.selection.accept(
          NarrativeEventSourceRef.entityInteract('b', 'chief'),
        ),
        isFalse,
      );
      expect(h.events.record(h.record.id)!.source, h.record.source);
      expect(h.workspace.active!.current.id, 'a');
    },
  );

  test(
    'wrong map identity and failed reads cannot provide selectable targets',
    () async {
      final h = await _Harness.create(gatedMaps: {'b'});
      addTearDown(h.dispose);
      await h.selection.pendingMap;
      expect(
        await h.selection.choose(NarrativeEventSourceKind.entityInteract),
        isTrue,
      );
      h.selection.selectMap('b');
      final pending = h.selection.pendingMap!;
      h.loader.gates['b']!.complete(h.port.saved['a']!);
      await pending;
      expect(h.selection.map, isNull);
      expect(
        h.selection.accept(
          NarrativeEventSourceRef.entityInteract('b', 'chief'),
        ),
        isFalse,
      );
      h.loader.gates['b'] = Completer<MapData>();
      h.selection.selectMap('b');
      final failed = expectLater(
        h.selection.pendingMap!,
        throwsA(isA<StateError>()),
      );
      h.loader.gates['b']!.completeError(StateError('Carte indisponible'));
      await failed;
      expect(h.selection.map, isNull);
      expect(h.events.record(h.record.id)!.source, h.record.source);
      expect(h.events.dirty, isFalse);
      expect(h.port.writes, 0);
    },
  );
}

NarrativeOutcomeRef _outcome() => NarrativeOutcomeRef(
  producerKind: NarrativeOutcomeProducerKind.scene,
  producerId: 'scene',
  outcomeId: 'completed',
);

class _Harness {
  _Harness(
    this.backend,
    this.port,
    this.workspace,
    this.narrative,
    this.events,
    this.record,
  ) {
    loader = _PreviewLoader(workspace, port.saved);
  }
  final EventBackendFixture backend;
  final _WorkspacePort port;
  final MapWorkspaceController workspace;
  final NarrativeWorkspaceController narrative;
  final EventWorkspaceController events;
  final NarrativeEventRecord record;
  late final _PreviewLoader loader;
  late final EventSourceSelectionSession selection;
  var changes = 0;
  Map<String, Object?> get savedMaps => {
    for (final entry in port.saved.entries) entry.key: entry.value.toJson(),
  };

  static Future<_Harness> create({Set<String> gatedMaps = const {}}) async {
    final backend = await EventBackendFixture.create();
    final port = _WorkspacePort();
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
      backend.narrative.port,
      () {},
      (_, _) async {},
    );
    final events = EventWorkspaceController(
      narrative,
      backend.port,
      changed: () {},
    );
    expect(await events.prepare(mapIds: ['a']), isTrue, reason: events.error);
    expect(events.open(record.id), isTrue);
    final h = _Harness(backend, port, workspace, narrative, events, record);
    for (final id in gatedMaps) {
      h.loader.gates[id] = Completer<MapData>();
    }
    h.selection = EventSourceSelectionSession(
      controller: events,
      loader: h.loader,
      record: record,
      changed: () => h.changes++,
    );
    return h;
  }

  Future<void> dispose() async {
    selection.dispose();
    events.dispose();
    narrative.dispose();
    workspace.dispose();
    await backend.dispose();
  }
}

class _PreviewLoader extends EventMapLoader {
  _PreviewLoader(super.workspace, this.maps);
  final Map<String, MapData> maps;
  final gates = <String, Completer<MapData>>{};
  @override
  Future<MapData> load(String id) =>
      gates[id]?.future ?? Future.value(maps[id]!);
}

class _WorkspacePort extends WorkspaceMemoryPort {
  String? delayedId;
  Completer<void>? releaseGate;
  Completer<void>? started;

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    if (entry.id == delayedId) {
      if (started case final beginning? when !beginning.isCompleted) {
        beginning.complete();
      }
      await releaseGate?.future;
    }
    return super.loadMap(session, entry);
  }
}
