import 'dart:convert';
import 'dart:io';

import 'package:map_editor/src/application/seeds/pokemon_moves_bootstrap_seed.dart';

/// Exporte le seed moves bootstrap embarqué vers stdout en JSON canonique.
///
/// Phase A a besoin d'une mesure reproductible de la vérité bootstrap :
/// - ce tooling ne lit aucun fichier généré ;
/// - il réutilise la vraie source embarquée de `map_editor` ;
/// - il laisse ensuite `map_runtime` auditer ce payload sans dépendre
///   directement du package editor.
void main() {
  const encoder = JsonEncoder.withIndent('  ');
  stdout.write(
    encoder.convert(
      buildEmbeddedPokemonMovesBootstrapSeed().toJson(),
    ),
  );
}
