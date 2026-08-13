import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('performance workflow references existing Dart entrypoints', () {
    final repositoryRoot = Directory.current.parent.parent;
    final workflow = File(
      '${repositoryRoot.path}/.github/workflows/'
      'pokemap_hub_product_certification.yml',
    ).readAsStringSync();
    final performanceJob = workflow.substring(
      workflow.indexOf('  performance-observation:'),
      workflow.indexOf('\n  windows-desktop-certification:'),
    );
    final dartEntrypoints = <File>{};
    var shellDirectory = repositoryRoot.uri;
    var stepDirectory = repositoryRoot.uri;

    for (final rawLine in performanceJob.split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith('- name:') || line.startsWith('- uses:')) {
        stepDirectory = repositoryRoot.uri;
      } else if (line.startsWith('working-directory:')) {
        final path = line.substring('working-directory:'.length).trim();
        stepDirectory = repositoryRoot.uri.resolve('$path/');
      } else if (line == 'run: |') {
        shellDirectory = stepDirectory;
      }
      if (line.startsWith('cd ')) {
        final path = line.substring(3).split(RegExp(r'\s')).first;
        final base = path.startsWith('packages/') ||
                path.startsWith('apps/') ||
                path.startsWith('examples/') ||
                path.startsWith('tools/')
            ? repositoryRoot.uri
            : shellDirectory;
        shellDirectory = base.resolve('$path/');
      }
      for (final match in RegExp(
        r'([a-z0-9_./-]+\.dart)(?=\s|\\|$)',
      ).allMatches(line)) {
        dartEntrypoints.add(
          File.fromUri(shellDirectory.resolve(match.group(1)!)),
        );
      }
    }

    expect(dartEntrypoints, isNotEmpty);
    final missing = dartEntrypoints
        .where((entrypoint) => !entrypoint.existsSync())
        .map((entrypoint) => entrypoint.path)
        .toList();
    expect(
      missing,
      isEmpty,
      reason: 'Missing performance workflow entrypoints:\n${missing.join('\n')}',
    );
  });

  test('performance workflow collects the complete PERF-000C matrix', () {
    final repositoryRoot = Directory.current.parent.parent;
    final workflow = File(
      '${repositoryRoot.path}/.github/workflows/'
      'pokemap_hub_product_certification.yml',
    ).readAsStringSync();
    final performanceJob = workflow.substring(
      workflow.indexOf('  performance-observation:'),
      workflow.indexOf('\n  windows-desktop-certification:'),
    );

    expect(
      RegExp(r'--extents 128,256,512,1024').allMatches(performanceJob),
      hasLength(2),
    );
    expect(
      performanceJob,
      contains(
        '--target=integration_test/editor_canvas_projection_journey_test.dart',
      ),
    );
  });

  test('isolates map editor functional and performance quality lanes', () {
    final repositoryRoot = Directory.current.parent.parent;
    final workflow = File(
      '${repositoryRoot.path}/.github/workflows/'
      'pokemap_hub_product_certification.yml',
    ).readAsStringSync();

    String job(String name, String nextName) {
      final start = workflow.indexOf('  $name:');
      final end = workflow.indexOf('\n  $nextName:', start);
      expect(start, greaterThanOrEqualTo(0), reason: 'Missing job: $name');
      expect(end, greaterThan(start), reason: 'Missing job: $nextName');
      return workflow.substring(start, end);
    }

    expect(workflow, isNot(contains('\n  map-editor-quality:\n')));
    final functionalJob = job(
      'map-editor-functional-quality',
      'map-editor-performance-quality',
    );
    final performanceJob = job(
      'map-editor-performance-quality',
      'map-editor-performance-gate',
    );
    expect(
      functionalJob,
      allOf(
        startsWith(
          '  map-editor-functional-quality:\n'
          '    runs-on: macos-15\n'
          '    timeout-minutes: 60\n',
        ),
        endsWith(
          '          flutter pub get\n'
          '          flutter test --no-pub --timeout 2m -r expanded\n'
          '          flutter analyze --no-pub\n',
        ),
      ),
    );
    expect(
      performanceJob,
      allOf(
        startsWith(
          '  map-editor-performance-quality:\n'
          '    runs-on: macos-15\n'
          '    timeout-minutes: 45\n',
        ),
        contains('      - name: Install pinned Flutter SDK\n'),
        contains(r'"refs/tags/$FLUTTER_VERSION:refs/tags/$FLUTTER_VERSION"'),
        contains(r'= "$FLUTTER_REVISION"'),
        contains('for run_number in 1 2 3; do'),
      ),
    );
    expect(
      RegExp(r'^          flutter pub get$', multiLine: true)
          .allMatches(performanceJob),
      hasLength(1),
    );
    expect(
      RegExp(
        r'^            flutter test --no-pub --timeout 2m -r expanded \\$',
        multiLine: true,
      ).allMatches(performanceJob),
      hasLength(1),
    );
    for (final flag in const <String>[
      '--tags performance',
      '--run-skipped',
      '--concurrency=1',
    ]) {
      expect(
        RegExp(
          '^              ${RegExp.escape(flag)} ' r'\\$',
          multiLine: true,
        ).allMatches(performanceJob),
        hasLength(1),
        reason: flag,
      );
    }

    const manifests = <String>[
      'test/cinematic_builder_characterization_performance_test.dart',
      'test/event_registry_persistence_performance_test.dart',
      'test/narrative_event_authoring_snapshot_performance_test.dart',
      'test/narrative_event_validation_incremental_performance_test.dart',
      'test/narrative_global_search_performance_test.dart',
      'test/narrative_large_project_workspace_performance_test.dart',
    ];
    final declaredManifests = RegExp(
      r'(test/[a-z0-9_]+_performance_test\.dart)',
    ).allMatches(performanceJob).map((match) => match.group(1)).toList();
    expect(declaredManifests, orderedEquals(manifests));
    expect(
      manifests.where(
        (path) => !File(
          '${repositoryRoot.path}/packages/map_editor/$path',
        ).existsSync(),
      ),
      isEmpty,
    );
    expect(
      workflow,
      allOf(
        contains(
          '\n  map-editor-performance-gate:\n'
          "    if: github.event_name != 'pull_request'\n",
        ),
        contains(
          '\n  performance-observation:\n'
          '    needs: map-editor-performance-gate\n'
          "    if: github.event_name != 'pull_request'\n",
        ),
      ),
    );
  });

  test('performance workflow has a blocking sequential PERF-009 gate', () {
    final repositoryRoot = Directory.current.parent.parent;
    final workflow =
        File(
          '${repositoryRoot.path}/.github/workflows/'
          'pokemap_hub_product_certification.yml',
        ).readAsStringSync();
    final gateStart = workflow.indexOf('  map-editor-performance-gate:');
    expect(gateStart, greaterThanOrEqualTo(0));
    if (gateStart < 0) return;
    final gate = workflow.substring(
      gateStart,
      workflow.indexOf('\n  performance-observation:'),
    );
    const soakTarget =
        '--target=integration_test/editor_performance_soak_journey_test.dart';
    const fineMaskTarget =
        '--target=integration_test/editor_fine_mask_journey_test.dart';

    expect(gate, isNot(contains('continue-on-error: true')));
    expect(gate, contains('test/performance_driver_contract_test.dart'));
    expect(gate, contains('test/fine_mask_performance_contract_test.dart'));
    expect(
      gate,
      contains('--target=integration_test/editor_project_journey_test.dart'),
    );
    expect(
      gate,
      contains(
        '--target=integration_test/editor_canvas_projection_journey_test.dart',
      ),
    );
    expect(gate, contains(soakTarget));
    expect(gate, contains(fineMaskTarget));
    expect(gate.indexOf(soakTarget), lessThan(gate.indexOf(fineMaskTarget)));
    expect(gate, contains('POKEMAP_PERF_SOAK_MINUTES='));
    expect(gate, contains('if-no-files-found: error'));
    expect(
      workflow,
      contains(
        'performance_soak_minutes:\n'
        '        description: Run the editor paint and undo soak for this many minutes\n'
        '        required: true\n'
        '        default: 30',
      ),
    );
    expect(
      File(
        '${repositoryRoot.path}/packages/map_editor/integration_test/'
        'editor_performance_soak_journey_test.dart',
      ).existsSync(),
      isTrue,
    );
  });
}
