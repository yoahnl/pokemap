import 'dart:convert';

import 'package:map_authoring/map_authoring_local.dart';

import '../domain/pokemon_workspace_models.dart';
import 'pokemon_index_projection.dart';

bool pokemonCompanionBelongsTo({
  required PokemonDocumentFamily family,
  required String ownerSpeciesId,
  required String reference,
  required String declaredSpeciesId,
  required Set<String> knownSpeciesIds,
  String ownerBaseFormId = '',
  bool ownerIsBaseForm = true,
}) {
  if (family == PokemonDocumentFamily.species) return false;
  if (declaredSpeciesId == ownerSpeciesId) return true;
  if (family == PokemonDocumentFamily.media &&
      !ownerIsBaseForm &&
      ownerBaseFormId == declaredSpeciesId &&
      knownSpeciesIds.contains(declaredSpeciesId)) {
    return true;
  }
  return declaredSpeciesId == reference && !knownSpeciesIds.contains(reference);
}

Future<PokemonDocumentSource?> loadPokemonCompanion({
  required ProjectFileReader reader,
  required String projectRoot,
  required PokemonDocumentFamily family,
  required String directory,
  required String reference,
  required String ownerSpeciesId,
  required Set<String> knownSpeciesIds,
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
  if (document != null &&
      !pokemonCompanionBelongsTo(
        family: family,
        ownerSpeciesId: ownerSpeciesId,
        reference: reference,
        declaredSpeciesId: document['speciesId'] as String? ?? '',
        knownSpeciesIds: knownSpeciesIds,
        ownerBaseFormId: ownerBaseFormId,
        ownerIsBaseForm: ownerIsBaseForm,
      )) {
    throw PokemonWorkspaceFailure('Référence $reference incohérente.');
  }
  return PokemonDocumentSource(
    family: family,
    relativePath: path,
    bytes: bytes,
    document: document,
  );
}
