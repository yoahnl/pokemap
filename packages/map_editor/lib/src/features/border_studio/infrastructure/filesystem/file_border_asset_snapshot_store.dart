import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../../application/border_asset_snapshot_service.dart';
import '../../application/ports/border_asset_snapshot_store.dart';

typedef BorderSnapshotStoreOperationHook = FutureOr<void> Function(
  BorderSnapshotStoreOperation operation,
  String relativePath,
);

/// Project-local store for immutable, content-addressed Border snapshots.
///
/// Staging is all-or-nothing. Final files are never deleted or overwritten:
/// identical content is reused, while different content at the same path is
/// reported as corruption.
final class FileBorderAssetSnapshotStore implements BorderAssetSnapshotStore {
  FileBorderAssetSnapshotStore({
    required String projectRootPath,
    String Function()? stageIdFactory,
    this.beforeOperation,
  })  : _projectRootPath = p.normalize(p.absolute(projectRootPath)),
        _stageIdFactory = stageIdFactory ?? _defaultStageId;

  final String _projectRootPath;
  final String Function() _stageIdFactory;
  final BorderSnapshotStoreOperationHook? beforeOperation;

  @override
  Future<BorderAssetSnapshotStage> stage(
    List<BorderSnapshotFilePayload> files,
  ) async {
    await _validateProjectRoot();
    final id = _stageIdFactory();
    if (!_isSafeStageId(id)) {
      throw const BorderAssetSnapshotStoreException(
        code: BorderAssetSnapshotStoreErrorCode.invalidStage,
        userMessage: 'L’identifiant temporaire du snapshot est invalide.',
      );
    }
    final stage = BorderAssetSnapshotStage(
      id: id,
      files: <BorderStagedSnapshotFile>[
        for (final file in files)
          BorderStagedSnapshotFile(
            relativePath: file.relativePath,
            contentSha256: file.contentSha256,
          ),
      ],
    );
    _validateStage(stage);
    final stageDirectory = Directory(_resolveStageDirectory(stage));
    if (await stageDirectory.exists()) {
      throw BorderAssetSnapshotStoreException(
        code: BorderAssetSnapshotStoreErrorCode.invalidStage,
        userMessage:
            'Un espace temporaire portant cet identifiant existe déjà.',
        relativePath: stage.stagingRelativeDirectory,
      );
    }

    try {
      await stageDirectory.create(recursive: true);
      await _rejectLinkedManagedPath(stageDirectory.path);
      for (var index = 0; index < files.length; index += 1) {
        final payload = files[index];
        final staged = stage.files[index];
        await Future<void>.sync(
          () => beforeOperation?.call(
            BorderSnapshotStoreOperation.stageWrite,
            staged.relativePath,
          ),
        );
        final destination = File(_resolveStagedFile(stage, staged));
        await destination.parent.create(recursive: true);
        await _rejectLinkedManagedPath(destination.parent.path);
        final partial = File('${destination.path}.partial');
        await partial.writeAsBytes(payload.bytes, flush: true);
        final actualHash =
            sha256.convert(await partial.readAsBytes()).toString();
        if (actualHash != staged.contentSha256) {
          throw BorderAssetSnapshotStoreException(
            code: BorderAssetSnapshotStoreErrorCode.stagedHashMismatch,
            userMessage:
                'Le fichier temporaire ne correspond pas au contenu analysé.',
            relativePath: staged.relativePath,
          );
        }
        await partial.rename(destination.path);
      }
      return stage;
    } catch (_) {
      if (await stageDirectory.exists()) {
        await stageDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  @override
  Future<BorderAssetSnapshotFinalizeResult> finalize(
    BorderAssetSnapshotStage stage,
  ) async {
    await _validateProjectRoot();
    _validateStage(stage);
    final stageDirectory = Directory(_resolveStageDirectory(stage));
    await _rejectLinkedManagedPath(stageDirectory.path);

    final created = <String>[];
    final deduplicated = <String>[];
    for (final staged in stage.files) {
      final stagedFile = File(_resolveStagedFile(stage, staged));
      final finalFile = File(_resolveProjectRelative(staged.relativePath));
      await _rejectLinkedManagedPath(finalFile.parent.path);
      // The final path itself may already be a link even when every parent is
      // safe. Treating matching target bytes as a deduplicated snapshot would
      // otherwise let a managed project path escape the project root.
      await _rejectLinkedManagedPath(finalFile.path);
      if (!await stagedFile.exists()) {
        if (await finalFile.exists()) {
          final existingHash =
              sha256.convert(await finalFile.readAsBytes()).toString();
          if (existingHash == staged.contentSha256) {
            deduplicated.add(staged.relativePath);
            continue;
          }
          throw BorderAssetSnapshotStoreException(
            code: BorderAssetSnapshotStoreErrorCode.corruptedExistingSnapshot,
            userMessage:
                'Un snapshot existant porte le bon chemin mais un contenu différent.',
            relativePath: staged.relativePath,
          );
        }
        throw BorderAssetSnapshotStoreException(
          code: BorderAssetSnapshotStoreErrorCode.missingStagedFile,
          userMessage: 'Un fichier temporaire de publication est manquant.',
          relativePath: staged.relativePath,
        );
      }
      final stagedHash =
          sha256.convert(await stagedFile.readAsBytes()).toString();
      if (stagedHash != staged.contentSha256) {
        throw BorderAssetSnapshotStoreException(
          code: BorderAssetSnapshotStoreErrorCode.stagedHashMismatch,
          userMessage: 'Un fichier temporaire a été modifié avant publication.',
          relativePath: staged.relativePath,
        );
      }

      if (await finalFile.exists()) {
        final existingHash =
            sha256.convert(await finalFile.readAsBytes()).toString();
        if (existingHash != staged.contentSha256) {
          throw BorderAssetSnapshotStoreException(
            code: BorderAssetSnapshotStoreErrorCode.corruptedExistingSnapshot,
            userMessage:
                'Un snapshot existant porte le bon chemin mais un contenu différent.',
            relativePath: staged.relativePath,
          );
        }
        deduplicated.add(staged.relativePath);
        await stagedFile.delete();
        continue;
      }

      await Future<void>.sync(
        () => beforeOperation?.call(
          BorderSnapshotStoreOperation.finalizeMove,
          staged.relativePath,
        ),
      );
      await finalFile.parent.create(recursive: true);
      await _rejectLinkedManagedPath(finalFile.parent.path);
      try {
        await stagedFile.rename(finalFile.path);
      } on FileSystemException catch (error) {
        if (await finalFile.exists()) {
          final existingHash =
              sha256.convert(await finalFile.readAsBytes()).toString();
          if (existingHash == staged.contentSha256) {
            deduplicated.add(staged.relativePath);
            if (await stagedFile.exists()) await stagedFile.delete();
            continue;
          }
        }
        throw BorderAssetSnapshotStoreException(
          code: BorderAssetSnapshotStoreErrorCode.ioFailure,
          userMessage: 'Le snapshot n’a pas pu être finalisé sur le disque.',
          relativePath: staged.relativePath,
          cause: error,
        );
      }
      created.add(staged.relativePath);
    }

    if (await stageDirectory.exists()) {
      await stageDirectory.delete(recursive: true);
    }
    return BorderAssetSnapshotFinalizeResult(
      createdRelativePaths: created,
      deduplicatedRelativePaths: deduplicated,
    );
  }

  @override
  Future<void> discard(BorderAssetSnapshotStage stage) async {
    await _validateProjectRoot();
    _validateStage(stage);
    final stageDirectory = Directory(_resolveStageDirectory(stage));
    await _rejectLinkedManagedPath(stageDirectory.path);
    if (await stageDirectory.exists()) {
      await stageDirectory.delete(recursive: true);
    }
  }

  String _resolveStageDirectory(BorderAssetSnapshotStage stage) =>
      _resolveProjectRelative(stage.stagingRelativeDirectory);

  String _resolveStagedFile(
    BorderAssetSnapshotStage stage,
    BorderStagedSnapshotFile file,
  ) {
    final stageRoot = _resolveStageDirectory(stage);
    final candidate = p.normalize(
      p.joinAll(<String>[stageRoot, ...p.posix.split(file.relativePath)]),
    );
    if (!p.isWithin(stageRoot, candidate)) {
      throw BorderAssetSnapshotStoreException(
        code: BorderAssetSnapshotStoreErrorCode.invalidStage,
        userMessage: 'Un chemin temporaire sort du projet.',
        relativePath: file.relativePath,
      );
    }
    return candidate;
  }

  String _resolveProjectRelative(String relativePath) {
    if (!_isSafeProjectRelativePath(relativePath)) {
      throw BorderAssetSnapshotStoreException(
        code: BorderAssetSnapshotStoreErrorCode.invalidStage,
        userMessage: 'Un chemin de snapshot sort du projet.',
        relativePath: relativePath,
      );
    }
    final candidate = p.normalize(
      p.joinAll(<String>[
        _projectRootPath,
        ...p.posix.split(relativePath),
      ]),
    );
    if (!p.isWithin(_projectRootPath, candidate)) {
      throw BorderAssetSnapshotStoreException(
        code: BorderAssetSnapshotStoreErrorCode.invalidStage,
        userMessage: 'Un chemin de snapshot sort du projet.',
        relativePath: relativePath,
      );
    }
    return candidate;
  }

  void _validateStage(BorderAssetSnapshotStage stage) {
    if (!_isSafeStageId(stage.id) ||
        stage.stagingRelativeDirectory !=
            'assets/borders/.staging/${stage.id}') {
      throw const BorderAssetSnapshotStoreException(
        code: BorderAssetSnapshotStoreErrorCode.invalidStage,
        userMessage: 'La publication temporaire est invalide.',
      );
    }
    final seen = <String>{};
    for (final file in stage.files) {
      if (!seen.add(file.relativePath)) {
        throw BorderAssetSnapshotStoreException(
          code: BorderAssetSnapshotStoreErrorCode.duplicateRelativePath,
          userMessage: 'Le même fichier snapshot est présent plusieurs fois.',
          relativePath: file.relativePath,
        );
      }
      if (!_isSafeSnapshotRelativePath(file.relativePath) ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(file.contentSha256)) {
        throw BorderAssetSnapshotStoreException(
          code: BorderAssetSnapshotStoreErrorCode.invalidStage,
          userMessage:
              'Un fichier temporaire possède des métadonnées invalides.',
          relativePath: file.relativePath,
        );
      }
    }
  }

  Future<void> _validateProjectRoot() async {
    if (await File(_projectRootPath).exists()) {
      throw const BorderAssetSnapshotStoreException(
        code: BorderAssetSnapshotStoreErrorCode.invalidProjectRoot,
        userMessage: 'Le dossier du projet est invalide.',
      );
    }
    final root = Directory(_projectRootPath);
    if (!await root.exists()) {
      try {
        await root.create(recursive: true);
      } on FileSystemException catch (error) {
        throw BorderAssetSnapshotStoreException(
          code: BorderAssetSnapshotStoreErrorCode.invalidProjectRoot,
          userMessage: 'Le dossier du projet ne peut pas être créé.',
          cause: error,
        );
      }
    }
    await _rejectLinkedManagedPath(
      p.join(_projectRootPath, 'assets'),
    );
    await _rejectLinkedManagedPath(
      p.join(_projectRootPath, 'assets', 'borders'),
    );
    await _rejectLinkedManagedPath(
      p.join(_projectRootPath, 'assets', 'borders', '.staging'),
    );
    await _rejectLinkedManagedPath(
      p.join(_projectRootPath, 'assets', 'borders', 'snapshots'),
    );
  }

  /// Rejects links in the portion of [candidatePath] controlled by this
  /// store. Lexical containment alone is insufficient because a link below
  /// `assets/borders` could redirect writes outside the project.
  Future<void> _rejectLinkedManagedPath(String candidatePath) async {
    final normalized = p.normalize(p.absolute(candidatePath));
    if (normalized != _projectRootPath &&
        !p.isWithin(_projectRootPath, normalized)) {
      throw const BorderAssetSnapshotStoreException(
        code: BorderAssetSnapshotStoreErrorCode.invalidProjectRoot,
        userMessage: 'Un dossier de snapshots sort du projet.',
      );
    }
    final relative = p.relative(normalized, from: _projectRootPath);
    if (relative == '.') return;
    var current = _projectRootPath;
    for (final segment in p.split(relative)) {
      current = p.join(current, segment);
      final type = await FileSystemEntity.type(current, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw BorderAssetSnapshotStoreException(
          code: BorderAssetSnapshotStoreErrorCode.invalidProjectRoot,
          userMessage:
              'Les dossiers de snapshots ne peuvent pas traverser un lien symbolique.',
          relativePath: p.relative(current, from: _projectRootPath),
        );
      }
      if (type == FileSystemEntityType.notFound) return;
    }
  }
}

bool _isSafeStageId(String id) =>
    id.isNotEmpty && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id);

bool _isSafeProjectRelativePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.contains(r'\') ||
      path.contains(':') ||
      path.trim() != path) {
    return false;
  }
  return path.split('/').every(
        (segment) => segment.isNotEmpty && segment != '.' && segment != '..',
      );
}

bool _isSafeSnapshotRelativePath(String path) =>
    path.startsWith('assets/borders/snapshots/') &&
    _isSafeProjectRelativePath(path);

String _defaultStageId() =>
    'border_${DateTime.now().microsecondsSinceEpoch}_${pid.toRadixString(16)}';
