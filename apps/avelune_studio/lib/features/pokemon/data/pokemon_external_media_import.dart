import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_workspace_models.dart';
import 'pokemon_document_transaction.dart';
import 'pokemon_index_projection.dart';

final class PokemonExternalMediaImport {
  const PokemonExternalMediaImport({
    required this.session,
    required this.mapAdapter,
    required this.reader,
    this.isCurrent,
  });

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader reader;
  final bool Function()? isCurrent;

  Future<bool> importPngs(
    PokemonPngSelection selection,
    String speciesId,
    String speciesPath,
    int nationalDex,
  ) async {
    if (isCurrent?.call() == false) throw StateError('La sélection a changé.');
    final speciesBytes = await readOptionalPokemonResource(
      reader: reader,
      projectRoot: session.directoryPath,
      relativePath: speciesPath,
    );
    if (speciesBytes == null) throw StateError('La fiche Pokémon est absente.');
    final species = PokemonSpeciesFile.fromJson(
      (jsonDecode(utf8.decode(speciesBytes)) as Map).cast<String, dynamic>(),
    );
    if (species.id != speciesId ||
        species.nationalDex != nationalDex ||
        !species.forms.isBaseForm ||
        species.refs.media != speciesId) {
      return false;
    }
    final baseline = await mapAdapter.resourceBaseline(session);
    final mediaPath = pokemonDocumentPath(
      baseline.manifest.pokemon.mediaDir,
      speciesId,
    );
    final before = await readOptionalPokemonResource(
      reader: reader,
      projectRoot: session.directoryPath,
      relativePath: mediaPath,
    );
    final Map<String, dynamic> document;
    if (before == null) {
      document = {
        'schemaVersion': currentPokemonMediaSchemaVersion,
        'speciesId': speciesId,
        'defaultFormId': 'base',
        'variants': {'base': <String, dynamic>{}},
      };
    } else {
      final decoded = jsonDecode(utf8.decode(before));
      if (decoded is! Map ||
          !const {
            1,
            currentPokemonMediaSchemaVersion,
          }.contains(decoded['schemaVersion']) ||
          decoded['speciesId'] != speciesId ||
          decoded['defaultFormId'] != 'base' ||
          decoded['variants'] is! Map ||
          (decoded['variants'] as Map)['base'] is! Map) {
        return false;
      }
      document = decoded.cast<String, dynamic>();
    }
    final variants = (document['variants'] as Map).cast<String, dynamic>();
    final variant = (variants['base'] as Map).cast<String, dynamic>();
    final artifacts = <String, List<int>>{};
    for (final entry in selection.media.entries) {
      final role = entry.key.name;
      final existing = variant[role];
      if (existing != null &&
          (existing is! String || existing.trim().isNotEmpty)) {
        continue;
      }
      variant[role] = 'assets/pokemon/images/${entry.value.sha256}.png';
      artifacts[role] = entry.value.bytes;
    }
    if (artifacts.isEmpty) return false;
    await PokemonDocumentTransaction(
      session: session,
      mapAdapter: mapAdapter,
      reader: reader,
    ).applyPokemonPngs(
      PokemonDocumentWriteRequest(
        family: PokemonDocumentFamily.media,
        relativePath: mediaPath,
        beforeBytes: before,
        document: document,
      ),
      species: (
        resourceIdentity: pokemonSpeciesResourceIdentity(speciesId),
        relativePath: speciesPath,
        beforeBytes: speciesBytes,
      ),
      pngs: artifacts,
    );
    return true;
  }

  Future<bool> importCry(
    AvelunePokemonCry cry,
    String speciesId,
    String speciesPath,
  ) async {
    if (isCurrent?.call() == false) throw StateError('La sélection a changé.');
    if (!const {'audio/wav', 'audio/mpeg'}.contains(cry.mediaType)) {
      throw const FormatException('Format de cri non pris en charge.');
    }
    final speciesBytes = await readOptionalPokemonResource(
      reader: reader,
      projectRoot: session.directoryPath,
      relativePath: speciesPath,
    );
    if (speciesBytes == null) throw StateError('La fiche Pokémon est absente.');
    final species = PokemonSpeciesFile.fromJson(
      (jsonDecode(utf8.decode(speciesBytes)) as Map).cast<String, dynamic>(),
    );
    if (species.id != speciesId ||
        !species.forms.isBaseForm ||
        species.refs.media != speciesId) {
      return false;
    }
    final baseline = await mapAdapter.resourceBaseline(session);
    final mediaPath = pokemonDocumentPath(
      baseline.manifest.pokemon.mediaDir,
      speciesId,
    );
    final before = await readOptionalPokemonResource(
      reader: reader,
      projectRoot: session.directoryPath,
      relativePath: mediaPath,
    );
    final Map<String, dynamic> document;
    if (before == null) {
      document = {
        'schemaVersion': currentPokemonMediaSchemaVersion,
        'speciesId': speciesId,
        'defaultFormId': 'base',
        'variants': {'base': <String, dynamic>{}},
      };
    } else {
      final decoded = jsonDecode(utf8.decode(before));
      if (decoded is! Map ||
          !const {
            1,
            currentPokemonMediaSchemaVersion,
          }.contains(decoded['schemaVersion']) ||
          decoded['speciesId'] != speciesId ||
          decoded['defaultFormId'] is! String ||
          decoded['variants'] is! Map ||
          (decoded['variants'] as Map)[decoded['defaultFormId']] is! Map) {
        return false;
      }
      document = decoded.cast<String, dynamic>();
    }
    final variants = (document['variants'] as Map).cast<String, dynamic>();
    final variant = (variants[document['defaultFormId']] as Map)
        .cast<String, dynamic>();
    final existing = variant['cry'];
    if (existing != null &&
        (existing is! String || existing.trim().isNotEmpty)) {
      return false;
    }
    final extension = cry.mediaType == 'audio/wav' ? 'wav' : 'mp3';
    variant['cry'] = 'assets/pokemon/battle-cries/${cry.sha256}.$extension';
    await PokemonDocumentTransaction(
      session: session,
      mapAdapter: mapAdapter,
      reader: reader,
    ).applyBattleCry(
      PokemonDocumentWriteRequest(
        family: PokemonDocumentFamily.media,
        relativePath: mediaPath,
        beforeBytes: before,
        document: document,
      ),
      species: (
        resourceIdentity: pokemonSpeciesResourceIdentity(speciesId),
        relativePath: speciesPath,
        beforeBytes: speciesBytes,
      ),
      bytes: cry.bytes,
      mediaType: cry.mediaType,
    );
    return true;
  }
}
