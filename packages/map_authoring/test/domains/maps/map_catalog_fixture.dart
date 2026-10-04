import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

MapData catalogMap(String id, {int width = 6, int height = 5}) => MapData(
      id: id,
      name: id,
      size: GridSize(width: width, height: height),
      version: ProjectVersion.v8,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
            id: 'base', name: 'Base', cells: List.filled(width * height, 0)),
        MapLayer.collision(
            id: 'collision',
            name: 'Collision',
            collisions: List.filled(width * height, false)),
      ],
    );

ProjectSnapshot catalogSnapshot(
  List<MapData> maps, {
  ProjectManifest? project,
  List<ProjectSnapshotLoadDiagnostic> diagnostics = const [],
  Map<String, Object?> extraMapFields = const {},
}) {
  final manifest = project ??
      ProjectManifest(
        name: 'Catalog fixture',
        version: ProjectVersion.v8,
        maps: [
          for (final map in maps)
            ProjectMapEntry(
                id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
        ],
        tilesets: const [],
      );
  final bytes = {
    'project': utf8.encode(jsonEncode(manifest.toJson())),
    for (final map in maps)
      'map:${map.id}':
          utf8.encode(jsonEncode({...map.toJson(), ...extraMapFields})),
  };
  String fingerprint(String path, List<int> value) =>
      computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(relativePath: path, bytes: value),
      ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('fixture'),
    revision:
        fingerprint('project', bytes.values.expand((bytes) => bytes).toList()),
    manifest: manifest,
    maps: maps,
    resourceFingerprints: bytes.map((key, value) => MapEntry(
        key,
        fingerprint(
            key == 'project' ? 'project.json' : 'maps/${key.substring(4)}.json',
            value))),
    resourceBytes: bytes,
    loadDiagnostics: diagnostics,
  );
}

AuthoringPlanningContext catalogContext(ProjectSnapshot snapshot,
        String actionId, Map<String, Object?> parameters) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
          requestId: 'fixture',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: 'fixture',
          expectedRevision: snapshot.revision,
          idempotencyKey: 'fixture',
          parameters: parameters),
      planId: 'fixture',
      seed: 1,
    );
