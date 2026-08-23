import 'dart:io';

/// BETA-BAT-016 — embarque les planches des transitions de début de combat.
///
/// Même précédent que les 181 planches d'animations et les sons de combat :
/// les visuels viennent du projet de test PSDK que Yoahn a désigné comme
/// source le 2026-08-23 (`graphics/transitions/spritesheets/`), et le dépôt
/// n'embarque que ce que le périmètre bêta consomme : la planche sauvage RBY
/// (10×3) et les deux planches dresseur Diamant/Perle/Platine (3×4).
///
/// Usage :
///   dart run tool/import_battle_transition_assets.dart \
///     "/chemin/vers/pokémon_sdk_test_project"
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/import_battle_transition_assets.dart '
      '<sdk_project_root>',
    );
    exitCode = 64;
    return;
  }

  final sourceDirectory = Directory(
    '${arguments.single}/graphics/transitions/spritesheets',
  );
  if (!sourceDirectory.existsSync()) {
    stderr.writeln('Source introuvable: ${sourceDirectory.path}');
    exitCode = 66;
    return;
  }

  const sheetFileNames = <String>[
    'rby_wild.png',
    'diamant_perle_trainer_01.png',
    'diamant_perle_trainer_02.png',
  ];

  final targetDirectory = Directory('assets/transitions');
  targetDirectory.createSync(recursive: true);

  final copied = <String>[];
  for (final fileName in sheetFileNames) {
    final source = File('${sourceDirectory.path}/$fileName');
    if (!source.existsSync()) {
      stderr.writeln('Planche absente de la source: $fileName');
      exitCode = 65;
      return;
    }
    source.copySync('${targetDirectory.path}/$fileName');
    copied.add(fileName);
  }

  final manifest = StringBuffer()
    ..writeln('// GÉNÉRÉ par tool/import_battle_transition_assets.dart —')
    ..writeln('// ne pas éditer à la main, relancer l\'outil.')
    ..writeln()
    ..writeln('/// Les planches de transition embarquées — BETA-BAT-016.')
    ..writeln('const Map<String, String> battleTransitionSheetManifest =')
    ..writeln('    <String, String>{');
  for (final fileName in copied) {
    final key = fileName.replaceAll('.png', '');
    manifest.writeln("  '$key': '$fileName',");
  }
  manifest
    ..writeln('};')
    ..writeln();
  File('lib/src/presentation/flame/battle_transition_manifest.dart')
      .writeAsStringSync(manifest.toString());

  stdout.writeln('${copied.length} planches copiées, manifeste écrit.');
}
