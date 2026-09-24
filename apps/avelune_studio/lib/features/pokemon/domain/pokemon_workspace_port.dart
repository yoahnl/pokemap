import 'dart:typed_data';

import 'pokemon_workspace_models.dart';
import 'pokemon_import_models.dart';
import 'pokemon_moves_sync_models.dart';
import 'pokemon_external_import_models.dart';

abstract interface class PokemonWorkspacePort {
  Future<PokemonWorkspaceIndex> loadIndex();

  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry);

  Future<PokemonSpeciesBundle> save(PokemonSpeciesDraft draft);

  Future<Uint8List?> loadImage(String relativePath);

  Future<Uint8List?> loadThumbnail(PokemonSpeciesSummary entry);

  Future<PokemonLocalImportPreview> previewJsonImport(String absolutePath);

  Future<String> applyJsonImport(
    PokemonLocalImportPreview preview, {
    required bool confirmOverwrite,
  });

  Future<String> importMenuPng({
    required String sourcePath,
    required String speciesId,
    required String formId,
    required String role,
  });

  Future<PokemonMovesSyncPreview> previewMovesSync();

  Future<void> applyMovesSync(PokemonMovesSyncPreview preview);

  Future<PokemonExternalSearch> searchExternal(String query);

  Future<PokemonExternalImportPreview> previewExternal(String speciesId);

  Future<PokemonExternalImportResult> applyExternal(
    PokemonExternalImportPreview preview,
    PokemonExternalConflictPolicy policy,
  );
}
