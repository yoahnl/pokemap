import 'dart:convert';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../domain/pokemon_workspace_models.dart';
import 'pokemon_index_projection.dart';

Set<String> pokemonReferenceOwners(
  Iterable<PokemonSpeciesSummary> entries,
  PokemonDocumentFamily family,
  String reference,
) => {
  for (final entry in entries)
    if (switch (family) {
      PokemonDocumentFamily.learnset => entry.learnsetReference == reference,
      PokemonDocumentFamily.evolution => entry.evolutionReference == reference,
      PokemonDocumentFamily.media => entry.mediaReference == reference,
      PokemonDocumentFamily.species => false,
    })
      entry.id,
};

bool pokemonCompanionBelongsTo({
  required PokemonDocumentFamily family,
  required String ownerSpeciesId,
  required String reference,
  required String declaredSpeciesId,
  required Set<String> knownSpeciesIds,
  required Set<String> referencingSpeciesIds,
  String ownerBaseFormId = '',
  bool ownerIsBaseForm = true,
}) {
  if (family == PokemonDocumentFamily.species) return false;
  return resolvePokemonCompanionOwnership(
        ownerSpeciesId: ownerSpeciesId,
        reference: reference,
        declaredSpeciesId: declaredSpeciesId,
        knownSpeciesIds: knownSpeciesIds,
        referencingSpeciesIds: referencingSpeciesIds,
        media: family == PokemonDocumentFamily.media,
        ownerBaseFormId: ownerBaseFormId,
        ownerIsBaseForm: ownerIsBaseForm,
      ) ==
      PokemonCompanionOwnership.owned;
}

Future<PokemonDocumentSource?> loadPokemonCompanion({
  required ProjectFileReader reader,
  required String projectRoot,
  required PokemonDocumentFamily family,
  required String directory,
  required String reference,
  required String ownerSpeciesId,
  required Set<String> knownSpeciesIds,
  required Set<String> referencingSpeciesIds,
  String ownerBaseFormId = '',
  bool ownerIsBaseForm = true,
}) async {
  if (reference.trim().isEmpty) return null;
  final path = '$directory/$reference.json';
  final bytes = await readOptionalPokemonResource(
    reader: reader,
    projectRoot: projectRoot,
    relativePath: path,
  );
  final decoded = bytes == null ? null : jsonDecode(utf8.decode(bytes));
  if (decoded != null && decoded is! Map<String, dynamic>) {
    throw PokemonWorkspaceFailure('Compagnon illisible : $reference.');
  }
  final document = decoded as Map<String, dynamic>?;
  final ownership = document == null
      ? PokemonCompanionOwnership.owned
      : resolvePokemonCompanionOwnership(
          ownerSpeciesId: ownerSpeciesId,
          reference: reference,
          declaredSpeciesId: document['speciesId'] as String? ?? '',
          knownSpeciesIds: knownSpeciesIds,
          referencingSpeciesIds: referencingSpeciesIds,
          media: family == PokemonDocumentFamily.media,
          ownerBaseFormId: ownerBaseFormId,
          ownerIsBaseForm: ownerIsBaseForm,
        );
  return PokemonDocumentSource(
    family: family,
    relativePath: path,
    bytes: bytes,
    document: ownership == PokemonCompanionOwnership.owned ? document : null,
    problem: switch (ownership) {
      PokemonCompanionOwnership.owned => null,
      PokemonCompanionOwnership.ambiguous =>
        'La référence $reference est partagée sans propriétaire unique. '
            'Le compagnon reste conservé ; son édition est bloquée.',
      PokemonCompanionOwnership.foreign =>
        'La référence $reference désigne un autre propriétaire. '
            'Le compagnon reste conservé ; son édition est bloquée.',
    },
  );
}
