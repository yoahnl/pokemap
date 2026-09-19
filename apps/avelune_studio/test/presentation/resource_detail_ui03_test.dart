import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_detail_panel.dart';
import 'package:avelune_studio/presentation/features/resources/resource_preview.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('terrain category is canonical and missing maps are explained', (
    tester,
  ) async {
    final base = _terrainProject();
    final project = base.copyWith(maps: []);
    final entry = resourceCatalog(
      project,
    ).firstWhere((item) => item.terrain != null);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 340,
            child: ResourceDetailPanel(
              item: entry,
              project: project,
              preview: const SizedBox(),
              onUse: (_) => fail('No map is available'),
              onEdit: (_) {},
              onTerrain: (_) {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Nature'), findsOneWidget);
    expect(
      find.text(
        'Ce projet ne contient aucune carte. Les ressources restent consultables.',
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<StudioButton>(find.byKey(const ValueKey('resource-use')))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('use action stays visible while detail scrolls at 150 percent', (
    tester,
  ) async {
    final entry = resourceCatalog(workspaceProject).first;
    ResourceItem? used;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: SizedBox(
              width: 340,
              height: 420,
              child: ResourceDetailPanel(
                item: entry,
                project: workspaceProject,
                preview: const SizedBox.square(dimension: 200),
                targetMapName: 'Clairière',
                onUse: (value) => used = value,
                onEdit: (_) {},
                onTerrain: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    final action = find.byKey(const ValueKey('resource-use'));
    final position = tester.getRect(action);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    expect(tester.getRect(action), position);
    await tester.tap(action);
    expect(used, same(entry));
    expect(find.text('Usages dans les cartes ouvertes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unprepared image retains an honest tile-use destination', (
    tester,
  ) async {
    final entry = resourceCatalog(workspaceProject).last;
    ResourceItem? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: SizedBox(
            width: 340,
            child: ResourceDetailPanel(
              item: entry,
              project: workspaceProject,
              preview: const SizedBox(),
              onUse: (value) => selected = value,
              onEdit: (_) => fail('An unprepared atlas cannot create a decor'),
              onTerrain: (_) =>
                  fail('An unprepared atlas cannot create terrain'),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Choisir une carte'), findsOneWidget);
    expect(
      find.text('Métadonnées non préparées — accès aux tuiles conservé'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('resource-use')));
    expect(selected, same(entry));
    expect(tester.takeException(), isNull);
  });

  testWidgets('terrain example resolves distinct edges using real tile IDs', (
    tester,
  ) async {
    final visuals = _TileSpy();
    final project = _terrainProject();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox.square(
            dimension: 240,
            child: resourcePreview(
              resourceCatalog(
                project,
              ).firstWhere((item) => item.terrain != null),
              project,
              visuals,
              size: 240,
              terrainPattern: true,
            ),
          ),
        ),
      ),
    );
    expect(visuals.tiles.map((tile) => tile.localTileId), [
      6,
      14,
      12,
      7,
      15,
      13,
      3,
      11,
      9,
    ]);
    expect(visuals.tiles.every((tile) => tile.tilesetId == 'terrain'), isTrue);
    expect(find.text('Exemple de raccord'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TileSpy extends WorkspaceTestVisuals {
  final tiles = <TileLayerPaletteEntry>[];
  @override
  Widget tileThumbnail(TileLayerPaletteEntry tile, {double size = 48}) {
    tiles.add(tile);
    return SizedBox.square(dimension: size);
  }
}

ProjectManifest _terrainProject() {
  const source = ProjectTilesetEntry(
    id: 'terrain',
    name: 'Chemin',
    relativePath: 'terrain.png',
    source: ProjectTilesetSource.regularAtlas(
      assetId: 'terrain',
      pixelWidth: 128,
      pixelHeight: 128,
      tileWidth: 32,
      tileHeight: 32,
    ),
  );
  final preset = ProjectSmartTilePreset(
    id: 'path',
    name: 'Chemin',
    categoryId: 'nature',
    usage: SmartTileUsage.path,
    topology: SmartTileTopology.cardinal4,
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'path',
    allowedMaterialIds: ['path'],
    rules: [
      for (var mask = 0; mask < 16; mask++)
        terrainConnectionRule(
          mask,
          SmartTileFrameRef(atlasId: 'atlas', column: mask % 4, row: mask ~/ 4),
          'path',
        ),
    ],
  );
  return workspaceProject.copyWith(
    tilesets: [source],
    smartTileCatalog: ProjectSmartTileCatalog(
      categories: [
        const ProjectSmartTileCategory(id: 'nature', name: 'Nature'),
      ],
      atlases: [terrainAtlas(source, 'atlas')],
      materials: [
        const ProjectSmartTileMaterial(
          id: 'path',
          name: 'Chemin',
          connectionGroupId: 'path',
        ),
      ],
      presets: [preset],
    ),
  );
}
