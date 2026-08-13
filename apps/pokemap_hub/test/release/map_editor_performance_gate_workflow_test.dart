import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('map editor performance gate is blocking and preserves four receipts', () {
    final repositoryRoot = Directory.current.parent.parent;
    final workflow = File(
      '${repositoryRoot.path}/.github/workflows/map_editor_performance_gate.yml',
    ).readAsStringSync();

    const projectTarget =
        '--target=integration_test/editor_project_journey_test.dart';
    const canvasTarget =
        '--target=integration_test/editor_canvas_projection_journey_test.dart';
    const soakTarget =
        '--target=integration_test/editor_performance_soak_journey_test.dart';
    const fineMaskTarget =
        '--target=integration_test/editor_fine_mask_journey_test.dart';

    expect(workflow, contains('map-editor-performance-gate:'));
    expect(workflow, isNot(contains('continue-on-error: true')));
    expect(workflow, contains('test/performance_driver_contract_test.dart'));
    expect(workflow, contains('test/fine_mask_performance_contract_test.dart'));
    expect(workflow, contains(projectTarget));
    expect(workflow, contains(canvasTarget));
    expect(workflow, contains(soakTarget));
    expect(workflow, contains(fineMaskTarget));
    expect(workflow.indexOf(projectTarget), lessThan(workflow.indexOf(canvasTarget)));
    expect(workflow.indexOf(canvasTarget), lessThan(workflow.indexOf(soakTarget)));
    expect(workflow.indexOf(soakTarget), lessThan(workflow.indexOf(fineMaskTarget)));
    expect(workflow, contains('performance_soak_minutes:'));
    expect(workflow, contains('default: 30'));
    expect(workflow, contains("github.head_ref == 'codex/perf-009-soak-gate-v2' && 30"));
    expect(workflow, contains('if-no-files-found: error'));
    expect(workflow, contains('editor_project_journey.json'));
    expect(workflow, contains('editor_canvas_projection_journey.json'));
    expect(workflow, contains('editor_performance_soak_journey.json'));
    expect(workflow, contains('editor_fine_mask_journey.json'));
  });
}
