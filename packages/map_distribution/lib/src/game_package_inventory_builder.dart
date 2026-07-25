import 'package:crypto/crypto.dart';

import 'content_tree_hasher.dart';
import 'game_package_format_exception.dart';
import 'game_package_manifest.dart';
import 'package_path_policy.dart';

typedef PackageMediaTypeResolver = String? Function(String path);

final class GamePackageInventoryBuildResult {
  GamePackageInventoryBuildResult({
    required this.content,
    required Map<String, List<int>> payloadSnapshot,
  }) : payloadSnapshot = Map.unmodifiable(payloadSnapshot);

  final GamePackageContent content;
  final Map<String, List<int>> payloadSnapshot;
}

/// Produces the complete payload inventory embedded in a package manifest.
final class GamePackageInventoryBuilder {
  const GamePackageInventoryBuilder({
    this.maxFileCount = 20000,
    this.maxFileBytes = 268435456,
    this.maxTotalBytes = 1073741824,
  });

  final int maxFileCount;
  final int maxFileBytes;
  final int maxTotalBytes;

  GamePackageContent build(
    Map<String, List<int>> payloadFiles, {
    PackageMediaTypeResolver? mediaTypeForPath,
  }) =>
      buildWithSnapshot(
        payloadFiles,
        mediaTypeForPath: mediaTypeForPath,
      ).content;

  GamePackageInventoryBuildResult buildWithSnapshot(
    Map<String, List<int>> payloadFiles, {
    PackageMediaTypeResolver? mediaTypeForPath,
  }) {
    final snapshot = Map<String, List<int>>.unmodifiable(
      payloadFiles.map(
        (path, bytes) => MapEntry(
          path,
          List<int>.unmodifiable(List<int>.from(bytes)),
        ),
      ),
    );
    if (snapshot.isEmpty || snapshot.length > maxFileCount) {
      _fail(
        'invalidFileCount',
        r'$.content.files',
        'Payload file count is outside policy.',
      );
    }
    final collisionKeys = <String>{};
    final entries = <GamePackageFileEntry>[];
    var totalBytes = 0;
    for (final entry in snapshot.entries) {
      PackagePathPolicy.validate(
        entry.key,
        errorPath: entry.key,
      );
      if (!collisionKeys.add(PackagePathPolicy.collisionKey(entry.key))) {
        _fail(
          'pathCollision',
          r'$.content.files',
          'Payload paths collide after normalization or case folding.',
        );
      }
      if (entry.value.any((byte) => byte < 0 || byte > 255)) {
        _fail(
          'invalidFileBytes',
          entry.key,
          'Payload values must be bytes.',
        );
      }
      if (entry.value.length > maxFileBytes) {
        _fail('fileTooLarge', entry.key, 'Payload file exceeds quota.');
      }
      final mediaType = mediaTypeForPath?.call(entry.key);
      if (mediaType != null && !_mediaType.hasMatch(mediaType)) {
        _fail(
          'invalidMediaType',
          entry.key,
          'Invalid inventory media type.',
        );
      }
      totalBytes += entry.value.length;
      if (totalBytes > maxTotalBytes) {
        _fail(
          'payloadTooLarge',
          r'$.content.totalBytes',
          'Payload exceeds total quota.',
        );
      }
      entries.add(
        GamePackageFileEntry(
          path: entry.key,
          size: entry.value.length,
          sha256: sha256.convert(entry.value).toString(),
          mediaType: mediaType,
        ),
      );
    }
    if (!snapshot.containsKey('project/project.json')) {
      _fail(
        'projectManifestMissing',
        r'$.content.files',
        'project/project.json is required.',
      );
    }
    if (totalBytes < 1) {
      _fail(
        'invalidTotalBytes',
        r'$.content.totalBytes',
        'Payload must contain at least one byte.',
      );
    }
    entries.sort(
      (left, right) => PackagePathPolicy.compareUtf8(left.path, right.path),
    );
    final content = GamePackageContent(
      fileCount: entries.length,
      totalBytes: totalBytes,
      treeSha256: ContentTreeHasher.sha256Hex(entries),
      files: entries,
    );
    return GamePackageInventoryBuildResult(
      content: content,
      payloadSnapshot: snapshot,
    );
  }

  Never _fail(String code, String path, String message) {
    throw GamePackageFormatException(
      code: code,
      path: path,
      message: message,
    );
  }

  static final RegExp _mediaType =
      RegExp(r'^[a-z0-9!#$&^_.+-]+/[a-z0-9!#$&^_.+-]+$');
}
