import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_smart_tile_density_section.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_smart_tile_paint_palette.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/application/world_map_tool_family.dart';
import 'package:map_editor/src/theme/theme.dart';

final _project = ProjectManifest(
  name: 'Densité',
  maps: const <ProjectMapEntry>[],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'world',
      name: 'World',
      relativePath: 'tilesets/world.png',
    ),
  ],
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'eau',
        name: 'Eau',
        connectionGroupId: 'eau',
      ),
    ],
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'riviere',
        name: 'Rivière',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.wangCorner4,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        status: SmartTilePresetStatus.published,
        defaultMaterialId: 'eau',
        allowedMaterialIds: <String>['eau'],
        rules: <SmartTileRule>[
          SmartTileRule(
            id: 'fill',
            centerMatch: SmartTileSlotMatch.any(),
            candidates: <SmartTileCandidate>[
              SmartTileCandidate(id: 'fill-c0', weight: 1000),
              SmartTileCandidate(id: 'fill-c1', weight: 1000),
            ],
          ),
        ],
      ),
    ],
  ),
);

final _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: const GridSize(width: 2, height: 2),
  layers: const <MapLayer>[
    SmartTileLayer(
      id: 'riviere-calque',
      name: 'Rivière',
      presetId: 'riviere',
      usage: SmartTileUsage.path,
      field: SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
    ),
  ],
);

void main() {
  testWidgets('la palette rend la section quand un calque Smart Tile est actif',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    addTearDown(keepAlive.close);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/virtual/project',
      project: _project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: _map,
      activeLayerId: 'riviere-calque',
      savedMapSnapshot: _map,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 440,
              height: 900,
              child: SingleChildScrollView(
                child: WorldMapSmartTilePaintPalette(
                  subtool: WorldMapPaintSubtool.path,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WorldMapSmartTileDensitySection), findsOneWidget);
    expect(
      find.byKey(const Key('world-map-density-summary')),
      findsOneWidget,
    );
  });

  testWidgets('pas de section quand le preset ne porte aucune règle',
      (tester) async {
    final barePreset = _project.smartTileCatalog.presets.single.copyWith(
      rules: const <SmartTileRule>[],
    );
    final bareProject = _project.copyWith(
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: _project.smartTileCatalog.materials,
        presets: <ProjectSmartTilePreset>[barePreset],
      ),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    addTearDown(keepAlive.close);
    container.read(editorNotifierProvider.notifier).state = EditorState(
      projectRootPath: '/virtual/project',
      project: bareProject,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: _map,
      activeLayerId: 'riviere-calque',
      savedMapSnapshot: _map,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 440,
              height: 900,
              child: SingleChildScrollView(
                child: WorldMapSmartTilePaintPalette(
                  subtool: WorldMapPaintSubtool.path,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(WorldMapSmartTileDensitySection), findsNothing);
  });
}
