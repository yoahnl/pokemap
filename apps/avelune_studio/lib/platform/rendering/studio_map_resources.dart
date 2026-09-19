import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:map_authoring/map_authoring.dart'
    show AssetCatalog, assetCatalogStorageKey;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/map_runtime_authoring.dart';
import 'package:path/path.dart' as p;

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/platform/rendering/studio_map_visual_widgets.dart';

final class StudioMapResources implements MapWorkspaceVisuals {
  StudioMapResources._(this.projectRoot, this.manifest);

  final String projectRoot;
  final ProjectManifest manifest;
  final Map<String, RuntimeTilesetImage> images = {};
  final Map<String, String> paths = {};
  final List<String> _warnings = [];
  bool _disposed = false;
  int decodedBytes = 0;

  static Future<StudioMapResources> load(
    ProjectSession session,
    ProjectManifest manifest, {
    int maximumBytes = 256 * 1024 * 1024,
    int maximumImages = 128,
  }) async {
    final result = StudioMapResources._(session.directoryPath, manifest);
    const reader = LocalProjectFileReader();
    AssetCatalog? catalog;
    try {
      final probe = await reader.probeResource(
        projectRoot: session.directoryPath,
        relativePath: assetCatalogStorageKey,
      );
      if (probe.status == ProjectResourceProbeStatus.exists) {
        catalog = AssetCatalog.fromJson(
          jsonDecode(
                utf8.decode(
                  await reader.readBytes(
                    projectRoot: session.directoryPath,
                    relativePath: assetCatalogStorageKey,
                  ),
                ),
              )
              as Map<String, dynamic>,
        );
      } else if (probe.status != ProjectResourceProbeStatus.missing) {
        throw StateError('Catalogue inaccessible');
      }
    } on Object {
      result._warnings.add('Le catalogue de ressources est inaccessible.');
    }
    for (final tileset in manifest.tilesets) {
      try {
        if (tileset.relativePath != tileset.relativePath.trim()) {
          throw StateError('Chemin non préservé');
        }
        final paths = resolveTilesetAbsolutePaths(
          manifest: manifest,
          projectRoot: session.directoryPath,
          tilesetIds: {tileset.id},
          assetCatalog: catalog,
        );
        for (final path in paths.entries) {
          if (result.images.containsKey(path.key)) continue;
          if (result.images.length >= maximumImages) {
            throw StateError('Limite de ressources');
          }
          final relativePath = p.relative(
            path.value,
            from: session.directoryPath,
          );
          if (relativePath != relativePath.trim()) {
            throw StateError('Chemin non préservé');
          }
          final probe = await reader.probeResource(
            projectRoot: session.directoryPath,
            relativePath: relativePath,
          );
          if (probe.status != ProjectResourceProbeStatus.exists ||
              probe.identity!.byteLength > maximumBytes) {
            throw StateError('Ressource inaccessible ou trop grande');
          }
          final bytes = Uint8List.fromList(
            await reader.readBytes(
              projectRoot: session.directoryPath,
              relativePath: relativePath,
            ),
          );
          final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
          late final int imageBytes;
          try {
            final descriptor = await ui.ImageDescriptor.encoded(buffer);
            imageBytes = descriptor.width * descriptor.height * 4;
            descriptor.dispose();
          } finally {
            buffer.dispose();
          }
          if (result.decodedBytes + imageBytes > maximumBytes) {
            throw StateError('Budget de ressources atteint');
          }
          result.images[path.key] = await decodeRuntimeTilesetImage(
            bytes,
            transparentColor: tileset.transparentColor,
          );
          result.paths[path.key] = path.value;
          result.decodedBytes += imageBytes;
        }
      } on Object {
        result._warnings.add(
          '${tileset.name} : ressource indisponible ou budget atteint.',
        );
      }
    }
    return result;
  }

  RuntimeAuthoringMapRenderer renderer(MapData map) {
    if (_disposed) throw StateError('Ressources fermées');
    return RuntimeAuthoringMapRenderer(
      bundle: RuntimeMapBundle(
        manifest: manifest,
        map: map,
        projectRootDirectory: projectRoot,
        tilesetAbsolutePathsById: paths,
      ),
      images: images,
    );
  }

  @override
  List<String> get warnings => List.unmodifiable(_warnings);

  @override
  Widget canvas(MapData map) => StudioMapVisual(map: map, resources: this);

  @override
  Widget thumbnail(ProjectElementEntry element, {double size = 48}) =>
      StudioMapThumbnail(element: element, resources: this, size: size);

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final image in images.values.toSet()) {
      image.dispose();
    }
    images.clear();
    paths.clear();
    decodedBytes = 0;
  }
}
