import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

final class ProjectTitleMusicImportResult {
  const ProjectTitleMusicImportResult({
    required this.relativePath,
    required this.sizeBytes,
  });

  final String relativePath;
  final int sizeBytes;
}

final class ProjectTitleMusicImportException implements Exception {
  const ProjectTitleMusicImportException({
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
  String toString() => 'ProjectTitleMusicImportException($code): $message';
}

abstract interface class ProjectTitleMusicImporter {
  Future<ProjectTitleMusicImportResult> importIntoProject({
    required Directory projectRoot,
    required File sourceFile,
  });
}

/// Validates and copies one project-owned title music file.
final class ProjectTitleMusicImportService
    implements ProjectTitleMusicImporter {
  const ProjectTitleMusicImportService({
    this.maxSizeBytes = 30 * 1024 * 1024,
  });

  static const Set<String> supportedExtensions = <String>{
    '.ogg',
    '.wav',
    '.mp3',
    '.flac',
    '.m4a',
  };

  final int maxSizeBytes;

  @override
  Future<ProjectTitleMusicImportResult> importIntoProject({
    required Directory projectRoot,
    required File sourceFile,
  }) async {
    if (await FileSystemEntity.type(
          sourceFile.path,
          followLinks: false,
        ) !=
        FileSystemEntityType.file) {
      throw ProjectTitleMusicImportException(
        code: 'titleMusicMissing',
        path: sourceFile.path,
        message: 'Choose a regular title music file.',
      );
    }
    final extension = p.extension(sourceFile.path).toLowerCase();
    if (!supportedExtensions.contains(extension)) {
      throw ProjectTitleMusicImportException(
        code: 'titleMusicFormatUnsupported',
        path: sourceFile.path,
        message: 'Title music must use OGG, WAV, MP3, FLAC, or M4A.',
      );
    }
    final sizeBytes = await sourceFile.length();
    if (sizeBytes > maxSizeBytes) {
      throw ProjectTitleMusicImportException(
        code: 'titleMusicSizeExceeded',
        path: sourceFile.path,
        message: 'Title music must not exceed 30 MiB.',
      );
    }
    final bytes = await sourceFile.readAsBytes();
    if (!_matchesSignature(extension, bytes)) {
      throw ProjectTitleMusicImportException(
        code: 'titleMusicSignatureInvalid',
        path: sourceFile.path,
        message: 'The title music signature does not match its extension.',
      );
    }

    final digest = sha256.convert(bytes).toString().substring(0, 16);
    final relativePath =
        'assets/presentation/branding/title-music-$digest$extension';
    await _persistAtomically(
      projectRoot: projectRoot,
      relativePath: relativePath,
      bytes: bytes,
      token: digest,
    );
    return ProjectTitleMusicImportResult(
      relativePath: relativePath,
      sizeBytes: sizeBytes,
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
      p.join(destination.path, '.title-music-import-$token'),
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
      throw ProjectTitleMusicImportException(
        code: 'titleMusicWriteFailed',
        path: relativePath,
        message: 'The title music could not be copied into the project.',
        cause: error,
      );
    } finally {
      if (await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }
}

bool _matchesSignature(String extension, List<int> bytes) {
  bool startsWith(List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index += 1) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }

  return switch (extension) {
    '.ogg' => startsWith(const <int>[0x4f, 0x67, 0x67, 0x53]),
    '.wav' => startsWith(const <int>[0x52, 0x49, 0x46, 0x46]) &&
        bytes.length >= 12 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x41 &&
        bytes[10] == 0x56 &&
        bytes[11] == 0x45,
    '.mp3' => startsWith(const <int>[0x49, 0x44, 0x33]) ||
        (bytes.length >= 2 && bytes[0] == 0xff && (bytes[1] & 0xe0) == 0xe0),
    '.flac' => startsWith(const <int>[0x66, 0x4c, 0x61, 0x43]),
    '.m4a' => bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70,
    _ => false,
  };
}
