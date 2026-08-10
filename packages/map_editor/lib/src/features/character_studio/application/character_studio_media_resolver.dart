import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

final class CharacterStudioMediaRequest {
  const CharacterStudioMediaRequest({
    required this.projectRootPath,
    required this.assetId,
    required this.projectRevision,
  });

  final String projectRootPath;
  final String assetId;
  final String projectRevision;

  CharacterStudioMediaRequest copyWith({String? projectRevision}) {
    return CharacterStudioMediaRequest(
      projectRootPath: projectRootPath,
      assetId: assetId,
      projectRevision: projectRevision ?? this.projectRevision,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CharacterStudioMediaRequest &&
        other.projectRootPath == projectRootPath &&
        other.assetId == assetId &&
        other.projectRevision == projectRevision;
  }

  @override
  int get hashCode => Object.hash(projectRootPath, assetId, projectRevision);
}

abstract interface class CharacterStudioMediaSource {
  Future<Uint8List> load(CharacterStudioMediaRequest request);
}

abstract interface class CharacterStudioMediaResolverContract {
  Future<Uint8List> resolve(CharacterStudioMediaRequest request);
}

final class CharacterStudioMediaResolver
    implements CharacterStudioMediaResolverContract {
  CharacterStudioMediaResolver({
    required CharacterStudioMediaSource source,
    this.maxEntries = 64,
  }) : _source = source {
    if (maxEntries <= 0) {
      throw ArgumentError.value(maxEntries, 'maxEntries', 'must be positive');
    }
  }

  final CharacterStudioMediaSource _source;
  final int maxEntries;
  final Map<CharacterStudioMediaRequest, Future<Uint8List>> _cache = {};

  @override
  Future<Uint8List> resolve(CharacterStudioMediaRequest request) {
    final cached = _cache.remove(request);
    if (cached != null) {
      _cache[request] = cached;
      return cached;
    }
    late final Future<Uint8List> pending;
    pending = Future<Uint8List>.sync(() => _source.load(request)).onError((
      error,
      stackTrace,
    ) {
      if (identical(_cache[request], pending)) _cache.remove(request);
      Error.throwWithStackTrace(
        error ?? StateError('Character Studio media failed to load'),
        stackTrace,
      );
    });
    _cache[request] = pending;
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
    return pending;
  }

  void invalidateProject(String projectRootPath) {
    _cache.removeWhere((request, _) {
      return request.projectRootPath == projectRootPath;
    });
  }
}

final class FileCharacterStudioMediaSource
    implements CharacterStudioMediaSource {
  const FileCharacterStudioMediaSource();

  @override
  Future<Uint8List> load(CharacterStudioMediaRequest request) async {
    final root = p.normalize(p.absolute(request.projectRootPath));
    final catalogFile = File(p.join(root, assetCatalogStorageKey));
    final decoded = jsonDecode(await catalogFile.readAsString());
    if (decoded is! Map) {
      throw const FormatException('Invalid Character Studio asset catalog');
    }
    final catalog = AssetCatalog.fromJson(Map<String, dynamic>.from(decoded));
    final asset = catalog.require(request.assetId);
    if (asset.artifact.mediaType != 'image/png') {
      throw const FormatException('Character Studio media must be PNG');
    }
    final blobPath = p.normalize(
      p.join(root, assetBlobStorageKey(asset.artifact)),
    );
    if (!p.isWithin(root, blobPath)) {
      throw const FileSystemException('Character Studio asset escaped project');
    }
    return File(blobPath).readAsBytes();
  }
}
