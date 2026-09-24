import 'dart:convert';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../domain/pokemon_workspace_models.dart';
import 'pokemon_companion_projection.dart';
import 'pokemon_index_projection.dart';

Future<Uint8List?> loadPokemonImage({
  required ProjectFileReader reader,
  required String projectRoot,
  required String relativePath,
}) async {
  final bytes = await readOptionalPokemonResource(
    reader: reader,
    projectRoot: projectRoot,
    relativePath: relativePath,
  );
  if (bytes == null ||
      bytes.length < 8 ||
      bytes[0] != 137 ||
      bytes[1] != 80 ||
      bytes[2] != 78 ||
      bytes[3] != 71) {
    return null;
  }
  return Uint8List.fromList(bytes);
}

Future<Uint8List?> loadPokemonThumbnail({
  required ProjectFileReader reader,
  required String projectRoot,
  required PokemonSpeciesSummary entry,
  required Set<String> knownSpeciesIds,
}) async {
  if (entry.mediaRelativePath.isEmpty) return null;
  final bytes = await readOptionalPokemonResource(
    reader: reader,
    projectRoot: projectRoot,
    relativePath: entry.mediaRelativePath,
  );
  if (bytes == null) return null;
  final media = PokemonMediaFile.fromJson(
    (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>(),
  );
  if (!pokemonCompanionBelongsTo(
    family: PokemonDocumentFamily.media,
    ownerSpeciesId: entry.id,
    reference: p.posix.basenameWithoutExtension(entry.mediaRelativePath),
    declaredSpeciesId: media.speciesId,
    knownSpeciesIds: knownSpeciesIds,
    ownerBaseFormId: entry.baseFormId,
    ownerIsBaseForm: entry.isBaseForm,
  )) {
    return null;
  }
  final variant = media.variants[media.defaultFormId];
  final path = variant?.icon ?? variant?.party ?? variant?.portrait;
  if (path == null) return null;
  return loadPokemonImage(
    reader: reader,
    projectRoot: projectRoot,
    relativePath: path,
  );
}
