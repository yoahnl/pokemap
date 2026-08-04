import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_session_lifecycle.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:path/path.dart' as p;

import '../../../tools/performance/benchmark_support.dart';

Future<void> main(List<String> arguments) async {
  try {
    final cli = PerformanceCli.parse(
      arguments,
      allowed: const {'roots', 'output'},
    );
    final rootCount = cli.positiveInt('roots', fallback: 10);
    final outputPath = cli.requiredValue('output');
    validatedPackageOutput(outputPath, packageName: 'map_editor');
    final sandbox = await Directory.systemTemp.createTemp(
      'pokemap_authoring_lifecycle_',
    );
    try {
      final roots = await Future.wait([
        for (var index = 0; index < rootCount; index += 1)
          _writeFixture(sandbox, index),
      ]);
      const reader = EditorProjectFileReader();
      final queries = AuthoringQueryAdapter(fileReader: reader);
      final mutations = AuthoringMutationAdapter(
        fileReader: reader,
        queries: queries,
        projectRoots: reader,
      );
      final lifecycle = EditorAuthoringSessionLifecycle(fileReader: reader)
        ..attach(queries)
        ..attach(mutations);
      final rssBefore = ProcessInfo.currentRss;
      final stopwatch = Stopwatch()..start();
      for (var index = 0; index < roots.length; index += 1) {
        final root = roots[index];
        await lifecycle.prepareCandidate(root.path);
        await queries.open(root.path);
        await mutations.plan(
          root.path,
          actionId: 'map.save',
          parameters: {
            'map': _map.copyWith(name: 'Candidate $index').toJson(),
          },
          idempotencyKey: 'lifecycle_$index',
        );
        await lifecycle.activate(root.path);
        _requireBounded(queries.diagnostics, label: 'query');
        _requireBounded(mutations.diagnostics, label: 'mutation');
      }
      stopwatch.stop();
      final rssAfter = ProcessInfo.currentRss;
      final queryDiagnostics = queries.diagnostics;
      final mutationDiagnostics = mutations.diagnostics;
      final result = <String, Object?>{
        'rootCount': rootCount,
        'elapsedUs': stopwatch.elapsedMicroseconds,
        'rssBeforeBytes': rssBefore,
        'rssAfterBytes': rssAfter,
        'rssGrowthBytes': rssAfter - rssBefore,
        'activeRoot': lifecycle.activeRoot,
        'participantCount': lifecycle.participantCount,
        'query': _diagnosticsJson(queryDiagnostics),
        'mutation': _diagnosticsJson(mutationDiagnostics),
      };
      final receipt = await performanceReceipt(
        benchmark: 'authoring_session_lifecycle',
        warmups: 0,
        sampleCount: 1,
        arguments: [
          'benchmark/authoring_session_lifecycle.dart',
          ...arguments,
        ],
        metadata: {'rootCount': rootCount, 'gcMode': 'not available in AOT'},
        results: [result],
      );
      await writePerformanceReceipt(
        outputPath: outputPath,
        packageName: 'map_editor',
        receipt: receipt,
      );
      await lifecycle.closeAll();
    } finally {
      await sandbox.delete(recursive: true);
    }
  } on FormatException catch (error) {
    stderr.writeln('authoring_session_lifecycle: ${error.message}');
    exitCode = 64;
  }
}

Future<Directory> _writeFixture(Directory sandbox, int index) async {
  final root = await Directory(p.join(sandbox.path, 'project_$index')).create();
  final maps = await Directory(p.join(root.path, 'maps')).create();
  await File(p.join(root.path, 'project.json')).writeAsString(
    jsonEncode(_project.copyWith(name: 'Lifecycle project $index').toJson()),
  );
  await File(p.join(maps.path, 'alpha.json'))
      .writeAsString(jsonEncode(_map.toJson()));
  return root;
}

void _requireBounded(
  EditorAuthoringSessionDiagnostics diagnostics, {
  required String label,
}) {
  if (diagnostics.liveSessions != 1 ||
      diagnostics.candidateRoot != null ||
      diagnostics.openingSessions != 0 ||
      diagnostics.retiringSessions != 0 ||
      diagnostics.activeOperations != 0) {
    throw StateError('$label sessions escaped the mono-project bound.');
  }
}

Map<String, Object?> _diagnosticsJson(
  EditorAuthoringSessionDiagnostics diagnostics,
) =>
    {
      'retainedRoot': diagnostics.retainedRoot,
      'candidateRoot': diagnostics.candidateRoot,
      'liveSessions': diagnostics.liveSessions,
      'openingSessions': diagnostics.openingSessions,
      'retiringSessions': diagnostics.retiringSessions,
      'activeOperations': diagnostics.activeOperations,
      'closeCount': diagnostics.closeCount,
    };

const _project = ProjectManifest(
  name: 'Lifecycle project',
  maps: [
    ProjectMapEntry(
      id: 'alpha',
      name: 'Alpha',
      relativePath: 'maps/alpha.json',
    ),
  ],
  tilesets: [],
);

const _map = MapData(
  id: 'alpha',
  name: 'Alpha',
  size: GridSize(width: 2, height: 2),
  version: ProjectVersion.v6,
  visualStack: MapVisualStackConfig.canonicalV1,
  layers: [
    MapLayer.tile(id: 'l_base', name: 'Base', cells: [0, 0, 0, 0]),
    MapLayer.smartTile(
      id: 'l_terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      field: SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
    ),
    MapLayer.collision(
      id: 'l_collisions',
      name: 'Collisions',
      collisions: [false, false, false, false],
    ),
  ],
);
