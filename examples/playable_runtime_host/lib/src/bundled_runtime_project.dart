import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

/// Resolves the project shipped inside a macOS `.app` bundle.
///
/// The packaged path is always preferred. The development fallback exists
/// only so `flutter run` can keep using the repository-local Selbrume project.
final class BundledRuntimeProject {
  const BundledRuntimeProject();

  static const projectDirectoryName = 'selbrume';
  static const projectFileName = 'project.json';

  String packagedProjectFilePath(String executablePath) {
    final macOsDirectory = Directory(p.dirname(p.absolute(executablePath)));
    final contentsDirectory = macOsDirectory.parent;
    return p.normalize(
      p.join(
        contentsDirectory.path,
        'Resources',
        projectDirectoryName,
        projectFileName,
      ),
    );
  }

  Future<String?> resolve({
    String? executablePath,
    String? workingDirectory,
    String? developmentProjectRoot,
  }) async {
    final resolvedExecutable = executablePath ?? Platform.resolvedExecutable;
    final packaged = File(packagedProjectFilePath(resolvedExecutable));
    if (await packaged.exists()) return packaged.path;

    final explicitDevelopmentRoot = developmentProjectRoot?.trim();
    final developmentRoot =
        explicitDevelopmentRoot != null && explicitDevelopmentRoot.isNotEmpty
            ? explicitDevelopmentRoot
            : p.join(
                workingDirectory ?? Directory.current.path,
                '..',
                '..',
                projectDirectoryName,
              );
    final development = File(
      p.join(
        p.normalize(p.absolute(developmentRoot)),
        projectFileName,
      ),
    );
    return await development.exists() ? development.path : null;
  }
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
  final project = ProjectManifest.fromJson(
    Map<String, dynamic>.from(decoded),
  );
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
    'data/pokemon/catalogs/items.json',
    'data/pokemon/catalogs/moves.json',
  };
  for (final relativePath in requiredPaths) {
    final file = File(p.join(projectRoot.path, relativePath));
    if (!await file.exists()) {
      throw StateError('Bundled project file is missing: $relativePath');
    }
  }
  requiredPaths.add(
    await _requireFirstFile(
      projectRoot,
      relativeDirectory: 'dialogues',
      extension: '.yarn',
    ),
  );
  requiredPaths.add(
    await _requireFirstFile(
      projectRoot,
      relativeDirectory: 'data/pokemon/species',
      extension: '.json',
    ),
  );
  requiredPaths.add(
    await _requireFirstFile(
      projectRoot,
      relativeDirectory: 'assets',
    ),
  );

  final startMapFile = File(
    p.join(projectRoot.path, startEntry.single.relativePath),
  );
  final startMapDecoded = jsonDecode(await startMapFile.readAsString());
  if (startMapDecoded is! Map) {
    throw StateError('Bundled start map must contain a JSON object.');
  }
  final startMap = MapData.fromJson(
    Map<String, dynamic>.from(startMapDecoded),
  );
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

Future<String> _requireFirstFile(
  Directory root, {
  required String relativeDirectory,
  String? extension,
}) async {
  final directory = Directory(p.join(root.path, relativeDirectory));
  if (!await directory.exists()) {
    throw StateError(
      'Bundled project directory is missing: $relativeDirectory',
    );
  }
  final files = <File>[];
  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    if (extension != null &&
        !entity.path.toLowerCase().endsWith(extension.toLowerCase())) {
      continue;
    }
    files.add(entity);
  }
  if (files.isEmpty) {
    throw StateError(
      'Bundled project directory contains no required file: '
      '$relativeDirectory${extension ?? ''}',
    );
  }
  files.sort((left, right) => left.path.compareTo(right.path));
  return p.posix.normalize(
    p.relative(files.first.path, from: root.path).replaceAll(r'\', '/'),
  );
}
