import 'dart:async';

import 'package:avelune_studio/features/map_workspace/domain/map_atmosphere_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/project_visuals/domain/project_visuals_port.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:map_core/map_core.dart';

import '../../support/scoped_map_workspace_port.dart';

class CoordinationPort extends ScopedTestMapPort
    implements MapWorkspaceExternalMutationPort {
  String revision = 'map-1';
  String? tilesetName;
  ProjectManifest? externalMetadata;
  Future<void> Function()? beforeLoad;
  int baselines = 0;
  @override
  Future<String?> readExternalMapRevision(
    ProjectSession session,
    String mapId,
  ) async =>
      (externalMetadata ?? metadata).maps.any((entry) => entry.id == mapId)
      ? revision
      : null;

  @override
  Future<MapWorkspaceCatalog> refreshExternalBaseline(
    ProjectSession session, {
    required Set<({String kind, String id})> resources,
  }) async {
    baselines++;
    return MapWorkspaceCatalog(
      metadata: externalMetadata ?? metadata,
      revision: 'catalog-external',
    );
  }

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final selection = await super.loadMapSelection(session, entry);
    return MapWorkspaceSelection(
      document: selection.document,
      definitions: selection.definitions.copyWith(
        tilesets: [
          for (final tileset in selection.definitions.tilesets)
            tilesetName == null
                ? tileset
                : tileset.copyWith(name: tilesetName!),
        ],
      ),
      catalogRevision: selection.catalogRevision,
      snapshotRevision: selection.snapshotRevision,
    );
  }

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    await beforeLoad?.call();
    final value = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: value.map.copyWith(
        name: revision == 'map-1' ? entry.name : 'Externe',
      ),
      revision: revision,
      mapId: entry.id,
    );
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    if (base.revision != revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Modification externe.',
      );
    }
    return revision;
  }
}

class EditorCoordinationPort implements MapEditorPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CoordinationReader
    implements
        ProjectFileReader,
        ProjectResourceStreamReader,
        ProjectResourceProbeReader {
  @override
  bool get supportsStreamingResources => true;
  @override
  Future<ProjectResourceProbe> probeResource({
    required String projectRoot,
    required String relativePath,
  }) => delegate.probeResource(
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  @override
  Stream<List<int>> openRead({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.openRead(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }

  final paths = <String>[];
  final delegate = const LocalProjectFileReader();
  @override
  Future<String> canonicalizeDirectory(String path) =>
      delegate.canonicalizeDirectory(path);
  @override
  Future<List<int>> readBytes({
    required String projectRoot,
    required String relativePath,
  }) {
    paths.add(relativePath);
    return delegate.readBytes(
      projectRoot: projectRoot,
      relativePath: relativePath,
    );
  }
}

class SecondaryCoordinationPort
    implements
        MapAtmospherePort,
        MapExteriorDecorationPort,
        ProjectVisualsPort {
  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async => MapAtmosphereState(
    settings: SpatialAtmosphereSettings(),
    revision: 'atmosphere-1',
  );
  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async => const MapExteriorDecorationState(
    decoration: null,
    revision: 'exterior-1',
  );
  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async =>
      ProjectVisualsState(profile: SpatialVisualPatch(), revision: 'weather-1');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisualCoordinationPort extends CoordinationPort
    implements ProjectVisualsPort {
  ProjectVisualsState projectState = ProjectVisualsState(
    profile: SpatialVisualPatch(),
    revision: 'project-1',
  );
  ProjectVisualsState mapState = ProjectVisualsState(
    profile: SpatialVisualPatch(),
    revision: 'map-visual-1',
  );
  @override
  Future<ProjectVisualsState> loadVisuals(
    ProjectSession session, {
    ProjectMapEntry? map,
  }) async => map == null ? projectState : mapState;
  @override
  Future<ProjectVisualsState> saveVisuals(
    ProjectSession session,
    SpatialVisualPatch profile,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) async {
    final before = map == null ? projectState : mapState;
    if (before.revision != expectedRevision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Visual conflict',
      );
    }
    final result = ProjectVisualsState(
      profile: profile,
      revision: '${before.revision}-saved',
    );
    if (map == null) {
      projectState = result;
    } else {
      mapState = result;
    }
    return result;
  }

  @override
  Future<ProjectVisualsState> undoVisuals(
    ProjectSession session,
    String receiptId,
    String expectedRevision, {
    ProjectMapEntry? map,
  }) => throw UnsupportedError('Not used');
}

class OwnerCoordinationPort extends VisualCoordinationPort
    implements MapAtmospherePort, MapEditorPort, MapExteriorDecorationPort {
  MapAtmosphereState atmosphere = MapAtmosphereState(
    settings: SpatialAtmosphereSettings(),
    revision: 'atmosphere-1',
  );
  MapEditorWorkspaceState editor = MapEditorWorkspaceState(
    state: MapEditorState(),
    revision: 'editor-1',
  );
  MapExteriorDecorationState exterior = const MapExteriorDecorationState(
    decoration: null,
    revision: 'exterior-1',
  );
  int unexpectedWrites = 0;
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final value = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: value.map.copyWith(
        version: ProjectVersion.v9,
        spatialScene: MapSpatialScene(width: 2, depth: 2),
      ),
      revision: value.revision,
      mapId: value.mapId,
    );
  }

  @override
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  ) async => atmosphere;
  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => editor;
  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async => exterior;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    unexpectedWrites++;
    return super.noSuchMethod(invocation);
  }
}
