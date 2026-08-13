import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('CLI reads gameplay reports from the canonical documentation tree', () async {
    final temporaryRoot = await Directory.systemTemp.createTemp(
      'pokemap_dashboard_documentation_layout_',
    );
    addTearDown(() => temporaryRoot.delete(recursive: true));
    final reportsDirectory = Directory(
      '${temporaryRoot.path}${Platform.pathSeparator}documentation'
      '${Platform.pathSeparator}reports${Platform.pathSeparator}gameplay',
    );
    await reportsDirectory.create(recursive: true);
    await File(
      '${temporaryRoot.path}${Platform.pathSeparator}'
      'pokemap_roadmap_mecaniques_fangame.md',
    ).writeAsString('''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `⬜ TODO` | — |
''');
    await File(
      '${reportsDirectory.path}${Platform.pathSeparator}'
      'fg_180_readiness.md',
    ).writeAsString('Repository layout evidence.\n');

    final result = await Process.run(
      Platform.resolvedExecutable,
      <String>[
        'run',
        'tool/generate_gameplay_roadmap_dashboard.dart',
        '--check',
        temporaryRoot.path,
      ],
      workingDirectory: Directory.current.path,
    );

    expect(result.exitCode, 0);
    expect(result.stderr, isEmpty);
  });
}
