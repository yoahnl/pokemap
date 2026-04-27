# PSDK Battle Migration - Lot 3 Map Editor Studio Sync

## Scope

Lot 3 adds a dedicated Pokemon SDK Studio moves sync/export path. It remains
parallel to the existing Showdown sync path.

## Added Files

- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/tools/export_pokemon_sdk_studio_catalog_cli.dart`
- `packages/map_editor/tool/export_pokemon_sdk_studio_catalog.dart`
- `packages/map_editor/test/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case_test.dart`
- `packages/map_editor/test/application/tools/export_pokemon_sdk_studio_catalog_cli_test.dart`

## Modified Files

- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

## Behavior Implemented

- `SyncPokemonSdkMovesCatalogUseCase` loads a PSDK Studio project through
  `PokemonExternalSourceRepository.fetchPokemonSdkStudioProjectPayload`.
- Studio moves are converted through `PokemonSdkMoveCatalogConverter`.
- The sync supports:
  - dry-run preview;
  - real JSON write;
  - custom `pokemon.dataRoot` and manifest-declared moves catalog path;
  - creation when `moves.json` is missing;
  - merge by `dbSymbol`;
  - preservation of local-only move entries;
  - preservation of local custom fields on matching canonical entries;
  - removal of obsolete legacy aliases (`power`, `accuracyText`, `shortDesc`)
    from canonical entries.
- A new provider exposes the PSDK sync use case without changing the existing
  Showdown moves sync provider.
- `ExportPokemonSdkStudioCatalogCli` exports the converted PSDK moves catalog
  as formatted JSON to stdout or to `--output`.
- The thin tool wrapper is available at:
  `packages/map_editor/tool/export_pokemon_sdk_studio_catalog.dart`.

## Explicit Non-Goals

- No UI button or flow was repointed to PSDK yet.
- `SyncExternalPokemonMovesCatalogUseCase` still uses Showdown.
- No runtime or battle-engine logic was changed in this lot.

## Verification

Commands run from `packages/map_editor`:

- `flutter test test/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case_test.dart --no-pub`
- `flutter test test/application/tools/export_pokemon_sdk_studio_catalog_cli_test.dart --no-pub`
- Combined guard:
  `flutter test test/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case_test.dart test/application/tools/export_pokemon_sdk_studio_catalog_cli_test.dart test/application/services/pokemon_sdk_move_catalog_converter_test.dart test/infrastructure/external/pokemon_sdk_studio_source_test.dart test/showdown_move_catalog_converter_test.dart test/sync_pokemon_moves_catalog_use_case_test.dart --no-pub`
- Targeted analysis on all touched Lot 3 files -> `No issues found!`
- Wrapper smoke:
  `dart run tool/export_pokemon_sdk_studio_catalog.dart --project-root <tmp> --catalog moves --output <tmp>/moves.json`

All Lot 3 targeted checks passed.
