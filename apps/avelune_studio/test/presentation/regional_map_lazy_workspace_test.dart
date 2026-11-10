import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_destination_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_navigation_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_controllers.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_session_loader.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workshop_routes.dart';
import 'package:avelune_studio/features/map_workspace/domain/workspace_navigation.dart';
import 'package:avelune_studio/features/regional_map/domain/regional_map_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('local map playtest starts without loading the regional catalogue', () async {
    final regional = DeferredRegionalMapPort();
    final f = await _open(regional);
    final started = Completer<void>(), returned = Completer<void>();
    var starts = 0;
    final document = f.maps.active;
    final workflow = WorkspaceWorkflow(
      controller: f.maps,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      regionalMap: () => f.owners.regionalMap,
      confirmClose: () async => WorkspaceCloseChoice.cancel,
      flushFocus: () {},
      launchMap: (_, _) async {
        starts++;
        started.complete();
        await returned.future;
      },
    );
    final running = workflow.test();
    await started.future.timeout(const Duration(seconds: 5));
    expect(starts, 1);
    expect(regional.loads, 0);
    expect(workflow.testing, isTrue);
    returned.complete();
    await running;
    expect(workflow.testing, isFalse);
    expect(f.maps.active, same(document));
  });

  test('regional catalogue loads on entry and refreshes on return', () async {
    final regional = DeferredRegionalMapPort();
    final f = await _open(regional);
    expect(regional.loads, 0);
    f.destinations.show(WorkspaceSpace.regionalMap);
    expect(regional.loads, 1);
    expect(f.navigation.space, WorkspaceSpace.regionalMap);
    expect(f.owners.regionalMap!.busy, isTrue);
    regional.complete();
    await regional.pending.future;
    await Future<void>.delayed(Duration.zero);
    expect(f.owners.regionalMap!.source, isNotNull);
    f.destinations.show(WorkspaceSpace.map);
    f.destinations.show(WorkspaceSpace.regionalMap);
    await Future<void>.delayed(Duration.zero);
    expect(regional.loads, 2);
    expect(f.navigation.space, WorkspaceSpace.regionalMap);
  });

  test('an active exporter blocks leaving its destination', () async {
    final exporter = _Exporter();
    final f = await _open(DeferredRegionalMapPort(), exporter: () => exporter);
    f.navigation.space = WorkspaceSpace.gameExport;
    exporter.operationActive = true;
    f.destinations.show(WorkspaceSpace.regionalMap);
    expect(f.navigation.space, WorkspaceSpace.gameExport);
    expect(f.regional.loads, 0);
    exporter.operationActive = false;
    f.destinations.show(WorkspaceSpace.map);
    expect(f.navigation.space, WorkspaceSpace.map);
  });

  test('a replaced library guard cannot release or navigate the newer library', () async {
    final pending = Completer<bool>();
    Future<bool> Function()? guard = () => pending.future;
    var releases = 0;
    final f = await _open(
      DeferredRegionalMapPort(),
      guard: () => guard,
      released: () => releases++,
    );
    f.navigation.space = WorkspaceSpace.resources;
    f.destinations.show(WorkspaceSpace.map);
    guard = () async => false;
    pending.complete(true);
    await Future<void>.delayed(Duration.zero);
    expect(releases, 0);
    expect(f.navigation.space, WorkspaceSpace.resources);
    guard = () async => true;
    f.destinations.show(WorkspaceSpace.map);
    await Future<void>.delayed(Duration.zero);
    expect(releases, 1);
    expect(f.navigation.space, WorkspaceSpace.map);
  });

  test('a disposed destination owner ignores a late library decision', () async {
    final pending = Completer<bool>();
    var releases = 0;
    final f = await _open(
      DeferredRegionalMapPort(),
      guard: () => () => pending.future,
      released: () => releases++,
    );
    f.navigation.space = WorkspaceSpace.resources;
    f.destinations.show(WorkspaceSpace.map);
    f.destinations.dispose();
    pending.complete(true);
    await Future<void>.delayed(Duration.zero);
    f.destinations.show(WorkspaceSpace.regionalMap);
    expect(releases, 0);
    expect(f.navigation.space, WorkspaceSpace.resources);
    expect(f.regional.loads, 0);
  });
}

Future<({
  MapWorkspaceController maps,
  WorkspaceSessionControllers owners,
  WorkspaceNavigationSession navigation,
  WorkspaceDestinationWorkflow destinations,
  DeferredRegionalMapPort regional,
})> _open(
  DeferredRegionalMapPort regional, {
  StudioGameExportPort? Function()? exporter,
  Future<bool> Function()? Function()? guard,
  void Function()? released,
}) async {
  final maps = MapWorkspaceController(workspaceSession, WorkspaceMemoryPort());
  await maps.initialize();
  final owners = WorkspaceSessionControllers(
    controller: maps,
    changed: () {},
    visualCatalogChanged: (_) {},
    flushEditors: () async => true,
    regionalMapPort: regional,
  );
  owners.initializeLoaded(LoadedWorkspaceSession(
    workspace: maps,
    visuals: WorkspaceTestVisuals(),
    resources: null,
    narrative: null,
    historyGuard: null,
    changed: () {},
  ));
  final navigation = WorkspaceNavigationSession(
    controller: maps, isActive: () => true, changed: () {},
  );
  final routes = WorkspaceWorkshopRoutes(
    controller: maps,
    isActive: () => true,
    failed: (error) { if (error != null) throw error; },
    changed: () {},
  );
  final destinations = WorkspaceDestinationWorkflow(
    controller: maps,
    navigation: navigation,
    sessions: owners,
    workshops: routes,
    isActive: () => true,
    changed: () {},
    leavePokemon: () async => true,
    flushFocus: () {},
    closeContext: () {},
    exporter: exporter,
    libraryExitGuard: guard,
    libraryReleased: released,
  );
  addTearDown(() async {
    destinations.dispose();
    regional.complete();
    await owners.dispose();
    maps.dispose();
  });
  return (maps: maps, owners: owners, navigation: navigation, destinations: destinations, regional: regional);
}

final class DeferredRegionalMapPort implements RegionalMapPort {
  final pending = Completer<RegionalMapSource>();
  var loads = 0;

  void complete() {
    if (pending.isCompleted) return;
    pending.complete(RegionalMapSource(
      project: workspaceProject,
      revision: 'regional-source',
      maps: { for (final entry in workspaceEntries) entry.id: workspaceMap(entry.id) },
      images: const {},
    ));
  }

  @override
  Future<RegionalMapSource> load() {
    loads++;
    return pending.future;
  }

  @override
  Future<Uint8List?> readImage(String path) async => null;

  @override
  Future<RegionalMapSource> publish({
    required RegionalMapSource base,
    required String actionId,
    required Map<String, Object?> parameters,
  }) => throw UnsupportedError('Loading must not publish a catalogue.');
}

class _Exporter extends Fake implements StudioGameExportPort {
  @override
  bool operationActive = false;
}
