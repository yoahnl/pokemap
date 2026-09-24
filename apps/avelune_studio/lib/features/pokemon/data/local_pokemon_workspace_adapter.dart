import 'dart:convert';
import 'dart:typed_data';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart'
    show PokemonExternalSourceRepository;
import 'package:map_core/map_core.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/pokemon_workspace_models.dart';
import '../domain/pokemon_workspace_port.dart';
import '../domain/pokemon_import_models.dart';
import '../domain/pokemon_moves_sync_models.dart';
import '../domain/pokemon_external_import_models.dart';
import 'pokemon_document_transaction.dart';
import 'pokemon_companion_projection.dart';
import 'pokemon_external_import.dart';
import 'pokemon_external_source_session.dart';
import 'pokemon_index_projection.dart';
import 'pokemon_json_import.dart';
import 'pokemon_media_import.dart';
import 'pokemon_media_projection.dart';
import 'pokemon_moves_snapshot_source.dart';
import 'pokemon_moves_sync.dart';
import 'pokemon_project_locale.dart';
import 'pokemon_types_projection.dart';

final class LocalPokemonWorkspaceAdapter implements PokemonWorkspacePort {
  LocalPokemonWorkspaceAdapter({
    required this.session,
    required this.mapAdapter,
    ProjectFileReader? reader,
    PokemonMovesSnapshotSource? movesSource,
    PokemonExternalSourceRepository? externalSource,
  }) : _reader = reader ?? const LocalProjectFileReader(),
       _movesSource = movesSource,
       _externalSource = externalSource;

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final ProjectFileReader _reader;
  final PokemonMovesSnapshotSource? _movesSource;
  final PokemonExternalSourceRepository? _externalSource;
  PokemonExternalSourceSession? _externalSession;
  PokemonExternalImport? _externalImport;
  Set<String>? _knownSpeciesIds;

  PokemonExternalImport get _external =>
      _externalImport ??= PokemonExternalImport(
        session: session,
        mapAdapter: mapAdapter,
        reader: _reader,
        source: (_externalSession ??= PokemonExternalSourceSession(
          _externalSource,
        )).source,
        loadIndex: loadIndex,
      );

  void dispose() => _externalSession?.dispose();
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
    _knownSpeciesIds = {for (final entry in entries) entry.id};
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
    final items = await loadPokemonItems(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: manifest.pokemon,
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
      items: items,
    );
  }

  @override
  Future<PokemonSpeciesBundle> loadSpecies(PokemonSpeciesSummary entry) async {
    final manifest = await _manifest;
    final species = await _required(
      PokemonDocumentFamily.species,
      entry.relativePath,
    );
    final parsed = PokemonSpeciesFile.fromJson(species.document!);
    if (parsed.id != entry.id ||
        !entry.relativePath.startsWith('${manifest.pokemon.speciesDir}/')) {
      throw const PokemonWorkspaceFailure(
        'La fiche ne correspond plus à l’espèce sélectionnée.',
      );
    }
    final knownSpeciesIds = await _speciesIdentities();
    return PokemonSpeciesBundle(
      species: species,
      learnset: await loadPokemonCompanion(
        reader: _reader,
        projectRoot: session.directoryPath,
        family: PokemonDocumentFamily.learnset,
        directory: manifest.pokemon.learnsetsDir,
        reference: parsed.refs.learnset,
        ownerSpeciesId: parsed.id,
        knownSpeciesIds: knownSpeciesIds,
      ),
      evolution: await loadPokemonCompanion(
        reader: _reader,
        projectRoot: session.directoryPath,
        family: PokemonDocumentFamily.evolution,
        directory: manifest.pokemon.evolutionsDir,
        reference: parsed.refs.evolution,
        ownerSpeciesId: parsed.id,
        knownSpeciesIds: knownSpeciesIds,
      ),
      media: await loadPokemonCompanion(
        reader: _reader,
        projectRoot: session.directoryPath,
        family: PokemonDocumentFamily.media,
        directory: manifest.pokemon.mediaDir,
        reference: parsed.refs.media,
        ownerSpeciesId: parsed.id,
        knownSpeciesIds: knownSpeciesIds,
        ownerBaseFormId: parsed.forms.baseFormId,
        ownerIsBaseForm: parsed.forms.isBaseForm,
      ),
    );
  }

  Future<PokemonDocumentSource> _required(
    PokemonDocumentFamily family,
    String path,
  ) async {
    final bytes = await _read(path);
    return PokemonDocumentSource(
      family: family,
      relativePath: path,
      bytes: bytes,
      document: _decode(bytes),
    );
  }

  @override
  Future<PokemonSpeciesBundle> save(PokemonSpeciesDraft draft) async {
    await PokemonDocumentTransaction(
      session: session,
      mapAdapter: mapAdapter,
      reader: _reader,
    ).save(draft);
    final entries = await loadPokemonSpeciesIndex(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: (await _manifest).pokemon,
    );
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
      );

  Future<Set<String>> _speciesIdentities() async => _knownSpeciesIds ??= {
    for (final entry in await loadPokemonSpeciesIndex(
      reader: _reader,
      projectRoot: session.directoryPath,
      config: (await _manifest).pokemon,
    ))
      entry.id,
  };

  Future<List<int>> _read(String path) =>
      _reader.readBytes(projectRoot: session.directoryPath, relativePath: path);

  Map<String, dynamic> _decode(List<int> bytes) {
    final value = jsonDecode(utf8.decode(bytes));
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Document Pokémon non objet.');
    }
    return value;
  }
}
