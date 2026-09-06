import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import 'runtime_player_pause_data.dart';
import 'runtime_regional_map.dart';

final class RuntimeRegionalMapBuilder {
  const RuntimeRegionalMapBuilder();

  Future<RuntimePlayerPauseDetailSnapshot> build({
    required GameState gameState,
    required String projectRootDirectory,
    required String locale,
    ProjectRegionalMapCatalog? catalog,
    List<ProjectMapEntry> projectMaps = const [],
  }) async {
    final french = locale.toLowerCase().startsWith('fr');
    final assets = await _loadAssets(projectRootDirectory);
    final regions = <RuntimePlayerRegionSnapshot>[];
    if (catalog == null) {
      final locations = projectRuntimeMapLocations(
        maps: projectMaps,
        gameState: gameState,
      );
      if (locations.isNotEmpty) {
        regions.add(RuntimePlayerRegionSnapshot(
          id: 'project-locations',
          label: french ? 'Lieux' : 'Locations',
          points: [
            for (final location in locations)
              RuntimePlayerMapPointSnapshot(
                id: 'map.${location.mapId}',
                label: location.displayName.isNotEmpty
                    ? location.displayName
                    : french
                        ? 'Zone actuelle'
                        : 'Current area',
                status: _status(location.status),
              ),
          ],
        ));
      }
    } else {
      for (final region in projectRuntimeRegionalMap(
        catalog: catalog,
        gameState: gameState,
        locale: locale,
      )) {
        regions.add(RuntimePlayerRegionSnapshot(
          id: region.id,
          label: region.displayName,
          imageFilePath: await _resolveImage(
              region.imagePath, projectRootDirectory, assets),
          pixelArt: region.sampling == ProjectMenuImageSampling.pixelArt,
          points: [
            for (final point in region.points)
              RuntimePlayerMapPointSnapshot(
                id: point.id,
                label: point.displayName,
                status: _status(point.status),
                u: point.u,
                v: point.v,
                description: point.description,
                thumbnailFilePath: await _resolveImage(
                    point.thumbnailPath, projectRootDirectory, assets),
              ),
          ],
        ));
      }
    }
    return RuntimePlayerPauseDetailSnapshot(
      section: RuntimePlayerPauseSection.map,
      title: french ? 'Carte' : 'Map',
      regionalMap: RuntimePlayerRegionMapSnapshot(regions: regions),
      entries: [
        for (final region in regions)
          for (final point in region.points)
            RuntimePlayerDetailEntrySnapshot(
              id: point.id,
              title: point.label,
              subtitle: switch (point.status) {
                RuntimePlayerMapPointStatus.current =>
                  french ? 'Position actuelle' : 'Current location',
                RuntimePlayerMapPointStatus.discovered =>
                  french ? 'Lieu découvert' : 'Discovered location',
                RuntimePlayerMapPointStatus.unknown =>
                  french ? 'Lieu non découvert' : 'Undiscovered location',
              },
            ),
      ],
      emptyMessage: french
          ? 'Aucun lieu n’est disponible sur cette carte.'
          : 'No location is available on this map.',
    );
  }

  RuntimePlayerMapPointStatus _status(RuntimeMapLocationStatus status) =>
      switch (status) {
        RuntimeMapLocationStatus.current => RuntimePlayerMapPointStatus.current,
        RuntimeMapLocationStatus.discovered =>
          RuntimePlayerMapPointStatus.discovered,
        RuntimeMapLocationStatus.unknown => RuntimePlayerMapPointStatus.unknown,
      };

  Future<AssetCatalog?> _loadAssets(String root) async {
    try {
      final path = await _safePath(root, assetCatalogStorageKey);
      if (path == null) return null;
      final json = jsonDecode(await File(path).readAsString());
      return json is Map
          ? AssetCatalog.fromJson(Map<String, dynamic>.from(json))
          : null;
    } on Object {
      return null;
    }
  }

  Future<String?> _resolveImage(
      String? path, String root, AssetCatalog? assets) async {
    if (path == null) return null;
    final asset = assets?.findByLogicalPath(path);
    if (asset != null) {
      if (!const {'image/png', 'image/jpeg', 'image/webp', 'image/gif'}
          .contains(asset.artifact.mediaType)) {
        return null;
      }
      return _safePath(root, assetBlobStorageKey(asset.artifact));
    }
    return _safePath(root, path);
  }

  Future<String?> _safePath(String rootDirectory, String relative) async {
    if (relative.isEmpty ||
        relative.contains('\\') ||
        p.posix.isAbsolute(relative) ||
        p.windows.isAbsolute(relative) ||
        p.posix.split(relative).contains('..') ||
        Uri.tryParse(relative)?.hasScheme == true) {
      return null;
    }
    try {
      final root = await Directory(rootDirectory).resolveSymbolicLinks();
      final file = File(p.join(root, relative));
      if (!await file.exists()) return null;
      final resolved = await file.resolveSymbolicLinks();
      return p.isWithin(root, resolved) ? resolved : null;
    } on FileSystemException {
      return null;
    }
  }
}
