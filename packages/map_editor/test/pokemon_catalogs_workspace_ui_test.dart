import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokemon_catalogs_workspace.dart';

Future<void> _pumpCatalogsWorkspace(
  WidgetTester tester, {
  required ProviderContainer container,
  required EditorState initialState,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 980));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosApp(
        home: MacosTheme(
          data: MacosThemeData.light(),
          child: const CupertinoPageScaffold(
            child: SizedBox.expand(
              child: PokemonCatalogsWorkspace(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
}

Widget _buildCatalogsHost({
  required ProviderContainer container,
  required bool showWorkspace,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MacosApp(
      home: MacosTheme(
        data: MacosThemeData.light(),
        child: CupertinoPageScaffold(
          child: SizedBox.expand(
            child: showWorkspace
                ? const PokemonCatalogsWorkspace()
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PokemonCatalogsWorkspace', () {
    testWidgets(
        'renders the real Pokédex workspace when the Pokédex section is active',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonMovesCatalogView(
              entries: <PokemonMoveCatalogEntryView>[
                PokemonMoveCatalogEntryView(
                  id: 'water-gun',
                  name: 'Water Gun',
                  type: 'water',
                  category: 'special',
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
      addTearDown(container.dispose);

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
        initialState: const EditorState(
          projectRootPath: '/tmp/pokemon_catalogs_workspace_test',
          project: ProjectManifest(
            name: 'Catalogs Test Project',
            maps: <ProjectMapEntry>[
              ProjectMapEntry(
                id: 'lab',
                name: 'Lab',
                relativePath: 'maps/lab.json',
              ),
            ],
            tilesets: <ProjectTilesetEntry>[],
          ),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.pokedex,
        ),
      );

      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsNothing);
      expect(find.textContaining('Pokédex est encore vide'), findsOneWidget);
    });

    testWidgets(
        'renders the Moves workspace when the Moves section is active',
        (tester) async {
      final container = ProviderContainer(
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
      addTearDown(container.dispose);

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
        initialState: const EditorState(
          projectRootPath: '/tmp/pokemon_catalogs_moves_test',
          project: ProjectManifest(
            name: 'Catalogs Test Project',
            maps: <ProjectMapEntry>[
              ProjectMapEntry(
                id: 'lab',
                name: 'Lab',
                relativePath: 'maps/lab.json',
              ),
            ],
            tilesets: <ProjectTilesetEntry>[],
          ),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.moves,
        ),
      );

      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );
      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the Items shell when the Items section is active',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonMovesCatalogView(
              entries: <PokemonMoveCatalogEntryView>[
                PokemonMoveCatalogEntryView(
                  id: 'water-gun',
                  name: 'Water Gun',
                  type: 'water',
                  category: 'special',
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
      addTearDown(container.dispose);

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
        initialState: const EditorState(
          projectRootPath: '/tmp/pokemon_catalogs_items_test',
          project: ProjectManifest(
            name: 'Catalogs Test Project',
            maps: <ProjectMapEntry>[
              ProjectMapEntry(
                id: 'lab',
                name: 'Lab',
                relativePath: 'maps/lab.json',
              ),
            ],
            tilesets: <ProjectTilesetEntry>[],
          ),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.items,
        ),
      );

      expect(find.text('Items'), findsWidgets);
      expect(
        find.text('Le futur catalogue des objets du projet vivra ici.'),
        findsOneWidget,
      );
      expect(find.textContaining('structure de workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the selected section when the workspace remounts',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_remount_test',
        project: ProjectManifest(
          name: 'Catalogs Test Project',
          maps: <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'lab',
              name: 'Lab',
              relativePath: 'maps/lab.json',
            ),
          ],
          tilesets: <ProjectTilesetEntry>[],
        ),
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      );

      await tester.binding.setSurfaceSize(const Size(1440, 980));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          showWorkspace: true,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          showWorkspace: false,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          showWorkspace: true,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );
    });
  });
}
