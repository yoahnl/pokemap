import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('dashboard CLI reads gameplay reports from documentation tree', () async {
    final repositoryRoot = await Directory.systemTemp.createTemp(
      'gameplay_roadmap_dashboard_cli_',
    );
    addTearDown(() async {
      if (await repositoryRoot.exists()) {
        await repositoryRoot.delete(recursive: true);
      }
    });

    await File(
      '${repositoryRoot.path}${Platform.pathSeparator}'
      'pokemap_roadmap_mecaniques_fangame.md',
    ).writeAsString('''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Readiness | `TODO` | — |
''');

    final reportsDirectory = Directory(
      '${repositoryRoot.path}${Platform.pathSeparator}'
      'documentation${Platform.pathSeparator}'
      'reports${Platform.pathSeparator}gameplay',
    );
    await reportsDirectory.create(recursive: true);
    await File(
      '${reportsDirectory.path}${Platform.pathSeparator}fg_180_report.md',
    ).writeAsString('Proposed status: TODO\n');

    final result = await Process.run(
      Platform.resolvedExecutable,
      [
        'run',
        'tool/generate_gameplay_roadmap_dashboard.dart',
        '--check',
        repositoryRoot.path,
      ],
      workingDirectory: Directory.current.path,
    );

    expect(
      result.exitCode,
      0,
      reason: 'stderr:\n${result.stderr}\nstdout:\n${result.stdout}',
    );
    expect(
      result.stdout,
      contains('documentation/reports/gameplay/fg_180_report.md'),
    );
  });
}
