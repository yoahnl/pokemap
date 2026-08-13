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
