// Vérificateur de l'asset binaire du catalogue d'animations RMXP.
//
// Historique : ce script a servi une fois à sérialiser le catalogue depuis
// son ancienne forme Dart const (282k lignes, supprimée depuis) vers
// assets/battle_animations/rmxp_animation_catalog.bin, avec validation
// round-trip complète avant écriture. Les données SDK sources
// (Animations.rxdata.yml, PSP_*.dat) n'étant plus dans le repo, l'asset
// binaire est désormais la source de vérité ; pour le régénérer depuis un
// projet SDK, voir tool/import_pokemon_sdk_rmxp_animations.py.
//
// Usage : dart run tool/export_rmxp_animation_catalog_asset.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_codec.dart';

void main() {
  final file = File('assets/battle_animations/rmxp_animation_catalog.bin');
  if (!file.existsSync()) {
    stderr.writeln('Missing asset: ${file.path}');
    exitCode = 1;
    return;
  }
  final bytes = Uint8List.fromList(file.readAsBytesSync());
  final catalog = decodeRmxpAnimationCatalog(bytes);
  var frames = 0;
  var cells = 0;
  var timings = 0;
  for (final spec in catalog.values) {
    frames += spec.frames.length;
    timings += spec.timings.length;
    for (final frame in spec.frames) {
      cells += frame.cells.length;
    }
  }
  stdout.writeln(
    'OK: ${catalog.length} animations, $frames frames, $cells cells, '
    '$timings timings (${bytes.length} bytes).',
  );
}
