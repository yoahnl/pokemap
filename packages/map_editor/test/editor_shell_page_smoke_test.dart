import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('EditorShellPage smoke', () {
    testWidgets('renders map workspace chrome and toggles the right panel',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_smoke',
          project: buildShellChromeProject(),
        ),
      );

      expect(find.text('Map Workspace'), findsOneWidget);
      expect(
        find.text('Open a map to start building your world.'),
        findsOneWidget,
      );
      expect(find.text('Ready'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Show right panel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('updates the workspace header for tileset mode',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_tileset',
          project: buildShellChromeProject(
            tilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'indoor',
                name: 'Indoor',
                relativePath: 'tilesets/indoor.json',
              ),
            ],
          ),
          workspaceMode: EditorWorkspaceMode.tileset,
          selectedTilesetEditorId: 'indoor',
        ),
      );

      expect(find.text('Indoor'), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'Visual library editing for tiles, elements and groups.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the trainer studio workspace chrome', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_trainer',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Trainer Studio'), findsWidgets);
      expect(
        find.textContaining('battle-ready rosters'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('trainer-library-new-trainer-button')),
        findsOneWidget,
      );
    });

    testWidgets('renders the Pokémon catalogs workspace shell', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_catalogs',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.moves,
        ),
        overrides: [
          pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonMovesCatalogView(
              entries: <PokemonMoveCatalogEntryView>[
                PokemonMoveCatalogEntryView(
                  id: 'water-gun',
                  name: 'Water Gun',
                  type: 'water',
                  category: 'special',
                  power: 40,
                  accuracy: 100,
                  pp: 25,
                ),
              ],
              isAvailable: true,
              description: 'Catalogue local des capacités du projet.',
            ),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );

      expect(find.text('Catalogues Pokémon'), findsWidgets);
      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsNothing);
      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              (widget.semanticLabel == 'Hide right panel' ||
                  widget.semanticLabel == 'Show right panel'),
        ),
        findsNothing,
      );
    });

    testWidgets('renders the Items catalogs workspace shell', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_items_catalogs',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.items,
        ),
        overrides: [
          pokemonItemsCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonItemsCatalogView(
              entries: <PokemonItemCatalogEntryView>[
                PokemonItemCatalogEntryView(
                  id: 'poke-ball',
                  name: 'Poké Ball',
                  categoryId: 'standard-balls',
                  pocketId: 'poke-balls',
                  cost: 200,
                ),
              ],
              isAvailable: true,
              description: 'Catalogue local des objets du projet.',
            ),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );

      expect(find.text('Catalogues Pokémon'), findsWidgets);
      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsNothing);
      expect(find.text('Items'), findsWidgets);
      expect(
        find.text('Catalogue local des objets du projet.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              (widget.semanticLabel == 'Hide right panel' ||
                  widget.semanticLabel == 'Show right panel'),
        ),
        findsNothing,
      );
    });

    testWidgets('opens Path Studio from the project explorer', (tester) async {
      final container = await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_path_studio',
          project: buildShellChromeProject(
            pathPresets: const <ProjectPathPreset>[
              ProjectPathPreset(
                id: 'legacy-water',
                name: 'Legacy Water',
                surfaceKind: PathSurfaceKind.water,
              ),
            ],
            pathPatternPresets: [
              ProjectPathPatternPreset(
                id: 'water-1x1',
                name: 'Water 1x1',
                basePathPresetId: 'legacy-water',
                centerPattern: PathCenterPattern(
                  size: PathCenterPatternSize(width: 1, height: 1),
                  cells: [
                    PathCenterPatternCell(
                      localX: 0,
                      localY: 0,
                      frames: [
                        const TilesetVisualFrame(
                          source: TilesetSourceRect(x: 0, y: 0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(
        find.byKey(const Key('project-explorer-path-studio-entry')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const Key('project-explorer-path-studio-entry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('project-explorer-path-studio-entry')),
      );
      await tester.pumpAndSettle();

      expect(
        container.read(editorNotifierProvider).workspaceMode,
        EditorWorkspaceMode.pathStudio,
      );
      expect(find.text('Path Studio'), findsWidgets);
      expect(find.text('Créer des motifs de chemin'), findsWidgets);
      expect(find.text('Water 1x1'), findsWidgets);
    });

    testWidgets('renders shell chrome with an error state already present',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_error',
          project: buildShellChromeProject(),
          errorMessage: 'Shell render failure',
        ),
      );

      expect(find.text('Shell render failure'), findsOneWidget);
    });
  });
}
