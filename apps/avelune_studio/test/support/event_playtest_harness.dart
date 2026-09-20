import 'dart:async';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/events/data/local_event_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/events/event_playtest.dart';
import 'package:avelune_studio/presentation/features/map_workspace/workspace_actions.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'ui06_scene_fixture.dart';

class EventPlaytestHarness {
  EventPlaytestHarness._(
    this.fixture,
    this.maps,
    this.port,
    this.narrative,
    this.events,
  );
  final Ui06SceneFixture fixture;
  final MapWorkspaceController maps;
  final EventTestReadPort port;
  final NarrativeWorkspaceController narrative;
  final EventWorkspaceController events;
  late BuildContext context;
  int launches = 0;
  int changed = 0;
  Future<String?>? running;

  static Future<EventPlaytestHarness> create() async {
    final fixture = await Ui06SceneFixture.create();
    final port = EventTestReadPort(fixture.maps);
    final maps = MapWorkspaceController(fixture.session, port);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
      () {},
      (_, _) async {},
    );
    final events = EventWorkspaceController(
      narrative,
      LocalEventAdapter(session: fixture.session, mapAdapter: fixture.maps),
      changed: () {},
    );
    events.open(Ui06SceneFixture.eventId);
    return EventPlaytestHarness._(fixture, maps, port, narrative, events);
  }

  Widget app() => MaterialApp(
    home: Builder(
      builder: (value) {
        context = value;
        return const Scaffold(body: Text('Événements'));
      },
    ),
  );
  Widget runtime(ProjectMapEntry entry, String revision, VoidCallback close) {
    launches++;
    return Scaffold(
      body: TextButton(onPressed: close, child: Text('Fermer ${entry.id}')),
    );
  }

  Future<String?> launch() => launchPublishedEvent(
    context: context,
    events: events,
    scenes: null,
    mapId: maps.active!.current.id,
    eventId: Ui06SceneFixture.eventId,
    runtimeBuilder: runtime,
  );
  WorkspaceActions actions() => WorkspaceActions(
    controller: maps,
    context: () => context,
    mounted: () => context.mounted,
    changed: () => changed++,
    resources: () => null,
    narrative: () => narrative,
    events: () => events,
    runtimeBuilder: runtime,
  );
  Future<void> dispose() async {
    events.dispose();
    narrative.dispose();
    maps.dispose();
    await fixture.dispose();
  }
}

class EventTestReadPort implements MapWorkspacePort {
  EventTestReadPort(this.delegate);
  final MapWorkspacePort delegate;
  bool delay = false;
  int reads = 0;
  final entered = Completer<void>();
  final release = Completer<void>();
  final finished = Completer<void>();
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      delegate.loadProject(session);
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    reads++;
    if (delay) {
      if (!entered.isCompleted) entered.complete();
      await release.future;
    }
    final value = await delegate.loadMap(session, entry);
    if (reads > 1 && !finished.isCompleted) finished.complete();
    return value;
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) => delegate.saveMap(session, base, current);
}
