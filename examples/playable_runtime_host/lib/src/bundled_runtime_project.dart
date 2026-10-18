import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

final class BundledRuntimeProject {
  const BundledRuntimeProject();

  static const projectDirectoryName = 'runtime-project';
  static const projectFileName = 'project.json';
  static const bundleManifestFileName = 'runtime-project.json';

  String packagedProjectFilePath(String executablePath) => p.normalize(
        p.join(
          p.dirname(p.dirname(p.absolute(executablePath))),
          'Resources',
          projectDirectoryName,
          projectFileName,
        ),
      );

  Future<String?> resolve({
    String? executablePath,
    String? developmentProjectRoot,
  }) async {
    final resources = p.normalize(
      p.join(
        p.dirname(
          p.dirname(p.absolute(executablePath ?? Platform.resolvedExecutable)),
        ),
        'Resources',
      ),
    );
    final descriptor = File(p.join(resources, bundleManifestFileName));
    final type = await FileSystemEntity.type(
      descriptor.path,
      followLinks: false,
    );
    if (type != FileSystemEntityType.notFound) {
      if (type != FileSystemEntityType.file) {
        throw StateError('The runtime bundle manifest must be a regular file.');
      }
      final decoded = jsonDecode(await descriptor.readAsString());
      if (decoded is! Map ||
          decoded.length != 2 ||
          decoded['schemaVersion'] != 1 ||
          decoded['projectFile'] is! String) {
        throw StateError('Invalid runtime bundle manifest.');
      }
      return _safeBundledFile(resources, decoded['projectFile'] as String);
    }
    final explicitRoot = developmentProjectRoot?.trim();
    if (explicitRoot == null || explicitRoot.isEmpty) return null;
    final file = File(
      p.join(p.normalize(p.absolute(explicitRoot)), projectFileName),
    );
    return await file.exists() ? file.path : null;
  }
}

Future<String> _safeBundledFile(String root, String relative) async {
  if (relative.isEmpty ||
      p.isAbsolute(relative) ||
      relative.contains('\\') ||
      relative
          .split('/')
          .any((part) => part.isEmpty || part == '.' || part == '..') ||
      p.basename(relative) != BundledRuntimeProject.projectFileName) {
    throw StateError(
      'The bundled project path must be a strict relative project.json path.',
    );
  }
  var current = root;
  if (await FileSystemEntity.type(root, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw StateError(
      'The runtime resources directory must be a regular directory.',
    );
  }
  final parts = relative.split('/');
  for (var index = 0; index < parts.length; index++) {
    current = p.join(current, parts[index]);
    final expected = index == parts.length - 1
        ? FileSystemEntityType.file
        : FileSystemEntityType.directory;
    if (await FileSystemEntity.type(current, followLinks: false) != expected) {
      throw StateError(
        'The bundled project path contains a missing, symbolic or invalid entry.',
      );
    }
  }
  final canonicalRoot = await Directory(root).resolveSymbolicLinks();
  final canonicalFile = await File(current).resolveSymbolicLinks();
  if (!p.isWithin(canonicalRoot, canonicalFile)) {
    throw StateError('The bundled project escapes its resources directory.');
  }
  return current;
}

final class BundledRuntimeProjectVerification {
  BundledRuntimeProjectVerification({
    required this.projectName,
    required this.startMapId,
    required this.mapCount,
    required this.newGameSaveReloadPassed,
    required Iterable<String> requiredRelativePaths,
  }) : requiredRelativePaths = List.unmodifiable(requiredRelativePaths);

  final String projectName;
  final String startMapId;
  final int mapCount;
  final bool newGameSaveReloadPassed;
  final List<String> requiredRelativePaths;
}

/// Fails closed when the package cannot start and persist an authored New Game.
Future<BundledRuntimeProjectVerification> verifyBundledRuntimeProject(
  String projectFilePath,
) async {
  final projectFile = File(p.normalize(p.absolute(projectFilePath)));
  if (!await projectFile.exists()) {
    throw StateError('Bundled project.json is missing: ${projectFile.path}');
  }
  final projectRoot = projectFile.parent;
  final decoded = jsonDecode(await projectFile.readAsString());
  if (decoded is! Map) {
    throw StateError('Bundled project.json must contain a JSON object.');
  }
  final project = ProjectManifest.fromJson(Map<String, dynamic>.from(decoded));
  if (!project.newGame.enabled) {
    throw StateError('Bundled project New Game is disabled.');
  }
  final startMapId = project.newGame.startMapId.trim();
  if (startMapId.isEmpty) {
    throw StateError('Bundled project New Game start map is missing.');
  }
  final startEntry = project.maps.where((entry) => entry.id == startMapId);
  if (startEntry.length != 1) {
    throw StateError(
      'Bundled project must reference exactly one start map "$startMapId".',
    );
  }

  final requiredPaths = <String>{
    BundledRuntimeProject.projectFileName,
    p.posix.normalize(startEntry.single.relativePath.replaceAll(r'\', '/')),
  };
  for (final relativePath in requiredPaths) {
    final normalized = p.normalize(relativePath);
    if (p.isAbsolute(relativePath) ||
        normalized == '..' ||
        normalized.startsWith('../') ||
        relativePath.contains(r'\')) {
      throw StateError('Invalid bundled project reference: $relativePath');
    }
    final file = File(p.join(projectRoot.path, normalized));
    if (!await file.exists()) {
      throw StateError('Bundled project file is missing: $relativePath');
    }
  }
  final startMapFile = File(
    p.join(projectRoot.path, startEntry.single.relativePath),
  );
  final startMapDecoded = jsonDecode(await startMapFile.readAsString());
  if (startMapDecoded is! Map) {
    throw StateError('Bundled start map must contain a JSON object.');
  }
  final startMap = MapData.fromJson(Map<String, dynamic>.from(startMapDecoded));
  final newGame = createNewGameStateFromProject(
    project: project,
    startMap: startMap,
    tileWidthPx: project.settings.tileWidth,
    tileHeightPx: project.settings.tileHeight,
  );
  final saveDirectory = await Directory.systemTemp.createTemp(
    'pokemap_bundled_project_save_',
  );
  late final GameState reloaded;
  try {
    final saveFile = File(p.join(saveDirectory.path, 'save.json'));
    await saveFile.writeAsString(
      '${jsonEncode(saveDataFromGameState(newGame).toJson())}\n',
      flush: true,
    );
    final saveDecoded = jsonDecode(await saveFile.readAsString());
    if (saveDecoded is! Map) {
      throw StateError('Bundled project save must contain a JSON object.');
    }
    reloaded = normalizeLoadedGameState(
      gameStateFromSaveData(
        SaveData.fromJson(Map<String, dynamic>.from(saveDecoded)),
      ),
    );
  } finally {
    if (await saveDirectory.exists()) {
      await saveDirectory.delete(recursive: true);
    }
  }
  final saveReloadPassed = reloaded.saveId == newGame.saveId &&
      reloaded.currentMapId == newGame.currentMapId &&
      reloaded.playerPosition == newGame.playerPosition &&
      reloaded.playerFacing == newGame.playerFacing &&
      reloaded.trainerProfile == newGame.trainerProfile &&
      reloaded.party == newGame.party &&
      reloaded.bag == newGame.bag;
  if (!saveReloadPassed) {
    throw StateError('Bundled project New Game save/reload round-trip failed.');
  }

  final orderedPaths = requiredPaths.toList(growable: false)..sort();
  return BundledRuntimeProjectVerification(
    projectName: project.name,
    startMapId: startMapId,
    mapCount: project.maps.length,
    newGameSaveReloadPassed: saveReloadPassed,
    requiredRelativePaths: orderedPaths,
  );
}
