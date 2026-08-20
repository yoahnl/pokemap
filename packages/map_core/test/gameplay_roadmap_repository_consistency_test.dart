import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('repository roadmap has unique coherent canonical gameplay lots',
      () async {
    final roadmapFile = File('../../pokemap_roadmap_mecaniques_fangame.md');
    final reportsDirectory = Directory('../../documentation/reports/gameplay');
    final reports = <String, String>{};
    await for (final entity in reportsDirectory.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
        continue;
      }
      final relativePath = entity.path
          .substring(reportsDirectory.path.length + 1)
          .replaceAll(Platform.pathSeparator, '/');
      reports['documentation/reports/gameplay/$relativePath'] =
          await entity.readAsString();
    }

    final dashboard = GameplayRoadmapDashboard.build(
      roadmapMarkdown: await roadmapFile.readAsString(),
      gameplayReports: reports,
    );
    final ids = dashboard.entries.map((entry) => entry.id).toList();

    expect(dashboard.diagnostics, isEmpty);
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.where((id) => id == 'FG-024'), hasLength(1));
  });

  /// Citations de preuve de la roadmap : chemin canonique et existence réelle.
  ///
  /// BETA-SYS-008 portait sur un générateur qui lisait le mauvais chemin. En le
  /// vérifiant, la roadmap elle-même s'est révélée pointer l'ancien layout — et
  /// pour la plupart, des fichiers qui n'existent nulle part. Le tableau de bord
  /// n'est donc pas vide par défaut d'outil, il est vide parce que le placard
  /// l'est.
  ///
  /// Les deux ensembles sont figés À L'IDENTIQUE, pas par un compteur. En
  /// ajouter un fait échouer la suite ; en résoudre un aussi, ce qui force à
  /// mettre la liste à jour au lieu de payer la dette en silence. Même forme que
  /// le catalogue de volatiles de map_battle.
  group('BETA-SYS-008 roadmap evidence citations', () {
    /// Chemins entre accents graves contenant `reports/gameplay` et finissant
    /// en `.md`, tels que la roadmap les promet.
    Set<String> citedEvidencePaths(String roadmap) {
      return RegExp(r'`([^`]*reports/gameplay/[^`]*\.md)`')
          .allMatches(roadmap)
          .map((match) => match.group(1)!)
          // `fg_xxx_<slug>.md` documente la convention de nommage : c'est un
          // gabarit, pas une promesse de preuve.
          .where((path) => !path.contains('fg_xxx_'))
          .toSet();
    }

    late String roadmap;

    setUpAll(() async {
      roadmap =
          await File('../../pokemap_roadmap_mecaniques_fangame.md').readAsString();
    });

    test('the roadmap cites evidence at all', () {
      // Garde du garde : une extraction rendant l'ensemble vide ferait passer
      // les deux cas suivants sans rien vérifier.
      expect(citedEvidencePaths(roadmap), hasLength(greaterThanOrEqualTo(8)));
    });

    test('citations still living in the legacy layout are exactly these six',
        () {
      // Le layout canonique est `documentation/reports/gameplay`. Ces six
      // citations datent d'avant le déplacement ; les réécrire sans écrire les
      // rapports transformerait un pointeur cassé en pointeur cassé autrement,
      // donc elles restent en attente de BETA-SYS-007.
      final legacy = citedEvidencePaths(roadmap)
          .where((path) => !path.startsWith('documentation/'))
          .toSet();

      expect(
        legacy,
        <String>{
          'reports/gameplay/fg_165_runtime_input_lock_conventions_v0_revalidation_2026-07-26.md',
          'reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md',
          'reports/gameplay/fg_181_golden_slice_fangame_fixture_v0.md',
          'reports/gameplay/fg_182_golden_slice_end_to_end_smoke_v0.md',
          'reports/gameplay/fg_183_regression_matrix_v0.md',
          'reports/gameplay/fg_185_mvp_release_gate_v0.md',
        },
      );
    });

    test('citations pointing at no file at all are exactly these seven', () {
      // Sept promesses sans fichier. FG-184 est sorti de cette liste le
      // 2026-08-20 en recevant son rapport : c'est la seule citation de la
      // roadmap qu'un fichier réel satisfait aujourd'hui.
      final missing = <String>{};
      for (final path in citedEvidencePaths(roadmap)) {
        if (!File('../../$path').existsSync()) missing.add(path);
      }

      expect(
        missing,
        <String>{
          'documentation/reports/gameplay/fangame_mechanics_roadmap.md',
          'reports/gameplay/fg_165_runtime_input_lock_conventions_v0_revalidation_2026-07-26.md',
          'reports/gameplay/fg_180_project_gameplay_readiness_report_v0.md',
          'reports/gameplay/fg_181_golden_slice_fangame_fixture_v0.md',
          'reports/gameplay/fg_182_golden_slice_end_to_end_smoke_v0.md',
          'reports/gameplay/fg_183_regression_matrix_v0.md',
          'reports/gameplay/fg_185_mvp_release_gate_v0.md',
        },
      );
    });

    test('the dashboard lot that owns the generator carries its evidence',
        () async {
      // Bout en bout : le générateur de tableau de bord est lui-même un lot, et
      // il affichait MISSING pour lui. Sans ce cas, supprimer son rapport
      // repasserait inaperçu.
      final reportsDirectory = Directory('../../documentation/reports/gameplay');
      final reports = <String, String>{};
      await for (final entity
          in reportsDirectory.list(recursive: true, followLinks: false)) {
        if (entity is! File || !entity.path.toLowerCase().endsWith('.md')) {
          continue;
        }
        final relativePath = entity.path
            .substring(reportsDirectory.path.length + 1)
            .replaceAll(Platform.pathSeparator, '/');
        reports['documentation/reports/gameplay/$relativePath'] =
            await entity.readAsString();
      }

      final dashboard = GameplayRoadmapDashboard.build(
        roadmapMarkdown: roadmap,
        gameplayReports: reports,
      );
      final generatorLot =
          dashboard.entries.singleWhere((entry) => entry.id == 'FG-184');

      expect(generatorLot.evidencePaths, isNotEmpty);
      expect(
        generatorLot.evidencePaths.single,
        startsWith('documentation/reports/gameplay/fg_184_'),
      );
    });
  });
}
