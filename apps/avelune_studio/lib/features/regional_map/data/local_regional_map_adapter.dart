import 'dart:convert';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_catalog_transaction.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/regional_map_port.dart';

final class LocalRegionalMapAdapter implements RegionalMapPort {
  const LocalRegionalMapAdapter({
    required this.session,
    required this.mapAdapter,
  });
  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;

  Future<ProjectSnapshot> _snapshot() async {
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [session.directoryPath],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(session.directoryPath);
    try {
      return await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle);
    } finally {
      handles.closeWorkspace(opened.workspaceHandle);
    }
  }

  AssetCatalog _assets(ProjectSnapshot snapshot) {
    final bytes = snapshot.findResourceBytes(assetCatalogResourceIdentity);
    return bytes == null
        ? AssetCatalog(records: [])
        : AssetCatalog.fromJson(
            Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
          );
  }

  @override
  Future<RegionalMapSource> load() async {
    final baseline = await mapAdapter.resourceBaseline(
      session,
      refreshCatalog: true,
    );
    final snapshot = await _snapshot();
    final revision = narrativeEventBytesFingerprint(
      snapshot.resourceBytes('project'),
    );
    if (revision != baseline.revision) {
      throw const NarrativeCatalogFailure(
        'Le catalogue a changé pendant sa lecture.',
      );
    }
    return RegionalMapSource(
      project: snapshot.manifest,
      revision: revision,
      maps: {for (final map in snapshot.maps) map.id: map},
      images: {
        for (final asset in _assets(snapshot).records)
          if (const {
            'image/png',
            'image/jpeg',
            'image/webp',
            'image/gif',
          }.contains(asset.artifact.mediaType))
            asset.logicalPath: asset.logicalPath.split('/').last,
      },
    );
  }

  @override
  Future<Uint8List?> readImage(String path) async {
    const reader = LocalProjectFileReader();
    final bytes = await reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: assetCatalogStorageKey,
    );
    final assets = AssetCatalog.fromJson(
      Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
    );
    final asset = assets.findByLogicalPath(path);
    if (asset == null ||
        !const {
          'image/png',
          'image/jpeg',
          'image/webp',
          'image/gif',
        }.contains(asset.artifact.mediaType)) {
      return null;
    }
    return Uint8List.fromList(
      await reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: assetBlobStorageKey(asset.artifact),
      ),
    );
  }

  @override
  Future<RegionalMapSource> publish({
    required RegionalMapSource base,
    required String actionId,
    required Map<String, Object?> parameters,
  }) async {
    await LocalNarrativeCatalogTransaction(
      session: session,
      mapAdapter: mapAdapter,
    ).run(
      actionId: actionId,
      parameters: (project) {
        if (project != base.project) {
          throw const NarrativeCatalogFailure(
            'Le projet a changé. Rechargez le catalogue après avoir conservé votre brouillon.',
          );
        }
        return parameters;
      },
      validate: (project, maps) {
        final pointJson = parameters['poi'];
        if (pointJson is! Map) return;
        final point = ProjectRegionPointOfInterest.fromJson(
          Map<String, dynamic>.from(pointJson),
        );
        final ids = {
          ...point.mapIds,
          if (point.destination != null) point.destination!.mapId,
        };
        for (final id in ids) {
          final actual = maps.where((map) => map.id == id).toList();
          if (actual.length != 1 || actual.single != base.maps[id]) {
            throw const NarrativeCatalogFailure(
              'Une carte ou son arrivée a changé. Rechargez le catalogue avant de publier.',
            );
          }
        }
      },
    );
    return load();
  }
}
