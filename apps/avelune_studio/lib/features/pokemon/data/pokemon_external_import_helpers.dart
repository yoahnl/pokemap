import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';

import '../domain/pokemon_workspace_models.dart';

Future<Map<String, dynamic>?> optionalExternalPayload(
  Future<Map<String, dynamic>> Function() load,
  String label,
  List<String> warnings,
) async {
  try {
    return await load();
  } on Object catch (error) {
    warnings.add('$label : $error');
    return null;
  }
}

PokemonDocumentKind externalDocumentKind(PokemonDocumentFamily family) =>
    switch (family) {
      PokemonDocumentFamily.species => PokemonDocumentKind.species,
      PokemonDocumentFamily.learnset => PokemonDocumentKind.learnset,
      PokemonDocumentFamily.evolution => PokemonDocumentKind.evolution,
      PokemonDocumentFamily.media => PokemonDocumentKind.media,
    };

bool samePokemonBytes(List<int>? a, List<int>? b) {
  if (a == null || b == null) return a == null && b == null;
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

String pokemonInventorySignature(List<PokemonSpeciesSummary> entries) =>
    jsonEncode([
      for (final entry in entries)
        [
          entry.id,
          entry.learnsetReference,
          entry.evolutionReference,
          entry.mediaReference,
          entry.baseFormId,
          entry.isBaseForm,
        ],
    ]);
