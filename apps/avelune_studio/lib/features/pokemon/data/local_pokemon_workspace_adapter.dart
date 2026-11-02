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

final class LocalPokemonWorkspaceAdapter
    implements PokemonWorkspacePort, PokemonMoveRecipePort {
  LocalPokemonWorkspaceAdapter({
    required this.session,
    required this.mapAdapter,
    ProjectFileReader? reader,
    this._movesSource,
    this._externalSource,
    this._gen5Source,
    this._gifSource,
    this._crySource,
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
  final AvelunePokemonMediaSource? _recipeMediaSource;
  http.Client? _gen5Client;
  http.Client? _recipeClient;
  Future<PokemonMoveRecipeImport>? _recipeOpening;
  Future<void>? _closing;
  bool _closed = false;
  PokemonExternalSourceSession? _externalSession;
  PokemonExternalImport? _externalImport;
  Set<String>? _knownSpeciesIds;
  List<PokemonSpeciesSummary>? _indexedSpecies;
  Map<String, Set<String>> _mediaReferenceOwners = const {};

  void _acceptSpeciesIndex(List<PokemonSpeciesSummary> entries) {
    _indexedSpecies = entries;
    _knownSpeciesIds = {for (final entry in entries) entry.id};
    final owners = <String, Set<String>>{};
    for (final entry in entries) {
      owners.putIfAbsent(entry.mediaReference, () => {}).add(entry.id);
    }
    _mediaReferenceOwners = owners;
  }

  PokemonExternalImport get _external =>
      _externalImport ??= PokemonExternalImport(
        session: session,
        mapAdapter: mapAdapter,
        reader: _reader,
        source: (_externalSession ??= PokemonExternalSourceSession(
          _externalSource,
        )).source,
        gen5Source: session.storage == ProjectSessionStorage.workingCatalog
            ? _gen5Source ??
                  AveluneGen5BattleSource(
                    client: HttpPokemonExternalTransport(
                      _gen5Client ??= http.Client(),
                    ),
                  )
            : null,
        gifSource: session.storage == ProjectSessionStorage.workingCatalog
            ? _gifSource ??
                  (_externalSource == null
                      ? AveluneBattleGifSource(
                          client: HttpPokemonExternalTransport(
                            _gen5Client ??= http.Client(),
                          ),
                        )
                      : null)
            : null,
        crySource: session.storage == ProjectSessionStorage.workingCatalog
            ? _crySource ??
                  (_externalSource == null
                      ? AvelunePokemonCrySource(
                          media: AvelunePokemonMediaSource(
                            client: HttpPokemonExternalTransport(
                              _gen5Client ??= http.Client(),
                            ),
                          ),
                        )
                      : null)
            : null,
        isCurrent: () => !_closed,
        loadIndex: loadIndex,
      );

  @override
  bool get supportsMoveRecipes =>
      session.storage == ProjectSessionStorage.workingCatalog;

  Future<PokemonMoveRecipeImport> _prepareMoveRecipes() {
    if (_closed) {
      return Future.error(StateError('L’atelier Pokémon est fermé.'));
    }
    if (!supportsMoveRecipes) {
      return Future.error(
        const PokemonWorkspaceFailure(
          'Une copie de travail est nécessaire pour importer une animation.',
        ),
      );
    }
    final existing = _recipeOpening;
    if (existing != null) return existing;
    final source =
        _recipeMediaSource ??
        AvelunePokemonMediaSource(
          client: HttpPokemonExternalTransport(_recipeClient ??= http.Client()),
        );
    late final Future<PokemonMoveRecipeImport> opening;
    opening =
        PokemonMoveRecipeImport.open(
          session: session,
          mapAdapter: mapAdapter,
          media: source,
          reader: _reader,
        ).catchError((Object error, StackTrace stack) {
          if (identical(_recipeOpening, opening)) _recipeOpening = null;
          Error.throwWithStackTrace(error, stack);
        });
    return _recipeOpening = opening;
  }

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
  Future<PokemonExternalSearch> searchExternal(String query) =>
      _external.search(query);

  @override
  Future<PokemonExternalImportPreview> previewExternal(String speciesId) =>
      _external.preview(speciesId);

  @override
  Future<PokemonExternalImportResult> applyExternal(
    PokemonExternalImportPreview preview,
    PokemonExternalConflictPolicy policy,
  ) => _external.apply(preview, policy);

  PokemonMovesSync get _sync => PokemonMovesSync(
    session: session,
    mapAdapter: mapAdapter,
    reader: _reader,
    source:
        _movesSource ??
        ExternalPokemonMovesSnapshotSource(
          (_externalSession ??= PokemonExternalSourceSession(
            _externalSource,
          )).source,
        ),
  );

  @override
  Future<PokemonMovesSyncPreview> previewMovesSync() => _sync.preview();

  @override
  Future<void> applyMovesSync(PokemonMovesSyncPreview preview) =>
      _sync.apply(preview);

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

  Future<ProjectManifest> get _manifest async =>
      (await mapAdapter.resourceBaseline(session)).manifest;
  @override
  Future<PokemonWorkspaceIndex> loadIndex() async {
    final manifest = await _manifest;
    if (!manifest.pokemon.enabled) {
      return PokemonWorkspaceIndex(
        enabled: false,
        entries: const [],
        types: const [],
        items: const {},
        moves: const PokemonMovesCatalogView(
          entries: [],
          relativePath: '',
          problem: 'La configuration Pokémon est désactivée pour ce projet.',
        ),
      );
    }
    final entries = await loadPokemonSpeciesIndex(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: manifest.pokemon,
    );
    _acceptSpeciesIndex(entries);
    final language = await readPokemonProjectLocale(session.directoryPath);
    final moves = await loadPokemonMoves(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: manifest.pokemon,
      locale: language.locale,
    );
    final types = await loadPokemonTypes(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: manifest.pokemon,
      entries: entries,
    );
    final itemCatalog = await loadPokemonItemCatalog(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: manifest.pokemon,
    );
    final abilityNames = await loadPokemonAbilityNames(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: manifest.pokemon,
      locale: language.locale,
    );
    return PokemonWorkspaceIndex(
      enabled: true,
      entries: entries,
      moves: language.diagnostic == null
          ? moves
          : PokemonMovesCatalogView(
              entries: moves.entries,
              relativePath: moves.relativePath,
              problem: moves.problem,
              diagnostics: [...moves.diagnostics, language.diagnostic!],
            ),
      types: types,
      items: {
        for (final item
            in itemCatalog?.entries ?? const <ProjectItemDefinition>[])
          item.id: item.displayName,
      },
      itemCatalog: itemCatalog,
      locale: language.locale,
      abilityNames: abilityNames,
    );
  }

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
  Future<PokemonSpeciesBundle> save(PokemonSpeciesDraft draft) async {
    final changed = draft.changedFamilies;
    final mediaOnly =
        changed.length == 1 && changed.single == PokemonDocumentFamily.media;
    final savedBytes = await PokemonDocumentTransaction(
      session: session,
      mapAdapter: mapAdapter,
      reader: _reader,
    ).save(draft);
    if (mediaOnly) {
      final source = draft.base.media!;
      try {
        final bytes = savedBytes!;
        final document = Map<String, dynamic>.from(
          jsonDecode(utf8.decode(bytes)) as Map,
        );
        return PokemonSpeciesBundle(
          species: draft.base.species,
          learnset: draft.base.learnset,
          evolution: draft.base.evolution,
          media: PokemonDocumentSource(
            family: PokemonDocumentFamily.media,
            relativePath: source.relativePath,
            bytes: bytes,
            document: document,
          ),
        );
      } on Object catch (error) {
        throw PokemonWorkspaceFailure(
          'Enregistrement confirmé, mais actualisation impossible. '
          'Rouvrez le projet avant de continuer : $error',
        );
      }
    }
    final entries = await loadPokemonSpeciesIndex(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: (await _manifest).pokemon,
    );
    _acceptSpeciesIndex(entries);
    final entry = entries.where((entry) => entry.id == draft.id).firstOrNull;
    if (entry == null) {
      throw const PokemonWorkspaceFailure(
        'La fiche enregistrée est introuvable dans le Pokédex.',
      );
    }
    return loadSpecies(entry);
  }

  @override
  Future<Uint8List?> loadImage(String relativePath) => loadPokemonImage(
    reader: _reader,
    projectRoot: session.directoryPath,
    relativePath: relativePath,
  );

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

  Future<Set<String>> _speciesIdentities() async {
    if (_knownSpeciesIds case final ids?) return ids;
    final entries = await loadPokemonSpeciesIndex(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: (await _manifest).pokemon,
    );
    _acceptSpeciesIndex(entries);
    return _knownSpeciesIds!;
  }
}
