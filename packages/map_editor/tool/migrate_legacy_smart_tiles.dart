import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  final root = _option(arguments, '--project-root');
  if (root == null || root.trim().isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/migrate_legacy_smart_tiles.dart '
      '--project-root <directory> [--apply]',
    );
    exitCode = 64;
    return;
  }
  final apply = arguments.contains('--apply');
  final requestedProjectRoot = Directory(p.normalize(p.absolute(root)));
  if (!await requestedProjectRoot.exists()) {
    stderr.writeln('Missing project directory: ${requestedProjectRoot.path}');
    exitCode = 66;
    return;
  }
  final projectRoot = Directory(
    await requestedProjectRoot.resolveSymbolicLinks(),
  );
  final projectFile = File(p.join(projectRoot.path, 'project.json'));
  if (!await projectFile.exists()) {
    stderr.writeln('Missing project.json in ${projectRoot.path}');
    exitCode = 66;
    return;
  }

  final project = ProjectManifest.fromJson(
    _jsonObject(await projectFile.readAsString(), projectFile.path),
  );
  final mapFiles = <File>[];
  final maps = <MapData>[];
  for (final entry in project.maps) {
    final file = await _resolveProjectMapFile(
      projectRoot: projectRoot,
      relativePath: entry.relativePath,
    );
    if (file == null) {
      exitCode = 65;
      return;
    }
    if (!await file.exists()) {
      stderr.writeln('Missing map file: ${entry.relativePath}');
      exitCode = 66;
      return;
    }
    mapFiles.add(file);
    maps.add(
      MapData.fromJson(_jsonObject(await file.readAsString(), file.path)),
    );
  }

  final migration = migrateLegacyTerrainAndPathsToSmartTiles(
    project: project,
    maps: maps,
    removeLegacyDefinitions: true,
  );
  final catalogErrors = validateProjectSmartTileCatalog(
    catalog: migration.project.smartTileCatalog,
    projectTilesetIds: migration.project.tilesets.map((tileset) => tileset.id),
  ).where((diagnostic) => diagnostic.isError).toList(growable: false);
  if (catalogErrors.isNotEmpty) {
    for (final diagnostic in catalogErrors) {
      stderr.writeln('${diagnostic.path}: ${diagnostic.message}');
    }
    exitCode = 65;
    return;
  }
  for (final map in migration.maps) {
    MapValidator.validate(
      map,
      projectDialogueContext: migration.project,
    );
  }

  final projectBytes = _encode(migration.project.toJson());
  final mapBytes = <List<int>>[
    for (final map in migration.maps) _encode(map.toJson()),
  ];
  ProjectManifest.fromJson(
    _jsonObject(utf8.decode(projectBytes), projectFile.path),
  );
  for (var index = 0; index < mapBytes.length; index += 1) {
    MapData.fromJson(
      _jsonObject(utf8.decode(mapBytes[index]), mapFiles[index].path),
    );
  }

  String? recoveryDirectory;
  if (apply) {
    final recovery = Directory(
      p.join(
        projectRoot.path,
        '.pokemap',
        'recovery',
        'legacy-smart-tiles-${DateTime.now().toUtc().millisecondsSinceEpoch}',
      ),
    );
    await recovery.create(recursive: true);
    recoveryDirectory = recovery.path;
    await _copyForRecovery(
      source: projectFile,
      projectRoot: projectRoot.path,
      recoveryRoot: recovery.path,
    );
    for (final file in mapFiles) {
      await _copyForRecovery(
        source: file,
        projectRoot: projectRoot.path,
        recoveryRoot: recovery.path,
      );
    }

    // The manifest is written first: a v4 catalog remains compatible with
    // legacy layers if the process is interrupted before all maps are replaced.
    await _replaceAtomically(projectFile, projectBytes);
    for (var index = 0; index < mapFiles.length; index += 1) {
      await _replaceAtomically(mapFiles[index], mapBytes[index]);
    }
  }

  final report = migration.report;
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'mode': apply ? 'applied' : 'dry-run',
      'projectRoot': projectRoot.path,
      'migratedTerrainPresets': report.migratedTerrainPresets,
      'migratedPathPresets': report.migratedPathPresets,
      'migratedTerrainLayers': report.migratedTerrainLayers,
      'migratedPathLayers': report.migratedPathLayers,
      'removedEmptyTerrainLayers': report.removedEmptyTerrainLayers,
      'smartTilePresets': migration.project.smartTileCatalog.presets.length,
      'smartTileMaterials': migration.project.smartTileCatalog.materials.length,
      'smartTileAtlases': migration.project.smartTileCatalog.atlases.length,
      'smartTileAnimations':
          migration.project.smartTileCatalog.animations.length,
      'warnings': report.warnings,
      if (recoveryDirectory != null) 'recoveryDirectory': recoveryDirectory,
    }),
  );
}

Future<File?> _resolveProjectMapFile({
  required Directory projectRoot,
  required String relativePath,
}) async {
  if (p.isAbsolute(relativePath)) {
    stderr.writeln('Map path must be relative to the project: $relativePath');
    return null;
  }

  final candidatePath = p.normalize(p.join(projectRoot.path, relativePath));
  if (!p.isWithin(projectRoot.path, candidatePath)) {
    stderr.writeln('Map path escapes the project directory: $relativePath');
    return null;
  }

  final candidate = File(candidatePath);
  if (await candidate.exists()) {
    final resolvedPath = await candidate.resolveSymbolicLinks();
    if (!p.isWithin(projectRoot.path, resolvedPath)) {
      stderr.writeln('Map path escapes the project directory: $relativePath');
      return null;
    }
    return File(resolvedPath);
  }
  return candidate;
}

String? _option(List<String> arguments, String name) {
  final index = arguments.indexOf(name);
  if (index < 0 || index + 1 >= arguments.length) return null;
  return arguments[index + 1];
}

Map<String, dynamic> _jsonObject(String source, String path) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw FormatException('$path must contain a JSON object.');
  }
  return Map<String, dynamic>.from(decoded);
}

List<int> _encode(Map<String, dynamic> json) =>
    utf8.encode('${const JsonEncoder.withIndent('  ').convert(json)}\n');

Future<void> _copyForRecovery({
  required File source,
  required String projectRoot,
  required String recoveryRoot,
}) async {
  final relative = p.relative(source.path, from: projectRoot);
  final target = File(p.join(recoveryRoot, relative));
  await target.parent.create(recursive: true);
  await source.copy(target.path);
}

Future<void> _replaceAtomically(File target, List<int> bytes) async {
  final temporary = File('${target.path}.smart-tile-migration.tmp');
  await temporary.writeAsBytes(bytes, flush: true);
  await temporary.rename(target.path);
}
