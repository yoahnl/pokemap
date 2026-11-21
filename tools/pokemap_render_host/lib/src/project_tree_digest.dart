import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Deterministic digest of the complete project tree used by the runtime.
///
/// Every included file is represented by its normalized relative path, byte
/// length and own SHA-256. Runtime saves, build output and machine-local caches
/// are excluded so executing the project does not invalidate its product hash.
final class ProjectTreeDigest {
  const ProjectTreeDigest();

  Future<String> compute(Directory projectRoot) async {
    if (!await projectRoot.exists()) {
      throw ArgumentError.value(
        projectRoot.path,
        'projectRoot',
        'does not exist',
      );
    }
    final files = <({File file, String relativePath})>[];
    await for (final entity
        in projectRoot.list(recursive: true, followLinks: false)) {
      final relativePath = p
          .relative(entity.path, from: projectRoot.path)
          .split(p.separator)
          .join('/');
      if (_isExcluded(relativePath)) continue;
      if (entity is Link) {
        throw StateError(
          'Project tree hashing refuses symbolic links: $relativePath',
        );
      }
      if (entity is File) {
        files.add((file: entity, relativePath: relativePath));
      }
    }
    files
        .sort((left, right) => left.relativePath.compareTo(right.relativePath));

    final canonical = StringBuffer('pokemap-project-tree-v1\n');
    for (final entry in files) {
      final length = await entry.file.length();
      final fileDigest = await sha256.bind(entry.file.openRead()).first;
      canonical
        ..write(entry.relativePath)
        ..write('\u0000')
        ..write(length)
        ..write('\u0000')
        ..write(fileDigest)
        ..write('\n');
    }
    return sha256.convert(utf8.encode(canonical.toString())).toString();
  }
}

bool _isExcluded(String relativePath) {
  final parts = relativePath.split('/');
  if (parts.any(
    (part) =>
        part == '.git' ||
        part == '.dart_tool' ||
        part == '.pokemap' ||
        part == 'build' ||
        part == 'saves',
  )) {
    return true;
  }
  final name = parts.last;
  return name == '.DS_Store' ||
      (name.startsWith('.pokemap-project-') && name.endsWith('.lock'));
}
