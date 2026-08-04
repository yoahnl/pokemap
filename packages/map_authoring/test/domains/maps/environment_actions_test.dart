import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('EnvironmentActions', () {
    test('generation preview is deterministic and revision/seed bound', () {
      final fixture = _fixture();
      const actions = EnvironmentActions();

      final first = actions.previewGeneration(
        manifest: fixture.manifest,
        map: fixture.map,
        layerId: 'env',
        areaId: 'forest-area',
        projectRevision: 'map-revision-1',
      );
      final second = actions.previewGeneration(
        manifest: fixture.manifest,
        map: fixture.map,
        layerId: 'env',
        areaId: 'forest-area',
        projectRevision: 'map-revision-1',
      );

      expect(second.fingerprint, first.fingerprint);
      expect(first.projectRevision, 'map-revision-1');
      expect(first.seed, 37);
      expect(first.placements, isNotEmpty);
      expect(
        actions
            .previewGeneration(
              manifest: fixture.manifest,
              map: fixture.map,
              layerId: 'env',
              areaId: 'forest-area',
              projectRevision: 'map-revision-2',
            )
            .fingerprint,
        isNot(first.fingerprint),
      );
    });

    test('local regeneration changes only its documented one-cell halo', () {
      final fixture = _fixture();
      const actions = EnvironmentActions();
      final fullPreview = actions.previewGeneration(
        manifest: fixture.manifest,
        map: fixture.map,
        layerId: 'env',
        areaId: 'forest-area',
        projectRevision: 'map-revision-1',
      );
      final generated = actions.applyGeneration(
        manifest: fixture.manifest,
        map: fixture.map,
        preview: fullPreview,
        currentRevision: 'map-revision-1',
      );
      final outside = generated.placedElements.singleWhere(
        (placement) => placement.pos == const GridPos(x: 5, y: 3),
      );
      final marked = generated.copyWith(
        placedElements: [
          for (final placement in generated.placedElements)
            if (placement.id == outside.id)
              placement.copyWith(properties: const {'outside': 'preserve'})
            else
              placement,
        ],
      );

      final localPreview = actions.previewGeneration(
        manifest: fixture.manifest,
        map: marked,
        layerId: 'env',
        areaId: 'forest-area',
        projectRevision: 'map-revision-2',
        region: const EnvironmentGenerationRegion(
          x: 2,
          y: 1,
          width: 1,
          height: 1,
        ),
      );
      final regenerated = actions.applyGeneration(
        manifest: fixture.manifest,
        map: marked,
        preview: localPreview,
        currentRevision: 'map-revision-2',
      );

      expect(localPreview.haloCells, 1);
      expect(
        localPreview.resolutionRegion,
        const EnvironmentGenerationRegion(x: 1, y: 0, width: 3, height: 3),
      );
      expect(
        regenerated.placedElements
            .singleWhere((placement) => placement.id == outside.id)
            .properties,
        const {'outside': 'preserve'},
      );
    });

    test('canonical dispatcher exposes area, mask, generation and overrides',
        () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();

      expect(
        ids,
        containsAll(<String>{
          'environment.area_create',
          'environment.area_update',
          'environment.area_delete',
          'environment.mask_paint',
          'environment.mask_erase',
          'environment.generate_apply',
          'environment.regenerate_apply',
          'environment.generated_placement_add',
          'environment.generated_placement_move',
          'environment.generated_placement_delete',
        }),
      );
    });
  });
}

({ProjectManifest manifest, MapData map}) _fixture() {
  final preset = EnvironmentPreset(
    id: 'forest',
    name: 'Forest',
    templateId: 'forest',
    palette: [
      EnvironmentPaletteItem(elementId: 'tree', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams(
      density: 1,
      variation: 0,
      edgeDensity: 1,
      minSpacingCells: 0,
    ),
    sortOrder: 0,
  );
  final manifest = ProjectManifest(
    name: 'Environment test',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'decor',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    environmentPresets: [preset],
  );
  final area = EnvironmentArea(
    id: 'forest-area',
    name: 'Forest area',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 6,
      height: 4,
      cells: List<bool>.filled(24, true),
    ),
    seed: 37,
  );
  final map = MapData(
    id: 'map',
    name: 'Map',
    tilesetId: 'nature',
    size: const GridSize(width: 6, height: 4),
    layers: [
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'ground',
          areas: [area],
        ),
      ),
      MapLayer.tile(
        id: 'ground',
        name: 'Ground',
        cells: List<int>.filled(24, 0),
      ),
    ],
  );
  return (manifest: manifest, map: map);
}
