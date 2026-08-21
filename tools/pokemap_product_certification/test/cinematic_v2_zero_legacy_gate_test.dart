import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final repositoryRoot = _repositoryRoot();

  test('CIN-010 removes every executable cinematic legacy surface', () {
    const forbiddenPaths = <String>[
      '.cursor/cutscene_studio_rules.md',
      'packages/map_editor/analyze.txt',
      'packages/map_editor/analyze_output.txt',
      'packages/map_runtime/lib/src/application/cutscene_runtime_models.dart',
      'packages/map_runtime/lib/src/application/cutscene_runtime_runner.dart',
      'packages/map_runtime/test/cutscene_runtime_runner_test.dart',
    ];

    final remaining = <String>[
      for (final relativePath in forbiddenPaths)
        if (File(p.join(repositoryRoot.path, relativePath)).existsSync())
          relativePath,
    ];

    expect(remaining, isEmpty);
  });

  test('CIN-010 production sources expose no active legacy symbol', () {
    final matches = _scanProductionSources(repositoryRoot, <RegExp>[
      RegExp(r'RuntimeCutsceneAsset'),
      RegExp(r'RuntimeCutsceneStep'),
      RegExp(r'CutsceneRuntimeRunner'),
      RegExp(r'CutsceneRuntimeContext'),
      RegExp(r'cutscene_runtime_(models|runner)'),
      RegExp(r'CutsceneStudio'),
      RegExp(r'Cutscene Studio'),
      RegExp(r'cinematicLegacy'),
      RegExp(r'scenarioBridge'),
      RegExp(r'EditorWorkspaceMode\.cutscene'),
      RegExp(r'selectCutsceneWorkspace'),
      RegExp(r'workspace\.cutscene'),
    ]);

    expect(matches, isEmpty);
  });

  test('CIN-010 keeps removed formats as fail-closed tombstones only', () {
    const allowedByToken = <String, Set<String>>{
      'legacyBridge': <String>{
        'packages/map_core/lib/src/models/cinematic_asset.dart',
        'packages/map_core/lib/src/models/project_manifest.dart',
      },
      'authoring.cutsceneSchema': <String>{
        'packages/map_core/lib/src/models/project_manifest.dart',
      },
      "actionId.startsWith('scenario.')": <String>{
        'packages/map_authoring/lib/src/application/map_mutation_dispatcher.dart',
      },
    };

    for (final entry in allowedByToken.entries) {
      final files = _productionFilesContaining(repositoryRoot, entry.key);
      expect(files, entry.value, reason: entry.key);
    }

    final cinematicAsset = _read(
      repositoryRoot,
      'packages/map_core/lib/src/models/cinematic_asset.dart',
    );
    final projectManifest = _read(
      repositoryRoot,
      'packages/map_core/lib/src/models/project_manifest.dart',
    );
    final dispatcher = _read(
      repositoryRoot,
      'packages/map_authoring/lib/src/application/map_mutation_dispatcher.dart',
    );

    expect(cinematicAsset, contains('is no longer supported'));
    expect(projectManifest, contains('legacy_cinematic_bridge_unsupported'));
    expect(projectManifest, contains('legacy_cinematic_scenario_unsupported'));
    expect(dispatcher, contains('cinematic.capability_removed'));
  });

  test('CIN-010 leaves no repository project data the runtime refuses', () {
    final offenders = <String>[];
    for (final file in _projectManifestFiles(repositoryRoot)) {
      final relativePath = p.relative(file.path, from: repositoryRoot.path);
      final Object? decoded;
      try {
        decoded = jsonDecode(file.readAsStringSync());
      } on FormatException {
        offenders.add('$relativePath: not readable as JSON');
        continue;
      }
      if (decoded is! Map) {
        offenders.add('$relativePath: not a JSON object');
        continue;
      }
      offenders.addAll(
        _refusedCinematicPaths(
          decoded,
        ).map((jsonPath) => '$relativePath: $jsonPath'),
      );
    }

    expect(offenders, isEmpty);
  });

  test('CIN-010 preserves both canonical cinematic families', () {
    const canonicalPaths = <String>[
      'packages/map_core/lib/src/models/cinematic_asset.dart',
      'packages/map_core/lib/src/models/presentation_cinematic_asset.dart',
      'packages/map_runtime/lib/src/application/scene_runtime/cinematic_runtime_playback_controller.dart',
      'packages/map_runtime/lib/src/player/runtime_presentation_scene_playback_controller.dart',
      'packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart',
    ];

    for (final relativePath in canonicalPaths) {
      expect(
        File(p.join(repositoryRoot.path, relativePath)).existsSync(),
        isTrue,
        reason: relativePath,
      );
    }
  });
}

/// Every project manifest committed to the repository — authored projects,
/// golden slices and test fixtures alike. Data that the strict decoder refuses
/// is data no host can load, and the production-source scan above cannot see
/// it: BETA-CIN-043 removed the legacy format without migrating the manifests
/// that still carried it, and Selbrume stayed unloadable until BETA-CIN-082.
Iterable<File> _projectManifestFiles(Directory repositoryRoot) sync* {
  const skippedDirectories = <String>{
    '.git',
    '.dart_tool',
    '.pokemap-store',
    'build',
    'node_modules',
  };
  final pending = <Directory>[repositoryRoot];
  while (pending.isNotEmpty) {
    final directory = pending.removeLast();
    final List<FileSystemEntity> entries;
    try {
      entries = directory.listSync(followLinks: false);
    } on FileSystemException {
      continue;
    }
    for (final entry in entries) {
      if (entry is Directory) {
        if (!skippedDirectories.contains(p.basename(entry.path))) {
          pending.add(entry);
        }
      } else if (entry is File && p.basename(entry.path) == 'project.json') {
        yield entry;
      }
    }
  }
}

/// The exact JSON paths `_preflightRemovedCinematicJson` refuses, resolved
/// semantically rather than by token so a manifest cannot smuggle one through
/// formatting.
List<String> _refusedCinematicPaths(Map<Object?, Object?> manifest) {
  final refused = <String>[];
  final cinematics = manifest['cinematics'];
  if (cinematics is List) {
    for (var index = 0; index < cinematics.length; index++) {
      final cinematic = cinematics[index];
      if (cinematic is Map && cinematic.containsKey('legacyBridge')) {
        refused.add(r'$.cinematics[' '$index' '].legacyBridge');
      }
    }
  }
  final scenarios = manifest['scenarios'];
  if (scenarios is List) {
    for (var index = 0; index < scenarios.length; index++) {
      final scenario = scenarios[index];
      if (scenario is! Map) continue;
      final metadata = scenario['metadata'];
      if (metadata is Map && metadata.containsKey('authoring.cutsceneSchema')) {
        refused.add(
          r'$.scenarios[' '$index' '].metadata.authoring.cutsceneSchema',
        );
      }
    }
  }
  return refused;
}

Directory _repositoryRoot() {
  var current = Directory.current.absolute;
  while (current.parent.path != current.path) {
    if (File(p.join(current.path, 'AGENTS.md')).existsSync() &&
        Directory(p.join(current.path, 'packages', 'map_core')).existsSync()) {
      return current;
    }
    current = current.parent;
  }
  throw StateError('PokeMap repository root not found.');
}

List<String> _scanProductionSources(
  Directory repositoryRoot,
  List<RegExp> patterns,
) {
  final matches = <String>[];
  for (final file in _productionSourceFiles(repositoryRoot)) {
    final relativePath = p.relative(file.path, from: repositoryRoot.path);
    final lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      if (patterns.any((pattern) => pattern.hasMatch(lines[index]))) {
        matches.add('$relativePath:${index + 1}:${lines[index].trim()}');
      }
    }
  }
  return matches;
}

Set<String> _productionFilesContaining(Directory repositoryRoot, String token) {
  return <String>{
    for (final file in _productionSourceFiles(repositoryRoot))
      if (file.readAsStringSync().contains(token))
        p.relative(file.path, from: repositoryRoot.path),
  };
}

Iterable<File> _productionSourceFiles(Directory repositoryRoot) sync* {
  const roots = <String>[
    'packages/map_core/lib',
    'packages/map_authoring/lib',
    'packages/map_runtime/lib',
    'packages/map_player_ui/lib',
    'packages/map_editor/lib',
    'packages/map_distribution/lib',
    'apps/pokemap_hub/lib',
    'examples/playable_runtime_host/lib',
    'tools/pokemap_mcp/src',
    '.cursor',
  ];
  for (final relativeRoot in roots) {
    final directory = Directory(p.join(repositoryRoot.path, relativeRoot));
    if (!directory.existsSync()) {
      continue;
    }
    yield* directory
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where(
          (file) => const <String>{
            '.dart',
            '.ts',
            '.md',
          }.contains(p.extension(file.path)),
        );
  }
}

String _read(Directory repositoryRoot, String relativePath) {
  return File(p.join(repositoryRoot.path, relativePath)).readAsStringSync();
}
