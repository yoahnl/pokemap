import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_map_render_adapter.dart';

Future<void> main(List<String> arguments) async {
  try {
    final projectRoot = _parseRoot(arguments);
    final decoded = jsonDecode(await utf8.decoder.bind(stdin).join());
    if (decoded is! Map) throw const FormatException();
    final request = Map<String, dynamic>.from(decoded);
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
    const queries = MapRenderQueries(RuntimeAuthoringMapRenderAdapter());
    final mapId = _string(request['mapId'], 'mapId');
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
    stdout.write(
      jsonEncode({
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
      }),
    );
  } on FormatException {
    _writeFailure(
      'render.request_invalid',
      'The render request does not match the canonical contract.',
    );
    exitCode = 2;
  } on ArgumentError {
    _writeFailure(
      'render.request_invalid',
      'The render request does not match the canonical contract.',
    );
    exitCode = 2;
  } on ProjectSnapshotException catch (error) {
    _writeFailure(error.code, error.message);
    exitCode = 3;
  } on WorkspaceAccessException catch (error) {
    _writeFailure(error.code, error.message);
    exitCode = 3;
  } on Object {
    _writeFailure(
      'render.failed',
      'The revision-bound runtime render failed unexpectedly.',
    );
    exitCode = 3;
  }
}

String _parseRoot(List<String> arguments) {
  if (arguments.length != 2 || arguments.first != '--root') {
    throw const FormatException();
  }
  return _string(arguments[1], 'root');
}

void _expectKeys(Map<String, dynamic> value, Set<String> expected) {
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

void _writeFailure(String code, String message) {
  stdout.write(
    jsonEncode({
      'status': 'failure',
      'error': {'code': code, 'message': message},
    }),
  );
}
