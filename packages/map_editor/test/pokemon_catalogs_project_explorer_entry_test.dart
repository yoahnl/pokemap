import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';

void main() {
  testWidgets(
      'ProjectExplorerPanel shows Catalogues Pokémon with Pokédex, Moves and Items child entries',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokemon_catalogs_project_explorer',
      project: ProjectManifest(
        name: 'catalogs_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 360,
                height: 900,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Catalogues Pokémon'), findsOneWidget);
    expect(
      find.text('Pokédex, Moves et Items dans un espace guidé unique'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pokemon-catalog-entry-pokedex')),
        findsOneWidget);
    expect(find.byKey(const Key('pokemon-catalog-entry-moves')), findsOneWidget);
    expect(find.byKey(const Key('pokemon-catalog-entry-items')), findsOneWidget);
    expect(find.text('Pokédex'), findsWidgets);
    expect(find.text('Moves'), findsWidgets);
    expect(find.text('Items'), findsWidgets);
    expect(
      find.text('Catalogue local des objets du projet'),
      findsOneWidget,
    );
  });

  testWidgets('ProjectExplorerPanel taps update the active catalog section',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokemon_catalogs_project_explorer_taps',
      project: ProjectManifest(
        name: 'catalogs_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      ),
    );

    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 360,
                height: 900,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('pokemon-catalog-entry-moves')));
    await tester.pumpAndSettle();

    final movesRow = tester.widget<EditorSidebarListRow>(
      find.byKey(const Key('pokemon-catalog-entry-moves')),
    );
    final afterMoves = container.read(editorNotifierProvider);
    expect(movesRow.selected, isTrue);
    expect(afterMoves.workspaceMode, EditorWorkspaceMode.pokedex);
    expect(afterMoves.pokemonCatalogSection, PokemonCatalogSection.moves);

    await tester.tap(find.byKey(const Key('pokemon-catalog-entry-items')));
    await tester.pumpAndSettle();

    final itemsRow = tester.widget<EditorSidebarListRow>(
      find.byKey(const Key('pokemon-catalog-entry-items')),
    );
    final afterItems = container.read(editorNotifierProvider);
    expect(itemsRow.selected, isTrue);
    expect(afterItems.pokemonCatalogSection, PokemonCatalogSection.items);

    await tester.tap(find.byKey(const Key('pokemon-catalog-entry-pokedex')));
    await tester.pumpAndSettle();

    final pokedexRow = tester.widget<EditorSidebarListRow>(
      find.byKey(const Key('pokemon-catalog-entry-pokedex')),
    );
    final afterPokedex = container.read(editorNotifierProvider);
    expect(pokedexRow.selected, isTrue);
    expect(afterPokedex.pokemonCatalogSection, PokemonCatalogSection.pokedex);
  });
}
