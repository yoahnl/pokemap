import 'dart:io';

import 'package:map_distribution/map_distribution.dart';
import 'package:path/path.dart' as p;

enum PackageAssetResolutionCode {
  unsafeRoot,
  invalidPath,
  notInventoried,
  missing,
  symbolicLink,
  notRegularFile,
  escapedRoot,
}

final class PackageAssetResolutionException implements Exception {
  const PackageAssetResolutionException(this.code, this.message);

  final PackageAssetResolutionCode code;
  final String message;

  @override
  String toString() =>
      'PackageAssetResolutionException(${code.name}): $message';
}

/// Opaque package-relative reference safe to retain in player snapshots.
final class PackageAssetReference {
  const PackageAssetReference._(this.packagePath);

  final String packagePath;

  @override
  bool operator ==(Object other) =>
      other is PackageAssetReference && other.packagePath == packagePath;

  @override
  int get hashCode => packagePath.hashCode;
}

/// Resolves immutable installed content without trusting project paths.
///
/// Installation already validates hashes and collisions. Launch repeats the
/// path and symlink checks because local tampering may happen after install.
final class PackageAssetResolver {
  PackageAssetResolver._({
    required Directory versionRoot,
    required String canonicalRoot,
    required Set<String> inventoriedPaths,
  })  : _versionRoot = versionRoot,
        _canonicalRoot = canonicalRoot,
        _inventoriedPaths = Set<String>.unmodifiable(inventoriedPaths);

  final Directory _versionRoot;
  final String _canonicalRoot;
  final Set<String> _inventoriedPaths;

  static Future<PackageAssetResolver> create({
    required Directory versionRoot,
    required GamePackageManifest manifest,
  }) async {
    final absoluteRoot = Directory(p.normalize(versionRoot.absolute.path));
    final type = await FileSystemEntity.type(
      absoluteRoot.path,
      followLinks: false,
    );
    if (type != FileSystemEntityType.directory) {
      throw const PackageAssetResolutionException(
        PackageAssetResolutionCode.unsafeRoot,
        'The installed version root is not a regular directory.',
      );
    }
    late final String canonicalRoot;
    try {
      canonicalRoot = p.normalize(await absoluteRoot.resolveSymbolicLinks());
    } on FileSystemException {
      throw const PackageAssetResolutionException(
        PackageAssetResolutionCode.unsafeRoot,
        'The installed version root cannot be canonicalized.',
      );
    }
    return PackageAssetResolver._(
      versionRoot: absoluteRoot,
      canonicalRoot: canonicalRoot,
      inventoriedPaths:
          manifest.content.files.map((entry) => entry.path).toSet(),
    );
  }

  PackageAssetReference reference(String packagePath) {
    final normalized = _validatePackagePath(packagePath);
    if (!_inventoriedPaths.contains(normalized)) {
      throw const PackageAssetResolutionException(
        PackageAssetResolutionCode.notInventoried,
        'The requested asset is not present in the package inventory.',
      );
    }
    return PackageAssetReference._(normalized);
  }

  Future<File> resolveFile(String packagePath) =>
      resolveReference(reference(packagePath));

  Future<File> resolveReference(PackageAssetReference reference) async {
    final segments = reference.packagePath.split('/');
    var current = _versionRoot.path;
    for (var index = 0; index < segments.length; index++) {
      current = p.join(current, segments[index]);
      final type = await FileSystemEntity.type(current, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw const PackageAssetResolutionException(
          PackageAssetResolutionCode.symbolicLink,
          'Symbolic links are forbidden in installed game content.',
        );
      }
      final isLast = index == segments.length - 1;
      if (type == FileSystemEntityType.notFound) {
        throw const PackageAssetResolutionException(
          PackageAssetResolutionCode.missing,
          'The inventoried asset is missing from the installed version.',
        );
      }
      if (isLast && type != FileSystemEntityType.file) {
        throw const PackageAssetResolutionException(
          PackageAssetResolutionCode.notRegularFile,
          'The inventoried asset is not a regular file.',
        );
      }
      if (!isLast && type != FileSystemEntityType.directory) {
        throw const PackageAssetResolutionException(
          PackageAssetResolutionCode.notRegularFile,
          'An asset parent is not a regular directory.',
        );
      }
    }

    late final String canonicalTarget;
    try {
      canonicalTarget = p.normalize(
        await File(current).resolveSymbolicLinks(),
      );
    } on FileSystemException {
      throw const PackageAssetResolutionException(
        PackageAssetResolutionCode.missing,
        'The inventoried asset cannot be canonicalized.',
      );
    }
    if (!p.isWithin(_canonicalRoot, canonicalTarget)) {
      throw const PackageAssetResolutionException(
        PackageAssetResolutionCode.escapedRoot,
        'The inventoried asset resolves outside the installed version.',
      );
    }
    return File(canonicalTarget);
  }

  String _validatePackagePath(String value) {
    if (value.isEmpty ||
        value.contains('\u0000') ||
        value.contains('\\') ||
        p.posix.isAbsolute(value) ||
        p.windows.isAbsolute(value)) {
      throw const PackageAssetResolutionException(
        PackageAssetResolutionCode.invalidPath,
        'Package asset paths must be canonical relative POSIX paths.',
      );
    }
    final segments = value.split('/');
    if (segments.any(
      (segment) => segment.isEmpty || segment == '.' || segment == '..',
    )) {
      throw const PackageAssetResolutionException(
        PackageAssetResolutionCode.invalidPath,
        'Package asset paths contain an unsafe segment.',
      );
    }
    final normalized = p.posix.normalize(value);
    if (normalized != value) {
      throw const PackageAssetResolutionException(
        PackageAssetResolutionCode.invalidPath,
        'Package asset paths must already be canonical.',
      );
    }
    return normalized;
  }
}
