import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';

import 'resource_map_journey_fixture.dart';

Future<ResourceMapJourneyFixture> createUi03Fixture() async {
  final fixture = await ResourceMapJourneyFixture.create();
  final project = fixture.workspace.project!;
  final tileset = project.tilesets.first.copyWith(
    name: 'Atelier — planche complète',
    source: const ProjectTilesetSource.regularAtlas(
      assetId: 'atelier',
      pixelWidth: 160,
      pixelHeight: 64,
      tileWidth: 16,
      tileHeight: 16,
    ),
  );
  final atlas = ProjectSmartTileAtlas(
    id: 'atelier-terrain',
    name: 'Atelier',
    tilesetId: tileset.id,
    columns: 10,
    rows: 4,
    cellWidth: 16,
    cellHeight: 16,
  );
  final terrain = TerrainDraftController(
    manifest: project,
    atlas: atlas,
    id: 'chemin',
    name: 'Chemin de l’atelier',
  );
  for (var mask = 0; mask < 16; mask++) {
    terrain.selectedRule = mask;
    terrain.assign(1, 0);
  }
  fixture.workspace.project = project.copyWith(
    tilesets: [tileset],
    elementCategories: [
      ...project.elementCategories,
      const ProjectElementCategory(id: 'nature', name: 'Nature'),
      const ProjectElementCategory(id: 'objets', name: 'Objets'),
    ],
    elements: [
      for (var i = 0; i < 120; i++)
        project.elements[i % 3].copyWith(
          id: 'decor-$i',
          name:
              '${project.elements[i % 3].name} ${i.toString().padLeft(3, '0')}',
          categoryId: i % 3 == 2 ? 'objets' : 'nature',
          tags: [i % 3 == 2 ? 'mobilier' : 'jardin'],
        ),
      ...project.elements,
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: [atlas],
      materials: terrain.draft.materials,
      presets: [terrain.previewPreset],
    ),
  );
  return fixture;
}
