# PSDK Battle Migration - Lot 2 Map Editor Studio Source

## Scope

Lot 2 adds a local Pokemon SDK Studio import path in `map_editor` without
removing the existing Showdown/PokeAPI import path.

## Added Files

- `packages/map_editor/lib/src/infrastructure/external/pokemon_sdk_studio_payload.dart`
- `packages/map_editor/lib/src/infrastructure/external/pokemon_sdk_studio_source.dart`
- `packages/map_editor/lib/src/application/services/pokemon_sdk_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/services/pokemon_sdk_species_converter.dart`
- `packages/map_editor/test/infrastructure/external/pokemon_sdk_studio_source_test.dart`
- `packages/map_editor/test/application/services/pokemon_sdk_move_catalog_converter_test.dart`
- `packages/map_editor/test/application/services/pokemon_sdk_species_converter_test.dart`

## Modified Files

- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart`
- Existing tests implementing `PokemonExternalSourceRepository` received
  no-op PSDK stubs.
- `packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart`
  now gives the learnset fixture a complete local move catalog. This was found
  by the full test run: `protect` and then `growl` were absent from the local
  validation catalog even though the tested learnset used them.

## Behavior Implemented

- `PokemonSdkStudioSource.loadProject(root)` reads:
  - `Data/Studio/moves/**/*.json`
  - `Data/Studio/abilities/**/*.json`
  - `Data/Studio/items/**/*.json`
  - `Data/Studio/types/**/*.json`
  - `Data/Studio/pokemon/**/*.json`
- Missing category subdirectories return empty lists.
- Missing `Data/Studio` throws `PokemonSdkStudioSourceException`.
- Invalid JSON and non-object JSON roots include the source file path.
- `PokemonSdkMoveCatalogConverter` accepts camelCase and snake_case Studio
  fields, maps Studio targets/flags/statuses/stat stages into the canonical
  `PokemonMove` model, and keeps `accuracy: 0` as the PSDK sentinel.
- `effectChance: 0` is treated as canonical `100` because current
  `PokemonMove.normalized()` reserves valid effect chances to `1..100`.
- `PokemonSdkSpeciesConverter` converts minimal Studio pokemon payloads into
  `PokemonSpeciesFile`.
- `ExternalPokemonCatalogNormalizer` can normalize raw PSDK Studio entries for
  generic catalog inspection.
- `HttpPokemonExternalSourceRepository` can delegate PSDK payload loading to
  `PokemonSdkStudioSource`.
- `pokedex_providers.dart` wires an optional `pokemonSdkStudioSourceProvider`.

## Explicit Non-Goals

- Showdown sources/converters remain in place.
- `SyncExternalPokemonMovesCatalogUseCase` still uses Showdown.
- No runtime or battle-engine logic was changed in this lot.
- No generated files were needed.

## Verification

Commands run from `packages/map_editor` unless otherwise noted:

- `flutter test test/infrastructure/external/pokemon_sdk_studio_source_test.dart --no-pub`
- `flutter test test/application/services/pokemon_sdk_move_catalog_converter_test.dart --no-pub`
- `flutter test test/application/services/pokemon_sdk_species_converter_test.dart --no-pub`
- `flutter test test/external_pokemon_catalog_normalizer_test.dart --no-pub`
- `flutter test test/showdown_move_catalog_converter_test.dart test/showdown_snapshot_source_test.dart test/sync_pokemon_moves_catalog_use_case_test.dart test/pokemon_moves_catalog_loader_test.dart --no-pub`
- `flutter test test/sync_pokemon_items_catalog_use_case_test.dart test/search_external_pokemon_species_use_case_test.dart test/resolve_external_pokemon_batch_selection_use_case_test.dart test/import_external_pokemon_use_cases_test.dart --no-pub`
- `flutter test test/update_pokedex_species_learnset_use_case_test.dart --no-pub`
- `flutter test --no-pub` -> `+673: All tests passed!`
- Targeted analysis on all touched map_editor files -> `No issues found!`
- `git diff --check` -> clean

`flutter analyze` for the whole package still exits with existing warnings/infos
outside this lot, including `undefined_shown_name` in
`lib/src/ui/canvas/pokedex_workspace_views.dart` and historical lint debt in
story/collision tests. None of the touched files are reported by the targeted
analysis.
