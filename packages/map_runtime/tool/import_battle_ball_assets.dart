import 'dart:io';

/// BETA-BAT-022 — embarque les planches de Poké Ball de la référence.
///
/// Même précédent que les planches de transitions : la source est le projet
/// de test PSDK (`graphics/ball/`), qui porte une planche verticale 64×2048
/// par type de Ball (32 cellules de 64×64 : vol 0-3, ouverture 4-5, fermeture
/// 6-14, secousses, casse, capture) plus `ball-retreat`. Le runtime consomme
/// les cellules de vol et d'ouverture pour la sortie de Ball en début de
/// combat et aux remplacements.
///
/// Usage :
///   dart run tool/import_battle_ball_assets.dart \
///     "/chemin/vers/pokémon_sdk_test_project"
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/import_battle_ball_assets.dart '
      '<sdk_project_root>',
    );
    exitCode = 64;
    return;
  }

  final sourceDirectory = Directory('${arguments.single}/graphics/ball');
  if (!sourceDirectory.existsSync()) {
    stderr.writeln('Source introuvable: ${sourceDirectory.path}');
    exitCode = 66;
    return;
  }

  final targetDirectory = Directory('assets/battle/balls');
  targetDirectory.createSync(recursive: true);

  final copied = <String>[];
  final sources = sourceDirectory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.toLowerCase().endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final source in sources) {
    final fileName = source.uri.pathSegments.last.toLowerCase();
    source.copySync('${targetDirectory.path}/$fileName');
    copied.add(fileName);
  }

  final manifest = StringBuffer()
    ..writeln('// GÉNÉRÉ par tool/import_battle_ball_assets.dart —')
    ..writeln('// ne pas éditer à la main, relancer l\'outil.')
    ..writeln()
    ..writeln('/// Les planches de Poké Ball embarquées — BETA-BAT-022.')
    ..writeln('const Map<String, String> battleBallSheetManifest =')
    ..writeln('    <String, String>{');
  for (final fileName in copied) {
    final key = fileName.replaceAll('.png', '');
    manifest.writeln("  '$key': '$fileName',");
  }
  manifest
    ..writeln('};')
    ..writeln();
  File('lib/src/presentation/flame/battle_ball_manifest.dart')
      .writeAsStringSync(manifest.toString());

  stdout.writeln('${copied.length} planches de Ball copiées, manifeste écrit.');
}
