part of 'local_pokemon_workspace_adapter.dart';

extension _PokemonWorkspaceSources on LocalPokemonWorkspaceAdapter {
  Future<String> get _catalogRelease {
    final existing = _catalogReleaseOpening;
    if (existing != null) return existing;
    late final Future<String> opening;
    opening = _manifest
        .then((manifest) {
          final release =
              manifest.pokemon.catalogRelease ?? aveluneCatalogRelease;
          if (!RegExp(r'^[a-z0-9][a-z0-9-]{0,127}$').hasMatch(release)) {
            throw const PokemonWorkspaceFailure(
              'La version du catalogue Pokémon est invalide.',
            );
          }
          return release;
        })
        .catchError((Object error, StackTrace stack) {
          if (identical(_catalogReleaseOpening, opening)) {
            _catalogReleaseOpening = null;
          }
          Error.throwWithStackTrace(error, stack);
        });
    return _catalogReleaseOpening = opening;
  }

  Future<PokemonExternalImport> _prepareExternal() async {
    if (_closed) throw StateError('L’atelier Pokémon est fermé.');
    if (_externalImport != null) return _externalImport!;
    final release = await _catalogRelease;
    if (_closed) throw StateError('L’atelier Pokémon est fermé.');
    return _externalImport ??= PokemonExternalImport(
      session: session,
      mapAdapter: mapAdapter,
      reader: _reader,
      source: (_externalSession ??= PokemonExternalSourceSession(
        _externalSource,
        release: release,
      )).source,
      gen5Source: session.storage == ProjectSessionStorage.workingCatalog
          ? _gen5Source ??
                AveluneGen5BattleSource(
                  release: release,
                  client: HttpPokemonExternalTransport(
                    _gen5Client ??= http.Client(),
                  ),
                )
          : null,
      gifSource: session.storage == ProjectSessionStorage.workingCatalog
          ? _gifSource ??
                (_externalSource == null
                    ? AveluneBattleGifSource(
                        release: release,
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
                          release: release,
                          client: HttpPokemonExternalTransport(
                            _gen5Client ??= http.Client(),
                          ),
                        ),
                      )
                    : null)
          : null,
      pngSource: session.storage == ProjectSessionStorage.workingCatalog
          ? _pngSource ??
                (_externalSource == null
                    ? AvelunePokemonPngSource(
                        media: AvelunePokemonMediaSource(
                          release: release,
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
  }

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
    late final Future<PokemonMoveRecipeImport> opening;
    opening = _openMoveRecipes().catchError((Object error, StackTrace stack) {
      if (identical(_recipeOpening, opening)) _recipeOpening = null;
      Error.throwWithStackTrace(error, stack);
    });
    return _recipeOpening = opening;
  }

  Future<PokemonMoveRecipeImport> _openMoveRecipes() async {
    var source = _recipeMediaSource;
    if (source == null) {
      final release = await _catalogRelease;
      if (_closed) throw StateError('L’atelier Pokémon est fermé.');
      source = AvelunePokemonMediaSource(
        client: HttpPokemonExternalTransport(_recipeClient ??= http.Client()),
        release: release,
      );
    }
    return PokemonMoveRecipeImport.open(
      session: session,
      mapAdapter: mapAdapter,
      media: source,
      reader: _reader,
    );
  }

  Future<PokemonMovesSync> _prepareSync() async {
    final release = await _catalogRelease;
    if (_closed) throw StateError('L’atelier Pokémon est fermé.');
    return PokemonMovesSync(
      session: session,
      mapAdapter: mapAdapter,
      reader: _reader,
      source:
          _movesSource ??
          ExternalPokemonMovesSnapshotSource(
            (_externalSession ??= PokemonExternalSourceSession(
              _externalSource,
              release: release,
            )).source,
          ),
    );
  }
}
