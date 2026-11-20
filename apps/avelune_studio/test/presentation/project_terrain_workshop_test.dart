import 'dart:typed_data';

import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/rendering/contracts/scoped_resource_preview_visuals.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/application/project_resource_preview.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_connections.dart';
import 'package:avelune_studio/presentation/features/resources/model_resource_preview.dart';
import 'package:avelune_studio/presentation/features/resources/project_terrain_workshop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('shows the tiles resolved for each connection of a 2D path', (
    tester,
  ) async {
    final visuals = _TerrainVisuals();
    await _pumpWorkshop(
      tester,
      ProjectResourcePreviews((_) async => _rasterProject()),
      visuals: visuals,
    );

    expect(find.text('Chemin du jardin'), findsOneWidget);
    expect(find.text('Chemin automatique'), findsOneWidget);
    expect(visuals.tiles.map((tile) => tile.tilesetId), everyElement('sheet'));
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
  });

  testWidgets('requests the referenced model for a 3D ground preview', (
    tester,
  ) async {
    final visuals = _SpatialTerrainVisuals();
    final project = _spatialProject();
    await _pumpWorkshop(
      tester,
      ProjectResourcePreviews((_) async => project),
      visuals: visuals,
      id: 'ground',
      name: 'Sol du jardin',
    );

    expect(find.text('Sol automatique'), findsOneWidget);
    expect(visuals.modelPaths, ['assets/models3d/ground-model.glb']);
    final preview = tester.widget<ModelResourcePreview>(
      find.byType(ModelResourcePreview),
    );
    expect(preview.compact, isFalse);
  });

  testWidgets('opens usage maps and refreshes the name without rereading art', (
    tester,
  ) async {
    final reads = <String>[];
    final opens = <String>[];
    var renames = 0;
    var backs = 0;
    final previews = ProjectResourcePreviews((item) async {
      reads.add(item.identity);
      return _rasterProject();
    });

    await _pumpWorkshop(tester, previews, loadingMapUsages: true);
    expect(find.text('Calcul des usages par carte…'), findsOneWidget);
    expect(find.text('Usages indisponibles.'), findsNothing);

    await _pumpWorkshop(
      tester,
      previews,
      usages: {'a': 'Clairière'},
      onOpenMap: (id) async {
        opens.add(id);
        return true;
      },
      onRename: () async => renames++,
    );
    await tester.tap(find.text('Clairière'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Renommer'));
    expect(opens, ['a']);
    expect(renames, 1);

    await _pumpWorkshop(
      tester,
      previews,
      name: 'Allée du jardin',
      usages: const {},
      onBack: () => backs++,
    );

    expect(find.text('Allée du jardin'), findsOneWidget);
    expect(find.text('Chemin du jardin'), findsNothing);
    expect(find.text('Aucune carte ne l’utilise.'), findsOneWidget);
    expect(find.text('Renommer'), findsNothing);
    expect(reads, ['smartTilePreset:path']);
    await tester.tap(find.text('Retour à la bibliothèque'));
    expect(backs, 1);
  });

  testWidgets('can retry a failed terrain preview with unknown map usages', (
    tester,
  ) async {
    var reads = 0;
    final visuals = _TerrainVisuals();
    await _pumpWorkshop(
      tester,
      ProjectResourcePreviews((_) async {
        if (reads++ == 0) throw StateError('Lecture impossible');
        return _rasterProject();
      }),
      visuals: visuals,
    );

    expect(find.text('Impossible de lire le terrain'), findsOneWidget);
    expect(find.text('Usages indisponibles.'), findsOneWidget);
    expect(visuals.tiles, isEmpty);
    await tester.tap(find.text('Réessayer'));
    await tester.pumpAndSettle();

    expect(reads, 2);
    expect(find.text('Impossible de lire le terrain'), findsNothing);
    expect(visuals.tiles, hasLength(9));
  });
}

Future<void> _pumpWorkshop(
  WidgetTester tester,
  ProjectResourcePreviews previews, {
  String id = 'path',
  String name = 'Chemin du jardin',
  MapWorkspaceVisuals? visuals,
  Map<String, String>? usages,
  bool loadingMapUsages = false,
  Future<bool> Function(String)? onOpenMap,
  VoidCallback? onBack,
  Future<void> Function()? onRename,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProjectTerrainWorkshop(
          item: ProjectLibraryItem(kind: 'smartTilePreset', id: id, name: name),
          previews: previews,
          visuals: visuals,
          usages: usages,
          loadingMapUsages: loadingMapUsages,
          onOpenMap: onOpenMap,
          onBack: onBack ?? () {},
          onRename: onRename,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

const _sheet = ProjectTilesetEntry(
  id: 'sheet',
  name: 'Planche du jardin',
  relativePath: 'sheet.png',
  source: ProjectTilesetSource.regularAtlas(
    assetId: 'sheet',
    pixelWidth: 128,
    pixelHeight: 128,
    tileWidth: 32,
    tileHeight: 32,
  ),
);

const _material = ProjectSmartTileMaterial(
  id: 'garden',
  name: 'Jardin',
  connectionGroupId: 'garden',
);

const _path = ProjectSmartTilePreset(
  id: 'path',
  name: 'Chemin du jardin',
  usage: SmartTileUsage.path,
  topology: SmartTileTopology.cardinal4,
  coveragePolicy: SmartTileCoveragePolicy.complete,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  status: SmartTilePresetStatus.published,
  defaultMaterialId: 'garden',
  allowedMaterialIds: ['garden'],
);

ProjectManifest _rasterProject() => workspaceProject.copyWith(
  tilesets: [_sheet],
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: [terrainAtlas(_sheet, 'atlas')],
    materials: [_material],
    presets: [
      _path.copyWith(
        rules: [
          for (var mask = 0; mask < 16; mask++)
            terrainConnectionRule(
              mask,
              SmartTileFrameRef(
                atlasId: 'atlas',
                column: mask % 4,
                row: mask ~/ 4,
              ),
              'garden',
            ),
        ],
      ),
    ],
  ),
);

ProjectManifest _spatialProject() => workspaceProject.copyWith(
  models3d: [
    ProjectModel3dEntry(
      id: 'ground-model',
      name: 'Sol',
      sourceAssetId: 'ground-asset',
      relativePath: 'assets/models3d/ground-model.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 1, z: 1),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    ),
  ],
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: [_material],
    presets: [
      _path.copyWith(
        id: 'ground',
        name: 'Sol du jardin',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        rules: const [
          SmartTileRule(
            id: 'garden-ground',
            centerMatch: SmartTileSlotMatch.material('garden'),
            candidates: [
              SmartTileCandidate(
                id: 'garden-ground',
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.model3d(
                      modelId: 'ground-model',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);

class _TerrainVisuals extends WorkspaceTestVisuals
    implements ScopedResourcePreviewVisuals {
  final tiles = <TileLayerPaletteEntry>[];

  @override
  void refreshResourcePreviews() {}

  @override
  void invalidateResourcePreviews(Set<String> changedRelativePaths) {}

  @override
  Widget scopedResourcePreview(
    ResourcePreviewSource source,
    ProjectManifest project, {
    required double size,
  }) {
    tiles.add((source as TileFramePreviewSource).entry);
    return SizedBox.square(dimension: size);
  }
}

class _SpatialTerrainVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals, SpatialScopedWorkspaceVisuals {
  final modelPaths = <String>[];

  @override
  Future<Uint8List> readModelDefinition(ProjectModel3dEntry model) async {
    modelPaths.add(model.relativePath);
    throw StateError('Source simulée indisponible');
  }

  @override
  Future<Uint8List> readModel(String modelId) =>
      throw UnsupportedError('La définition ciblée doit être utilisée');

  @override
  Future<Uint8List> readGroundDefinition(ProjectTilesetEntry tileset) =>
      throw UnsupportedError('Aucune planche demandée');

  @override
  Future<Uint8List> readGroundImage(String tilesetId) =>
      throw UnsupportedError('Aucune planche demandée');

  @override
  Future<SpatialNpcPreview> spatialPreview(
    MapData map,
    ProjectManifest project,
  ) => throw UnsupportedError('Aucune carte ouverte');
}
