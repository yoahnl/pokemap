import 'dart:io';

import 'package:path/path.dart' as p;

import '../../ports/project_file_reader.dart';
import '../../workspace/workspace_policy.dart';
import 'game_package_export_profile.dart';
import 'game_package_export_profile_store.dart';
import 'game_package_export_service.dart';

abstract interface class GamePackageExportApiPort {
  Future<GamePackageExportReceipt> export({
    required String projectRoot,
    required String outputPath,
  });
}

final class GamePackageExportReceipt {
  const GamePackageExportReceipt({
    required this.outputPath,
    required this.sizeBytes,
    required this.sha256,
    required this.gameId,
    required this.gameVersion,
    required this.title,
    required this.fileCount,
    required this.treeSha256,
  });

  final String outputPath;
  final int sizeBytes;
  final String sha256;
  final String gameId;
  final String gameVersion;
  final String title;
  final int fileCount;
  final String treeSha256;

  Map<String, Object?> toJson() => <String, Object?>{
        'outputPath': outputPath,
        'sizeBytes': sizeBytes,
        'sha256': sha256,
        'gameId': gameId,
        'gameVersion': gameVersion,
        'title': title,
        'fileCount': fileCount,
        'treeSha256': treeSha256,
      };
}

final class LocalGamePackageExportApi implements GamePackageExportApiPort {
  LocalGamePackageExportApi._({
    required WorkspacePolicy projectPolicy,
    required List<String> exportRoots,
    required CanonicalGamePackageExportService exportService,
  })  : _projectPolicy = projectPolicy,
        _exportRoots = List.unmodifiable(exportRoots),
        _exportService = exportService;

  static Future<LocalGamePackageExportApi> create({
    required Iterable<String> allowedProjectRoots,
    required Iterable<String> allowedExportRoots,
    CanonicalGamePackageExportService exportService =
        const CanonicalGamePackageExportService(),
  }) async {
    const reader = LocalProjectFileReader();
    final projectPolicy = await WorkspacePolicy.create(
      allowedRootPaths: allowedProjectRoots,
      fileReader: reader,
    );
    final exportRoots = <String>{};
    for (final root in allowedExportRoots) {
      if (!p.isAbsolute(root) || root.contains('\u0000')) {
        throw const GamePackageExportException(
          code: 'exportRootInvalid',
          message: 'Export roots must be absolute filesystem paths.',
        );
      }
      exportRoots.add(await Directory(root).resolveSymbolicLinks());
    }
    if (exportRoots.isEmpty) {
      throw const GamePackageExportException(
        code: 'exportRootsRequired',
        message: 'At least one export root must be configured.',
      );
    }
    final orderedExportRoots = exportRoots.toList(growable: false)..sort();
    return LocalGamePackageExportApi._(
      projectPolicy: projectPolicy,
      exportRoots: orderedExportRoots,
      exportService: exportService,
    );
  }

  final WorkspacePolicy _projectPolicy;
  final List<String> _exportRoots;
  final CanonicalGamePackageExportService _exportService;

  @override
  Future<GamePackageExportReceipt> export({
    required String projectRoot,
    required String outputPath,
  }) async {
    final canonicalProjectRoot =
        await _projectPolicy.authorizeProjectRoot(projectRoot);
    final outputFile = await _authorizeOutput(outputPath);
    final profile = await GamePackageExportProfileStore(
      projectRoot: Directory(canonicalProjectRoot),
    ).load();
    if (profile == null) {
      throw GamePackageExportException(
        code: 'missingExportProfile',
        path: canonicalProjectRoot,
        message: 'The project has no canonical export profile.',
      );
    }
    final artifact = await _exportService.exportToFile(
      projectRoot: Directory(canonicalProjectRoot),
      profile: profile,
      outputFile: outputFile,
    );
    final canonicalOutput = await outputFile.resolveSymbolicLinks();
    return GamePackageExportReceipt(
      outputPath: canonicalOutput,
      sizeBytes: await outputFile.length(),
      sha256: artifact.packageSha256,
      gameId: artifact.manifest.gameId,
      gameVersion: artifact.manifest.gameVersion.toString(),
      title: artifact.manifest.title,
      fileCount: artifact.manifest.content.fileCount,
      treeSha256: artifact.manifest.content.treeSha256,
    );
  }

  Future<File> _authorizeOutput(String outputPath) async {
    if (!p.isAbsolute(outputPath) ||
        outputPath.contains('\u0000') ||
        p.split(outputPath).contains('..')) {
      throw const GamePackageExportException(
        code: 'exportPathInvalid',
        message: 'The export destination must be an absolute canonical path.',
      );
    }
    final normalized = p.normalize(outputPath);
    final output = File(normalized);
    final type = await FileSystemEntity.type(normalized, followLinks: false);
    if (type == FileSystemEntityType.link) {
      throw GamePackageExportException(
        code: 'exportPathSymlinkForbidden',
        path: normalized,
        message: 'The export destination cannot be a symbolic link.',
      );
    }
    if (type != FileSystemEntityType.notFound) {
      throw GamePackageExportException(
        code: 'exportDestinationExists',
        path: normalized,
        message: 'The export destination already exists.',
      );
    }
    final canonicalParent = await output.parent.resolveSymbolicLinks();
    if (!_exportRoots.any(
      (root) => workspacePathIsWithin(root: root, candidate: canonicalParent),
    )) {
      throw GamePackageExportException(
        code: 'exportPathOutsideAllowedRoots',
        path: normalized,
        message: 'The export destination is outside configured export roots.',
      );
    }
    return output;
  }
}
