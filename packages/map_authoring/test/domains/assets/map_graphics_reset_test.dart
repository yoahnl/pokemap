import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('reset keeps character assets and removes map graphics only', () {
    final mapArtifact = ContentArtifactRef.fromBytes(
      utf8.encode('map'),
      mediaType: 'image/png',
    );
    final characterArtifact = ContentArtifactRef.fromBytes(
      utf8.encode('character'),
      mediaType: 'image/png',
    );
    final mapPageArtifact = ContentArtifactRef.fromBytes(
      utf8.encode('map-page'),
      mediaType: 'image/png',
    );
    final legacyMapArtifact = ContentArtifactRef.fromBytes(
      utf8.encode('legacy-map'),
      mediaType: 'image/png',
    );
    final manifest = ProjectManifest(
      name: 'Fixture',
      maps: const [
        ProjectMapEntry(
          id: 'map',
          name: 'Map',
          relativePath: 'maps/map.json',
        ),
      ],
      tilesetFolders: const [
        ProjectTilesetFolder(id: 'map-folder', name: 'Map'),
      ],
      tilesets: const [
        ProjectTilesetEntry(
          id: 'map-tileset',
          name: 'Map',
          relativePath: 'assets/tilesets/map.png',
        ),
        ProjectTilesetEntry(
          id: 'character-tileset',
          name: 'Character',
          relativePath: 'assets/tilesets/characters/hero.png',
        ),
      ],
      elementCategories: const [
        ProjectElementCategory(id: 'map-category', name: 'Map'),
      ],
      elements: const [
        ProjectElementEntry(
          id: 'tree',
          name: 'Tree',
          tilesetId: 'map-tileset',
          categoryId: 'map-category',
          frames: [
            TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
          ],
        ),
      ],
      environmentPresets: [
        EnvironmentPreset(
          id: 'forest',
          name: 'Forest',
          templateId: 'forest',
          palette: [EnvironmentPaletteItem(elementId: 'tree', weight: 1)],
          defaultParams: EnvironmentGenerationParams.standard(),
          sortOrder: 0,
        ),
      ],
      characters: const [
        ProjectCharacterEntry(
          id: 'hero',
          name: 'Hero',
          tilesetId: 'character-tileset',
        ),
      ],
    );
    final map = MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 2, height: 2),
      tilesetId: 'map-tileset',
      layers: const [
        MapLayer.tile(
          id: 'ground',
          name: 'Ground',
          palette: [
            TileLayerPaletteEntry(tilesetId: 'map-tileset', localTileId: 0),
          ],
          cells: [1, 1, 1, 1],
        ),
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: [false, true, false, true],
        ),
      ],
      placedElements: const [
        MapPlacedElement(
          id: 'tree-instance',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 0, y: 0),
        ),
      ],
      properties: const {'story': 'kept'},
    );
    final assets = AssetCatalog(records: [
      AssetRecord(
        id: 'map-asset',
        logicalPath: 'assets/tilesets/map.png',
        artifact: mapArtifact,
      ),
      AssetRecord(
        id: 'character-asset',
        logicalPath: 'assets/tilesets/characters/hero.png',
        artifact: characterArtifact,
      ),
      AssetRecord(
        id: 'map-page-asset',
        logicalPath: 'assets/tilesets/map.png/page-0000.png',
        artifact: mapPageArtifact,
      ),
      AssetRecord(
        id: 'legacy-map-asset',
        logicalPath: 'assets/legacy/map.png',
        artifact: legacyMapArtifact,
        usages: ['tileset'],
      ),
    ]);

    final result = const MapGraphicsResetProjector().project(
      manifest: manifest,
      maps: [map],
      assets: assets,
    );

    expect(result.manifest.tilesets.map((value) => value.id), [
      'character-tileset',
    ]);
    expect(result.manifest.characters, manifest.characters);
    expect(result.manifest.elements, isEmpty);
    expect(result.manifest.elementCategories, isEmpty);
    expect(result.manifest.environmentPresets, isEmpty);
    expect(result.manifest.tilesetFolders, isEmpty);
    expect(result.manifest.smartTileCatalog,
        const ProjectSmartTileCatalog.empty());
    expect(result.manifest.borderCatalog, const ProjectBorderCatalog.empty());
    expect(result.maps.single.tilesetId, isEmpty);
    expect(result.maps.single.layers, [map.layers.last]);
    expect(result.maps.single.placedElements, isEmpty);
    expect(result.maps.single.properties, {'story': 'kept'});
    expect(result.assets.records.map((value) => value.id), [
      'character-asset',
    ]);
    expect(result.removedAssetIds, [
      'legacy-map-asset',
      'map-asset',
      'map-page-asset',
    ]);
    expect(result.removedAssetPaths, [
      'assets/legacy/map.png',
      'assets/tilesets/map.png',
      'assets/tilesets/map.png/page-0000.png',
    ]);
  });

  test('descriptor exposes one high-risk atomic reset action', () {
    final descriptor = AssetActions.descriptors.singleWhere(
      (value) => value.id == 'asset.map_graphics.reset',
    );

    expect(descriptor.riskLevel, AuthoringRiskLevel.high);
    expect(descriptor.guarantees, contains(AuthoringGuarantee.atomic));
  });
}
