import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repositoryRoot = Directory.current.parent.parent;

  String workflow(String name) =>
      File('${repositoryRoot.path}/.github/workflows/$name').readAsStringSync();

  String triggers(String source) => source.substring(
    source.indexOf('on:\n'),
    source.indexOf('\npermissions:'),
  );

  test('automatic commits run one bounded Linux workflow', () {
    final source = workflow('pokemap_quick_checks.yml');
    final markdownSource = workflow('markdown_hygiene.yml');

    expect(source, startsWith('name: PokeMap quick checks\n'));
    expect(
      triggers(source),
      allOf(
        contains('  pull_request:\n'),
        contains('  push:\n    branches: [main]\n'),
      ),
    );
    expect(source, contains('runs-on: ubuntu-24.04'));
    expect(source, contains('timeout-minutes: 15'));
    expect(source, contains('cancel-in-progress: true'));
    expect('"apps/avelune_studio/**"'.allMatches(source), hasLength(2));
    expect('"apps/Avelune iOS/**"'.allMatches(source), hasLength(2));
    expect('"apps/avelune_android/**"'.allMatches(source), hasLength(2));
    expect('"apps/pokemap_hub/lib/**"'.allMatches(source), hasLength(2));
    expect(source, isNot(contains('"apps/pokemap_hub/**"')));
    expect(source, isNot(contains('working-directory: apps/pokemap_hub')));
    expect(source, contains('test_native_host_contracts.py'));
    expect(source, contains('working-directory: apps/avelune_studio'));
    expect(source, contains('test/app/studio_bootstrap_test.dart'));
    expect(source, contains('test/home/recent_projects_test.dart'));
    expect(
      source,
      contains('test/project_session/scoped_project_session_adapter_test.dart'),
    );
    expect(source, contains('flutter analyze --no-pub'));
    expect(source, contains('dart analyze'));
    expect(source, contains('test/map_editing_controller_test.dart'));
    expect(source, isNot(contains('test/editor_shell_page_smoke_test.dart')));
    expect(source, isNot(contains('flutter build')));
    expect(source, isNot(contains('flutter drive')));
    expect(source, isNot(contains('upload-artifact')));
    expect(source, isNot(contains('macos-')));
    expect(source, isNot(contains('windows-')));
    expect(markdownSource, contains('cancel-in-progress: true'));
  });

  test('remaining distribution and certification workflows are opt-in', () {
    final heavyweightWorkflows = <String, String>{
      'pokemap_desktop_release.yml': 'tags: ["pokemap-v*"]',
    };

    for (final entry in heavyweightWorkflows.entries) {
      final source = workflow(entry.key);
      final triggerSource = triggers(source);

      expect(triggerSource, contains('  workflow_dispatch:'));
      expect(triggerSource, contains(entry.value));
      expect(triggerSource, isNot(contains('  pull_request:')));
      expect(triggerSource, isNot(contains('    branches: [main]')));
    }

    expect(
      triggers(workflow('pokemap_product_certification.yml')),
      contains('  workflow_dispatch:'),
    );

    expect(
      triggers(workflow('beta_perf_009_certification.yml')),
      'on:\n  workflow_dispatch:\n',
    );
  });
}
