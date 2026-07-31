import 'package:map_core/map_core.dart';

import '../contracts/resource_ref.dart';
import '../workspace/project_snapshot.dart';

enum MapRenderOverlay {
  collision,
  zones,
  warps,
  entities,
}

/// Immutable, path-free request for a revision-bound map preview.
final class MapRenderRequest {
  MapRenderRequest({
    required this.mapResource,
    required this.manifest,
    required this.map,
    MapRect? region,
    Iterable<String> layerIds = const [],
    Iterable<MapRenderOverlay> overlays = const [],
    this.cellPixelSize = 8,
  })  : region = region ??
            MapRect(
              pos: const GridPos(x: 0, y: 0),
              size: map.size,
            ),
        layerIds = _validatedLayerIds(map, layerIds),
        overlays = _sortedOverlays(overlays) {
    if (mapResource.kind != 'map' || mapResource.id != map.id) {
      throw ArgumentError.value(
        mapResource.toJson(),
        'mapResource',
        'must identify the supplied map',
      );
    }
    final revision = mapResource.revision;
    if (revision == null ||
        !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(revision)) {
      throw ArgumentError.value(
        revision,
        'mapResource.revision',
        'must bind the render to a lowercase SHA-256 revision',
      );
    }
    if (!manifest.maps.any((entry) => entry.id == map.id)) {
      throw ArgumentError.value(
        map.id,
        'map',
        'must be owned by the supplied project manifest',
      );
    }
    _validateRegion(map, this.region);
    if (cellPixelSize < 1 || cellPixelSize > 64) {
      throw ArgumentError.value(
        cellPixelSize,
        'cellPixelSize',
        'must be between 1 and 64',
      );
    }
  }

  final AuthoringResourceRef mapResource;
  final ProjectManifest manifest;
  final MapData map;
  final MapRect region;
  final List<String> layerIds;
  final List<MapRenderOverlay> overlays;
  final int cellPixelSize;

  String get revision => mapResource.revision!;

  Map<String, Object?> toJson() => {
        'map': mapResource.toJson(),
        'region': _rectJson(region),
        'layerIds': layerIds,
        'overlays': [for (final overlay in overlays) overlay.name],
        'cellPixelSize': cellPixelSize,
      };
}

/// Rendered artifact whose source revision and visible scope are explicit.
final class MapRenderResult {
  MapRenderResult({
    required String mimeType,
    required Iterable<int> bytes,
    required this.width,
    required this.height,
    required String sourceRevision,
    required this.region,
    required Iterable<String> layerIds,
    required Iterable<MapRenderOverlay> overlays,
    Map<MapRenderOverlay, int> overlayCounts = const {},
  })  : mimeType = _nonBlank(mimeType, 'mimeType'),
        bytes = List<int>.unmodifiable(bytes),
        sourceRevision = _revision(sourceRevision),
        layerIds = List<String>.unmodifiable(layerIds),
        overlays = List<MapRenderOverlay>.unmodifiable(overlays),
        overlayCounts = Map.unmodifiable(overlayCounts) {
    if (!this.mimeType.startsWith('image/')) {
      throw ArgumentError.value(
        mimeType,
        'mimeType',
        'must describe an image artifact',
      );
    }
    if (this.bytes.isEmpty ||
        this.bytes.any((value) => value < 0 || value > 255)) {
      throw ArgumentError.value(bytes, 'bytes', 'must be nonempty bytes');
    }
    if (width < 1 || height < 1) {
      throw ArgumentError.value(
        '$width x $height',
        'dimensions',
        'must be positive',
      );
    }
    if (overlayCounts.values.any((value) => value < 0)) {
      throw ArgumentError.value(
        overlayCounts,
        'overlayCounts',
        'counts must not be negative',
      );
    }
  }

  final String mimeType;
  final List<int> bytes;
  final int width;
  final int height;
  final String sourceRevision;
  final MapRect region;
  final List<String> layerIds;
  final List<MapRenderOverlay> overlays;
  final Map<MapRenderOverlay, int> overlayCounts;

  Map<String, Object?> toJson() => {
        'mimeType': mimeType,
        'byteLength': bytes.length,
        'width': width,
        'height': height,
        'sourceRevision': sourceRevision,
        'region': _rectJson(region),
        'layerIds': layerIds,
        'overlays': [for (final overlay in overlays) overlay.name],
        'overlayCounts': {
          for (final entry in overlayCounts.entries)
            entry.key.name: entry.value,
        },
      };
}

abstract interface class MapRenderPort {
  Future<MapRenderResult> render(MapRenderRequest request);
}

/// Snapshot adapter for `map.render` and `map.render_region` query handlers.
final class MapRenderQueries {
  const MapRenderQueries(this._port);

  final MapRenderPort _port;

  Future<MapRenderResult> renderMap({
    required ProjectSnapshot snapshot,
    required String mapId,
    Iterable<String> layerIds = const [],
    Iterable<MapRenderOverlay> overlays = const [],
    int cellPixelSize = 8,
  }) =>
      _render(
        snapshot: snapshot,
        mapId: mapId,
        layerIds: layerIds,
        overlays: overlays,
        cellPixelSize: cellPixelSize,
      );

  Future<MapRenderResult> renderRegion({
    required ProjectSnapshot snapshot,
    required String mapId,
    required MapRect region,
    Iterable<String> layerIds = const [],
    Iterable<MapRenderOverlay> overlays = const [],
    int cellPixelSize = 8,
  }) =>
      _render(
        snapshot: snapshot,
        mapId: mapId,
        region: region,
        layerIds: layerIds,
        overlays: overlays,
        cellPixelSize: cellPixelSize,
      );

  Future<MapRenderResult> _render({
    required ProjectSnapshot snapshot,
    required String mapId,
    required Iterable<String> layerIds,
    required Iterable<MapRenderOverlay> overlays,
    required int cellPixelSize,
    MapRect? region,
  }) {
    final map = snapshot.mapById(mapId);
    final revision = snapshot.resourceFingerprints['map:$mapId'];
    if (map == null || revision == null) {
      throw ProjectSnapshotException(
        'map.render_source_missing',
        'The requested revision-bound map cannot be rendered.',
      );
    }
    final request = MapRenderRequest(
      mapResource: AuthoringResourceRef(
        kind: 'map',
        id: map.id,
        revision: revision,
      ),
      manifest: snapshot.manifest,
      map: map,
      region: region,
      layerIds: layerIds,
      overlays: overlays,
      cellPixelSize: cellPixelSize,
    );
    return _checkedRender(request);
  }

  Future<MapRenderResult> _checkedRender(MapRenderRequest request) async {
    final result = await _port.render(request);
    if (result.sourceRevision != request.revision) {
      throw const ProjectSnapshotException(
        'map.render_revision_mismatch',
        'The render result does not match the requested map revision.',
      );
    }
    if (result.region != request.region ||
        result.width != request.region.size.width * request.cellPixelSize ||
        result.height != request.region.size.height * request.cellPixelSize) {
      throw const ProjectSnapshotException(
        'map.render_scope_mismatch',
        'The render result does not match the requested map scope.',
      );
    }
    return result;
  }
}

List<String> _validatedLayerIds(MapData map, Iterable<String> values) {
  final known = {for (final layer in map.layers) layer.id};
  final result = <String>{};
  for (final value in values) {
    final normalized = _nonBlank(value, 'layerId');
    if (!known.contains(normalized)) {
      throw ArgumentError.value(
        value,
        'layerIds',
        'must identify a layer on the supplied map',
      );
    }
    result.add(normalized);
  }
  return List.unmodifiable(result.toList()..sort());
}

List<MapRenderOverlay> _sortedOverlays(Iterable<MapRenderOverlay> values) {
  final result = values.toSet().toList()
    ..sort((left, right) => left.name.compareTo(right.name));
  return List.unmodifiable(result);
}

void _validateRegion(MapData map, MapRect region) {
  final right = region.pos.x + region.size.width;
  final bottom = region.pos.y + region.size.height;
  if (region.size.width < 1 ||
      region.size.height < 1 ||
      region.pos.x < 0 ||
      region.pos.y < 0 ||
      right > map.size.width ||
      bottom > map.size.height) {
    throw ArgumentError.value(
      _rectJson(region),
      'region',
      'must be a positive rectangle inside the supplied map',
    );
  }
}

Map<String, Object?> _rectJson(MapRect value) => {
      'x': value.pos.x,
      'y': value.pos.y,
      'width': value.size.width,
      'height': value.size.height,
    };

String _nonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized != value) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return normalized;
}

String _revision(String value) {
  final normalized = _nonBlank(value, 'sourceRevision');
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'sourceRevision',
      'must be a lowercase SHA-256 revision',
    );
  }
  return normalized;
}
