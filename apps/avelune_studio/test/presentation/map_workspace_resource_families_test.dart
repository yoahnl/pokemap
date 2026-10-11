import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_palette_dock.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_panels.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_tile_palette.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import '../support/border_catalog_fixture.dart';
import '../support/spatial_narrative_fixture.dart';

void main() {
  for (final dock in [false, true]) {
    testWidgets(
      '${dock ? 'dock' : 'full palette'} exposes family and scope filters',
      (tester) async {
        final view = MapWorkspaceViewState();
        final search = TextEditingController();
        final document = EditableMapDocument(
          MapWorkspaceDocument(
            map: workspaceMap('a'),
            revision: 'r0',
            mapId: 'a',
          ),
        );
        addTearDown(view.dispose);
        addTearDown(search.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: SizedBox(
                width: dock ? 1000 : 300,
                height: dock ? 300 : 700,
                child: dock
                    ? MapWorkspacePaletteDock(
                        project: workspaceProject,
                        document: document,
                        visuals: WorkspaceTestVisuals(),
                        view: view,
                        search: search,
                        onChanged: () {},
                        onResources: () {},
                        onOpenFullPalette: () {},
                      )
                    : MapWorkspacePalette(
                        project: workspaceProject,
                        document: document,
                        visuals: WorkspaceTestVisuals(),
                        view: view,
                        search: search,
                        onChanged: () {},
                      ),
              ),
            ),
          ),
        );
        expect(find.text('Familles'), findsOneWidget);
        expect(find.text('Filtres'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${dock ? 'dock' : 'full palette'} applies descendants and map scope through controls',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final project = _project();
        final view = MapWorkspaceViewState();
        final search = TextEditingController();
        final document = _document(workspaceMap('a'));
        var changes = 0;
        addTearDown(view.dispose);
        addTearDown(search.dispose);
        await tester.pumpWidget(
          _palette(
            dock,
            project,
            document,
            view,
            search,
            onChanged: () => changes++,
          ),
        );
        expect(find.byKey(const ValueKey('decor-shared-tree')), findsOneWidget);
        expect(find.byKey(const ValueKey('decor-a-tree')), findsOneWidget);
        expect(find.byKey(const ValueKey('decor-b-tree')), findsNothing);
        expect(find.byKey(const ValueKey('decor-door')), findsNothing);
        await tester.tap(find.text('Familles'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('resource-nature-family-trees')),
        );
        await tester.tap(
          find.byKey(const ValueKey('resource-nature-family-trees')),
        );
        await tester.pumpAndSettle();
        expect(view.resourceFilters.familyId, 'trees');
        expect(find.byKey(const ValueKey('decor-a-tree')), findsOneWidget);
        expect(find.byKey(const ValueKey('decor-house')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('resource-filter-usage')),
          findsNothing,
        );
        String draftCount() => tester
            .widget<Text>(
              find.byKey(const ValueKey('resource-filter-result-count')),
            )
            .data!;
        expect(draftCount(), '2 résultats');
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('resource-filter-scope')),
            )
            .onChanged!('map');
        await tester.pump();
        expect(draftCount(), '1 résultat');
        expect(view.resourceFilters.scope, ResourceCatalogScope.all);
        expect(find.byKey(const ValueKey('decor-shared-tree')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('resource-filter-cancel')));
        await tester.pumpAndSettle();
        expect(view.resourceFilters.scope, ResourceCatalogScope.all);
        expect(find.byKey(const ValueKey('decor-shared-tree')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
        await tester.pumpAndSettle();
        expect(draftCount(), '2 résultats');
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('resource-filter-scope')),
            )
            .onChanged!('map');
        await tester.pump();
        expect(draftCount(), '1 résultat');
        await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
        await tester.pumpAndSettle();
        expect(view.resourceFilters.scope, ResourceCatalogScope.map);
        if (!dock) expect(changes, 0);
        expect(find.byKey(const ValueKey('decor-shared-tree')), findsNothing);
        expect(find.byKey(const ValueKey('decor-a-tree')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('decor-a-tree')));
        await tester.pump();
        expect(view.brush?.id, 'a-tree');
        if (!dock) expect(changes, 1);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${dock ? 'dock' : 'full palette'} draft count retains search and displays zero matches',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final project = _project();
        final view = MapWorkspaceViewState()
          ..resourceFilters.familyId = 'trees';
        final search = TextEditingController(text: 'a-tree');
        final document = _document(workspaceMap('a'));
        addTearDown(view.dispose);
        addTearDown(search.dispose);
        await tester.pumpWidget(
          _palette(dock, project, document, view, search),
        );
        expect(find.byKey(const ValueKey('decor-a-tree')), findsOneWidget);
        expect(find.byKey(const ValueKey('decor-shared-tree')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
        await tester.pumpAndSettle();
        String draftCount() => tester
            .widget<Text>(
              find.byKey(const ValueKey('resource-filter-result-count')),
            )
            .data!;
        expect(draftCount(), '1 résultat');
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('resource-filter-scope')),
            )
            .onChanged!('project');
        await tester.pump();
        expect(draftCount(), '0 résultats');
        expect(view.resourceFilters.scope, ResourceCatalogScope.all);
        await tester.tap(find.byKey(const ValueKey('resource-filter-apply')));
        await tester.pumpAndSettle();
        expect(view.resourceFilters.scope, ResourceCatalogScope.project);
        expect(view.resourceFilters.familyId, 'trees');
        expect(view.resourceFilters.query, 'a-tree');
        expect(find.byKey(const ValueKey('decor-a-tree')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${dock ? 'dock' : 'full palette'} draft count includes the character search',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final view = MapWorkspaceViewState()
          ..paletteTab = 'Personnages'
          ..characterQuery = 'inexistant';
        final search = TextEditingController();
        addTearDown(view.dispose);
        addTearDown(search.dispose);
        await tester.pumpWidget(
          _palette(
            dock,
            _project(),
            _document(workspaceMap('a')),
            view,
            search,
          ),
        );
        expect(find.byKey(const ValueKey('character-guide')), findsNothing);
        await tester.tap(find.byKey(const ValueKey('resource-filter-button')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(
                find.byKey(const ValueKey('resource-filter-result-count')),
              )
              .data,
          '0 résultats',
        );
        await tester.tap(find.byKey(const ValueKey('resource-filter-cancel')));
        await tester.pumpAndSettle();
        expect(view.characterQuery, 'inexistant');
        expect(view.resourceFilters.scope, ResourceCatalogScope.all);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${dock ? 'dock' : 'full palette'} filters borders environments characters and tile sources',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final project = _project();
        final view = MapWorkspaceViewState();
        final search = TextEditingController();
        final document = _document(workspaceMap('a'));
        final picked = <String>[];
        addTearDown(view.dispose);
        addTearDown(search.dispose);
        for (final entry in {
          'Bordures': 'border-muret',
          'Environnements': 'environment-garden',
          'Personnages': 'character-guide',
        }.entries) {
          view.paletteTab = entry.key;
          await tester.pumpWidget(
            _palette(
              dock,
              project,
              document,
              view,
              search,
              onPick: (item) => picked.add(item.identity),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byKey(ValueKey(entry.value)), findsOneWidget);
          expect(find.byKey(ValueKey('${entry.value}-other')), findsNothing);
          await tester.tap(find.byKey(ValueKey(entry.value)));
          await tester.pump();
        }
        expect(picked, [
          'borderBlueprint:muret',
          'environmentPreset:garden',
          'character:guide',
        ]);
        view.paletteTab = 'Tuiles';
        await tester.pumpWidget(
          _palette(false, project, document, view, search),
        );
        expect(
          tester
              .widget<MapTilePalette>(find.byType(MapTilePalette))
              .sources
              .map((source) => source.id),
          ['atlas'],
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      '${dock ? 'dock' : 'full palette'} preserves spatial smart tiles and characters eligibility',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final project = _project().copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.threeD),
        );
        final view = MapWorkspaceViewState()..paletteTab = 'Terrains';
        final search = TextEditingController();
        final document = _document(spatialNarrativeMap());
        addTearDown(view.dispose);
        addTearDown(search.dispose);
        await tester.pumpWidget(
          _palette(dock, project, document, view, search),
        );
        expect(find.byKey(const ValueKey('terrain-path')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('terrain-path')));
        await tester.pump();
        expect(view.terrain?.id, 'path');
        view.paletteTab = 'Décors';
        await tester.pumpWidget(
          _palette(dock, project, document, view, search),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('decor-door')), findsOneWidget);
        expect(find.byKey(const ValueKey('decor-shared-tree')), findsNothing);
        view.paletteTab = 'Personnages';
        await tester.pumpWidget(
          _palette(dock, project, document, view, search),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('character-guide')), findsOneWidget);
        if (dock) {
          await tester.tap(find.byTooltip('Changer la palette'));
          await tester.pumpAndSettle();
        }
        expect(find.text('Bordures'), findsNothing);
        expect(find.text('Environnements'), findsNothing);
        expect(find.text('Tuiles'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  test(
    'map changes clear unavailable brushes without resetting family filters',
    () {
      final project = _project();
      final view = MapWorkspaceViewState();
      addTearDown(view.dispose);
      view.resourceFilters.familyId = 'trees';
      view.resourceFilters.usage = ResourceCatalogUsage.trace;
      expect(
        view.paletteResources(project, 'a').any((item) => item.id == 'a-tree'),
        isTrue,
      );
      view.reconcileResources(project, mapId: 'a', map: workspaceMap('a'));
      expect(view.resourceFilters.usage, ResourceCatalogUsage.all);
      view.brush = project.elements.firstWhere(
        (element) => element.id == 'a-tree',
      );
      view.tool = StudioMapTool.place;
      view.reconcileResources(project, mapId: 'b', map: workspaceMap('b'));
      expect(view.brush, isNull);
      expect(view.tool, StudioMapTool.select);
      expect(view.resourceFilters.familyId, 'trees');
      view.brush = project.elements.firstWhere(
        (element) => element.id == 'shared-tree',
      );
      view.tool = StudioMapTool.place;
      view.reconcileResources(project, mapId: 'a', map: workspaceMap('a'));
      expect(view.brush?.id, 'shared-tree');
      expect(view.tool, StudioMapTool.place);
    },
  );
  test(
    'map changes disarm character tile terrain border and model brushes',
    () {
      for (final kind in [
        'character',
        'tileset',
        'smartTilePreset',
        'borderBlueprint',
        'model3d',
      ]) {
        var project = _project();
        if (kind == 'model3d') {
          project = project.copyWith(
            settings: const ProjectSettings(dimension: ProjectDimension.threeD),
          );
        }
        final id = switch (kind) {
          'character' => 'guide-other',
          'tileset' => 'atlas-other',
          'borderBlueprint' => 'muret-other',
          'model3d' => 'door',
          _ => 'path',
        };
        if (kind == 'smartTilePreset' || kind == 'model3d') {
          project = project.copyWith(
            resourceLibraryCatalog: ResourceLibraryCatalog(
              families: project.resourceLibraryCatalog.families,
              entries: [
                ...project.resourceLibraryCatalog.entries,
                ResourceLibraryEntry(
                  resourceKind: kind,
                  resourceId: id,
                  mapId: 'b',
                ),
              ],
            ),
          );
        }
        final view = MapWorkspaceViewState();
        addTearDown(view.dispose);
        view.reconcileResources(project, mapId: 'b');
        switch (kind) {
          case 'character':
            view.character = project.characters.firstWhere(
              (item) => item.id == id,
            );
            view.tool = StudioMapTool.character;
          case 'tileset':
            view.tile = TileLayerPaletteEntry(tilesetId: id, localTileId: 0);
            view.paletteAtlasId = id;
            view.tool = StudioMapTool.paint;
          case 'smartTilePreset':
            view.terrain = project.smartTileCatalog.presets.single;
            view.tool = StudioMapTool.terrain;
          case 'borderBlueprint':
            view.borderBlueprintId = id;
            view.tool = StudioMapTool.border;
          case 'model3d':
            view.model3d = project.models3d.single;
            view.tool = StudioMapTool.place;
        }
        view.reconcileResources(project, mapId: 'a');
        expect(view.tool, StudioMapTool.select, reason: kind);
        expect(view.character, isNull);
        expect(view.tile, isNull);
        expect(view.paletteAtlasId, isNull);
        expect(view.terrain, isNull);
        expect(view.borderBlueprintId, isNull);
        expect(view.model3d, isNull);
      }
    },
  );
}

EditableMapDocument _document(MapData map) => EditableMapDocument(
  MapWorkspaceDocument(map: map, revision: 'r0', mapId: map.id),
);

Widget _palette(
  bool dock,
  ProjectManifest project,
  EditableMapDocument document,
  MapWorkspaceViewState view,
  TextEditingController search, {
  ValueChanged<ResourceItem>? onPick,
  VoidCallback? onChanged,
}) => MaterialApp(
  theme: studioTheme(),
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: dock ? 1100 : 300,
        height: dock ? 330 : 850,
        child: dock
            ? MapWorkspacePaletteDock(
                project: project,
                document: document,
                visuals: WorkspaceTestVisuals(),
                view: view,
                search: search,
                onChanged: onChanged ?? () {},
                onResources: () {},
                onOpenFullPalette: () {},
                onPickResource: onPick,
              )
            : MapWorkspacePalette(
                project: project,
                document: document,
                visuals: WorkspaceTestVisuals(),
                view: view,
                search: search,
                onChanged: onChanged ?? () {},
                onPickResource: onPick,
              ),
      ),
    ),
  ),
);

ProjectManifest _project() {
  final character = spatialNarrativeProject().characters.single;
  final border = testBorderCatalog().records.single;
  final environment = EnvironmentPreset(
    id: 'garden',
    name: 'Jardin',
    templateId: 'manual',
    sortOrder: 0,
    palette: [EnvironmentPaletteItem(elementId: 'shared-tree', weight: 1)],
    defaultParams: EnvironmentGenerationParams.standard(),
  );
  return workspaceProject.copyWith(
    models3d: spatialNarrativeProject().models3d,
    elements: [
      for (final id in ['shared-tree', 'a-tree', 'b-tree', 'house'])
        workspaceElement.copyWith(id: id, name: id),
    ],
    characters: [
      character,
      character.copyWith(id: 'guide-other', name: 'Autre guide'),
    ],
    tilesets: [
      workspaceProject.tilesets.single,
      workspaceProject.tilesets.single.copyWith(id: 'atlas-other'),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: testBorderCatalog().formatVersion,
      visualSnapshots: testBorderCatalog().visualSnapshots,
      records: [
        border,
        BorderBlueprintRecord(
          id: 'muret-other',
          draft: border.draft,
          latestPublished: border.latestPublished,
        ),
      ],
    ),
    environmentPresets: [
      environment,
      EnvironmentPreset(
        id: 'garden-other',
        name: 'Autre jardin',
        templateId: environment.templateId,
        sortOrder: 0,
        palette: environment.palette,
        defaultParams: environment.defaultParams,
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      presets: [
        const ProjectSmartTilePreset(
          id: 'path',
          name: 'Chemin',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.cardinal4,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'path',
          allowedMaterialIds: ['path'],
        ),
      ],
    ),
    resourceLibraryCatalog: ResourceLibraryCatalog(
      families: [
        ResourceFamily(
          id: 'small-trees',
          name: 'Petits arbres',
          parentId: 'trees',
        ),
      ],
      entries: [
        for (final id in ['shared-tree', 'a-tree', 'b-tree'])
          ResourceLibraryEntry(
            resourceKind: 'element',
            resourceId: id,
            familyId: id == 'a-tree' ? 'small-trees' : 'trees',
            mapId: id == 'a-tree'
                ? 'a'
                : id == 'b-tree'
                ? 'b'
                : null,
          ),
        ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: 'house',
          familyId: 'buildings',
        ),
        for (final kindAndId in {
          'character': 'guide-other',
          'tileset': 'atlas-other',
          'borderBlueprint': 'muret-other',
          'environmentPreset': 'garden-other',
        }.entries)
          ResourceLibraryEntry(
            resourceKind: kindAndId.key,
            resourceId: kindAndId.value,
            mapId: 'b',
          ),
      ],
    ),
  );
}
