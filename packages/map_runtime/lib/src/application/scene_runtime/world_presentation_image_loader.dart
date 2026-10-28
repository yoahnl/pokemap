import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class WorldPresentationImageLoader {
  WorldPresentationImageLoader(this.projectRootDirectory);
  final String projectRootDirectory;
  Future<(ProjectMediaCatalog, AssetCatalog)>? _catalogs;

  Future<File> _confinedFile(String storageKey) async {
    final root = await Directory(projectRootDirectory).resolveSymbolicLinks();
    final file = File(p.join(root, storageKey));
    final resolved = await file.resolveSymbolicLinks();
    if (!p.isWithin(root, resolved)) {
      throw StateError('The presentation resource escapes its project.');
    }
    return File(resolved);
  }

  Future<List<int>> _read(String key, int limit) async {
    final file = await _confinedFile(key);
    if (await file.length() > limit) {
      throw StateError('The presentation resource exceeds its budget.');
    }
    return file.readAsBytes();
  }

  Future<(ProjectMediaCatalog, AssetCatalog)> _loadCatalogs() async => (
    decodeProjectMediaCatalogBytes(
      await _read(projectMediaCatalogStorageKey, 4 * 1024 * 1024),
    ),
    AssetCatalog.fromJson(
      Map<String, dynamic>.from(
        jsonDecode(
          utf8.decode(await _read(assetCatalogStorageKey, 16 * 1024 * 1024)),
        ) as Map,
      ),
    ),
  );

  Future<ProjectMediaCatalog> loadCatalog() async =>
      (await (_catalogs ??= _loadCatalogs())).$1;

  Future<Map<String, (String, String)>> loadAudioFiles(Iterable<String> ids) async {
    final selected = ids.toSet();
    if (selected.isEmpty) return const {};
    final (catalog, assets) = await (_catalogs ??= _loadCatalogs());
    final result = <String, (String, String)>{};
    for (final id in selected) {
      final media = catalog.find(id);
      final metadata = media?.technicalMetadata;
      final asset = media == null ? null : assets.find(media.sourceAssetId);
      if (media?.kind != ProjectMediaKind.audio || metadata == null ||
          !metadata.mediaType.startsWith('audio/') || asset == null) {
        throw StateError('The project sound $id is unavailable or is not audio.');
      }
      final file = await _confinedFile(assetBlobStorageKey(asset.artifact));
      if (await file.length() != metadata.sizeBytes) {
        throw StateError('The project sound $id has changed since its import.');
      }
      result[id] = (file.path, metadata.mediaType);
    }
    return Map.unmodifiable(result);
  }

  Future<ui.Image> load(String id) async {
    final (mediaCatalog, assets) = await (_catalogs ??= _loadCatalogs());
    final media = mediaCatalog.find(id);
    final metadata = media?.technicalMetadata;
    if (media == null ||
        media.kind != ProjectMediaKind.image ||
        metadata == null ||
        metadata.width == null ||
        metadata.height == null ||
        metadata.width! * metadata.height! > 16 * 1024 * 1024) {
      throw StateError(
        'The presentation image is unavailable or exceeds its pixel budget.',
      );
    }
    final asset = assets.find(media.sourceAssetId);
    if (asset == null) {
      throw StateError('The presentation image source is unavailable.');
    }
    final bytes = await _read(
      assetBlobStorageKey(asset.artifact),
      32 * 1024 * 1024,
    );
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
    try {
      if (codec.frameCount != 1) {
        throw StateError('World pictures require a static image.');
      }
      final image = (await codec.getNextFrame()).image;
      if (image.width * image.height > 16 * 1024 * 1024) {
        image.dispose();
        throw StateError('The decoded image exceeds its pixel budget.');
      }
      return image;
    } finally {
      codec.dispose();
    }
  }
}
