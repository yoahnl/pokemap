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
  const ProjectBrandingImageImportService();

  static const Set<String> supportedExtensions = <String>{
    '.png',
    '.jpg',
    '.jpeg',
    '.webp',
  };

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
    final bytes = await sourceFile.readAsBytes();
    final decoded = image.decodeImage(bytes);
    if (decoded == null) {
      throw ProjectBrandingImageImportException(
        code: 'brandingImageCorrupt',
        path: sourceFile.path,
        message: 'The selected branding image could not be decoded.',
      );
    }

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
      sizeBytes: bytes.length,
    );
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
