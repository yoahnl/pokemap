import 'dart:io';

import 'package:test/test.dart';

const _forbiddenStoryImports = [
  'package:flutter/',
  'package:flame',
  'dart:ui',
  'dart:io',
  'package:map_gameplay/',
  'package:map_runtime/',
  'package:map_authoring/',
  'package:map_editor/',
  'package:map_player_ui/',
  'package:map_distribution/',
];

const _movedSources = [
  '../map_core/lib/src/runtime/scene_execution_context.dart',
  '../map_core/lib/src/runtime/scene_runtime_plan.dart',
  '../map_core/lib/src/runtime/scene_runtime_plan_builder.dart',
  '../map_core/lib/src/runtime/scene_runtime_executor.dart',
  '../map_core/lib/src/runtime/scene_runtime_dry_run_preview.dart',
  '../map_core/lib/src/runtime/scene_structured_interaction_port.dart',
  '../map_gameplay/lib/src/narrative_event_dispatch_planner.dart',
  '../map_gameplay/lib/src/narrative_event_execution_coordinator.dart',
  '../map_gameplay/lib/src/narrative_event_state_transactions.dart',
  '../map_gameplay/lib/src/narrative_outcome_outbox_processor.dart',
  '../map_gameplay/lib/src/narrative_parallel_scheduler.dart',
  '../map_gameplay/lib/src/narrative_trigger_enter_fronts.dart',
];

const _consumerRoots = [
  '../map_core',
  '../map_gameplay',
  '../map_runtime',
  '../map_authoring',
  '../map_editor',
  '../map_player_ui',
  '../map_distribution',
  '../avelune_converter_adapters',
  '../../apps/avelune_studio',
  '../../apps/pokemap_hub',
  '../../apps/avelune_converter',
  '../../tools/avelune_converter_cli',
  '../../tools/pokemap_product_certification',
  '../../examples/playable_runtime_host',
];

Iterable<File> _dartFiles(String root) sync* {
  for (final folder in ['lib', 'test', 'tool', 'bin']) {
    final directory = Directory('$root/$folder');
    if (!directory.existsSync()) continue;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) yield entity;
    }
  }
}

Iterable<String> _directives(File file) => file
    .readAsLinesSync()
    .where((line) => line.startsWith('import ') || line.startsWith('export '));

void main() {
  test('map_story production code stays pure Dart and below its consumers', () {
    final offenders = <String>[];
    for (final file in _dartFiles('.').where((f) => f.path.contains('/lib/'))) {
      for (final directive in _directives(file)) {
        if (_forbiddenStoryImports.any(directive.contains)) {
          offenders.add('${file.path}: $directive');
        }
      }
    }
    expect(offenders, isEmpty);
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final forbidden in [
      'flutter',
      'flame',
      'map_gameplay',
      'map_runtime',
      'map_authoring',
      'map_editor',
      'map_player_ui',
      'map_distribution',
    ]) {
      expect(pubspec, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('map_core never depends on map_story, even in its tests', () {
    expect(File('../map_core/pubspec.yaml').readAsStringSync(),
        isNot(contains('map_story')));
    final offenders = [
      for (final file in _dartFiles('../map_core'))
        for (final directive in _directives(file))
          if (directive.contains('package:map_story/')) '${file.path}: $directive',
    ];
    expect(offenders, isEmpty);
  });

  test('moved implementations have no copy left at their former paths', () {
    expect(
      [for (final path in _movedSources) if (File(path).existsSync()) path],
      isEmpty,
    );
  });

  test('consumers only use the public map_story barrel', () {
    final offenders = [
      for (final root in _consumerRoots)
        for (final file in _dartFiles(root))
          for (final directive in _directives(file))
            if (directive.contains('package:map_story/src/'))
              '${file.path}: $directive',
    ];
    expect(offenders, isEmpty);
  });
}
