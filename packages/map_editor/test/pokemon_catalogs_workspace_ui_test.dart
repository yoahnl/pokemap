import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokemon_catalogs_workspace.dart';

Future<void> _pumpCatalogsWorkspace(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 980));
  addTearDown(() => tester.binding.setSurfaceSize(null));

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
  await tester.pump(const Duration(milliseconds: 300));
}

ProjectManifest _project() {
  return const ProjectManifest(
    name: 'Catalogs Test Project',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'lab',
        name: 'Lab',
        relativePath: 'maps/lab.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[],
  );
}

Widget _buildCatalogsHost({
  required ProviderContainer container,
  required PageStorageBucket bucket,
  required bool showWorkspace,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MacosApp(
      home: MacosTheme(
        data: MacosThemeData.light(),
        child: CupertinoPageScaffold(
          child: PageStorage(
            bucket: bucket,
            child: SizedBox.expand(
              child: showWorkspace
                  ? const PokemonCatalogsWorkspace()
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PokemonCatalogsWorkspace', () {
    testWidgets(
        'shows Catalogues Pokémon navigation and defaults to the real Pokédex workspace',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_workspace_test',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.pokedex,
      );

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
      );

      expect(find.text('Choisissez un catalogue.'), findsOneWidget);
      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsOneWidget);
      expect(find.byKey(const Key('pokemon-catalogs-tab-pokedex')),
          findsOneWidget);
      expect(
          find.byKey(const Key('pokemon-catalogs-tab-moves')), findsOneWidget);
      expect(
          find.byKey(const Key('pokemon-catalogs-tab-items')), findsOneWidget);
      expect(find.textContaining('Pokédex est encore vide'), findsOneWidget);
    });

    testWidgets('opens the Moves shell without crashing', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_moves_test',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.pokedex,
      );

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
      );

      await tester.tap(find.byKey(const Key('pokemon-catalogs-tab-moves')));
      await tester.pumpAndSettle();

      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Le futur catalogue des capacités du projet vivra ici.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Pokédex > Learnset'),
        findsOneWidget,
      );
      expect(find.textContaining('lot dédié'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('opens the Items shell without crashing', (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_items_test',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.pokedex,
      );

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
      );

      await tester.tap(find.byKey(const Key('pokemon-catalogs-tab-items')));
      await tester.pumpAndSettle();

      expect(find.text('Items'), findsWidgets);
      expect(
        find.text('Le futur catalogue des objets du projet vivra ici.'),
        findsOneWidget,
      );
      expect(find.textContaining('structure de workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('restores the selected section after remounting the workspace',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      final bucket = PageStorageBucket();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_restore_test',
        project: _project(),
        workspaceMode: EditorWorkspaceMode.pokedex,
      );

      await tester.binding.setSurfaceSize(const Size(1440, 980));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          bucket: bucket,
          showWorkspace: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('pokemon-catalogs-tab-moves')));
      await tester.pumpAndSettle();
      expect(find.text('Moves'), findsWidgets);

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          bucket: bucket,
          showWorkspace: false,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          bucket: bucket,
          showWorkspace: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Le futur catalogue des capacités du projet vivra ici.'),
          findsOneWidget);
    });
  });
}
