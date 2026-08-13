import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final repositoryRoot = Directory.current.parent.parent;

  String workflow(String name) => File(
        '${repositoryRoot.path}/.github/workflows/$name',
      ).readAsStringSync();

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

  test('distribution and certification workflows are opt-in or tagged', () {
    final heavyweightWorkflows = <String, String>{
      'avelune_android_release.yml': 'tags: ["avelune-v*"]',
      'pokemap_desktop_release.yml': 'tags: ["pokemap-v*"]',
      'pokemap_hub_product_certification.yml': 'tags: ["pokemap-hub-v*"]',
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
      triggers(workflow('beta_perf_009_certification.yml')),
      'on:\n  workflow_dispatch:\n',
    );
  });
}
