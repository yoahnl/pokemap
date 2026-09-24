import 'dart:convert';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

import '../domain/pokemon_workspace_models.dart';
import 'pokemon_companion_projection.dart';

Future<PokemonSpeciesBundle> loadPokemonSpeciesBundle({
  required ProjectFileReader reader,
  required String projectRoot,
  required ProjectPokemonConfig config,
  required PokemonSpeciesSummary entry,
  required List<PokemonSpeciesSummary> index,
}) async {
  final bytes = await reader.readBytes(
    projectRoot: projectRoot,
    relativePath: entry.relativePath,
  );
  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map<String, dynamic>) {
    throw const PokemonWorkspaceFailure('Fiche Pokémon illisible.');
  }
  final parsed = PokemonSpeciesFile.fromJson(decoded);
  if (parsed.id != entry.id ||
      !entry.relativePath.startsWith('${config.speciesDir}/')) {
    throw const PokemonWorkspaceFailure(
      'La fiche ne correspond plus à l’espèce sélectionnée.',
    );
  }
  final knownSpeciesIds = {for (final species in index) species.id};
  Future<PokemonDocumentSource?> companion(
    PokemonDocumentFamily family,
    String directory,
    String reference,
  ) => loadPokemonCompanion(
    reader: reader,
    projectRoot: projectRoot,
    family: family,
    directory: directory,
    reference: reference,
    ownerSpeciesId: parsed.id,
    knownSpeciesIds: knownSpeciesIds,
    referencingSpeciesIds: pokemonReferenceOwners(index, family, reference),
    ownerBaseFormId: parsed.forms.baseFormId,
    ownerIsBaseForm: parsed.forms.isBaseForm,
  );
  return PokemonSpeciesBundle(
    species: PokemonDocumentSource(
      family: PokemonDocumentFamily.species,
      relativePath: entry.relativePath,
      bytes: bytes,
      document: decoded,
    ),
    learnset: await companion(
      PokemonDocumentFamily.learnset,
      config.learnsetsDir,
      parsed.refs.learnset,
    ),
    evolution: await companion(
      PokemonDocumentFamily.evolution,
      config.evolutionsDir,
      parsed.refs.evolution,
    ),
    media: await companion(
      PokemonDocumentFamily.media,
      config.mediaDir,
      parsed.refs.media,
    ),
  );
}
