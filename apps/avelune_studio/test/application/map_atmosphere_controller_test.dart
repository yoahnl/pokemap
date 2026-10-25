import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import '../support/spatial_environment_fixture.dart';

import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('workspace opens the sidecar once and saves it without saving or reloading the map', () async {
    final port = _WorkspacePort();
    final workspace = MapWorkspaceController(_session, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final document = workspace.active!;
    final atmosphere = document.atmosphere!;
    expect(port.loads, 1);
    atmosphere.edit(atmosphere.current.copyWith(waterAnimated: true));
    expect(workspace.dirty, isTrue);
    expect(document.dirty, isFalse);
    expect(await workspace.saveAll(), isTrue);
    expect(port.loads, 1);
    expect(port.mapReads, 1);
    expect(port.mapWrites, 0);
    expect(workspace.dirty, isFalse);
    await workspace.activate(port.entry);
    expect(port.loads, 1);
    expect(workspace.active!.atmosphere, same(atmosphere));
  });

  test('overlapping activation shares the initial atmosphere load', () async {
    final port = _WorkspacePort()..pendingLoad = Completer<void>();
    final workspace = MapWorkspaceController(_session, port)
      ..project = port.manifest;
    addTearDown(workspace.dispose);
    final first = workspace.activate(port.entry);
    final second = workspace.activate(port.entry);
    await Future<void>.delayed(Duration.zero);
    expect(port.loads, 1);
    port.pendingLoad!.complete();
    await Future.wait([first, second]);
    expect(port.loads, 1);
    expect(workspace.active!.atmosphere, isNotNull);
  });

  test(
    'edits stay local and first save persists only the atmosphere draft',
    () async {
      final port = _Port();
      final controller = await MapAtmosphereController.open(
        _session,
        'river',
        port,
      );
      addTearDown(controller.dispose);
      var notices = 0;
      controller.addListener(() => notices++);
      controller.edit(controller.current.copyWith(waterAnimated: true));
      expect(controller.dirty, isTrue);
      expect(port.loads, 1);
      expect(port.saves, isEmpty);
      expect(notices, 1);
      expect(await controller.save(), isTrue);
      expect(controller.dirty, isFalse);
      expect(port.loads, 1);
      expect(port.saves.single.waterAnimated, isTrue);
      expect(port.revisions, ['r0']);
      controller.edit(controller.current.copyWith(windowsLit: true));
      controller.undo();
      expect(controller.current.windowsLit, isFalse);
      controller.redo();
      expect(controller.current.windowsLit, isTrue);
      expect(await controller.save(), isTrue);
      expect(port.revisions, ['r0', 'r1']);
    },
  );

  test(
    'an edit during persistence remains dirty and a failed save stays editable',
    () async {
      final port = _Port();
      final controller = await MapAtmosphereController.open(
        _session,
        'river',
        port,
      );
      addTearDown(controller.dispose);
      controller.edit(controller.current.copyWith(fireflies: true));
      port.pending = Completer<void>();
      final saving = controller.save();
      expect(controller.saving, isTrue);
      controller.edit(controller.current.copyWith(fireflyDensity: .5));
      port.pending!.complete();
      expect(await saving, isTrue);
      expect(controller.dirty, isTrue);
      expect(controller.current.fireflyDensity, .5);
      port.failure = StateError('Conflit concurrent');
      expect(await controller.save(), isFalse);
      expect(controller.saving, isFalse);
      expect(controller.dirty, isTrue);
      expect(controller.error, contains('Conflit concurrent'));
      controller.edit(controller.current.copyWith(fireflyDensity: .7));
      expect(controller.error, isNull);
    },
  );
}

const _session = ProjectSession(
  sessionId: 's',
  name: 'Test',
  directoryPath: '/copy',
);

class _Port implements MapAtmospherePort {
  var loads = 0;
  final saves = <SpatialAtmosphereSettings>[];
  final revisions = <String>[];
  Completer<void>? pending;
  Object? failure;
  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async {
    loads++;
    return MapAtmosphereState(
      settings: SpatialAtmosphereSettings(),
      revision: 'r0',
    );
  }

  @override
  Future<MapAtmosphereState> saveAtmosphere(
    ProjectSession session,
    String mapId,
    SpatialAtmosphereSettings settings,
    String expectedRevision,
  ) async {
    saves.add(settings);
    revisions.add(expectedRevision);
    await pending?.future;
    if (failure != null) throw failure!;
    return MapAtmosphereState(settings: settings, revision: 'r${saves.length}');
  }
}

class _WorkspacePort extends _Port implements MapWorkspacePort {
  final entry = const ProjectMapEntry(
    id: 'a',
    name: 'Rive',
    relativePath: 'maps/a.json',
  );
  ProjectManifest get manifest =>
      ProjectManifest(name: 'Test', maps: [entry], tilesets: []);
  var mapReads = 0, mapWrites = 0;
  Completer<void>? pendingLoad;
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async => manifest;
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    mapReads++;
    return MapWorkspaceDocument(
      map: spatialEnvironmentMap(),
      revision: 'map0',
      mapId: 'a',
    );
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    mapWrites++;
    throw StateError('Atmosphere must not save the map');
  }

  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async {
    final state = await super.loadAtmosphere(session, mapId);
    await pendingLoad?.future;
    return state;
  }
}
