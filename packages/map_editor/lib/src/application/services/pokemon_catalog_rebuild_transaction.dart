import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

final class PokemonCatalogRebuildGate {
  const PokemonCatalogRebuildGate({
    required this.firstNationalDex,
    required this.lastNationalDex,
  });

  final int firstNationalDex;
  final int lastNationalDex;

  List<String> validate({
    required Set<int> nationalDexIds,
    required Set<String> speciesIds,
    required Set<String> learnsetIds,
    required Set<String> evolutionIds,
    required Set<String> mediaIds,
    required PokemonCatalogCoherenceReport coherenceReport,
  }) {
    final issues = <String>[];
    final expectedDexIds = <int>{
      for (var value = firstNationalDex; value <= lastNationalDex; value++)
        value,
    };
    final missingDexIds = expectedDexIds.difference(nationalDexIds).toList()
      ..sort();
    final unexpectedDexIds = nationalDexIds.difference(expectedDexIds).toList()
      ..sort();
    if (missingDexIds.isNotEmpty) {
      issues.add('National Dex ids missing: ${missingDexIds.join(', ')}');
    }
    if (unexpectedDexIds.isNotEmpty) {
      issues.add(
        'National Dex ids outside range: ${unexpectedDexIds.join(', ')}',
      );
    }
    final expectedCount = lastNationalDex - firstNationalDex + 1;
    if (speciesIds.length != expectedCount) {
      issues.add(
        'Species documents: expected $expectedCount, found ${speciesIds.length}',
      );
    }
    _validateDocumentIds(
      label: 'Learnset',
      speciesIds: speciesIds,
      documentIds: learnsetIds,
      issues: issues,
    );
    _validateDocumentIds(
      label: 'Evolution',
      speciesIds: speciesIds,
      documentIds: evolutionIds,
      issues: issues,
    );
    _validateDocumentIds(
      label: 'Media',
      speciesIds: speciesIds,
      documentIds: mediaIds,
      issues: issues,
    );
    if (coherenceReport.errorCount > 0) {
      issues.add('Pokemon coherence errors: ${coherenceReport.errorCount}');
    }
    return List<String>.unmodifiable(issues);
  }

  void _validateDocumentIds({
    required String label,
    required Set<String> speciesIds,
    required Set<String> documentIds,
    required List<String> issues,
  }) {
    if (documentIds.length != speciesIds.length) {
      issues.add(
        '$label documents: expected ${speciesIds.length}, '
        'found ${documentIds.length}',
      );
    }
    final missing = speciesIds.difference(documentIds).toList()..sort();
    if (missing.isNotEmpty) {
      issues.add('$label ids missing: ${missing.join(', ')}');
    }
    final unexpected = documentIds.difference(speciesIds).toList()..sort();
    if (unexpected.isNotEmpty) {
      issues.add('$label ids without species: ${unexpected.join(', ')}');
    }
  }
}

final class PokemonCatalogRebuildResult {
  const PokemonCatalogRebuildResult({required this.backupDirectory});

  final Directory backupDirectory;
}

final class PokemonCatalogRebuildTransaction {
  const PokemonCatalogRebuildTransaction();

  Future<PokemonCatalogRebuildResult> replace({
    required Directory projectDirectory,
    required Directory stagingDirectory,
    required Directory backupDirectory,
  }) async {
    final project = Directory(p.normalize(projectDirectory.absolute.path));
    final staging = Directory(p.normalize(stagingDirectory.absolute.path));
    final backup = Directory(p.normalize(backupDirectory.absolute.path));
    _validateRoots(project: project, staging: staging, backup: backup);

    final targetData = Directory(p.join(project.path, 'data', 'pokemon'));
    final targetAssets = Directory(p.join(project.path, 'assets', 'pokemon'));
    final stagedData = Directory(p.join(staging.path, 'data', 'pokemon'));
    final stagedAssets = Directory(p.join(staging.path, 'assets', 'pokemon'));
    await _requireDirectory(targetData, 'project Pokemon data');
    await _requireDirectory(targetAssets, 'project Pokemon assets');
    await _requireDirectory(stagedData, 'staging Pokemon data');
    await _requireDirectory(stagedAssets, 'staging Pokemon assets');
    if (await backup.exists()) {
      throw FileSystemException(
        'Pokemon catalog backup already exists',
        backup.path,
      );
    }

    await _copyDirectory(
      targetData,
      Directory(p.join(backup.path, 'data', 'pokemon')),
    );
    await _copyDirectory(
      targetAssets,
      Directory(p.join(backup.path, 'assets', 'pokemon')),
    );

    final recovery = Directory(
      p.join(
        project.parent.path,
        '.${p.basename(project.path)}.catalog-recovery-'
        '${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final recoveryData = Directory(p.join(recovery.path, 'data', 'pokemon'));
    final recoveryAssets = Directory(
      p.join(recovery.path, 'assets', 'pokemon'),
    );
    await recoveryData.parent.create(recursive: true);
    await recoveryAssets.parent.create(recursive: true);

    var oldDataMoved = false;
    var oldAssetsMoved = false;
    var stagedDataMoved = false;
    var stagedAssetsMoved = false;
    try {
      await targetData.rename(recoveryData.path);
      oldDataMoved = true;
      await targetAssets.rename(recoveryAssets.path);
      oldAssetsMoved = true;
      await stagedData.rename(targetData.path);
      stagedDataMoved = true;
      await stagedAssets.rename(targetAssets.path);
      stagedAssetsMoved = true;
    } on Object catch (error, stackTrace) {
      await _rollback(
        targetData: targetData,
        targetAssets: targetAssets,
        stagedData: stagedData,
        stagedAssets: stagedAssets,
        recoveryData: recoveryData,
        recoveryAssets: recoveryAssets,
        oldDataMoved: oldDataMoved,
        oldAssetsMoved: oldAssetsMoved,
        stagedDataMoved: stagedDataMoved,
        stagedAssetsMoved: stagedAssetsMoved,
      );
      Error.throwWithStackTrace(error, stackTrace);
    }

    await recovery.delete(recursive: true);
    return PokemonCatalogRebuildResult(backupDirectory: backup);
  }

  void _validateRoots({
    required Directory project,
    required Directory staging,
    required Directory backup,
  }) {
    final paths = <String>{project.path, staging.path, backup.path};
    if (paths.length != 3) {
      throw const FileSystemException(
        'Project, staging and backup directories must be distinct',
      );
    }
    if (p.isWithin(project.path, staging.path) ||
        p.isWithin(staging.path, project.path) ||
        p.isWithin(project.path, backup.path) ||
        p.isWithin(backup.path, project.path)) {
      throw const FileSystemException(
        'Staging and backup directories must stay outside the project',
      );
    }
  }

  Future<void> _requireDirectory(Directory directory, String label) async {
    if (!await directory.exists()) {
      throw FileSystemException('$label directory is missing', directory.path);
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(followLinks: false)) {
      final targetPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(targetPath));
      } else if (entity is File) {
        await entity.copy(targetPath);
      } else {
        throw FileSystemException(
          'Pokemon catalog backup does not support symbolic links',
          entity.path,
        );
      }
    }
  }

  Future<void> _rollback({
    required Directory targetData,
    required Directory targetAssets,
    required Directory stagedData,
    required Directory stagedAssets,
    required Directory recoveryData,
    required Directory recoveryAssets,
    required bool oldDataMoved,
    required bool oldAssetsMoved,
    required bool stagedDataMoved,
    required bool stagedAssetsMoved,
  }) async {
    if (stagedAssetsMoved && await targetAssets.exists()) {
      await stagedAssets.parent.create(recursive: true);
      await targetAssets.rename(stagedAssets.path);
    }
    if (stagedDataMoved && await targetData.exists()) {
      await stagedData.parent.create(recursive: true);
      await targetData.rename(stagedData.path);
    }
    if (oldAssetsMoved && await recoveryAssets.exists()) {
      await targetAssets.parent.create(recursive: true);
      await recoveryAssets.rename(targetAssets.path);
    }
    if (oldDataMoved && await recoveryData.exists()) {
      await targetData.parent.create(recursive: true);
      await recoveryData.rename(targetData.path);
    }
  }
}
