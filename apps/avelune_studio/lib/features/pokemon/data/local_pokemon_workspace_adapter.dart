import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show
        AveluneBattleGifSource,
        AveluneGen5BattleSource,
        AvelunePokemonCrySource,
        AvelunePokemonMediaSource,
        AvelunePokemonPngSource,
        BattleMoveRecipeBatchEntry,
        BattleMoveRecipeBatchImporter,
        BattleMoveRecipeBatchResult,
        PokemonExternalSourceRepository;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_workspace_models.dart';
import '../domain/pokemon_workspace_port.dart';
import '../domain/pokemon_import_models.dart';
import '../domain/pokemon_moves_sync_models.dart';
import '../domain/pokemon_external_import_models.dart';
import '../domain/pokemon_move_recipe_choice.dart';
import '../domain/pokemon_move_recipe_port.dart';
import 'http_pokemon_external_transport.dart';
import 'pokemon_document_transaction.dart';
import 'pokemon_bundle_projection.dart';
import 'pokemon_external_import.dart';
import 'pokemon_external_source_session.dart';
import 'pokemon_index_projection.dart';
import 'pokemon_json_import.dart';
import 'pokemon_media_import.dart';
import 'pokemon_media_projection.dart';
import 'pokemon_moves_snapshot_source.dart';
import 'pokemon_move_recipe_import.dart';
import 'pokemon_moves_sync.dart';
import 'pokemon_project_locale.dart';
import 'pokemon_types_projection.dart';

part 'local_pokemon_workspace_index.dart';
part 'local_pokemon_workspace_sources.dart';

final class LocalPokemonWorkspaceAdapter
    implements
        PokemonWorkspacePort,
        PokemonMoveRecipePort,
        PokemonMoveRecipeBatchPort {
  LocalPokemonWorkspaceAdapter({
    required this.session,
    required this.mapAdapter,
    ProjectFileReader? reader,
    this._movesSource,
    this._externalSource,
    this._gen5Source,
    this._gifSource,
    this._crySource,
    this._pngSource,
    this._recipeMediaSource,
  }) : _reader = reader ?? const LocalProjectFileReader();

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader _reader;
  final PokemonMovesSnapshotSource? _movesSource;
  final PokemonExternalSourceRepository? _externalSource;
  final AveluneGen5BattleSource? _gen5Source;
  final AveluneBattleGifSource? _gifSource;
  final AvelunePokemonCrySource? _crySource;
  final AvelunePokemonPngSource? _pngSource;
  final AvelunePokemonMediaSource? _recipeMediaSource;
  http.Client? _gen5Client;
  http.Client? _recipeClient;
  Future<PokemonMoveRecipeImport>? _recipeOpening;
  Future<void>? _closing;
  bool _closed = false;
  PokemonExternalSourceSession? _externalSession;
  PokemonExternalImport? _externalImport;
  Future<String>? _catalogReleaseOpening;
  Set<String>? _knownSpeciesIds;
  List<PokemonSpeciesSummary>? _indexedSpecies;
  Map<String, Set<String>> _mediaReferenceOwners = const {};

  @override
  bool get supportsMoveRecipes =>
      session.storage == ProjectSessionStorage.workingCatalog;

  @override
  Future<void> prepareMoveRecipes() async {
    await _prepareMoveRecipes();
  }

  @override
  Future<List<PokemonMoveRecipeChoice>> listMoveRecipes(
    String projectMoveId,
  ) async => (await _prepareMoveRecipes()).listForMove(projectMoveId);

  @override
  Future<bool> importMoveRecipe(
    String projectMoveId,
    PokemonMoveRecipeChoice choice, {
    bool Function()? isCurrent,
  }) async => (await _prepareMoveRecipes()).importChoice(
    projectMoveId,
    choice,
    isCurrent: isCurrent,
  );

  @override
  Future<void> prepareMoveRecipeBatchProject() async =>
      (await _prepareMoveRecipes()).prepareBatchProject();

  @override
  Future<BattleMoveRecipeBatchResult> importMoveRecipeBatch({
    required String operationId,
    int startIndex = 0,
    int limit = BattleMoveRecipeBatchImporter.maximumBatchSize,
    String? expectedInventoryRevision,
    bool Function()? isCancelled,
    void Function(BattleMoveRecipeBatchEntry entry)? onProgress,
  }) async => (await _prepareMoveRecipes()).importBatch(
    operationId: operationId,
    startIndex: startIndex,
    limit: limit,
    expectedInventoryRevision: expectedInventoryRevision,
    isCancelled: isCancelled,
    onProgress: onProgress,
  );

  void dispose() => unawaited(close());

  Future<void> close() => _closing ??= _close();

  Future<void> _close() async {
    _closed = true;
    _externalSession?.dispose();
    _gen5Client?.close();
    _recipeClient?.close();
    final opening = _recipeOpening;
    if (opening != null) {
      PokemonMoveRecipeImport? importer;
      try {
        importer = await opening;
      } on Object {
        return;
      }
      await importer.close();
    }
  }

  @override
  Future<PokemonExternalSearch> searchExternal(String query) async =>
      (await _prepareExternal()).search(query);

  @override
  Future<PokemonExternalImportPreview> previewExternal(
    String speciesId,
  ) async => (await _prepareExternal()).preview(speciesId);

  @override
  Future<PokemonExternalImportResult> applyExternal(
    PokemonExternalImportPreview preview,
    PokemonExternalConflictPolicy policy,
  ) async => (await _prepareExternal()).apply(preview, policy);

  @override
  Future<PokemonMovesSyncPreview> previewMovesSync() async =>
      (await _prepareSync()).preview();

  @override
  Future<void> applyMovesSync(PokemonMovesSyncPreview preview) async =>
      (await _prepareSync()).apply(preview);

  PokemonJsonImport get _import => PokemonJsonImport(
    session: session,
    mapAdapter: mapAdapter,
    reader: _reader,
  );

  @override
  Future<PokemonLocalImportPreview> previewJsonImport(String absolutePath) =>
      _import.preview(absolutePath);

  @override
  Future<String> applyJsonImport(
    PokemonLocalImportPreview preview, {
    required bool confirmOverwrite,
  }) => _import.apply(preview, confirmOverwrite: confirmOverwrite);

  @override
  Future<String> importMenuPng({
    required String sourcePath,
    required String speciesId,
    required String formId,
    required String role,
  }) => PokemonMenuMediaImport(session: session, mapAdapter: mapAdapter).run(
    sourcePath: sourcePath,
    speciesId: speciesId,
    formId: formId,
    role: role,
  );

  @override
  Future<PokemonWorkspaceIndex> loadIndex() => _loadIndex();

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async {
    final manifest = await _manifest;
    final indexed =
        _indexedSpecies ??
        await loadPokemonSpeciesIndex(
          reader: _reader,
          projectRoot: session.directoryPath,
          config: manifest.pokemon,
        );
    return loadPokemonSpeciesBundle(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: manifest.pokemon,
      entry: entry,
      index: indexed,
    );
  }

  @override
  Future<PokemonSpeciesBundle> save(PokemonSpeciesDraft draft) => _save(draft);

  @override
  Future<Uint8List?> loadImage(String relativePath) => loadPokemonImage(
    reader: _reader,
    projectRoot: session.directoryPath,
    relativePath: relativePath,
  );

  @override
  Future<PokemonMediaFileStatus> probeMedia(String relativePath) async {
    final reader = _reader;
    if (reader is! ProjectResourceProbeReader) {
      return PokemonMediaFileStatus.unverified;
    }
    final probe = await (reader as ProjectResourceProbeReader).probeResource(
      projectRoot: session.directoryPath,
      relativePath: relativePath,
    );
    return switch (probe.status) {
      ProjectResourceProbeStatus.exists => PokemonMediaFileStatus.present,
      ProjectResourceProbeStatus.missing => PokemonMediaFileStatus.missing,
      _ => PokemonMediaFileStatus.inaccessible,
    };
  }

  @override
  Future<Uint8List?> loadThumbnail(PokemonSpeciesSummary entry) async =>
      loadPokemonThumbnail(
        reader: _reader,
        projectRoot: session.directoryPath,
        entry: entry,
        knownSpeciesIds: await _speciesIdentities(),
        referencingSpeciesIds:
            _mediaReferenceOwners[entry.mediaReference] ?? const {},
      );
}
