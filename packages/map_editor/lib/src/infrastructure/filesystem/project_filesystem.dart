import 'dart:io';

import 'package:path/path.dart' as p;

import '../../application/ports/project_workspace.dart';

class ProjectFileSystem implements ProjectWorkspace {
  final String _projectRoot;

  ProjectFileSystem(this._projectRoot);

  @override
  String get projectRoot => _projectRoot;

  @override
  String get projectManifestPath => p.join(_projectRoot, 'project.json');
  String get tilesetsDirectoryPath =>
      p.normalize(p.join(_projectRoot, 'assets', 'tilesets'));

  @override
  String resolveMapPath(String relativePath) {
    return p.normalize(p.join(_projectRoot, relativePath));
  }

  @override
  String getMapPath(String mapId) {
    return p.normalize(p.join(_projectRoot, 'maps', '$mapId.json'));
  }

  @override
  String getMapRelativePath(String mapId) {
    return 'maps/$mapId.json';
  }

  @override
  String resolveTilesetPath(String relativePath) {
    return resolveProjectRelativePath(relativePath);
  }

  @override
  String resolveProjectRelativePath(String relativePath) {
    return p.normalize(p.join(_projectRoot, relativePath));
  }

  String getTilesetRelativePath(String fileName) {
    return p.posix.join('assets', 'tilesets', fileName);
  }

  String relativePath(String absolutePath) {
    return p.relative(absolutePath, from: _projectRoot);
  }

  @override
  Future<void> ensureDirectoryExists(String path) async {
    final dir = Directory(p.dirname(path));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  @override
  Future<bool> fileExists(String path) {
    return File(path).exists();
  }

  @override
  Future<bool> directoryExists(String path) {
    return Directory(path).exists();
  }

  @override
  Future<String> readTextFile(String path) {
    return File(path).readAsString();
  }

  @override
  Future<void> writeTextFile(String path, String contents) async {
    await ensureDirectoryExists(path);
    await File(path).writeAsString(contents);
  }

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Source file not found',
        sourcePath,
      );
    }
    await ensureDirectoryExists(destinationPath);
    await sourceFile.copy(destinationPath);
  }

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Source file not found',
        sourcePath,
      );
    }
    if (await File(destinationPath).exists()) {
      throw FileSystemException(
        'Destination file already exists',
        destinationPath,
      );
    }
    await ensureDirectoryExists(destinationPath);
    try {
      await sourceFile.rename(destinationPath);
    } on FileSystemException {
      await sourceFile.copy(destinationPath);
      await sourceFile.delete();
    }
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {
    final sourceDirectory = Directory(sourcePath);
    if (!await sourceDirectory.exists()) {
      return;
    }
    if (await Directory(destinationPath).exists()) {
      throw FileSystemException(
        'Destination directory already exists',
        destinationPath,
      );
    }
    await Directory(p.dirname(destinationPath)).create(recursive: true);
    try {
      await sourceDirectory.rename(destinationPath);
    } on FileSystemException {
      await _copyDirectoryRecursive(
        sourceDirectory,
        Directory(destinationPath),
      );
      await sourceDirectory.delete(recursive: true);
    }
  }

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      return;
    }
    try {
      await directory.delete(recursive: false);
    } on FileSystemException {
      // Non-empty or locked directories are intentionally ignored here.
    }
  }

  @override
  Future<String> importTilesetImage(String sourcePath,
      {String? preferredName}) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException(
        'Tileset source file not found',
        sourcePath,
      );
    }

    final ext = p.extension(sourcePath).toLowerCase();
    final sanitizedBase = _sanitizeFileName(
      preferredName ?? p.basenameWithoutExtension(sourcePath),
    );
    final baseName = sanitizedBase.isEmpty ? 'tileset' : sanitizedBase;

    final destinationDir = Directory(tilesetsDirectoryPath);
    if (!await destinationDir.exists()) {
      await destinationDir.create(recursive: true);
    }

    var fileName = '$baseName$ext';
    var destinationPath = p.join(tilesetsDirectoryPath, fileName);
    var suffix = 1;
    while (await File(destinationPath).exists()) {
      fileName = '${baseName}_$suffix$ext';
      destinationPath = p.join(tilesetsDirectoryPath, fileName);
      suffix++;
    }

    await sourceFile.copy(destinationPath);
    return getTilesetRelativePath(fileName);
  }

  @override
  Future<void> deleteRelativeFile(String relativePath) async {
    final absolutePath = resolveProjectRelativePath(relativePath);
    final file = File(absolutePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  String _sanitizeFileName(String value) {
    final normalized = value.trim().toLowerCase();
    final safe = normalized.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    return safe.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  Future<void> _copyDirectoryRecursive(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list(recursive: false)) {
      final name = p.basename(entity.path);
      if (entity is File) {
        await entity.copy(p.join(to.path, name));
      } else if (entity is Directory) {
        await _copyDirectoryRecursive(
          entity,
          Directory(p.join(to.path, name)),
        );
      }
    }
  }
}

class FileProjectWorkspaceFactory implements ProjectWorkspaceFactory {
  const FileProjectWorkspaceFactory();

  @override
  ProjectWorkspace create(String projectRoot) {
    return ProjectFileSystem(projectRoot);
  }
}
