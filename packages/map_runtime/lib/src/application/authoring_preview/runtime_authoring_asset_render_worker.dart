import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../load_runtime_map_bundle.dart';
import 'runtime_authoring_asset_map_render_adapter.dart';

Future<Map<String, Object?>> renderRuntimeAuthoringAssetRequest({
  required String projectRoot,
  required Map<String, Object?> request,
}) async {
  try {
    _expectKeys(
      request,
      const {
        'mapId',
        'region',
        'layerIds',
        'overlays',
        'cellPixelSize',
      },
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [projectRoot],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final opened = await ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ).openProject(projectRoot);
    final snapshot = await ProjectSnapshotLoader(handles: handles).load(
      opened.projectHandle,
    );
    final mapId = _string(request['mapId'], 'mapId');
    final adapter = RuntimeAuthoringAssetMapRenderAdapter(
      bundleLoader: (_) => loadRuntimeMapBundle(
        projectFilePath: p.join(projectRoot, 'project.json'),
        mapId: mapId,
        preloadedManifest: snapshot.manifest,
      ),
    );
    final queries = MapRenderQueries(adapter);
    final layerIds = _strings(request['layerIds'], 'layerIds');
    final overlays = _overlays(request['overlays']);
    final cellPixelSize = _integer(
      request['cellPixelSize'] ?? 8,
      'cellPixelSize',
    );
    final region = _region(request['region']);
    final result = region == null
        ? await queries.renderMap(
            snapshot: snapshot,
            mapId: mapId,
            layerIds: layerIds,
            overlays: overlays,
            cellPixelSize: cellPixelSize,
          )
        : await queries.renderRegion(
            snapshot: snapshot,
            mapId: mapId,
            region: region,
            layerIds: layerIds,
            overlays: overlays,
            cellPixelSize: cellPixelSize,
          );
    final content = ContentArtifactRef.fromBytes(
      result.bytes,
      mediaType: result.mimeType,
    );
    return {
      'status': 'success',
      'data': result.toJson(),
      'artifact': {
        'id': 'render-$mapId',
        'mediaType': result.mimeType,
        'uri': content.handle,
        'byteLength': content.byteLength,
        'sha256': content.hexDigest,
      },
      'blob': base64Encode(result.bytes),
    };
  } on FormatException {
    return _failure(
      'render.request_invalid',
      'The render request does not match the canonical contract.',
    );
  } on ArgumentError {
    return _failure(
      'render.request_invalid',
      'The render request does not match the canonical contract.',
    );
  } on ProjectSnapshotException catch (error) {
    return _failure(error.code, error.message);
  } on WorkspaceAccessException catch (error) {
    return _failure(error.code, error.message);
  } on Object {
    return _failure(
      'render.failed',
      'The revision-bound asset render failed unexpectedly.',
    );
  }
}

void _expectKeys(Map<String, Object?> value, Set<String> expected) {
  if (value.keys.toSet().difference(expected).isNotEmpty) {
    throw const FormatException();
  }
}

String _string(Object? value, String field) {
  if (value is! String || value.trim().isEmpty || value != value.trim()) {
    throw FormatException('$field must be nonblank and trimmed');
  }
  return value;
}

int _integer(Object? value, String field) {
  if (value is! int) throw FormatException('$field must be an integer');
  return value;
}

List<String> _strings(Object? value, String field) {
  if (value == null) return const [];
  if (value is! List) throw FormatException('$field must be a list');
  return List<String>.unmodifiable(
    value.map((entry) => _string(entry, field)),
  );
}

List<MapRenderOverlay> _overlays(Object? value) {
  return _strings(value, 'overlays').map((name) {
    return MapRenderOverlay.values.firstWhere(
      (candidate) => candidate.name == name,
      orElse: () => throw const FormatException(),
    );
  }).toList(growable: false);
}

MapRect? _region(Object? value) {
  if (value == null) return null;
  if (value is! Map) throw const FormatException();
  final json = Map<String, dynamic>.from(value);
  if (json.keys
          .toSet()
          .difference(const {'x', 'y', 'width', 'height'}).isNotEmpty ||
      json.length != 4) {
    throw const FormatException();
  }
  return MapRect(
    pos: GridPos(
      x: _integer(json['x'], 'region.x'),
      y: _integer(json['y'], 'region.y'),
    ),
    size: GridSize(
      width: _integer(json['width'], 'region.width'),
      height: _integer(json['height'], 'region.height'),
    ),
  );
}

Map<String, Object?> _failure(String code, String message) => {
      'status': 'failure',
      'error': {'code': code, 'message': message},
    };
