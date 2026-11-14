import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';

import '../domain/pokemon_external_import_models.dart';
import '../domain/pokemon_workspace_models.dart';
import 'pokemon_index_projection.dart';
import 'pokemon_companion_projection.dart';
import 'pokemon_external_import_helpers.dart';

Future<PokemonExternalDocument> readPokemonExternalDocument({
  required ProjectFileReader reader,
  required String projectRoot,
  required List<PokemonSpeciesSummary> indexed,
  required Map<String, dynamic> refs,
  required String speciesId,
  required PokemonDocumentFamily family,
  required String path,
  required Map<String, dynamic> json,
}) async {
  PokemonJsonDocument.fromJson(externalDocumentKind(family), json);
  final beforeBytes = await readOptionalPokemonResource(
    reader: reader,
    projectRoot: projectRoot,
    relativePath: path,
  );
  if (beforeBytes != null && family != PokemonDocumentFamily.species) {
    final existing = PokemonJsonDocument.fromJson(
      externalDocumentKind(family),
      (jsonDecode(utf8.decode(beforeBytes)) as Map).cast<String, dynamic>(),
    ).toJson();
    final reference = path.split('/').last.replaceAll(RegExp(r'\.json$'), '');
    final ownerIds = {
      ...pokemonReferenceOwners(indexed, family, reference),
      if (family == PokemonDocumentFamily.learnset &&
              refs['learnset'] == reference ||
          family == PokemonDocumentFamily.evolution &&
              refs['evolution'] == reference)
        speciesId,
    };
    if (!pokemonCompanionBelongsTo(
      family: family,
      ownerSpeciesId: speciesId,
      reference: reference,
      declaredSpeciesId: existing['speciesId'] as String? ?? '',
      knownSpeciesIds: {for (final entry in indexed) entry.id, speciesId},
      referencingSpeciesIds: ownerIds,
    )) {
      throw PokemonWorkspaceFailure(
        'Le document $path appartient déjà à ${existing['speciesId']}.',
      );
    }
  }
  return PokemonExternalDocument(
    family: family,
    relativePath: path,
    beforeBytes: beforeBytes,
    document: json,
  );
}
