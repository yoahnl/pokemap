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
  CharacterStudioMediaResolver({required CharacterStudioMediaSource source})
    : _source = source;

  final CharacterStudioMediaSource _source;
  final Map<CharacterStudioMediaRequest, Future<Uint8List>> _cache = {};

  @override
  Future<Uint8List> resolve(CharacterStudioMediaRequest request) {
    return _cache.putIfAbsent(request, () => _source.load(request));
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
