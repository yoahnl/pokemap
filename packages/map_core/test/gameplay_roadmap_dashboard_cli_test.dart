import 'dart:io';

import 'package:test/test.dart';

import 'support/dart_executable.dart';

/// Racine de dépôt jetable portant une roadmap et les rapports demandés.
///
/// Les chemins sont donnés relatifs à la racine, ce qui permet d'y poser
/// délibérément l'ANCIEN layout à côté du canonique.
Future<Directory> _temporaryRepository({
  required String roadmap,
  required Map<String, String> files,
}) async {
  final root = await Directory.systemTemp.createTemp(
    'gameplay_roadmap_dashboard_cli_',
  );
  await File(
    '${root.path}${Platform.pathSeparator}'
    'pokemap_roadmap_mecaniques_fangame.md',
  ).writeAsString(roadmap);
  for (final entry in files.entries) {
    final file = File(
      '${root.path}${Platform.pathSeparator}'
      '${entry.key.replaceAll('/', Platform.pathSeparator)}',
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
  }
  return root;
}

Future<ProcessResult> _runDashboard(Directory repositoryRoot) {
  return Process.run(
    resolveDartExecutable(),
    <String>[
      'run',
      'tool/generate_gameplay_roadmap_dashboard.dart',
      '--check',
      repositoryRoot.path,
    ],
    workingDirectory: Directory.current.path,
  );
}

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

    final result = await _runDashboard(repositoryRoot);

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

  test('dashboard CLI ignores the legacy reports layout entirely', () async {
    // Critère « layout documentation/reports/gameplay exclusif » de
    // BETA-SYS-008. Le ticket est né d'un générateur qui lisait /reports/gameplay
    // au lieu de /documentation/reports/gameplay ; le chemin canonique est
    // désormais bien épinglé, mais rien n'interdisait d'ajouter l'ancien EN PLUS
    // — c'est-à-dire la panne d'origine sous sa forme la plus probable, celle
    // d'un repli ajouté pour « être gentil ».
    //
    // Mesuré avant d'écrire ce cas : en faisant scanner les deux arborescences,
    // les 43 tests du périmètre restaient verts.
    final repositoryRoot = await _temporaryRepository(
      roadmap: '''
| ID | Lot | Statut | Preuve |
|---|---|---|---|
| FG-180 | Canonical | `TODO` | — |
| FG-181 | Legacy | `TODO` | — |
''',
      files: <String, String>{
        'documentation/reports/gameplay/fg_180_canonical.md':
            'Proposed status: TODO\n',
        // Même convention de nom, même contenu valide : seul le chemin diffère.
        // Si le lot FG-181 récolte une preuve, c'est que l'ancien layout est lu.
        'reports/gameplay/fg_181_legacy.md': 'Proposed status: TODO\n',
      },
    );
    addTearDown(() async {
      if (await repositoryRoot.exists()) {
        await repositoryRoot.delete(recursive: true);
      }
    });

    final result = await _runDashboard(repositoryRoot);
    final stdout = result.stdout as String;

    expect(
      result.exitCode,
      0,
      reason: 'stderr:\n${result.stderr}\nstdout:\n$stdout',
    );
    expect(
      stdout,
      contains('documentation/reports/gameplay/fg_180_canonical.md'),
      reason: 'the canonical report must still be found',
    );
    expect(
      stdout,
      isNot(contains('fg_181_legacy.md')),
      reason: 'a report living in the legacy tree must not appear at all',
    );
    // Et pas seulement absent du texte : le lot ne doit récolter AUCUNE preuve.
    expect(
      RegExp(r'\|\s*FG-181\s*\|[^|]*\|[^|]*\|\s*0\s*\|').hasMatch(stdout),
      isTrue,
      reason: 'FG-181 must count zero evidence:\n$stdout',
    );
  });
}
