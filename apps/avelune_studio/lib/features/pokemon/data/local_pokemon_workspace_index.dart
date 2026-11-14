part of 'local_pokemon_workspace_adapter.dart';

extension _PokemonWorkspaceIndexing on LocalPokemonWorkspaceAdapter {
  void _acceptSpeciesIndex(List<PokemonSpeciesSummary> entries) {
    _indexedSpecies = entries;
    _knownSpeciesIds = {for (final entry in entries) entry.id};
    final owners = <String, Set<String>>{};
    for (final entry in entries) {
      owners.putIfAbsent(entry.mediaReference, () => {}).add(entry.id);
    }
    _mediaReferenceOwners = owners;
  }

  Future<ProjectManifest> get _manifest async =>
      (await mapAdapter.resourceBaseline(session)).manifest;

  Future<PokemonWorkspaceIndex> _loadIndex() async {
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

  Future<PokemonSpeciesBundle> _save(PokemonSpeciesDraft draft) async {
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
