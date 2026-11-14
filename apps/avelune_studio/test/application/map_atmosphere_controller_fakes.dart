import 'dart:async';

import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import '../support/spatial_environment_fixture.dart';

import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';

const atmosphereSession = ProjectSession(
  sessionId: 's',
  name: 'Test',
  directoryPath: '/copy',
);

class AtmospherePort implements MapAtmospherePort {
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

class AtmosphereWorkspacePort extends AtmospherePort
    implements MapWorkspacePort {
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

class AtmosphereNarrativePort implements NarrativePort {
  AtmosphereNarrativePort(this.workspace, this.atmosphere);
  final MapWorkspaceController workspace;
  final AtmospherePort atmosphere;
  int publications = 0;
  bool atmosphereWasSavedFirst = false;
  @override
  Future<NarrativeDialogueSource> readDialogue(ProjectDialogueEntry entry) =>
      throw UnimplementedError();
  @override
  Future<NarrativePublicationReceipt> publish(
    NarrativePublication publication,
  ) async {
    publications++;
    atmosphereWasSavedFirst =
        atmosphere.saves.isNotEmpty &&
        workspace.active!.atmosphere!.dirty == false;
    return NarrativePublicationReceipt(
      beforeManifest: workspace.project!,
      manifest: workspace.project!,
      savedMap: publication.current,
      revision: 'published-$publications',
      sourceRevisions: {},
      changedPaths: [],
    );
  }
}
