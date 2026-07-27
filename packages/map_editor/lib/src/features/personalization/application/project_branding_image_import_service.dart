import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as image;
import 'package:path/path.dart' as p;

enum ProjectBrandingImageRole { icon, cover, hero }

final class ProjectBrandingImageImportResult {
  const ProjectBrandingImageImportResult({
    required this.role,
    required this.relativePath,
    required this.width,
    required this.height,
    required this.sizeBytes,
  });

  final ProjectBrandingImageRole role;
  final String relativePath;
  final int width;
  final int height;
  final int sizeBytes;
}

final class ProjectBrandingImageImportException implements Exception {
  const ProjectBrandingImageImportException({
    required this.code,
    required this.message,
    this.path,
    this.cause,
  });

  final String code;
  final String message;
  final String? path;
  final Object? cause;

  @override
  String toString() => 'ProjectBrandingImageImportException($code): $message';
}

abstract interface class ProjectBrandingImageImporter {
  Future<ProjectBrandingImageImportResult> importIntoProject({
    required Directory projectRoot,
    required ProjectBrandingImageRole role,
    required File sourceFile,
  });
}

/// Validates and copies one project-owned branding image.
final class ProjectBrandingImageImportService
    implements ProjectBrandingImageImporter {
  const ProjectBrandingImageImportService({
    this.maxSizeBytes = 10 * 1024 * 1024,
  });

  static const Set<String> supportedExtensions = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  };
  static const int maxDimension = 4096;
  static const int minimumIconDimension = 64;
  static const int maximumIconDimension = 1024;
  static const int minimumCoverWidth = 640;
  static const int minimumCoverHeight = 360;
  static const int minimumHeroWidth = 256;
  static const int minimumHeroHeight = 128;

  final int maxSizeBytes;

  @override
  Future<ProjectBrandingImageImportResult> importIntoProject({
    required Directory projectRoot,
    required ProjectBrandingImageRole role,
    required File sourceFile,
  }) async {
    if (await FileSystemEntity.type(
          sourceFile.path,
          followLinks: false,
        ) !=
        FileSystemEntityType.file) {
      throw ProjectBrandingImageImportException(
        code: 'brandingImageMissing',
        path: sourceFile.path,
        message: 'Choose a regular branding image file.',
      );
    }
    final extension = p.extension(sourceFile.path).toLowerCase();
    if (!supportedExtensions.contains(extension)) {
      throw ProjectBrandingImageImportException(
        code: 'brandingImageFormatUnsupported',
        path: sourceFile.path,
        message: 'Branding images must use PNG, JPEG, or WebP.',
      );
    }
    final sizeBytes = await sourceFile.length();
    if (sizeBytes > maxSizeBytes) {
      throw ProjectBrandingImageImportException(
        code: 'brandingImageSizeExceeded',
        path: sourceFile.path,
        message: 'Branding images must not exceed 10 MiB.',
      );
    }
    final bytes = await sourceFile.readAsBytes();
    final decoded = image.decodeImage(bytes);
    if (decoded == null) {
      throw ProjectBrandingImageImportException(
        code: 'brandingImageCorrupt',
        path: sourceFile.path,
        message: 'The selected branding image could not be decoded.',
      );
    }
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      throw ProjectBrandingImageImportException(
        code: 'brandingImageDimensionsExceeded',
        path: sourceFile.path,
        message: 'Branding images must not exceed 4096 pixels per side.',
      );
    }
    _validateRoleDimensions(
      role: role,
      width: decoded.width,
      height: decoded.height,
      path: sourceFile.path,
    );

    final digest = sha256.convert(bytes).toString().substring(0, 16);
    final relativePath =
        'assets/presentation/branding/${role.name}-$digest$extension';
    await _persistAtomically(
      projectRoot: projectRoot,
      relativePath: relativePath,
      bytes: bytes,
      token: '${role.name}-$digest',
    );
    return ProjectBrandingImageImportResult(
      role: role,
      relativePath: relativePath,
      width: decoded.width,
      height: decoded.height,
      sizeBytes: sizeBytes,
    );
  }

  void _validateRoleDimensions({
    required ProjectBrandingImageRole role,
    required int width,
    required int height,
    required String path,
  }) {
    switch (role) {
      case ProjectBrandingImageRole.icon:
        if (width != height) {
          throw ProjectBrandingImageImportException(
            code: 'brandingIconMustBeSquare',
            path: path,
            message: 'The game icon must be square.',
          );
        }
        if (width < minimumIconDimension || width > maximumIconDimension) {
          throw ProjectBrandingImageImportException(
            code: 'brandingIconDimensionsUnsupported',
            path: path,
            message: 'The game icon must be between 64 and 1024 pixels.',
          );
        }
        break;
      case ProjectBrandingImageRole.cover:
        if (width < minimumCoverWidth || height < minimumCoverHeight) {
          throw ProjectBrandingImageImportException(
            code: 'brandingCoverDimensionsUnsupported',
            path: path,
            message: 'The library cover must be at least 640 × 360 pixels.',
          );
        }
        break;
      case ProjectBrandingImageRole.hero:
        if (width < minimumHeroWidth || height < minimumHeroHeight) {
          throw ProjectBrandingImageImportException(
            code: 'brandingHeroDimensionsUnsupported',
            path: path,
            message: 'The title hero must be at least 256 × 128 pixels.',
          );
        }
        break;
    }
  }

  Future<void> _persistAtomically({
    required Directory projectRoot,
    required String relativePath,
    required List<int> bytes,
    required String token,
  }) async {
    final destination = Directory(
      p.join(projectRoot.path, 'assets', 'presentation', 'branding'),
    );
    final staging = Directory(
      p.join(destination.path, '.branding-import-$token'),
    );
    final staged = File(p.join(staging.path, p.basename(relativePath)));
    final target = File(p.join(projectRoot.path, relativePath));
    try {
      await staging.create(recursive: true);
      await staged.writeAsBytes(bytes, flush: true);
      if (await target.exists()) {
        await staged.delete();
      } else {
        await staged.rename(target.path);
      }
    } on Object catch (error) {
      throw ProjectBrandingImageImportException(
        code: 'brandingImageWriteFailed',
        path: relativePath,
        message: 'The branding image could not be copied into the project.',
        cause: error,
      );
    } finally {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }
}
