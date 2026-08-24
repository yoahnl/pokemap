import 'dart:io';

/// BETA-BAT-021 — embarque les planches d'aura de changement de stats.
///
/// Même précédent que les planches de transitions et de Poké Ball : la source
/// est le projet de test PSDK (`graphics/animations/`), qui porte deux
/// planches 2400×2000 — `stat_up` et `stat_down` — soit 12 colonnes × 10
/// lignes de cellules 200×200, jouées d'un bloc en 1,5 s par
/// `UI::StatAnimation`.
///
/// Usage :
///   dart run tool/import_battle_stat_assets.dart \
///     "/chemin/vers/pokémon_sdk_test_project"
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/import_battle_stat_assets.dart <sdk_project_root>',
    );
    exitCode = 64;
    return;
  }

  final sourceDirectory = Directory('${arguments.single}/graphics/animations');
  if (!sourceDirectory.existsSync()) {
    stderr.writeln('Source introuvable: ${sourceDirectory.path}');
    exitCode = 66;
    return;
  }

  final targetDirectory = Directory('assets/battle/stats')
    ..createSync(recursive: true);

  const sheetFileNames = <String>['stat_up.png', 'stat_down.png'];
  final copied = <String>[];
  final missing = <String>[];
  for (final fileName in sheetFileNames) {
    final source = File('${sourceDirectory.path}/$fileName');
    if (!source.existsSync()) {
      missing.add(fileName);
      continue;
    }
    source.copySync('${targetDirectory.path}/$fileName');
    copied.add(fileName);
  }

  final manifest = StringBuffer()
    ..writeln('// GÉNÉRÉ par tool/import_battle_stat_assets.dart —')
    ..writeln('// ne pas éditer à la main, relancer l\'outil.')
    ..writeln()
    ..writeln('/// Les planches d\'aura de stats embarquées — BETA-BAT-021.')
    ..writeln('///')
    ..writeln('/// Grille de la référence : 12 colonnes × 10 lignes, jouées')
    ..writeln('/// d\'un bloc en 1,5 s (`UI::StatAnimation`).')
    ..writeln('const Map<String, String> battleStatSheetManifest =')
    ..writeln('    <String, String>{');
  for (final fileName in copied) {
    manifest.writeln("  '${fileName.replaceAll('.png', '')}': '$fileName',");
  }
  manifest
    ..writeln('};')
    ..writeln()
    ..writeln('/// Les colonnes de la grille de la référence.')
    ..writeln('const int battleStatSheetColumns = 12;')
    ..writeln()
    ..writeln('/// Les lignes de la grille de la référence.')
    ..writeln('const int battleStatSheetRows = 10;');
  File('lib/src/presentation/flame/battle_stat_sheet_manifest.dart')
      .writeAsStringSync(manifest.toString());

  stdout.writeln(
    'embedded=${copied.length} missing=${missing.length} '
    '${missing.isEmpty ? '' : missing.join(', ')}',
  );
}
