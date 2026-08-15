import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../../project_tree_digest.dart';

final class EvaluationProjectProjectionException extends StateError {
  EvaluationProjectProjectionException(this.code, String message)
    : super('$code: $message');

  final String code;
}

final class EvaluationProjectProjection {
  EvaluationProjectProjection({
    required this.projectRoot,
    required this.relativeProjectRoot,
    required this.projectTreeHash,
    required Future<void> Function() dispose,
  }) : _dispose = dispose;

  final Directory projectRoot;
  final String relativeProjectRoot;
  final String projectTreeHash;
  final Future<void> Function() _dispose;

  Future<void> dispose() => _dispose();
}

abstract interface class EvaluationProjectProjectionFactory {
  Future<EvaluationProjectProjection> create({
    required Directory repositoryRoot,
    required String projectId,
    required String runId,
  });
}

final class LocalEvaluationProjectProjectionFactory
    implements EvaluationProjectProjectionFactory {
  const LocalEvaluationProjectProjectionFactory({
    this.maxEntryCount = 20000,
    this.maxFileBytes = 256 * 1024 * 1024,
    this.maxTotalBytes = 1024 * 1024 * 1024,
  });

  final int maxEntryCount;
  final int maxFileBytes;
  final int maxTotalBytes;

  @override
  Future<EvaluationProjectProjection> create({
    required Directory repositoryRoot,
    required String projectId,
    required String runId,
  }) async {
    if (Platform.isWindows) {
      throw EvaluationProjectProjectionException(
        'playtest.projection_immutable_unavailable',
        'Certified playtest projections are unavailable on Windows.',
      );
    }
    final repositoryCanonical = Directory(
      await repositoryRoot.resolveSymbolicLinks(),
    );
    final sourceRoot = await _resolveSourceProject(
      repositoryCanonical,
      projectId,
    );
    Directory? projectionParent;
    try {
      projectionParent = await _createProjectionParent(
        repositoryCanonical,
        runId,
      );
      final projectedRoot = Directory(p.join(projectionParent.path, 'project'));
      await projectedRoot.create();
      final snapshot = await _capture(sourceRoot);
      await _materialize(projectedRoot, snapshot);
      final digest = const ProjectTreeDigest();
      final projectedHash = await digest.compute(projectedRoot);
      final sourceHash = await digest.compute(sourceRoot);
      if (projectedHash != sourceHash) {
        throw EvaluationProjectProjectionException(
          'playtest.revision_drift',
          'The project changed while its playtest projection was captured.',
        );
      }
      await _validatePokemonCatalog(projectedRoot);
      if (await digest.compute(projectedRoot) != projectedHash) {
        throw EvaluationProjectProjectionException(
          'playtest.revision_drift',
          'The playtest projection changed during validation.',
        );
      }
      await _chmod(<String>['-R', 'a-w', projectedRoot.path]);
      final retainedParent = projectionParent;
      return EvaluationProjectProjection(
        projectRoot: projectedRoot,
        relativeProjectRoot: p
            .relative(projectedRoot.path, from: repositoryCanonical.path)
            .split(p.separator)
            .join('/'),
        projectTreeHash: projectedHash,
        dispose: () => _removeProjection(retainedParent),
      );
    } catch (error) {
      if (projectionParent != null) {
        await _removeProjection(projectionParent);
      }
      rethrow;
    }
  }

  Future<Directory> _resolveSourceProject(
    Directory repositoryRoot,
    String projectId,
  ) async {
    final normalized = projectId.trim().split('\\').join('/');
    if (normalized.isEmpty ||
        p.posix.isAbsolute(normalized) ||
        p.posix.normalize(normalized) != normalized ||
        normalized.split('/').any((part) => part.isEmpty || part == '..')) {
      throw EvaluationProjectProjectionException(
        'playtest.project_path_invalid',
        'The scenario project id must be a canonical repository-relative path.',
      );
    }
    final source = Directory(
      p.joinAll(<String>[repositoryRoot.path, ...normalized.split('/')]),
    );
    if (!await source.exists()) {
      throw EvaluationProjectProjectionException(
        'playtest.project_missing',
        'The scenario project does not exist: $normalized.',
      );
    }
    final canonical = Directory(await source.resolveSymbolicLinks());
    if (!_isWithin(repositoryRoot.path, canonical.path)) {
      throw EvaluationProjectProjectionException(
        'playtest.project_path_unsafe',
        'The scenario project resolves outside the repository.',
      );
    }
    return canonical;
  }

  Future<Directory> _createProjectionParent(
    Directory repositoryRoot,
    String runId,
  ) async {
    var current = repositoryRoot;
    for (final segment in <String>[
      'examples',
      'playable_runtime_host',
      'build',
      'pokemap-eval',
      'input',
    ]) {
      final next = Directory(p.join(current.path, segment));
      if (!await next.exists()) {
        await next.create();
      }
      final type = await FileSystemEntity.type(next.path, followLinks: false);
      if (type != FileSystemEntityType.directory) {
        throw EvaluationProjectProjectionException(
          'playtest.projection_path_unsafe',
          'The projection destination contains a non-directory entry.',
        );
      }
      final canonical = Directory(await next.resolveSymbolicLinks());
      if (!_isWithin(repositoryRoot.path, canonical.path)) {
        throw EvaluationProjectProjectionException(
          'playtest.projection_path_unsafe',
          'The projection destination resolves outside the repository.',
        );
      }
      current = canonical;
    }
    final identity = sha256
        .convert(utf8.encode(runId))
        .toString()
        .substring(0, 24);
    final parent = Directory(p.join(current.path, identity));
    if (await parent.exists()) {
      throw EvaluationProjectProjectionException(
        'playtest.projection_identity_collision',
        'A playtest projection already exists for this run.',
      );
    }
    await parent.create();
    return parent;
  }

  Future<_ProjectSnapshot> _capture(Directory sourceRoot) async {
    final files = <_ProjectFileSnapshot>[];
    final directories = <String>[];
    var entryCount = 0;
    var totalBytes = 0;
    await for (final entity in sourceRoot.list(
      recursive: true,
      followLinks: false,
    )) {
      final relativePath = p
          .relative(entity.path, from: sourceRoot.path)
          .split(p.separator)
          .join('/');
      if (_isExcluded(relativePath)) continue;
      entryCount += 1;
      if (entryCount > maxEntryCount) {
        throw EvaluationProjectProjectionException(
          'playtest.projection_quota_exceeded',
          'The project contains too many entries.',
        );
      }
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw EvaluationProjectProjectionException(
          'playtest.projection_path_unsafe',
          'The project contains a symbolic link: $relativePath.',
        );
      }
      if (type == FileSystemEntityType.directory) {
        directories.add(relativePath);
        continue;
      }
      if (type != FileSystemEntityType.file) {
        throw EvaluationProjectProjectionException(
          'playtest.projection_path_unsafe',
          'The project contains an unsupported entry: $relativePath.',
        );
      }
      final file = File(entity.path);
      final before = await file.stat();
      if (before.size > maxFileBytes) {
        throw EvaluationProjectProjectionException(
          'playtest.projection_quota_exceeded',
          'A project file exceeds the projection quota: $relativePath.',
        );
      }
      final bytes = await file.readAsBytes();
      final after = await file.stat();
      if (before.size != after.size ||
          before.modified != after.modified ||
          before.changed != after.changed ||
          bytes.length != before.size) {
        throw EvaluationProjectProjectionException(
          'playtest.revision_drift',
          'A project file changed while it was captured: $relativePath.',
        );
      }
      totalBytes += bytes.length;
      if (totalBytes > maxTotalBytes) {
        throw EvaluationProjectProjectionException(
          'playtest.projection_quota_exceeded',
          'The project exceeds the total projection quota.',
        );
      }
      files.add(_ProjectFileSnapshot(relativePath, bytes));
    }
    files.sort(
      (left, right) => left.relativePath.compareTo(right.relativePath),
    );
    directories.sort();
    return _ProjectSnapshot(files, directories);
  }

  Future<void> _materialize(
    Directory projectRoot,
    _ProjectSnapshot snapshot,
  ) async {
    for (final relativePath in snapshot.directories) {
      await Directory(
        p.joinAll(<String>[projectRoot.path, ...relativePath.split('/')]),
      ).create(recursive: true);
    }
    for (final entry in snapshot.files) {
      final target = File(
        p.joinAll(<String>[projectRoot.path, ...entry.relativePath.split('/')]),
      );
      await target.parent.create(recursive: true);
      await target.writeAsBytes(entry.bytes, flush: true);
    }
  }

  Future<void> _validatePokemonCatalog(Directory projectRoot) async {
    final projectFile = File(p.join(projectRoot.path, 'project.json'));
    if (!await projectFile.exists()) {
      throw EvaluationProjectProjectionException(
        'pokemon.catalog_not_ready',
        'The projected project manifest is missing.',
      );
    }
    final decoded = jsonDecode(await projectFile.readAsString());
    if (decoded is! Map) {
      throw EvaluationProjectProjectionException(
        'pokemon.catalog_not_ready',
        'The projected project manifest is not a JSON object.',
      );
    }
    final manifest = ProjectManifest.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    final report = await const PokemonCatalogCoherenceLoader()
        .validateProjectFiles(
          reader: const LocalProjectFileReader(),
          projectRoot: projectRoot.path,
          manifest: manifest,
        );
    if (!report.canPlaytest) {
      final codes =
          report.diagnostics
              .where(
                (diagnostic) =>
                    diagnostic.severity ==
                    PokemonCatalogDiagnosticSeverity.error,
              )
              .map((diagnostic) => diagnostic.code)
              .toSet()
              .toList(growable: false)
            ..sort();
      throw EvaluationProjectProjectionException(
        'pokemon.catalog_not_ready',
        'The projected Pokemon catalog is not ready: ${codes.join(', ')}.',
      );
    }
  }

  Future<void> _removeProjection(Directory parent) async {
    if (!await parent.exists()) return;
    await _chmod(<String>['-R', 'u+w', parent.path], allowFailure: true);
    await parent.delete(recursive: true);
  }

  Future<void> _chmod(
    List<String> arguments, {
    bool allowFailure = false,
  }) async {
    final result = await Process.run('chmod', arguments);
    if (!allowFailure && result.exitCode != 0) {
      throw EvaluationProjectProjectionException(
        'playtest.projection_immutable_unavailable',
        'The playtest projection could not be made immutable.',
      );
    }
  }
}

final class _ProjectFileSnapshot {
  const _ProjectFileSnapshot(this.relativePath, this.bytes);

  final String relativePath;
  final List<int> bytes;
}

final class _ProjectSnapshot {
  const _ProjectSnapshot(this.files, this.directories);

  final List<_ProjectFileSnapshot> files;
  final List<String> directories;
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

bool _isWithin(String root, String candidate) {
  final relative = p.relative(candidate, from: root);
  return relative == '.' ||
      (!p.isAbsolute(relative) &&
          relative != '..' &&
          !relative.startsWith('..${p.separator}'));
}
