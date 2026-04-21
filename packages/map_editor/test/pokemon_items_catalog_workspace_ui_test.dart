import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart';
import 'package:map_editor/src/application/use_cases/load_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_items_catalog_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokemon_catalogs_workspace.dart';
import 'package:map_editor/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart';
import 'package:path/path.dart' as p;

void main() {
  const project = ProjectManifest(
    name: 'Items Catalog UI Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  testWidgets('Items catalog shows a no project state without crashing',
      (tester) async {
    await _pumpItemsWorkspace(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.items,
      ),
    );

    expect(
      find.text('Ouvre un projet pour afficher le catalogue des items.'),
      findsOneWidget,
    );
  });

  testWidgets('Items catalog shows empty state when project has no local items',
      (tester) async {
    await _pumpItemsWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/items_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.items,
      ),
      overrides: [
        pokemonItemsCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonItemsCatalogView(
            entries: <PokemonItemCatalogEntryView>[],
            isAvailable: false,
            description: 'Catalogue local des objets indisponible.',
            loadState: PokemonItemsCatalogLoadState.missingCatalog,
          ),
        ),
      ],
    );

    expect(find.text('Items'), findsWidgets);
    expect(
      find.textContaining('Aucun item local pour le moment.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('data/pokemon/catalogs/items.json'),
      findsOneWidget,
    );
  });

  testWidgets('Items catalog lists local items and selects the first item',
      (tester) async {
    await _pumpItemsWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/items_catalog_ui_test',
        project: project,
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
                shortEffectText: 'Catches wild Pokémon.',
              ),
              PokemonItemCatalogEntryView(
                id: 'potion',
                name: 'Potion',
                categoryId: 'medicine',
                pocketId: 'medicine',
                cost: 300,
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des objets.',
          ),
        ),
      ],
    );

    expect(find.byKey(const Key('items-catalog-list')), findsOneWidget);
    expect(find.text('Poké Ball'), findsWidgets);
    expect(find.text('Potion'), findsWidgets);
    expect(find.byKey(const Key('items-catalog-detail-poke-ball')), findsOneWidget);
    expect(find.text('Catches wild Pokémon.'), findsOneWidget);
  });

  testWidgets('Items catalog search filters by name id category pocket and effect',
      (tester) async {
    await _pumpItemsWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/items_catalog_ui_test',
        project: project,
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
                shortEffectText: 'Catches wild Pokémon.',
              ),
              PokemonItemCatalogEntryView(
                id: 'potion',
                name: 'Potion',
                categoryId: 'medicine',
                pocketId: 'medicine',
                shortEffectText: 'Restores HP.',
              ),
              PokemonItemCatalogEntryView(
                id: 'x-attack',
                name: 'X Attack',
                categoryId: 'battle-items',
                pocketId: 'battle-items',
                shortEffectText: 'Boosts Attack.',
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des objets.',
          ),
        ),
      ],
    );

    await tester.enterText(
      find.byKey(const Key('items-catalog-search-field')),
      'medicine',
    );
    await tester.pumpAndSettle();
    expect(find.text('Potion'), findsWidgets);
    expect(find.text('Poké Ball'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('items-catalog-search-field')),
      'poke-ball',
    );
    await tester.pumpAndSettle();
    expect(find.text('Poké Ball'), findsWidgets);
    expect(find.text('Potion'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('items-catalog-search-field')),
      'boosts',
    );
    await tester.pumpAndSettle();
    expect(find.text('X Attack'), findsWidgets);
    expect(find.text('Poké Ball'), findsNothing);
  });

  testWidgets('Items catalog keeps valid items visible when diagnostics exist',
      (tester) async {
    await _pumpItemsWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/items_catalog_ui_test',
        project: project,
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
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des objets.',
            diagnostics: <PokemonItemsCatalogDiagnostic>[
              PokemonItemsCatalogDiagnostic(
                message: 'Items catalog entry "broken-item" has an empty name.',
                entryId: 'broken-item',
                entryIndex: 1,
              ),
            ],
          ),
        ),
      ],
    );

    expect(find.text('Poké Ball'), findsWidgets);
    expect(find.textContaining('1 entrée ignorée'), findsOneWidget);
  });

  testWidgets('Items catalog shows an invalid-catalog state when every entry is ignored',
      (tester) async {
    await _pumpItemsWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/items_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.items,
      ),
      overrides: [
        pokemonItemsCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonItemsCatalogView(
            entries: <PokemonItemCatalogEntryView>[],
            isAvailable: true,
            description: 'Catalogue local des objets.',
            diagnostics: <PokemonItemsCatalogDiagnostic>[
              PokemonItemsCatalogDiagnostic(
                message: 'Items catalog entry "broken-item" has an empty name.',
                entryId: 'broken-item',
                entryIndex: 0,
              ),
            ],
          ),
        ),
      ],
    );

    expect(
      find.textContaining(
        'Le catalogue local des items contient uniquement des entrées invalides.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('1 entrée ignorée'), findsOneWidget);
  });

  testWidgets('Items catalog detail formats missing values as dash',
      (tester) async {
    await _pumpItemsWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/items_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.items,
      ),
      overrides: [
        pokemonItemsCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonItemsCatalogView(
            entries: <PokemonItemCatalogEntryView>[
              PokemonItemCatalogEntryView(
                id: 'mystery-item',
                name: 'Mystery Item',
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des objets.',
          ),
        ),
      ],
    );

    expect(find.byKey(const Key('items-catalog-detail-mystery-item')), findsOneWidget);
    expect(find.text('Cost'), findsWidgets);
    expect(find.text('Fling power'), findsWidgets);
    expect(find.text('—'), findsWidgets);
  });

  test('Items catalog local sprite helper detects an existing local sprite',
      () async {
    final tempRoot = Directory(
      p.join(
        Directory.systemTemp.path,
        'items_catalog_sprite_ui_${DateTime.now().microsecondsSinceEpoch}',
      ),
    );
    final spriteFile = File(
      '${tempRoot.path}/data/pokemon/assets/items/poke-ball.png',
    );
    await spriteFile.create(recursive: true);
    await spriteFile.writeAsBytes(_tinyTransparentPng);

    expect(
      hasPokemonItemsLocalSpriteAsset(
        projectRootPath: tempRoot.path,
        localSpritePath: 'data/pokemon/assets/items/poke-ball.png',
      ),
      isTrue,
    );
  });

  testWidgets('Items catalog keeps sprite metadata text-only when only spriteUrl exists',
      (tester) async {
    await _pumpItemsWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/items_catalog_ui_test',
        project: project,
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
                spriteUrl:
                    'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png',
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des objets.',
          ),
        ),
      ],
    );

    expect(find.text('Sprite metadata available'), findsOneWidget);
    expect(
      find.textContaining(
        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('items-catalog-local-sprite-preview')), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('Items catalog preview sync uses the workspace syncer and shows a summary',
      (tester) async {
    String? capturedProjectRootPath;
    bool? capturedDryRun;
    bool? capturedDownloadSprites;

    await _pumpItemsWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/items_catalog_ui_test',
        project: project,
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
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des objets.',
          ),
        ),
        pokemonItemsCatalogWorkspaceSyncerProvider.overrideWithValue(
          (
            projectRootPath, {
            bool dryRun = false,
            bool downloadSprites = false,
            bool overwriteSprites = false,
          }) async {
            capturedProjectRootPath = projectRootPath;
            capturedDryRun = dryRun;
            capturedDownloadSprites = downloadSprites;
            return const PokemonItemsCatalogSyncResult(
              dryRun: true,
              externalEntryCount: 2,
              createdIds: <String>['potion'],
              updatedIds: <String>['poke-ball'],
              unchangedIds: <String>[],
              preservedLocalOnlyIds: <String>[],
              downloadedSpriteIds: <String>[],
              skippedSpriteIds: <String>[],
              failedSpriteIds: <String>[],
              resultingEntryCount: 2,
            );
          },
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('items-catalog-preview-sync-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(capturedProjectRootPath, '/tmp/items_catalog_ui_test');
    expect(capturedDryRun, isTrue);
    expect(capturedDownloadSprites, isFalse);
    expect(find.textContaining('Prévisualisation'), findsOneWidget);
  });
}

const List<int> _tinyTransparentPng = <int>[
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
  0,
  0,
  0,
  1,
  0,
  0,
  0,
  1,
  8,
  6,
  0,
  0,
  0,
  31,
  21,
  196,
  137,
  0,
  0,
  0,
  12,
  73,
  68,
  65,
  84,
  8,
  153,
  99,
  0,
  1,
  0,
  0,
  5,
  0,
  1,
  13,
  10,
  44,
  181,
  0,
  0,
  0,
  0,
  73,
  69,
  78,
  68,
  174,
  66,
  96,
  130,
];

Future<ProviderContainer> _pumpItemsWorkspace(
  WidgetTester tester, {
  required EditorState initialState,
  List<Override> overrides = const <Override>[],
}) async {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);

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
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 50));
  return container;
}
