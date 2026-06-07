import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/ui/canvas/pokemon_catalogs_workspace.dart';

void main() {
  const project = ProjectManifest(surfaceCatalog: const ProjectSurfaceCatalog.empty(), 
    name: 'Moves Catalog UI Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  testWidgets('Moves catalog shows a no project state without crashing',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
    );

    expect(
      find.text('Ouvre un projet pour afficher le catalogue des moves.'),
      findsOneWidget,
    );
  });

  testWidgets('Moves catalog shows empty state when project has no local moves',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonMovesCatalogView(
            entries: <PokemonMoveCatalogEntryView>[],
            isAvailable: false,
            description: 'Catalogue local des attaques indisponible.',
            loadState: PokemonMovesCatalogLoadState.missingCatalog,
          ),
        ),
      ],
    );

    expect(find.text('Moves'), findsWidgets);
    expect(
      find.textContaining('Aucun move local pour le moment.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('data/pokemon/catalogs/moves.json'),
      findsOneWidget,
    );
  });

  testWidgets('Moves catalog lists local moves and selects the first move',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
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
                shortEffectText: 'Inflicts regular damage.',
                shortDesc: 'Inflicts regular damage.',
              ),
              PokemonMoveCatalogEntryView(
                id: 'thunder-shock',
                name: 'Thunder Shock',
                type: 'electric',
                category: 'special',
                power: 40,
                accuracy: 100,
                pp: 30,
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
          ),
        ),
      ],
    );

    expect(find.byKey(const Key('moves-catalog-list')), findsOneWidget);
    expect(find.text('Water Gun'), findsWidgets);
    expect(find.text('Thunder Shock'), findsWidgets);
    expect(find.byKey(const Key('moves-catalog-detail-water-gun')), findsOneWidget);
    expect(find.text('Inflicts regular damage.'), findsOneWidget);
  });

  testWidgets('Moves catalog shows sync actions when a project is open',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
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
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
          ),
        ),
      ],
    );

    expect(find.byKey(const Key('moves-catalog-preview-sync-button')), findsOneWidget);
    expect(find.byKey(const Key('moves-catalog-run-sync-button')), findsOneWidget);
    expect(find.text('Prévisualiser la synchro'), findsOneWidget);
    expect(find.text('Sync depuis Showdown'), findsOneWidget);
  });

  testWidgets('Moves catalog search filters by name id type and damage class',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
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
              ),
              PokemonMoveCatalogEntryView(
                id: 'thunder-shock',
                name: 'Thunder Shock',
                type: 'electric',
                category: 'special',
              ),
              PokemonMoveCatalogEntryView(
                id: 'growl',
                name: 'Growl',
                category: 'status',
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
          ),
        ),
      ],
    );

    await tester.enterText(
      find.byKey(const Key('moves-catalog-search-field')),
      'water',
    );
    await tester.pumpAndSettle();
    expect(find.text('Water Gun'), findsWidgets);
    expect(find.text('Thunder Shock'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('moves-catalog-search-field')),
      'status',
    );
    await tester.pumpAndSettle();
    expect(find.text('Growl'), findsWidgets);
    expect(find.text('Water Gun'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('moves-catalog-search-field')),
      'thunder',
    );
    await tester.pumpAndSettle();
    expect(find.text('Thunder Shock'), findsWidgets);
    expect(find.text('Growl'), findsNothing);
  });

  testWidgets('Moves catalog keeps valid moves visible when diagnostics exist',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
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
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
            diagnostics: <PokemonMovesCatalogDiagnostic>[
              PokemonMovesCatalogDiagnostic(
                message: 'Moves catalog entry "broken-move" has an empty name.',
                entryId: 'broken-move',
                entryIndex: 1,
              ),
            ],
          ),
        ),
      ],
    );

    expect(find.text('Water Gun'), findsWidgets);
    expect(find.textContaining('1 entrée ignorée'), findsOneWidget);
  });

  testWidgets('Moves catalog shows an invalid-catalog state when every entry is ignored',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonMovesCatalogView(
            entries: <PokemonMoveCatalogEntryView>[],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
            diagnostics: <PokemonMovesCatalogDiagnostic>[
              PokemonMovesCatalogDiagnostic(
                message: 'Moves catalog entry "broken-move" has an empty name.',
                entryId: 'broken-move',
                entryIndex: 0,
              ),
            ],
          ),
        ),
      ],
    );

    expect(
      find.textContaining(
        'Le catalogue local des moves contient uniquement des entrées invalides.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('1 entrée ignorée'), findsOneWidget);
  });

  testWidgets('Moves catalog detail formats missing values as dash',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonMovesCatalogView(
            entries: <PokemonMoveCatalogEntryView>[
              PokemonMoveCatalogEntryView(
                id: 'growl',
                name: 'Growl',
                category: 'status',
                power: null,
                accuracy: null,
                pp: null,
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
          ),
        ),
      ],
    );

    expect(find.byKey(const Key('moves-catalog-detail-growl')), findsOneWidget);
    expect(find.text('Power'), findsWidgets);
    expect(find.text('Accuracy'), findsWidgets);
    expect(find.text('PP'), findsWidgets);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('Moves catalog preview sync uses the workspace syncer and shows a summary',
      (tester) async {
    var loaderCallCount = 0;
    String? capturedProjectRootPath;
    bool? capturedDryRun;

    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async {
            loaderCallCount += 1;
            return const PokemonMovesCatalogView(
              entries: <PokemonMoveCatalogEntryView>[
                PokemonMoveCatalogEntryView(
                  id: 'water-gun',
                  name: 'Water Gun',
                  type: 'water',
                  category: 'special',
                ),
              ],
              isAvailable: true,
              description: 'Catalogue local des attaques.',
            );
          },
        ),
        pokemonMovesCatalogWorkspaceSyncerProvider.overrideWithValue(
          (
            projectRootPath, {
            bool dryRun = false,
          }) async {
            capturedProjectRootPath = projectRootPath;
            capturedDryRun = dryRun;
            return const PokemonMovesCatalogSyncResult(
              dryRun: true,
              externalEntryCount: 3,
              createdIds: <String>['swift'],
              updatedIds: <String>['water-gun'],
              unchangedIds: <String>['growl'],
              preservedLocalOnlyIds: <String>['custom-move'],
              resultingEntryCount: 4,
              warnings: <String>['Ignored malformed external move "broken".'],
            );
          },
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('moves-catalog-preview-sync-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(capturedProjectRootPath, '/tmp/moves_catalog_ui_test');
    expect(capturedDryRun, isTrue);
    expect(find.byKey(const Key('moves-catalog-sync-status')), findsOneWidget);
    expect(find.textContaining('Prévisualisation'), findsOneWidget);
    expect(
      find.textContaining('Ignored malformed external move "broken".'),
      findsOneWidget,
    );
    expect(loaderCallCount, 1);
  });

  testWidgets('Moves catalog run sync refreshes the local catalog after success',
      (tester) async {
    var loaderCallCount = 0;
    var hasSynced = false;
    bool? capturedDryRun;

    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async {
            loaderCallCount += 1;
            return PokemonMovesCatalogView(
              entries: hasSynced
                  ? const <PokemonMoveCatalogEntryView>[
                      PokemonMoveCatalogEntryView(
                        id: 'thunderbolt',
                        name: 'Thunderbolt',
                        type: 'electric',
                        category: 'special',
                        power: 90,
                      ),
                    ]
                  : const <PokemonMoveCatalogEntryView>[
                      PokemonMoveCatalogEntryView(
                        id: 'water-gun',
                        name: 'Water Gun',
                        type: 'water',
                        category: 'special',
                        power: 40,
                      ),
                    ],
              isAvailable: true,
              description: 'Catalogue local des attaques.',
            );
          },
        ),
        pokemonMovesCatalogWorkspaceSyncerProvider.overrideWithValue(
          (
            projectRootPath, {
            bool dryRun = false,
          }) async {
            capturedDryRun = dryRun;
            hasSynced = true;
            return const PokemonMovesCatalogSyncResult(
              dryRun: false,
              externalEntryCount: 1,
              createdIds: <String>['thunderbolt'],
              updatedIds: <String>[],
              unchangedIds: <String>[],
              preservedLocalOnlyIds: <String>[],
              resultingEntryCount: 1,
            );
          },
        ),
      ],
    );

    expect(find.text('Water Gun'), findsWidgets);

    await tester.tap(find.byKey(const Key('moves-catalog-run-sync-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(capturedDryRun, isFalse);
    expect(find.text('Thunderbolt'), findsWidgets);
    expect(find.text('Water Gun'), findsNothing);
    expect(loaderCallCount, greaterThanOrEqualTo(2));
    expect(find.textContaining('Synchronisation'), findsOneWidget);
  });

  testWidgets('Moves catalog sync errors do not crash the workspace',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
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
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
          ),
        ),
        pokemonMovesCatalogWorkspaceSyncerProvider.overrideWithValue(
          (
            projectRootPath, {
            bool dryRun = false,
          }) async {
            throw StateError('showdown offline');
          },
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('moves-catalog-run-sync-button')));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('Échec de la sync moves'), findsOneWidget);
    expect(find.textContaining('showdown offline'), findsOneWidget);
    expect(find.text('Water Gun'), findsWidgets);
  });
}

Future<ProviderContainer> _pumpMovesWorkspace(
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
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
  return container;
}
