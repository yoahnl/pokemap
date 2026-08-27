import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../infrastructure/runtime_tileset_image.dart';
import '../../infrastructure/tile_image_loader.dart';
import '../runtime_map_bundle.dart';
import 'runtime_authoring_asset_map_capture_service.dart';

typedef RuntimeAuthoringMapBundleLoader = Future<RuntimeMapBundle> Function(
  MapRenderRequest request,
);
typedef RuntimeAuthoringTilesetImageLoader
    = Future<Map<String, RuntimeTilesetImage>> Function(
  RuntimeMapBundle bundle,
);

final class RuntimeAuthoringAssetMapRenderAdapter implements MapRenderPort {
  RuntimeAuthoringAssetMapRenderAdapter({
    required RuntimeAuthoringMapBundleLoader bundleLoader,
    RuntimeAuthoringTilesetImageLoader? tilesetImageLoader,
    RuntimeAuthoringAssetMapCaptureService captureService =
        const RuntimeAuthoringAssetMapCaptureService(),
  })  : _bundleLoader = bundleLoader,
        _tilesetImageLoader = tilesetImageLoader ?? _loadTilesetImages,
        _captureService = captureService;

  final RuntimeAuthoringMapBundleLoader _bundleLoader;
  final RuntimeAuthoringTilesetImageLoader _tilesetImageLoader;
  final RuntimeAuthoringAssetMapCaptureService _captureService;

  @override
  Future<MapRenderResult> render(MapRenderRequest request) async {
    final loadedBundle = await _bundleLoader(request);
    if (loadedBundle.map != request.map) {
      throw const ProjectSnapshotException(
        'map.render_revision_mismatch',
        'The loaded runtime map does not match the requested revision.',
      );
    }
    final images = await _tilesetImageLoader(loadedBundle);
    try {
      final capture = await _captureService.capture(
        bundle: loadedBundle,
        tileImagesByTilesetId: images,
        region: request.region,
        layerIds: request.layerIds,
        overlays: request.overlays,
        cellPixelSize: request.cellPixelSize,
      );
      return MapRenderResult(
        mimeType: 'image/png',
        bytes: capture.bytes,
        width: capture.width,
        height: capture.height,
        sourceRevision: request.revision,
        region: request.region,
        layerIds: _selectedLayerIds(request),
        overlays: request.overlays,
        overlayCounts: capture.overlayCounts,
      );
    } finally {
      final unique = Set<RuntimeTilesetImage>.identity()..addAll(images.values);
      for (final image in unique) {
        image.dispose();
      }
    }
  }
}

Future<Map<String, RuntimeTilesetImage>> _loadTilesetImages(
  RuntimeMapBundle bundle,
) {
  return loadTilesetImagesById(
    bundle.tilesetAbsolutePathsById,
    transparentColorByTilesetId: <String, TilesetTransparentColor>{
      for (final tileset in bundle.manifest.tilesets)
        if (tileset.transparentColor != null)
          tileset.id: tileset.transparentColor!,
    },
  );
}

List<String> _selectedLayerIds(MapRenderRequest request) {
  final selected = request.layerIds.toSet();
  return [
    for (final layer in request.map.layers)
      if (selected.isEmpty ? layer.isVisible : selected.contains(layer.id))
        layer.id,
  ];
}
