import '../../../map_core/test/support/spatial_border_ground_surface_fixture.dart';
import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';

ProjectManifest exteriorDecorationFixtureProject({String mapId = 'route'}) =>
    ProjectManifest(
      name: 'Native exterior fixture',
      version: ProjectVersion.v9,
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile()),
      maps: [
        ProjectMapEntry(
            id: mapId, name: 'Route', relativePath: 'maps/$mapId.json')
      ],
      tilesets: const [
        ProjectTilesetEntry(
            id: 'grass',
            name: 'Grass',
            relativePath: 'assets/grass.png',
            source: ProjectTilesetSource.regularAtlas(
                assetId: 'grass',
                pixelWidth: 32,
                pixelHeight: 32,
                tileWidth: 32,
                tileHeight: 32))
      ],
      smartTileCatalog: ProjectSmartTileCatalog(atlases: const [
        ProjectSmartTileAtlas(
            id: 'grass',
            name: 'Grass',
            tilesetId: 'grass',
            cellWidth: 32,
            cellHeight: 32,
            columns: 1,
            rows: 1)
      ], materials: const [
        ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'grass',
            pathSurfaceKind: PathSurfaceKind.tallGrass)
      ], presets: const [
        ProjectSmartTilePreset(
            id: 'grass',
            name: 'Grass',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            status: SmartTilePresetStatus.published,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile:
                SmartTileCoverageProfile(mode: SmartTileCoverageMode.template),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: [
              'grass'
            ],
            rules: [
              SmartTileRule(
                  id: 'grass',
                  centerMatch: SmartTileSlotMatch.material('grass'),
                  candidates: [
                    SmartTileCandidate(id: 'grass', parts: [
                      SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                              frame: SmartTileFrameRef(
                                  atlasId: 'grass', column: 0, row: 0)))
                    ])
                  ])
            ])
      ]),
      borderCatalog: spatialBorderFixture().project.borderCatalog,
      models3d: [
        ...spatialBorderFixture().project.models3d,
        ProjectModel3dEntry(
            id: 'oak',
            name: 'Oak',
            sourceAssetId: 'oak_source',
            relativePath: 'assets/models3d/oak.glb',
            inspection: Model3dInspection(
                bounds: Model3dBounds(
                    min: Model3dVector3(x: -.4, y: 0, z: -.4),
                    max: Model3dVector3(x: .4, y: 2, z: .4)),
                meshCount: 1,
                triangleCount: 4))
      ],
      environmentPresets: [
        EnvironmentPreset(
            id: 'forest',
            name: 'Forest',
            templateId: 'manual',
            sortOrder: 0,
            palette: [EnvironmentPaletteItem(modelId: 'oak', weight: 1)],
            defaultParams: EnvironmentGenerationParams(
                density: 1, variation: 0, edgeDensity: 1, minSpacingCells: 0))
      ],
    );

Future<Map<String, Object?>> createExteriorDecorationFixture(
    String projectRoot) async {
  final root = Directory(projectRoot);
  await root.create(recursive: true);
  final canonical = await root.resolveSymbolicLinks();
  if (await File('$canonical/project.json').exists() ||
      await File('$canonical/maps/route.json').exists()) {
    throw const FormatException(
        'Fixture generator requires a new empty project destination.');
  }
  final store = await CatalogStorageStore.open(projectRoot: canonical);
  await WorkingProjectCatalog.create(
      store: store,
      projectId: 'exterior_fixture',
      project: exteriorDecorationFixtureProject());
  final map = MapData(
      id: 'route',
      name: 'Route',
      size: const GridSize(width: 16, height: 16),
      version: ProjectVersion.v9,
      spatialScene: MapSpatialScene(width: 16, depth: 16));
  final file = File('$canonical/maps/route.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(map.toJson()));
  final policy = await WorkspacePolicy.create(
      allowedRootPaths: [canonical],
      fileReader: const LocalProjectFileReader());
  final service = LocalMapExteriorDecorationAuthoring(policy: policy);
  final initial = await service.inspect(projectRoot: canonical, mapId: 'route');
  final configured = await service.configure(
      projectRoot: canonical,
      mapId: 'route',
      expectedRevision: initial.revision,
      decoration: MapExteriorDecoration(
          mapId: 'route', playableWidth: 16, playableDepth: 16, west: 16),
      operationId: 'fixture_configure');
  final sector = await service.setSector(
      projectRoot: canonical,
      mapId: 'route',
      expectedRevision: configured.afterRevision,
      sector: ExteriorDecorationSector(
          id: 'west',
          originX: -16,
          originZ: 0,
          scene: MapSpatialScene(width: 16, depth: 16, generateCliffs: false)),
      operationId: 'fixture_sector');
  return {
    'projectRoot': canonical,
    'mapId': 'route',
    'sectorId': 'west',
    'revision': sector.afterRevision,
    'catalogRevision': await service.inspectNativeCatalogRevision(
        projectRoot: canonical, mapId: 'route'),
    'terrainPresetId': 'grass',
    'environmentPresetId': 'forest',
    'modelId': 'oak',
    'borderBlueprintId': 'fence',
    'borderModelId': 'unit'
  };
}

Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw const FormatException('Expected one absolute fixture destination.');
  }
  stdout
      .writeln(jsonEncode(await createExteriorDecorationFixture(args.single)));
}
