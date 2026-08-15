import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/app/providers/editor/project_use_case_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/authoring_api/encounter_table_persistence_gateway.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/domain/repositories/repositories.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';
import 'package:map_editor/src/ui/panels/encounter_tables_panel.dart';
import 'package:path/path.dart' as p;

void main() {
  Future<void> pumpEncounterPanel(
    WidgetTester tester,
    ProviderContainer container, {
    double width = 1280,
    double height = 1800,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 2200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: width,
                height: height,
                child: const EncounterTablesPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'filters the encounter library case-insensitively and configures the selected table at 1280',
    (tester) async {
      final repository = _FakeProjectRepository();
      const workspace = _FakeWorkspace();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => _speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/encounter_library_test',
        project: ProjectManifest(
          name: 'encounter_library_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          encounterTables: <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'route_1_grass',
              name: 'Route 1 — Hautes herbes',
              encounterKind: EncounterKind.walk,
              chancePerStep: 0.12,
            ),
            ProjectEncounterTable(
              id: 'moon_cave_surf',
              name: 'Grotte Sélénite — Eau',
              encounterKind: EncounterKind.surf,
              chancePerStep: 0.08,
            ),
          ],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('encounter-library-search-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('encounter-tables-table-toggle-route_1_grass')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('encounter-tables-table-toggle-moon_cave_surf')),
        findsOneWidget,
      );

      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('encounter-library-search-field')),
          matching: find.byType(EditableText),
        ),
        'SÉLÉNITE',
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('encounter-tables-table-toggle-route_1_grass')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('encounter-tables-table-toggle-moon_cave_surf')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-moon_cave_surf')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Configuration de la table'), findsWidgets);
      expect(
        find.byKey(
          const Key('encounter-tables-edit-name-field-moon_cave_surf'),
        ),
        findsOneWidget,
      );
      expect(find.text('Runtime certifié'), findsWidgets);
    },
  );

  testWidgets(
    'renders roster order with distinct relative and per-step probabilities',
    (tester) async {
      final repository = _FakeProjectRepository();
      const workspace = _FakeWorkspace();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => _speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/encounter_roster_test',
        project: ProjectManifest(
          name: 'encounter_roster_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          encounterTables: <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'route_1_grass',
              name: 'Route 1 — Hautes herbes',
              encounterKind: EncounterKind.walk,
              chancePerStep: 0.2,
              entries: <ProjectEncounterEntry>[
                ProjectEncounterEntry(
                  speciesId: 'bulbasaur',
                  minLevel: 2,
                  maxLevel: 4,
                  weight: 3,
                ),
                ProjectEncounterEntry(
                  speciesId: 'pikachu',
                  minLevel: 3,
                  maxLevel: 5,
                  weight: 1,
                ),
              ],
            ),
          ],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final firstRow = find.byKey(
        const Key('encounter-roster-entry-route_1_grass-0'),
      );
      final secondRow = find.byKey(
        const Key('encounter-roster-entry-route_1_grass-1'),
      );

      expect(firstRow, findsOneWidget);
      expect(secondRow, findsOneWidget);
      expect(
        tester.getTopLeft(firstRow).dy,
        lessThan(tester.getTopLeft(secondRow).dy),
      );
      expect(find.text('75.0% du roster'), findsOneWidget);
      expect(find.text('15.0% par pas'), findsOneWidget);
      expect(find.text('25.0% du roster'), findsOneWidget);
      expect(find.text('5.0% par pas'), findsOneWidget);
      expect(
        find.byKey(const Key('encounter-roster-sprite-route_1_grass-0')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('encounter-roster-sprite-route_1_grass-0')),
          matching: find.byIcon(CupertinoIcons.photo),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'does not expose a false zero probability for an invalid roster',
    (tester) async {
      final repository = _FakeProjectRepository();
      const workspace = _FakeWorkspace();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => _speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/encounter_invalid_roster_test',
        project: ProjectManifest(
          name: 'encounter_invalid_roster_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          encounterTables: <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'invalid_grass',
              name: 'Invalid Grass',
              encounterKind: EncounterKind.walk,
              chancePerStep: 0.2,
              entries: <ProjectEncounterEntry>[
                ProjectEncounterEntry(
                  speciesId: 'bulbasaur',
                  minLevel: 2,
                  maxLevel: 4,
                  weight: 0,
                ),
                ProjectEncounterEntry(
                  speciesId: 'bulbasaur',
                  minLevel: 3,
                  maxLevel: 5,
                  weight: 0,
                ),
              ],
            ),
          ],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Part indisponible'), findsNWidgets(2));
      expect(find.text('Chance par pas indisponible'), findsNWidgets(2));
      expect(find.byType(PokeMapProgressBar), findsNothing);
      expect(
        find.text('L’espèce "bulbasaur" apparaît aux entrées 1, 2.'),
        findsOneWidget,
      );
      expect(
        find.text(
          'La somme des poids doit être strictement supérieure à zéro.',
        ),
        findsOneWidget,
      );
      expect(find.text('Table valide'), findsNothing);
    },
  );

  testWidgets(
    'renders catalog thumbnails in the roster, inspector, and species suggestions',
    (tester) async {
      final projectRoot = await tester.runAsync(
        () => Directory.systemTemp.createTemp('encounter_thumbnail_test_'),
      );
      if (projectRoot == null) {
        fail('Unable to create the temporary encounter thumbnail fixture.');
      }
      addTearDown(() => projectRoot.delete(recursive: true));
      const thumbnailBytes =
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=';
      const bulbasaurRelativePath =
          'assets/pokemon/sprites/bulbasaur/front.png';
      const pikachuRelativePath = 'assets/pokemon/sprites/pikachu/front.png';
      await tester.runAsync(() async {
        for (final relativePath in <String>[
          bulbasaurRelativePath,
          pikachuRelativePath,
        ]) {
          final file = File(p.join(projectRoot.path, relativePath));
          await file.parent.create(recursive: true);
          await file.writeAsBytes(base64Decode(thumbnailBytes));
        }
      });

      final repository = _FakeProjectRepository();
      const workspace = _FakeWorkspace();
      final speciesEntries = <PokemonDatabaseIndexEntry>[
        PokemonDatabaseIndexEntry(
          id: 'bulbasaur',
          nationalDex: 1,
          primaryName: 'Bulbizarre',
          genIntroduced: 1,
          types: <String>['grass', 'poison'],
          isEnabledInProject: true,
          refs: const PokemonDatabaseIndexRefs(
            learnset: 'bulbasaur',
            evolution: 'bulbasaur',
            media: 'bulbasaur',
          ),
          thumbnailRelativePath: bulbasaurRelativePath,
        ),
        PokemonDatabaseIndexEntry(
          id: 'pikachu',
          nationalDex: 25,
          primaryName: 'Pikachu',
          genIntroduced: 1,
          types: <String>['electric'],
          isEnabledInProject: true,
          refs: const PokemonDatabaseIndexRefs(
            learnset: 'pikachu',
            evolution: 'pikachu',
            media: 'pikachu',
          ),
          thumbnailRelativePath: pikachuRelativePath,
        ),
      ];
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: projectRoot.path,
        project: const ProjectManifest(
          name: 'encounter_thumbnail_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          encounterTables: <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'route_1_grass',
              name: 'Route 1 — Hautes herbes',
              encounterKind: EncounterKind.walk,
              chancePerStep: 0.2,
              entries: <ProjectEncounterEntry>[
                ProjectEncounterEntry(
                  speciesId: 'bulbasaur',
                  minLevel: 2,
                  maxLevel: 4,
                  weight: 3,
                ),
              ],
            ),
          ],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pumpAndSettle();

      final rosterThumbnail = tester.widget<PokeMapAssetThumbnail>(
        find.byKey(const Key('encounter-roster-sprite-route_1_grass-0')),
      );
      expect(
        rosterThumbnail.imageFilePath,
        p.join(projectRoot.path, bulbasaurRelativePath),
      );
      expect((rosterThumbnail as dynamic).imageScale, 3);

      await tester.tap(
        find.byKey(const Key('encounter-roster-entry-route_1_grass-0')),
      );
      await tester.pumpAndSettle();

      final inspectorThumbnail = tester.widget<PokeMapAssetThumbnail>(
        find.byKey(const Key('encounter-entry-species-thumbnail')),
      );
      expect(
        inspectorThumbnail.imageFilePath,
        p.join(projectRoot.path, bulbasaurRelativePath),
      );

      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-species-field')),
        'pika',
      );
      await tester.pumpAndSettle();

      final suggestionThumbnail = tester.widget<PokeMapAssetThumbnail>(
        find.byKey(const Key('encounter-species-suggestion-thumbnail-pikachu')),
      );
      expect(
        suggestionThumbnail.imageFilePath,
        p.join(projectRoot.path, pikachuRelativePath),
      );
    },
  );

  testWidgets(
    'edits and confirms deletion from the contextual entry inspector',
    (tester) async {
      final repository = _FakeProjectRepository();
      const workspace = _FakeWorkspace();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => _speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/encounter_inspector_test',
        project: ProjectManifest(
          name: 'encounter_inspector_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          encounterTables: <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'route_1_grass',
              name: 'Route 1 — Hautes herbes',
              encounterKind: EncounterKind.walk,
              chancePerStep: 0.2,
              entries: <ProjectEncounterEntry>[
                ProjectEncounterEntry(
                  speciesId: 'bulbasaur',
                  minLevel: 2,
                  maxLevel: 4,
                  weight: 3,
                ),
                ProjectEncounterEntry(
                  speciesId: 'pikachu',
                  minLevel: 3,
                  maxLevel: 5,
                  weight: 1,
                ),
              ],
            ),
          ],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Validation globale'), findsOneWidget);
      expect(find.text('Table valide'), findsOneWidget);

      await tester.tap(
        find.byKey(const Key('encounter-roster-entry-route_1_grass-0')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('encounter-entry-inspector')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-weight-field')),
        '5',
      );
      await tester.tap(
        find.byKey(const Key('encounter-tables-entry-save-button')),
      );
      await tester.pumpAndSettle();

      expect(
        container
            .read(editorNotifierProvider)
            .project!
            .encounterTables
            .single
            .entries
            .first
            .weight,
        5,
      );

      await tester.tap(
        find.byKey(const Key('encounter-roster-entry-route_1_grass-0')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('encounter-entry-delete-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(pokeMapConfirmationDialogKey), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byKey(pokeMapConfirmationDialogKey),
          matching: find.text('Annuler'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(pokeMapConfirmationDialogKey), findsNothing);
      expect(
        container
            .read(editorNotifierProvider)
            .project!
            .encounterTables
            .single
            .entries
            .length,
        2,
      );

      await tester.tap(find.byKey(const Key('encounter-entry-delete-button')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byKey(pokeMapConfirmationDialogKey),
          matching: find.text('Supprimer'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        container
            .read(editorNotifierProvider)
            .project!
            .encounterTables
            .single
            .entries
            .length,
        1,
      );
    },
  );

  testWidgets(
    'keeps the entry draft and exposes retry after persistence fails',
    (tester) async {
      final repository = _FakeProjectRepository(
        saveError: StateError('disk exploded'),
        remainingSaveFailures: 1,
      );
      const workspace = _FakeWorkspace();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => _speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/encounter_entry_failure_test',
        project: ProjectManifest(
          name: 'encounter_entry_failure_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          encounterTables: <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'route_1_grass',
              name: 'Route 1 — Hautes herbes',
              encounterKind: EncounterKind.walk,
              entries: <ProjectEncounterEntry>[
                ProjectEncounterEntry(
                  speciesId: 'bulbasaur',
                  minLevel: 2,
                  maxLevel: 4,
                  weight: 3,
                ),
              ],
            ),
          ],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(
        find.byKey(const Key('encounter-roster-entry-route_1_grass-0')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-weight-field')),
        '7',
      );
      await tester.tap(
        find.byKey(const Key('encounter-tables-entry-save-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('encounter-tables-entry-weight-field')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('encounter-tables-entry-weight-field')),
            )
            .controller!
            .text,
        '7',
      );
      expect(find.text('Réessayer'), findsOneWidget);
      expect(
        container
            .read(editorNotifierProvider)
            .project!
            .encounterTables
            .single
            .entries
            .single
            .weight,
        3,
      );

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(
        container
            .read(editorNotifierProvider)
            .project!
            .encounterTables
            .single
            .entries
            .single
            .weight,
        7,
      );
      expect(
        find.byKey(const Key('encounter-tables-entry-weight-field')),
        findsNothing,
      );
    },
  );

  testWidgets('keeps the entry inspector visible when deletion fails', (
    tester,
  ) async {
    final repository = _FakeProjectRepository(
      saveError: StateError('disk exploded'),
    );
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        encounterTablePersistenceGatewayProvider.overrideWithValue(
          _FakeEncounterTablePersistenceGateway(repository),
        ),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_entry_delete_failure_test',
      project: ProjectManifest(
        name: 'encounter_entry_delete_failure_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        encounterTables: <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'route_1_grass',
            name: 'Route 1 — Hautes herbes',
            encounterKind: EncounterKind.walk,
            entries: <ProjectEncounterEntry>[
              ProjectEncounterEntry(
                speciesId: 'missingno',
                minLevel: 5,
                maxLevel: 3,
                weight: 0,
              ),
            ],
          ),
        ],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(const Key('encounter-roster-entry-route_1_grass-0')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('encounter-entry-delete-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(pokeMapConfirmationDialogKey),
        matching: find.text('Supprimer'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Failed to delete encounter entry'),
      findsWidgets,
    );
    expect(find.byKey(const Key('encounter-entry-inspector')), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
    expect(
      container
          .read(editorNotifierProvider)
          .project!
          .encounterTables
          .single
          .entries
          .length,
      1,
    );
  });

  testWidgets(
    'creates a table and a valid encounter entry with local species assist',
    (tester) async {
      final semanticsHandle = tester.ensureSemantics();
      final repository = _FakeProjectRepository();
      const workspace = _FakeWorkspace();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => _speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/encounter_panel_test',
        project: ProjectManifest(
          name: 'encounter_panel_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(const Key('encounter-tables-new-table-button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('encounter-tables-create-name-field')),
        'Grass Patch',
      );
      await tester.enterText(
        find.byKey(const Key('encounter-tables-create-rate-percent-field')),
        '25',
      );
      await tester.enterText(
        find.byKey(const Key('encounter-tables-create-required-flags-field')),
        'route_1_open',
      );
      await tester.enterText(
        find.byKey(const Key('encounter-tables-create-tags-field')),
        'extérieur, commun, Extérieur',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('encounter-tables-create-submit-button')),
      );
      await tester.pumpAndSettle();

      final table = container
          .read(editorNotifierProvider)
          .project!
          .encounterTables
          .single;
      expect(table.id, 'grass_patch');
      expect(table.name, 'Grass Patch');
      expect(table.chancePerStep, 0.25);
      expect(
        table.conditions.single.params[ScriptConditionParams.flagName],
        'route_1_open',
      );
      expect(table.tags, <String>['extérieur', 'commun']);

      await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-grass_patch')),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('encounter-tables-add-entry-button-grass_patch')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-species-field')),
        'bulba',
      );
      await tester.pumpAndSettle();
      final suggestion = find.byKey(
        const Key('encounter-tables-entry-species-suggestion-bulbasaur'),
      );
      expect(
        find.bySemanticsLabel(RegExp('Choisir Bulbasaur, bulbasaur')),
        findsOneWidget,
      );
      tester
          .widget<FocusableActionDetector>(
            find.descendant(
              of: suggestion,
              matching: find.byType(FocusableActionDetector),
            ),
          )
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-min-level-field')),
        '2',
      );
      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-max-level-field')),
        '4',
      );
      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-weight-field')),
        '3',
      );

      final natureControl = find.byKey(
        const Key('encounter-entry-nature-control'),
      );
      await tester.ensureVisible(natureControl);
      tester
          .widget<PokeMapDropdownField<String>>(natureControl)
          .onChanged('jolly');
      await tester.pumpAndSettle();

      final shinyControl = find.byKey(
        const Key('encounter-entry-shiny-policy-control'),
      );
      await tester.ensureVisible(shinyControl);
      tester
          .widget<PokeMapDropdownField<ProjectEncounterShinyPolicy>>(
            shinyControl,
          )
          .onChanged(ProjectEncounterShinyPolicy.always);
      await tester.pumpAndSettle();

      final saveButton = find.byKey(
        const Key('encounter-tables-entry-save-button'),
      );
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final savedEntry = container
          .read(editorNotifierProvider)
          .project!
          .encounterTables
          .single
          .entries
          .single;
      expect(savedEntry.speciesId, 'bulbasaur');
      expect(savedEntry.minLevel, 2);
      expect(savedEntry.maxLevel, 4);
      expect(savedEntry.weight, 3);
      expect(savedEntry.pokemonOverrides?.natureId, 'jolly');
      expect(
        savedEntry.pokemonOverrides?.shinyPolicy,
        ProjectEncounterShinyPolicy.always,
      );
      expect(find.text('Bulbasaur'), findsOneWidget);
      expect(find.textContaining('Lv. 2–4'), findsOneWidget);
      expect(find.text('100.0% du roster'), findsOneWidget);
      semanticsHandle.dispose();
    },
  );

  testWidgets(
    'shows inline validation and blocks save when local species or levels are invalid',
    (tester) async {
      final repository = _FakeProjectRepository();
      const workspace = _FakeWorkspace();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => _speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/encounter_panel_test',
        project: ProjectManifest(
          name: 'encounter_panel_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          encounterTables: <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'grass_patch',
              name: 'Grass Patch',
              encounterKind: EncounterKind.walk,
            ),
          ],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-grass_patch')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('encounter-tables-add-entry-button-grass_patch')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-species-field')),
        'missingno',
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-min-level-field')),
        '10',
      );
      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-max-level-field')),
        '5',
      );
      await tester.enterText(
        find.byKey(const Key('encounter-tables-entry-weight-field')),
        '0',
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'L\'espèce "missingno" n\'est pas présente dans le Pokédex local.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Le niveau max doit être supérieur ou égal au niveau min.'),
        findsOneWidget,
      );
      expect(
        find.text('Le poids doit être un entier positif.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PokeMapButton>(
              find.byKey(const Key('encounter-tables-entry-save-button')),
            )
            .onPressed,
        isNull,
      );
      expect(
        container
            .read(editorNotifierProvider)
            .project!
            .encounterTables
            .single
            .entries,
        isEmpty,
      );
    },
  );

  testWidgets(
    'keeps the selected configuration after a successful table update',
    (tester) async {
      final repository = _FakeProjectRepository();
      const workspace = _FakeWorkspace();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => _speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/encounter_panel_test',
        project: ProjectManifest(
          name: 'encounter_panel_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          encounterTables: <ProjectEncounterTable>[
            ProjectEncounterTable(
              id: 'cave_floor',
              name: 'Cave Floor',
              encounterKind: EncounterKind.walk,
            ),
            ProjectEncounterTable(
              id: 'grass_patch',
              name: 'Grass Patch',
              encounterKind: EncounterKind.walk,
            ),
          ],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(const Key('encounter-tables-table-toggle-grass_patch')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('encounter-tables-edit-name-field-grass_patch')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('encounter-tables-edit-name-field-grass_patch')),
        'Tall Grass',
      );
      await tester.enterText(
        find.byKey(const Key('encounter-tables-edit-tags-field-grass_patch')),
        'route, early-game',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const Key('encounter-tables-save-table-button-grass_patch')),
      );
      await tester.pumpAndSettle();

      final savedTable = container
          .read(editorNotifierProvider)
          .project!
          .encounterTables
          .where((table) => table.id == 'grass_patch')
          .single;
      expect(savedTable.name, 'Tall Grass');
      expect(savedTable.tags, <String>['route', 'early-game']);
      expect(
        find.byKey(const Key('encounter-tables-edit-name-field-grass_patch')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('encounter-tables-edit-name-field-cave_floor')),
        findsNothing,
      );
      expect(find.text('Tall Grass'), findsWidgets);
    },
  );

  testWidgets('requires confirmation before deleting a table', (tester) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        encounterTablePersistenceGatewayProvider.overrideWithValue(
          _FakeEncounterTablePersistenceGateway(repository),
        ),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => _speciesEntries,
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_table_delete_test',
      project: ProjectManifest(
        name: 'encounter_table_delete_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        encounterTables: <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
          ProjectEncounterTable(
            id: 'cave_floor',
            name: 'Cave Floor',
            encounterKind: EncounterKind.walk,
          ),
        ],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(
      find.byKey(const Key('encounter-tables-delete-table-button-grass_patch')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(pokeMapConfirmationDialogKey), findsOneWidget);

    await tester.tap(find.widgetWithText(PokeMapButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(
      container.read(editorNotifierProvider).project!.encounterTables.length,
      2,
    );

    await tester.tap(
      find.byKey(const Key('encounter-tables-delete-table-button-grass_patch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PokeMapButton, 'Supprimer la table'));
    await tester.pumpAndSettle();

    final remainingTables = container
        .read(editorNotifierProvider)
        .project!
        .encounterTables;
    expect(remainingTables.map((table) => table.id), <String>['cave_floor']);
  });

  testWidgets('keeps the panel usable when the local species index is unavailable', (
    tester,
  ) async {
    final repository = _FakeProjectRepository();
    const workspace = _FakeWorkspace();
    final container = ProviderContainer(
      overrides: [
        projectRepositoryProvider.overrideWithValue(repository),
        encounterTablePersistenceGatewayProvider.overrideWithValue(
          _FakeEncounterTablePersistenceGateway(repository),
        ),
        projectWorkspaceFactoryProvider.overrideWithValue(
          const _FakeWorkspaceFactory(workspace),
        ),
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => throw StateError('species loader exploded'),
        ),
      ],
    );
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/encounter_panel_test',
      project: ProjectManifest(
        name: 'encounter_panel_test',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        encounterTables: <ProjectEncounterTable>[
          ProjectEncounterTable(
            id: 'grass_patch',
            name: 'Grass Patch',
            encounterKind: EncounterKind.walk,
          ),
        ],
      ),
    );

    await pumpEncounterPanel(tester, container);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.textContaining(
        'Unable to load local species data. Raw species IDs are still allowed.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('encounter-tables-table-toggle-grass_patch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('encounter-tables-add-entry-button-grass_patch')),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-species-field')),
      'missingno',
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-min-level-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-max-level-field')),
      '7',
    );
    await tester.enterText(
      find.byKey(const Key('encounter-tables-entry-weight-field')),
      '2',
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Impossible de vérifier par rapport aux données locales d’espèces. Les IDs bruts restent autorisés.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Les suggestions locales d\'espèces sont indisponibles pour le moment.',
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const Key('encounter-tables-entry-save-button')),
    );
    await tester.pumpAndSettle();

    final savedEntry = container
        .read(editorNotifierProvider)
        .project!
        .encounterTables
        .single
        .entries
        .single;
    expect(savedEntry.speciesId, 'missingno');
    expect(
      find.text(
        'Vérification d’espèce locale indisponible. L’ID brut d’espèce est conservé.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'La validation des espèces est indisponible tant que le Pokédex local ne peut pas être chargé.',
      ),
      findsOneWidget,
    );
    expect(find.text('Table valide'), findsNothing);
  });

  testWidgets(
    'keeps the create form open and surfaces the error when persistence fails',
    (tester) async {
      final repository = _FakeProjectRepository(
        saveError: StateError('disk exploded'),
      );
      const workspace = _FakeWorkspace();
      final container = ProviderContainer(
        overrides: [
          projectRepositoryProvider.overrideWithValue(repository),
          encounterTablePersistenceGatewayProvider.overrideWithValue(
            _FakeEncounterTablePersistenceGateway(repository),
          ),
          projectWorkspaceFactoryProvider.overrideWithValue(
            const _FakeWorkspaceFactory(workspace),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => _speciesEntries,
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/encounter_panel_test',
        project: ProjectManifest(
          name: 'encounter_panel_test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
      );

      await pumpEncounterPanel(tester, container);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.byKey(const Key('encounter-tables-new-table-button')),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('encounter-tables-create-name-field')),
        'Grass Patch',
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('encounter-tables-create-submit-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('encounter-tables-create-name-field')),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'Failed to create encounter table: Bad state: disk exploded',
        ),
        findsWidgets,
      );
      expect(
        container.read(editorNotifierProvider).project!.encounterTables,
        isEmpty,
      );
    },
  );
}

const List<PokemonDatabaseIndexEntry> _speciesEntries =
    <PokemonDatabaseIndexEntry>[
      PokemonDatabaseIndexEntry(
        id: 'bulbasaur',
        nationalDex: 1,
        primaryName: 'Bulbasaur',
        genIntroduced: 1,
        types: <String>['grass', 'poison'],
        isEnabledInProject: true,
        refs: PokemonDatabaseIndexRefs(
          learnset: 'bulbasaur',
          evolution: 'bulbasaur',
          media: 'bulbasaur',
        ),
      ),
      PokemonDatabaseIndexEntry(
        id: 'pikachu',
        nationalDex: 25,
        primaryName: 'Pikachu',
        genIntroduced: 1,
        types: <String>['electric'],
        isEnabledInProject: true,
        refs: PokemonDatabaseIndexRefs(
          learnset: 'pikachu',
          evolution: 'pikachu',
          media: 'pikachu',
        ),
      ),
    ];

class _FakeProjectRepository implements ProjectRepository {
  _FakeProjectRepository({this.saveError, this.remainingSaveFailures})
    : assert(remainingSaveFailures == null || remainingSaveFailures >= 0);

  final Object? saveError;
  int? remainingSaveFailures;
  final List<ProjectManifest> savedProjects = <ProjectManifest>[];

  @override
  Future<ProjectManifest> loadProject(String path) {
    throw UnimplementedError();
  }

  @override
  Future<void> saveProject(ProjectManifest project, String path) async {
    final shouldFail =
        saveError != null &&
        (remainingSaveFailures == null || remainingSaveFailures! > 0);
    if (shouldFail) {
      if (remainingSaveFailures != null) {
        remainingSaveFailures = remainingSaveFailures! - 1;
      }
      throw saveError!;
    }
    savedProjects.add(project);
  }
}

class _FakeEncounterTablePersistenceGateway
    implements EncounterTablePersistenceGateway {
  _FakeEncounterTablePersistenceGateway(this._repository);

  final _FakeProjectRepository _repository;

  @override
  Future<ProjectManifest> remove({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required String tableId,
  }) async {
    final updated = expectedProject.copyWith(
      encounterTables: expectedProject.encounterTables
          .where((table) => table.id != tableId)
          .toList(growable: false),
    );
    await _repository.saveProject(updated, projectRootPath);
    return updated;
  }

  @override
  Future<ProjectManifest> upsert({
    required String projectRootPath,
    required ProjectManifest expectedProject,
    required ProjectEncounterTable table,
  }) async {
    final updated = expectedProject.copyWith(
      encounterTables: <ProjectEncounterTable>[
        for (final existing in expectedProject.encounterTables)
          if (existing.id != table.id) existing,
        table,
      ],
    );
    await _repository.saveProject(updated, projectRootPath);
    return updated;
  }
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectManifestPath => '/tmp/project.json';

  @override
  String get projectRoot => '/tmp';

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {}

  @override
  Future<void> deleteDirectoryIfEmpty(String path) async {}

  @override
  Future<void> deleteRelativeFile(String relativePath) async {}

  @override
  Future<bool> directoryExists(String path) async => false;

  @override
  Future<void> ensureDirectoryExists(String path) async {}

  @override
  Future<bool> fileExists(String path) async => false;

  @override
  String getMapPath(String mapId) => '/tmp/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => '$mapId.json';

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) async {
    return sourcePath;
  }

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) async {}

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) async {}

  @override
  Future<String> readTextFile(String path) async => '';

  @override
  String resolveMapPath(String relativePath) => '/tmp/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '/tmp/$relativePath';

  @override
  String resolveTilesetPath(String relativePath) => '/tmp/$relativePath';

  @override
  Future<void> writeTextFile(String path, String contents) async {}
}

class _FakeWorkspaceFactory implements ProjectWorkspaceFactory {
  const _FakeWorkspaceFactory(this.workspace);

  final ProjectWorkspace workspace;

  @override
  ProjectWorkspace create(String projectRootPath) => workspace;
}
