import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/use_cases/project_tileset_use_cases.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:path/path.dart' as p;

const _usage = '''
Usage:
  dart run tool/qa_import_tileset_bundle.dart
    --source <bundle-directory>
    --project <disposable-pokemap-project>
    [--report <json-path>]
    [--scan-only]

The command only accepts raster files supported by PokeMap's native tileset
importer. It never reads Tiled metadata and never modifies the source bundle.
''';

Future<void> main(List<String> arguments) async {
  final options = _Options.parse(arguments);
  if (options == null) {
    stderr.writeln(_usage);
    exitCode = 64;
    return;
  }

  final sourceRoot = Directory(p.normalize(p.absolute(options.sourceRoot)));
  final projectRoot = Directory(p.normalize(p.absolute(options.projectRoot)));
  final manifestFile = File(p.join(projectRoot.path, 'project.json'));
  if (!await sourceRoot.exists()) {
    stderr.writeln('Source directory not found: ${sourceRoot.path}');
    exitCode = 66;
    return;
  }
  if (!await manifestFile.exists()) {
    stderr.writeln('PokeMap project manifest not found: ${manifestFile.path}');
    exitCode = 66;
    return;
  }

  final files = await sourceRoot
      .list(recursive: true, followLinks: false)
      .where((entity) => entity is File)
      .cast<File>()
      .where((file) => p.extension(file.path).toLowerCase() == '.png')
      .toList();
  files.sort((left, right) => left.path.compareTo(right.path));

  final startedAt = DateTime.now().toUtc();
  final stopwatch = Stopwatch()..start();
  final dimensions = <String, int>{};
  final failures = <Map<String, Object?>>[];
  var decodedCount = 0;
  var gridAlignedCount = 0;
  var importedCount = 0;
  var maxWidth = 0;
  var maxHeight = 0;

  ProjectManifest? project;
  ImportProjectTilesetUseCase? importer;
  ProjectFileSystem? workspace;
  var initialTilesetCount = 0;
  if (!options.scanOnly) {
    final repository = _JsonProjectRepository();
    workspace = ProjectFileSystem(projectRoot.path);
    project = await repository.loadProject(manifestFile.path);
    initialTilesetCount = project.tilesets.length;
    importer = ImportProjectTilesetUseCase(repository);
  }

  for (var index = 0; index < files.length; index++) {
    final file = files[index];
    final relativePath = p.relative(file.path, from: sourceRoot.path);
    try {
      final decoded = img.decodeImage(await file.readAsBytes());
      if (decoded == null) {
        throw const FormatException('Image decoder returned null.');
      }
      decodedCount++;
      maxWidth = decoded.width > maxWidth ? decoded.width : maxWidth;
      maxHeight = decoded.height > maxHeight ? decoded.height : maxHeight;
      final dimensionKey = '${decoded.width}x${decoded.height}';
      dimensions.update(dimensionKey, (value) => value + 1, ifAbsent: () => 1);
      if (decoded.width % 32 == 0 && decoded.height % 32 == 0) {
        gridAlignedCount++;
      }

      if (!options.scanOnly) {
        final relativeWithoutExtension = p.withoutExtension(relativePath);
        final displayName =
            relativeWithoutExtension.split(p.separator).join(' / ');
        project = await importer!.execute(
          workspace!,
          project!,
          sourcePath: file.path,
          name: displayName,
          scope: TilesetScope.global,
        );
        importedCount++;
      }
    } on Object catch (error, stackTrace) {
      failures.add(<String, Object?>{
        'relativePath': relativePath,
        'error': error.toString(),
        'stackTrace': stackTrace.toString(),
      });
    }

    final completed = index + 1;
    if (completed % 100 == 0 || completed == files.length) {
      stdout.writeln(
        'progress=$completed/${files.length} '
        'decoded=$decodedCount imported=$importedCount '
        'failures=${failures.length} elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    }
  }
  stopwatch.stop();

  final sortedDimensions = dimensions.entries.toList()
    ..sort((left, right) {
      final countComparison = right.value.compareTo(left.value);
      return countComparison != 0
          ? countComparison
          : left.key.compareTo(right.key);
    });
  final report = <String, Object?>{
    'sourceRoot': sourceRoot.path,
    'projectRoot': projectRoot.path,
    'mode': options.scanOnly ? 'scanOnly' : 'nativeSequentialImport',
    'startedAt': startedAt.toIso8601String(),
    'elapsedMilliseconds': stopwatch.elapsedMilliseconds,
    'requestedFileCount': files.length,
    'decodedFileCount': decodedCount,
    'gridAligned32FileCount': gridAlignedCount,
    'importedFileCount': importedCount,
    'initialTilesetCount': initialTilesetCount,
    'finalTilesetCount': project?.tilesets.length ?? initialTilesetCount,
    'failureCount': failures.length,
    'maximumWidth': maxWidth,
    'maximumHeight': maxHeight,
    'dimensionHistogram': <String, int>{
      for (final entry in sortedDimensions) entry.key: entry.value,
    },
    'failures': failures,
  };
  final reportJson = const JsonEncoder.withIndent('  ').convert(report);
  final reportPath = options.reportPath;
  if (reportPath == null) {
    stdout.writeln(reportJson);
  } else {
    final output = File(p.normalize(p.absolute(reportPath)));
    await output.parent.create(recursive: true);
    await output.writeAsString('$reportJson\n', flush: true);
    stdout.writeln('report=${output.path}');
  }

  if (failures.isNotEmpty) {
    exitCode = 65;
  }
}

final class _JsonProjectRepository implements ProjectRepository {
  @override
  Future<ProjectManifest> loadProject(String path) async {
    return decodeValidatedNarrativeEventAuthoringProject(
      await File(path).readAsBytes(),
    ).manifest;
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    ProjectValidator.validate(project);
    final destination = File(path);
    final temporary = File('$path.qa-import.tmp');
    await temporary.writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(project.toJson())}\n',
      flush: true,
    );
    await temporary.rename(destination.path);
  }
}

final class _Options {
  const _Options({
    required this.sourceRoot,
    required this.projectRoot,
    required this.reportPath,
    required this.scanOnly,
  });

  final String sourceRoot;
  final String projectRoot;
  final String? reportPath;
  final bool scanOnly;

  static _Options? parse(List<String> arguments) {
    String? sourceRoot;
    String? projectRoot;
    String? reportPath;
    var scanOnly = false;

    for (var index = 0; index < arguments.length; index++) {
      final argument = arguments[index];
      switch (argument) {
        case '--source':
          if (index + 1 >= arguments.length) return null;
          sourceRoot = arguments[++index];
        case '--project':
          if (index + 1 >= arguments.length) return null;
          projectRoot = arguments[++index];
        case '--report':
          if (index + 1 >= arguments.length) return null;
          reportPath = arguments[++index];
        case '--scan-only':
          scanOnly = true;
        case '--help':
        case '-h':
          return null;
        default:
          return null;
      }
    }

    if (sourceRoot == null || projectRoot == null) return null;
    return _Options(
      sourceRoot: sourceRoot,
      projectRoot: projectRoot,
      reportPath: reportPath,
      scanOnly: scanOnly,
    );
  }
}
