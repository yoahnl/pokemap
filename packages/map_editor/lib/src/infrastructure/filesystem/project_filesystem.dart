import 'dart:io';

import 'package:path/path.dart' as p;

import '../../application/errors/application_errors.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/project_map_id_policy.dart';

class ProjectFileSystem implements ProjectWorkspace, ProjectWorkspaceCache {
  static const ProjectMapIdPolicy _mapIdPolicy = ProjectMapIdPolicy();

  final String _projectRoot;
  final Map<String, Object> _cachedValues = <String, Object>{};

  ProjectFileSystem(this._projectRoot);

  @override
  String get projectRoot => _projectRoot;

  @override
  String get projectManifestPath => p.join(_projectRoot, 'project.json');
  String get tilesetsDirectoryPath =>
      p.normalize(p.join(_projectRoot, 'assets', 'tilesets'));

  @override
  T? readCachedValue<T extends Object>(String key) {
    return _cachedValues[key] as T?;
  }

  @override
  void writeCachedValue(String key, Object? value) {
    if (value == null) {
      _cachedValues.remove(key);
      return;
    }
    _cachedValues[key] = value;
  }

  @override
  String resolveMapPath(String relativePath) {
    if (relativePath.isEmpty || relativePath.trim() != relativePath) {
      throw const EditorValidationException(
        'Map path must be a non-empty project-relative path',
      );
    }
    if (relativePath.contains(r'\') ||
        p.posix.isAbsolute(relativePath) ||
        p.windows.isAbsolute(relativePath)) {
      throw EditorValidationException(
        'Map path must stay inside the project maps directory: $relativePath',
      );
    }

    final normalizedRelativePath = p.posix.normalize(relativePath);
    if (normalizedRelativePath != relativePath) {
      throw EditorValidationException(
        'Map path must already be canonical: $relativePath',
      );
    }
    final segments = p.posix.split(normalizedRelativePath);
    if (segments.length < 2 ||
        segments.first != 'maps' ||
        p.posix.extension(normalizedRelativePath).toLowerCase() != '.json') {
      throw EditorValidationException(
        'Map path must target a JSON file inside maps/: $relativePath',
      );
    }

    final lexicalCandidate = p.normalize(
      p.joinAll(<String>[_projectRoot, ...segments]),
    );
    final lexicalMapsRoot = p.normalize(p.join(_projectRoot, 'maps'));
    _rejectMapSymlinkAliases(
      mapsRoot: lexicalMapsRoot,
      candidate: lexicalCandidate,
    );
    final canonicalProjectRoot = _resolveWithExistingAncestor(_projectRoot);
    final canonicalMapsRoot = p.normalize(
      p.join(canonicalProjectRoot, 'maps'),
    );
    final canonicalCandidate = _resolveWithExistingAncestor(lexicalCandidate);

    // Lexical `..` checks do not cover a pre-existing `maps` or nested
    // directory symlink. Resolve every existing ancestor before allowing a
    // repository read/write/delete to consume the candidate.
    if (!p.isWithin(canonicalMapsRoot, canonicalCandidate)) {
      throw EditorValidationException(
        'Map path resolves outside the project maps directory: $relativePath',
      );
    }
    return lexicalCandidate;
  }

  void _rejectMapSymlinkAliases({
    required String mapsRoot,
    required String candidate,
  }) {
    // Even an in-bounds link gives one file several manifest spellings
    // (`maps/town.json` and `maps/alias/town.json`). Reject every link below
    // maps/ so lifecycle collision checks operate on one lexical identity.
    var cursor = mapsRoot;
    final relative = p.relative(candidate, from: mapsRoot);
    for (final segment in <String>['', ...p.split(relative)]) {
      if (segment.isNotEmpty) cursor = p.join(cursor, segment);
      if (FileSystemEntity.typeSync(cursor, followLinks: false) ==
          FileSystemEntityType.link) {
        throw EditorValidationException(
          'Map path cannot traverse a symbolic-link alias: $candidate',
        );
      }
    }
  }

  @override
  String getMapPath(String mapId) {
    return resolveMapPath(getMapRelativePath(mapId));
  }

  @override
  String getMapRelativePath(String mapId) {
    final canonicalId = _mapIdPolicy.requireValid(mapId);
    return 'maps/$canonicalId.json';
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

  String _resolveWithExistingAncestor(String path) {
    var cursor = p.normalize(p.absolute(path));
    final missingSegments = <String>[];

    while (true) {
      final type = FileSystemEntity.typeSync(cursor, followLinks: false);
      if (type != FileSystemEntityType.notFound) {
        try {
          final resolvedAncestor = switch (type) {
            FileSystemEntityType.directory =>
              Directory(cursor).resolveSymbolicLinksSync(),
            FileSystemEntityType.file =>
              File(cursor).resolveSymbolicLinksSync(),
            FileSystemEntityType.link =>
              Link(cursor).resolveSymbolicLinksSync(),
            _ => throw FileSystemException(
                'Unsupported map path entity',
                cursor,
              ),
          };
          return p.normalize(
            p.joinAll(<String>[resolvedAncestor, ...missingSegments]),
          );
        } on FileSystemException catch (error) {
          throw EditorValidationException(
            'Map path cannot be resolved safely: ${error.message}',
          );
        }
      }

      final parent = p.dirname(cursor);
      if (parent == cursor) {
        throw EditorValidationException(
          'Map path has no resolvable project ancestor: $path',
        );
      }
      missingSegments.insert(0, p.basename(cursor));
      cursor = parent;
    }
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
